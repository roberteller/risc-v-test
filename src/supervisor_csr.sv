module supervisor_csr #(
    parameter DATA_WIDTH = 64
)(
    input  logic                    clk,
    input  logic                    rst_n,
    
    // CSR interface
    input  logic [11:0]             csr_addr,
    input  logic [DATA_WIDTH-1:0]   csr_write_data,
    input  logic [1:0]              csr_op,  // 00: read, 01: write, 10: set, 11: clear
    output logic [DATA_WIDTH-1:0]   csr_read_data,
    output logic                    csr_error,
    
    // Interrupt outputs
    output logic                    s_software_interrupt,
    output logic                    s_timer_interrupt,
    output logic                    s_external_interrupt,
    
    // TLB management
    output logic                    tlb_flush,
    
    // Virtual memory controls
    output logic [DATA_WIDTH-1:0]   satp,
    output logic                    mstatus_sum,  // Supervisor may access user memory
    output logic                    mstatus_mxr,  // Make executable readable
    
    // Current operating mode (from privilege control)
    input  logic [1:0]              current_mode,  // 00:U, 01:S, 11:M
    
    // Exception inputs
    input  logic                    exception,
    input  logic [3:0]              exception_code,
    input  logic [DATA_WIDTH-1:0]   exception_value,
    input  logic [DATA_WIDTH-1:0]   exception_pc,
    input  logic [DATA_WIDTH-1:0]   exception_instr,
    
    // Return from exception
    input  logic                    return_from_exception,
    output logic [DATA_WIDTH-1:0]   return_pc,
    output logic [1:0]              return_mode
);

    // Supervisor CSR addresses
    localparam CSR_SSTATUS          = 12'h100;
    localparam CSR_SIE              = 12'h104;
    localparam CSR_STVEC            = 12'h105;
    localparam CSR_SCOUNTEREN       = 12'h106;
    localparam CSR_SSCRATCH         = 12'h140;
    localparam CSR_SEPC             = 12'h141;
    localparam CSR_SCAUSE           = 12'h142;
    localparam CSR_STVAL            = 12'h143;
    localparam CSR_SIP              = 12'h144;
    localparam CSR_SATP             = 12'h180;
    
    // CSR registers
    logic [DATA_WIDTH-1:0] sstatus_reg;
    logic [DATA_WIDTH-1:0] sie_reg;
    logic [DATA_WIDTH-1:0] stvec_reg;
    logic [DATA_WIDTH-1:0] scounteren_reg;
    logic [DATA_WIDTH-1:0] sscratch_reg;
    logic [DATA_WIDTH-1:0] sepc_reg;
    logic [DATA_WIDTH-1:0] scause_reg;
    logic [DATA_WIDTH-1:0] stval_reg;
    logic [DATA_WIDTH-1:0] sip_reg;
    logic [DATA_WIDTH-1:0] satp_reg;
    
    // SSTATUS fields
    typedef struct packed {
        logic [DATA_WIDTH-20-1:0] reserved_high;
        logic mxr;             // Make executable readable
        logic sum;             // Supervisor user memory access
        logic reserved_13;
        logic [1:0] xs;        // Extension context status
        logic [1:0] fs;        // Floating-point context status
        logic [1:0] reserved_9_8;
        logic spp;             // Supervisor previous privilege
        logic reserved_6;
        logic spie;            // Supervisor previous interrupt enable
        logic [3:0] reserved_5_2;
        logic sie;             // Supervisor interrupt enable
        logic reserved_0;
    } sstatus_t;
    
    // SIE fields
    typedef struct packed {
        logic [DATA_WIDTH-13-1:0] reserved_high;
        logic seie;            // Supervisor external interrupt enable
        logic [2:0] reserved_8_6;
        logic stie;            // Supervisor timer interrupt enable
        logic [2:0] reserved_4_2;
        logic ssie;            // Supervisor software interrupt enable
        logic reserved_0;
    } sie_t;
    
    // SIP fields (same structure as SIE)
    typedef struct packed {
        logic [DATA_WIDTH-13-1:0] reserved_high;
        logic seip;            // Supervisor external interrupt pending
        logic [2:0] reserved_8_6;
        logic stip;            // Supervisor timer interrupt pending
        logic [2:0] reserved_4_2;
        logic ssip;            // Supervisor software interrupt pending
        logic reserved_0;
    } sip_t;
    
    // SCAUSE fields
    typedef struct packed {
        logic interrupt;       // 1 if interrupt, 0 if exception
        logic [DATA_WIDTH-2-1:0] reserved_high;
        logic [3:0] code;      // Exception/interrupt code
    } scause_t;
    
    // SATP fields (for RV64 with Sv39)
    typedef struct packed {
        logic [3:0] mode;      // 0: bare (no translation), 8: Sv39
        logic [15:0] asid;     // Address space identifier
        logic [43:0] ppn;      // Physical page number of root page table
    } satp_t;
    
    // CSR field access
    sstatus_t sstatus;
    sie_t sie;
    sip_t sip;
    scause_t scause;
    satp_t satp_fields;
    
    // Connect structs to actual registers
    assign sstatus = sstatus_reg;
    assign sie = sie_reg;
    assign sip = sip_reg;
    assign scause = scause_reg;
    assign satp_fields = satp_reg;
    
    // Export important control signals
    assign satp = satp_reg;
    assign mstatus_sum = sstatus.sum;
    assign mstatus_mxr = sstatus.mxr;
    
    // Interrupt outputs
    assign s_software_interrupt = sie.ssie & sip.ssip;
    assign s_timer_interrupt = sie.stie & sip.stip;
    assign s_external_interrupt = sie.seie & sip.seip;
    
    // Return from exception
    assign return_pc = sepc_reg;
    assign return_mode = {1'b0, sstatus.spp};  // Convert SPP to 2-bit mode
    
    // CSR write logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sstatus_reg <= 64'h0;
            sie_reg <= 64'h0;
            stvec_reg <= 64'h0;
            scounteren_reg <= 64'h0;
            sscratch_reg <= 64'h0;
            sepc_reg <= 64'h0;
            scause_reg <= 64'h0;
            stval_reg <= 64'h0;
            sip_reg <= 64'h0;
            satp_reg <= 64'h0;
            tlb_flush <= 1'b0;
        end else begin
            // Reset tlb_flush pulse
            tlb_flush <= 1'b0;
            
            // Handle exception entry
            if (exception) begin
                // Save current PC and mode
                sepc_reg <= exception_pc;
                
                // Update sstatus
                // Create a local variable for the modified status
                logic [DATA_WIDTH-1:0] new_sstatus_reg;
                new_sstatus_reg = sstatus_reg;
                
                // Modify using bit-field assignments compatible with Verilator
                // Extract and modify sstatus fields
                sstatus_t temp_sstatus;
                temp_sstatus = sstatus_reg;
                temp_sstatus.spp = current_mode[0];  // Save previous privilege (only bit 0)
                temp_sstatus.spie = temp_sstatus.sie;  // Save previous interrupt enable
                temp_sstatus.sie = 1'b0;              // Disable interrupts
                new_sstatus_reg = temp_sstatus;
                
                // Update the register
                sstatus_reg <= new_sstatus_reg;
                
                // Update scause
                // Create a local variable for the modified status
                logic [DATA_WIDTH-1:0] new_scause_reg;
                new_scause_reg = 64'h0;
                
                // Set fields directly in a Verilator-compatible way
                scause_t temp_scause;
                temp_scause.interrupt = (exception_code >= 4'h8);
                temp_scause.reserved_high = '0;
                temp_scause.code = exception_code;
                new_scause_reg = temp_scause;
                
                scause_reg <= new_scause_reg;
                
                // Update stval with exception-specific value
                stval_reg <= exception_value;
            end
            
            // Handle SRET (return from exception)
            if (return_from_exception) begin
                // Update sstatus
                // Create a local variable for the modified status
                logic [DATA_WIDTH-1:0] new_sstatus_reg;
                
                // Extract and modify sstatus fields
                sstatus_t temp_sstatus;
                temp_sstatus = sstatus_reg;
                temp_sstatus.sie = temp_sstatus.spie;  // Restore previous interrupt enable
                temp_sstatus.spie = 1'b1;              // Set SPIE to 1
                temp_sstatus.spp = 1'b0;               // Clear SPP (return to U-mode)
                new_sstatus_reg = temp_sstatus;
                
                // Update the register
                sstatus_reg <= new_sstatus_reg;
            end
            
            // CSR write operations
            if (csr_op != 2'b00 && (current_mode >= 2'b01 || (current_mode == 2'b00 && csr_addr[9:8] == 2'b00))) begin
                case (csr_addr)
                    CSR_SSTATUS: begin
                        case (csr_op)
                            2'b01: sstatus_reg <= csr_write_data;
                            2'b10: sstatus_reg <= sstatus_reg | csr_write_data;
                            2'b11: sstatus_reg <= sstatus_reg & ~csr_write_data;
                        endcase
                    end
                    
                    CSR_SIE: begin
                        case (csr_op)
                            2'b01: sie_reg <= csr_write_data;
                            2'b10: sie_reg <= sie_reg | csr_write_data;
                            2'b11: sie_reg <= sie_reg & ~csr_write_data;
                        endcase
                    end
                    
                    CSR_STVEC: begin
                        case (csr_op)
                            2'b01: stvec_reg <= csr_write_data;
                            2'b10: stvec_reg <= stvec_reg | csr_write_data;
                            2'b11: stvec_reg <= stvec_reg & ~csr_write_data;
                        endcase
                    end
                    
                    CSR_SCOUNTEREN: begin
                        case (csr_op)
                            2'b01: scounteren_reg <= csr_write_data;
                            2'b10: scounteren_reg <= scounteren_reg | csr_write_data;
                            2'b11: scounteren_reg <= scounteren_reg & ~csr_write_data;
                        endcase
                    end
                    
                    CSR_SSCRATCH: begin
                        case (csr_op)
                            2'b01: sscratch_reg <= csr_write_data;
                            2'b10: sscratch_reg <= sscratch_reg | csr_write_data;
                            2'b11: sscratch_reg <= sscratch_reg & ~csr_write_data;
                        endcase
                    end
                    
                    CSR_SEPC: begin
                        case (csr_op)
                            2'b01: sepc_reg <= csr_write_data & ~64'h1; // Clear LSB for alignment
                            2'b10: sepc_reg <= (sepc_reg | csr_write_data) & ~64'h1;
                            2'b11: sepc_reg <= (sepc_reg & ~csr_write_data) & ~64'h1;
                        endcase
                    end
                    
                    CSR_SCAUSE: begin
                        case (csr_op)
                            2'b01: scause_reg <= csr_write_data;
                            2'b10: scause_reg <= scause_reg | csr_write_data;
                            2'b11: scause_reg <= scause_reg & ~csr_write_data;
                        endcase
                    end
                    
                    CSR_STVAL: begin
                        case (csr_op)
                            2'b01: stval_reg <= csr_write_data;
                            2'b10: stval_reg <= stval_reg | csr_write_data;
                            2'b11: stval_reg <= stval_reg & ~csr_write_data;
                        endcase
                    end
                    
                    CSR_SIP: begin
                        // Only software interrupt bits are writable by software
                        logic [DATA_WIDTH-1:0] mask = 64'h2; // SSIP bit is writable
                        logic [DATA_WIDTH-1:0] new_value;
                        
                        case (csr_op)
                            2'b01: new_value = (sip_reg & ~mask) | (csr_write_data & mask);
                            2'b10: new_value = sip_reg | (csr_write_data & mask);
                            2'b11: new_value = sip_reg & ~(csr_write_data & mask);
                            default: new_value = sip_reg;
                        endcase
                        
                        sip_reg <= new_value;
                    end
                    
                    CSR_SATP: begin
                        logic [DATA_WIDTH-1:0] new_satp;
                        
                        case (csr_op)
                            2'b01: new_satp = csr_write_data;
                            2'b10: new_satp = satp_reg | csr_write_data;
                            2'b11: new_satp = satp_reg & ~csr_write_data;
                            default: new_satp = satp_reg;
                        endcase
                        
                        // Only allowed in S and M modes
                        if (current_mode >= 2'b01) begin
                            // Check if mode field is changing or ASID changed
                            if ((new_satp[63:60] != satp_reg[63:60]) || 
                                (new_satp[59:44] != satp_reg[59:44])) begin
                                tlb_flush <= 1'b1;
                            end
                            
                            satp_reg <= new_satp;
                        end
                    end
                endcase
            end
        end
    end
    
    // CSR read logic
    always_comb begin
        csr_error = 1'b0;
        
        // Only allow access in S and M modes, or U mode for user-level CSRs
        if (current_mode >= 2'b01 || (current_mode == 2'b00 && csr_addr[9:8] == 2'b00)) begin
            case (csr_addr)
                CSR_SSTATUS:     csr_read_data = sstatus_reg;
                CSR_SIE:         csr_read_data = sie_reg;
                CSR_STVEC:       csr_read_data = stvec_reg;
                CSR_SCOUNTEREN:  csr_read_data = scounteren_reg;
                CSR_SSCRATCH:    csr_read_data = sscratch_reg;
                CSR_SEPC:        csr_read_data = sepc_reg;
                CSR_SCAUSE:      csr_read_data = scause_reg;
                CSR_STVAL:       csr_read_data = stval_reg;
                CSR_SIP:         csr_read_data = sip_reg;
                CSR_SATP:        csr_read_data = satp_reg;
                default: begin
                    csr_read_data = '0;
                    csr_error = 1'b1;
                end
            endcase
        end else begin
            // Access denied due to insufficient privilege
            csr_read_data = '0;
            csr_error = 1'b1;
        end
    end

endmodule 
