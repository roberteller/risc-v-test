module plic #(
    parameter NUM_CORES = 4,
    parameter NUM_SOURCES = 32,
    parameter ADDR_WIDTH = 64,
    parameter DATA_WIDTH = 64,
    parameter BASE_ADDR = 64'h0C000000,
    parameter MAX_PRIORITY = 7
)(
    input  logic                          clk,
    input  logic                          rst_n,
    
    // Interrupt sources
    input  logic [NUM_SOURCES-1:0]        interrupt_sources,
    
    // Interrupt outputs to cores (machine and supervisor mode)
    output logic [NUM_CORES-1:0]          m_external_interrupt,
    output logic [NUM_CORES-1:0]          s_external_interrupt,
    
    // Memory interface (MMIO)
    input  logic [ADDR_WIDTH-1:0]         mmio_addr,
    input  logic [DATA_WIDTH-1:0]         mmio_write_data,
    output logic [DATA_WIDTH-1:0]         mmio_read_data,
    input  logic                          mmio_read,
    input  logic                          mmio_write,
    input  logic [7:0]                    mmio_byte_en,
    output logic                          mmio_ready,
    output logic                          mmio_error
);

    // PLIC Register Map (relative to BASE_ADDR)
    // 0x000000-0x000FFF: Interrupt source priorities (0x004 per source)
    // 0x001000-0x001FFF: Interrupt pending bits (32 sources = 4 bytes)
    // 0x002000-0x1FFFFF: Interrupt enables (per context)
    // 0x200000-0x3FFFFF: Priority thresholds and claim/complete (per context)
    
    localparam PRIORITY_BASE     = 24'h000000;
    localparam PENDING_BASE      = 24'h001000;
    localparam ENABLE_BASE       = 24'h002000;
    localparam CONTEXT_BASE      = 24'h200000;
    
    // Number of contexts (machine + supervisor mode per core)
    localparam NUM_CONTEXTS = NUM_CORES * 2;
    
    // Internal registers
    logic [MAX_PRIORITY:0][NUM_SOURCES-1:0]  priority_reg;        // Priority per source
    logic [NUM_SOURCES-1:0]                  pending_reg;         // Pending interrupts
    logic [NUM_CONTEXTS-1:0][NUM_SOURCES-1:0] enable_reg;         // Enable per context
    logic [MAX_PRIORITY:0][NUM_CONTEXTS-1:0] threshold_reg;       // Threshold per context
    logic [NUM_SOURCES-1:0][NUM_CONTEXTS-1:0] claimed_reg;        // Claimed interrupts
    
    // Address decoding
    logic [23:0]                             local_addr;
    logic                                    addr_valid;
    logic                                    priority_access;
    logic                                    pending_access;
    logic                                    enable_access;
    logic                                    context_access;
    logic [$clog2(NUM_SOURCES)-1:0]          source_index;
    logic [$clog2(NUM_CONTEXTS)-1:0]         context_index;
    
    assign local_addr = mmio_addr[23:0];
    assign addr_valid = (mmio_addr[ADDR_WIDTH-1:24] == BASE_ADDR[ADDR_WIDTH-1:24]);
    
    // Decode access type
    assign priority_access = addr_valid && (local_addr >= PRIORITY_BASE) && (local_addr < PENDING_BASE);
    assign pending_access = addr_valid && (local_addr >= PENDING_BASE) && (local_addr < ENABLE_BASE);
    assign enable_access = addr_valid && (local_addr >= ENABLE_BASE) && (local_addr < CONTEXT_BASE);
    assign context_access = addr_valid && (local_addr >= CONTEXT_BASE);
    
    // Calculate indices
    assign source_index = priority_access ? local_addr[7:2] :
                         enable_access ? local_addr[4:0] : 5'b0;
    assign context_index = enable_access ? local_addr[11:5] :
                          context_access ? local_addr[14:5] : 5'b0;
    
    // Interrupt arbitration logic
    logic [NUM_CONTEXTS-1:0][MAX_PRIORITY:0]    best_priority;
    logic [NUM_CONTEXTS-1:0][$clog2(NUM_SOURCES)-1:0] best_source;
    logic [NUM_CONTEXTS-1:0]                    interrupt_valid;
    
    // Priority arbitration per context
    genvar ctx, src;
    generate
        for (ctx = 0; ctx < NUM_CONTEXTS; ctx++) begin : gen_context_arbitration
            logic [NUM_SOURCES-1:0] candidate_sources;
            logic [MAX_PRIORITY:0] max_priority;
            logic [$clog2(NUM_SOURCES)-1:0] selected_source;
            logic interrupt_available;
            
            // Find candidate sources (pending, enabled, not claimed, above threshold)
            always_comb begin
                for (int s = 0; s < NUM_SOURCES; s++) begin
                    candidate_sources[s] = pending_reg[s] & 
                                         enable_reg[ctx][s] & 
                                         ~claimed_reg[s][ctx] &
                                         (priority_reg[s] > threshold_reg[ctx]);
                end
            end
            
            // Priority encoder to find highest priority interrupt
            always_comb begin
                max_priority = 0;
                selected_source = 0;
                interrupt_available = 1'b0;
                
                for (int s = 0; s < NUM_SOURCES; s++) begin
                    if (candidate_sources[s] && priority_reg[s] > max_priority) begin
                        max_priority = priority_reg[s];
                        selected_source = s;
                        interrupt_available = 1'b1;
                    end
                end
            end
            
            assign best_priority[ctx] = max_priority;
            assign best_source[ctx] = selected_source;
            assign interrupt_valid[ctx] = interrupt_available;
        end
    endgenerate
    
    // Update pending register based on interrupt sources
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pending_reg <= '0;
        end else begin
            // Set pending bits for active interrupt sources
            pending_reg <= pending_reg | interrupt_sources;
            
            // Clear pending bits when claimed (completed elsewhere)
        end
    end
    
    // Register update logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_reg <= '{default: 3'h0};
            enable_reg <= '{default: '0};
            threshold_reg <= '{default: 3'h0};
            claimed_reg <= '{default: '0};
        end else begin
            // Handle MMIO writes
            if (mmio_write && addr_valid) begin
                if (priority_access && source_index < NUM_SOURCES) begin
                    // Priority register write
                    priority_reg[source_index] <= mmio_write_data[MAX_PRIORITY:0];
                end else if (enable_access && context_index < NUM_CONTEXTS) begin
                    // Enable register write (32 sources per word)
                    if (local_addr[4:2] == 3'b000) begin
                        enable_reg[context_index] <= mmio_write_data[NUM_SOURCES-1:0];
                    end
                end else if (context_access && context_index < NUM_CONTEXTS) begin
                    case (local_addr[4:2])
                        3'b000: begin // Threshold register
                            threshold_reg[context_index] <= mmio_write_data[MAX_PRIORITY:0];
                        end
                        3'b001: begin // Claim/Complete register
                            if (mmio_write_data[4:0] < NUM_SOURCES) begin
                                // Complete interrupt
                                pending_reg[mmio_write_data[4:0]] <= 1'b0;
                                claimed_reg[mmio_write_data[4:0]][context_index] <= 1'b0;
                            end
                        end
                    endcase
                end
            end
            
            // Auto-claim logic when interrupt is serviced
            for (int c = 0; c < NUM_CONTEXTS; c++) begin
                if (interrupt_valid[c] && !claimed_reg[best_source[c]][c]) begin
                    // Claim the interrupt when read
                    if (mmio_read && context_access && context_index == c && 
                        local_addr[4:2] == 3'b001) begin
                        claimed_reg[best_source[c]][c] <= 1'b1;
                    end
                end
            end
        end
    end
    
    // MMIO read logic
    always_comb begin
        mmio_read_data = 64'h0;
        mmio_ready = 1'b1;
        mmio_error = 1'b0;
        
        if (mmio_read && addr_valid) begin
            if (priority_access && source_index < NUM_SOURCES) begin
                // Priority register read
                mmio_read_data = {61'h0, priority_reg[source_index]};
            end else if (pending_access) begin
                // Pending register read
                mmio_read_data = {32'h0, pending_reg};
            end else if (enable_access && context_index < NUM_CONTEXTS) begin
                // Enable register read
                if (local_addr[4:2] == 3'b000) begin
                    mmio_read_data = {32'h0, enable_reg[context_index]};
                end
            end else if (context_access && context_index < NUM_CONTEXTS) begin
                case (local_addr[4:2])
                    3'b000: begin // Threshold register
                        mmio_read_data = {61'h0, threshold_reg[context_index]};
                    end
                    3'b001: begin // Claim register
                        if (interrupt_valid[context_index]) begin
                            mmio_read_data = {59'h0, best_source[context_index]};
                        end else begin
                            mmio_read_data = 64'h0;
                        end
                    end
                endcase
            end else begin
                mmio_error = 1'b1;
            end
        end else if (mmio_read && !addr_valid) begin
            mmio_error = 1'b1;
        end
    end
    
    // Generate external interrupts to cores
    generate
        for (genvar core = 0; core < NUM_CORES; core++) begin : gen_core_interrupts
            // Machine mode context = core * 2
            // Supervisor mode context = core * 2 + 1
            assign m_external_interrupt[core] = interrupt_valid[core * 2];
            assign s_external_interrupt[core] = interrupt_valid[core * 2 + 1];
        end
    endgenerate
    
    // Debug outputs (for simulation/verification)
    `ifdef SIMULATION
    always @(posedge clk) begin
        if (mmio_write && addr_valid) begin
            $display("[PLIC] Write to 0x%08x = 0x%016x", mmio_addr, mmio_write_data);
        end
        if (mmio_read && addr_valid) begin
            $display("[PLIC] Read from 0x%08x = 0x%016x", mmio_addr, mmio_read_data);
        end
        
        for (int c = 0; c < NUM_CONTEXTS; c++) begin
            if (interrupt_valid[c]) begin
                $display("[PLIC] Context %0d: Interrupt %0d with priority %0d", 
                        c, best_source[c], best_priority[c]);
            end
        end
    end
    `endif
    
endmodule 
