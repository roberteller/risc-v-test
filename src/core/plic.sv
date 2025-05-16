module plic #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter NUM_SOURCES = 32,
    parameter NUM_CONTEXTS = 2
)(
    input  logic                    clk,
    input  logic                    rst_n,
    
    // Memory interface
    input  logic [ADDR_WIDTH-1:0]   addr,
    input  logic [DATA_WIDTH-1:0]   wdata,
    input  logic                    we,
    input  logic                    re,
    output logic [DATA_WIDTH-1:0]   rdata,
    output logic                    ack,
    
    // Interrupt sources
    input  logic [NUM_SOURCES-1:0]  irq_sources,
    
    // Interrupt outputs
    output logic [NUM_CONTEXTS-1:0] m_ext_irq,
    output logic [NUM_CONTEXTS-1:0] s_ext_irq
);

    // PLIC register addresses
    localparam PRIORITY_BASE = 32'h0C000000;  // Interrupt source priorities
    localparam PENDING_BASE = 32'h0C001000;   // Interrupt pending bits
    localparam ENABLE_BASE = 32'h0C002000;    // Interrupt enables
    localparam THRESHOLD_BASE = 32'h0C200000; // Interrupt thresholds
    localparam CLAIM_BASE = 32'h0C200004;     // Interrupt claim/complete
    
    // Registers
    logic [3:0]  priority [NUM_SOURCES-1:0];  // Interrupt priorities
    logic [NUM_SOURCES-1:0] pending;          // Interrupt pending bits
    logic [NUM_SOURCES-1:0] enable [NUM_CONTEXTS-1:0];  // Interrupt enables
    logic [3:0]  threshold [NUM_CONTEXTS-1:0];  // Interrupt thresholds
    logic [5:0]  claim [NUM_CONTEXTS-1:0];    // Interrupt claims
    
    // Internal signals
    logic [NUM_SOURCES-1:0] effective_irq;    // Effective interrupts after priority
    logic [3:0]  max_priority [NUM_CONTEXTS-1:0];  // Maximum priority for each context
    
    // Register read
    always_comb begin
        rdata = '0;
        ack = 1'b0;
        
        if (re) begin
            case (addr)
                // Priority registers
                PRIORITY_BASE + 0: begin
                    rdata = {28'b0, priority[0]};
                    ack = 1'b1;
                end
                PRIORITY_BASE + 4: begin
                    rdata = {28'b0, priority[1]};
                    ack = 1'b1;
                end
                // ... more priority registers ...
                
                // Pending registers
                PENDING_BASE + 0: begin
                    rdata = pending[31:0];
                    ack = 1'b1;
                end
                PENDING_BASE + 4: begin
                    rdata = {32'b0, pending[63:32]};
                    ack = 1'b1;
                end
                
                // Enable registers
                ENABLE_BASE + 0: begin
                    rdata = enable[0][31:0];
                    ack = 1'b1;
                end
                ENABLE_BASE + 4: begin
                    rdata = {32'b0, enable[0][63:32]};
                    ack = 1'b1;
                end
                // ... more enable registers ...
                
                // Threshold registers
                THRESHOLD_BASE + 0: begin
                    rdata = {28'b0, threshold[0]};
                    ack = 1'b1;
                end
                THRESHOLD_BASE + 4: begin
                    rdata = {28'b0, threshold[1]};
                    ack = 1'b1;
                end
                
                // Claim registers
                CLAIM_BASE + 0: begin
                    rdata = {26'b0, claim[0]};
                    ack = 1'b1;
                end
                CLAIM_BASE + 4: begin
                    rdata = {26'b0, claim[1]};
                    ack = 1'b1;
                end
            endcase
        end
    end
    
    // Register write
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < NUM_SOURCES; i++) begin
                priority[i] <= '0;
            end
            pending <= '0;
            for (int i = 0; i < NUM_CONTEXTS; i++) begin
                enable[i] <= '0;
                threshold[i] <= '0;
                claim[i] <= '0;
            end
        end else begin
            if (we) begin
                case (addr)
                    // Priority registers
                    PRIORITY_BASE + 0: priority[0] <= wdata[3:0];
                    PRIORITY_BASE + 4: priority[1] <= wdata[3:0];
                    // ... more priority registers ...
                    
                    // Enable registers
                    ENABLE_BASE + 0: enable[0][31:0] <= wdata;
                    ENABLE_BASE + 4: enable[0][63:32] <= wdata;
                    // ... more enable registers ...
                    
                    // Threshold registers
                    THRESHOLD_BASE + 0: threshold[0] <= wdata[3:0];
                    THRESHOLD_BASE + 4: threshold[1] <= wdata[3:0];
                    
                    // Claim registers
                    CLAIM_BASE + 0: claim[0] <= wdata[5:0];
                    CLAIM_BASE + 4: claim[1] <= wdata[5:0];
                endcase
            end
            
            // Update pending bits
            pending <= (pending & ~irq_sources) | irq_sources;
        end
    end
    
    // Interrupt priority logic
    always_comb begin
        // Calculate effective interrupts
        for (int i = 0; i < NUM_SOURCES; i++) begin
            effective_irq[i] = pending[i] & (priority[i] > 0);
        end
        
        // Find highest priority interrupt for each context
        for (int c = 0; c < NUM_CONTEXTS; c++) begin
            max_priority[c] = '0;
            for (int i = 0; i < NUM_SOURCES; i++) begin
                if (effective_irq[i] && enable[c][i] && priority[i] > max_priority[c]) begin
                    max_priority[c] = priority[i];
                end
            end
        end
    end
    
    // Generate interrupts
    always_comb begin
        for (int c = 0; c < NUM_CONTEXTS; c++) begin
            m_ext_irq[c] = (max_priority[c] > threshold[c]);
            s_ext_irq[c] = 1'b0;  // Supervisor external interrupts not implemented
        end
    end
    
endmodule 