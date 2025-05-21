module csr #(
    parameter DATA_WIDTH = 64
)(
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic [11:0]            csr_addr,
    input  logic [DATA_WIDTH-1:0]   csr_write_data,
    input  logic [1:0]             csr_op,  // 00: read, 01: write, 10: set, 11: clear
    output logic [DATA_WIDTH-1:0]   csr_read_data,
    output logic                    csr_error,
    
    // Performance counter inputs
    input  logic [63:0]            cycles,
    input  logic [63:0]            instructions,
    input  logic [63:0]            branches,
    input  logic [63:0]            branch_mispredicts,
    input  logic [63:0]            loads,
    input  logic [63:0]            stores,
    input  logic [63:0]            load_use_stalls,
    input  logic [63:0]            alignment_faults,
    
    // Exception and interrupt handling
    input  logic                    exception_raised,
    input  logic [3:0]             exception_code,
    input  logic [DATA_WIDTH-1:0]   exception_value,
    input  logic [DATA_WIDTH-1:0]   exception_pc,
    input  logic                    external_interrupt,
    input  logic                    timer_interrupt,
    input  logic                    software_interrupt,
    output logic                    handle_exception,
    output logic [DATA_WIDTH-1:0]   exception_target
);

    // CSR addresses
    // Machine information registers
    localparam CSR_MVENDORID   = 12'hF11;
    localparam CSR_MARCHID     = 12'hF12;
    localparam CSR_MIMPID      = 12'hF13;
    localparam CSR_MHARTID     = 12'hF14;
    
    // Machine trap setup
    localparam CSR_MSTATUS     = 12'h300;
    localparam CSR_MISA        = 12'h301;
    localparam CSR_MEDELEG     = 12'h302;
    localparam CSR_MIDELEG     = 12'h303;
    localparam CSR_MIE         = 12'h304;
    localparam CSR_MTVEC       = 12'h305;
    localparam CSR_MCOUNTEREN  = 12'h306;
    
    // Machine trap handling
    localparam CSR_MSCRATCH    = 12'h340;
    localparam CSR_MEPC        = 12'h341;
    localparam CSR_MCAUSE      = 12'h342;
    localparam CSR_MTVAL       = 12'h343;
    localparam CSR_MIP         = 12'h344;
    
    // Machine counters/timers
    localparam CSR_MCYCLE      = 12'hB00;
    localparam CSR_MINSTRET    = 12'hB02;
    localparam CSR_CYCLE       = 12'hC00;
    localparam CSR_TIME        = 12'hC01;
    localparam CSR_INSTRET     = 12'hC02;
    localparam CSR_CYCLEH      = 12'hC80;
    localparam CSR_TIMEH       = 12'hC81;
    localparam CSR_INSTRETH    = 12'hC82;
    
    // Performance counters
    localparam CSR_MHPMCOUNTER3  = 12'hB03;  // Branches
    localparam CSR_MHPMCOUNTER4  = 12'hB04;  // Branch mispredicts
    localparam CSR_MHPMCOUNTER5  = 12'hB05;  // Loads
    localparam CSR_MHPMCOUNTER6  = 12'hB06;  // Stores
    localparam CSR_MHPMCOUNTER7  = 12'hB07;  // Load-use stalls
    localparam CSR_MHPMCOUNTER8  = 12'hB08;  // Alignment faults

    // CSR registers
    // Performance counters
    logic [DATA_WIDTH-1:0] cycle_reg;
    logic [DATA_WIDTH-1:0] time_reg;
    logic [DATA_WIDTH-1:0] instret_reg;
    logic [DATA_WIDTH-1:0] mhpmcounter3_reg;
    logic [DATA_WIDTH-1:0] mhpmcounter4_reg;
    logic [DATA_WIDTH-1:0] mhpmcounter5_reg;
    logic [DATA_WIDTH-1:0] mhpmcounter6_reg;
    logic [DATA_WIDTH-1:0] mhpmcounter7_reg;
    logic [DATA_WIDTH-1:0] mhpmcounter8_reg;
    
    // Trap handling registers
    logic [DATA_WIDTH-1:0] mstatus_reg;
    logic [DATA_WIDTH-1:0] misa_reg;
    logic [DATA_WIDTH-1:0] medeleg_reg;
    logic [DATA_WIDTH-1:0] mideleg_reg;
    logic [DATA_WIDTH-1:0] mie_reg;
    logic [DATA_WIDTH-1:0] mtvec_reg;
    logic [DATA_WIDTH-1:0] mscratch_reg;
    logic [DATA_WIDTH-1:0] mepc_reg;
    logic [DATA_WIDTH-1:0] mcause_reg;
    logic [DATA_WIDTH-1:0] mtval_reg;
    logic [DATA_WIDTH-1:0] mip_reg;
    
    // Information registers
    logic [DATA_WIDTH-1:0] mvendorid_reg;
    logic [DATA_WIDTH-1:0] marchid_reg;
    logic [DATA_WIDTH-1:0] mimpid_reg;
    logic [DATA_WIDTH-1:0] mhartid_reg;
    
    // MSTATUS bit positions
    localparam MIE_BIT  = 3;   // Machine Interrupt Enable
    localparam MPIE_BIT = 7;   // Previous MIE value
    localparam MPP_BIT  = 11;  // Previous privilege mode (2 bits: 11:12)
    
    // MIE and MIP bit positions
    localparam MSIE_BIT = 3;   // Machine software interrupt enable
    localparam MTIE_BIT = 7;   // Machine timer interrupt enable
    localparam MEIE_BIT = 11;  // Machine external interrupt enable
    
    // MCAUSE values
    localparam INTERRUPT_BIT = 63;  // Set for interrupts
    
    // Privilege modes
    localparam PRIV_USER       = 2'b00;
    localparam PRIV_SUPERVISOR = 2'b01;
    localparam PRIV_MACHINE    = 2'b11;
    
    // Current privilege mode
    logic [1:0] privilege_mode;
    
    // Interrupt pending logic
    logic interrupt_pending;
    logic [DATA_WIDTH-1:0] interrupt_cause;
    
    // Exception enabling
    initial begin
        privilege_mode = PRIV_MACHINE;
        misa_reg = 64'h8000000000100100;  // RV64I base ISA + M extension
        mvendorid_reg = 64'h0;  // Non-commercial implementation
        marchid_reg = 64'h0;  // Not implemented
        mimpid_reg = 64'h0;  // Version 0
        mhartid_reg = 64'h0;  // Hart ID 0
        mtvec_reg = 64'h0;  // Default trap vector
        medeleg_reg = 64'h0;  // No delegation
        mideleg_reg = 64'h0;  // No delegation
        mie_reg = 64'h0;  // Interrupts disabled
        mip_reg = 64'h0;  // No interrupts pending
        mstatus_reg = 64'h0;  // Interrupts disabled
    end
    
    // Interrupt pending detection
    always_comb begin
        interrupt_pending = 1'b0;
        interrupt_cause = '0;
        
        // Check if interrupts are globally enabled
        if (mstatus_reg[MIE_BIT]) begin
            // External interrupt
            if (external_interrupt && mie_reg[MEIE_BIT]) begin
                interrupt_pending = 1'b1;
                interrupt_cause = (1 << INTERRUPT_BIT) | 11;  // Machine external interrupt
            end
            // Timer interrupt
            else if (timer_interrupt && mie_reg[MTIE_BIT]) begin
                interrupt_pending = 1'b1;
                interrupt_cause = (1 << INTERRUPT_BIT) | 7;  // Machine timer interrupt
            end
            // Software interrupt
            else if (software_interrupt && mie_reg[MSIE_BIT]) begin
                interrupt_pending = 1'b1;
                interrupt_cause = (1 << INTERRUPT_BIT) | 3;  // Machine software interrupt
            end
        end
    end
    
    // Exception and interrupt handling
    always_comb begin
        handle_exception = 1'b0;
        exception_target = 64'h0;
        
        if (exception_raised) begin
            handle_exception = 1'b1;
            exception_target = mtvec_reg;
        end
        else if (interrupt_pending) begin
            handle_exception = 1'b1;
            // Check trap vector mode (bit 0 of mtvec)
            if (mtvec_reg[0] == 1'b0) begin
                // Direct mode
                exception_target = {mtvec_reg[DATA_WIDTH-1:2], 2'b00};
            end else begin
                // Vectored mode
                exception_target = {mtvec_reg[DATA_WIDTH-1:2], 2'b00} + (interrupt_cause[5:0] * 4);
            end
        end
    end

    // CSR write logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_reg <= '0;
            time_reg <= '0;
            instret_reg <= '0;
            mhpmcounter3_reg <= '0;
            mhpmcounter4_reg <= '0;
            mhpmcounter5_reg <= '0;
            mhpmcounter6_reg <= '0;
            mhpmcounter7_reg <= '0;
            mhpmcounter8_reg <= '0;
            mstatus_reg <= '0;
            mie_reg <= '0;
            mtvec_reg <= '0;
            mscratch_reg <= '0;
            mepc_reg <= '0;
            mcause_reg <= '0;
            mtval_reg <= '0;
            mip_reg <= '0;
        end else begin
            // Update performance counters
            cycle_reg <= cycles;
            time_reg <= $time;
            instret_reg <= instructions;
            mhpmcounter3_reg <= branches;
            mhpmcounter4_reg <= branch_mispredicts;
            mhpmcounter5_reg <= loads;
            mhpmcounter6_reg <= stores;
            mhpmcounter7_reg <= load_use_stalls;
            mhpmcounter8_reg <= alignment_faults;

            // Update MIP with external interrupt status
            mip_reg[MEIE_BIT] <= external_interrupt;
            mip_reg[MTIE_BIT] <= timer_interrupt;
            mip_reg[MSIE_BIT] <= software_interrupt;
            
            // Handle exceptions
            if (exception_raised) begin
                // Save current state
                mepc_reg <= exception_pc;
                mcause_reg <= {60'h0, exception_code};
                mtval_reg <= exception_value;
                
                // Update status register
                mstatus_reg[MPIE_BIT] <= mstatus_reg[MIE_BIT];  // Save current interrupt enable
                mstatus_reg[MIE_BIT] <= 1'b0;  // Disable interrupts
                mstatus_reg[MPP_BIT+:2] <= privilege_mode;  // Save privilege mode
                
                // Enter machine mode
                privilege_mode <= PRIV_MACHINE;
            end
            // Handle interrupts
            else if (interrupt_pending) begin
                // Save current state
                mepc_reg <= exception_pc;
                mcause_reg <= interrupt_cause;
                
                // Update status register
                mstatus_reg[MPIE_BIT] <= mstatus_reg[MIE_BIT];  // Save current interrupt enable
                mstatus_reg[MIE_BIT] <= 1'b0;  // Disable interrupts
                mstatus_reg[MPP_BIT+:2] <= privilege_mode;  // Save privilege mode
                
                // Enter machine mode
                privilege_mode <= PRIV_MACHINE;
            end
            // MRET instruction handling
            else if (csr_op != 2'b00 && csr_addr == CSR_MEPC && csr_write_data == 64'hFFFFFFFF) begin
                // Restore previous interrupt enable and privilege mode
                mstatus_reg[MIE_BIT] <= mstatus_reg[MPIE_BIT];
                privilege_mode <= mstatus_reg[MPP_BIT+:2];
                mstatus_reg[MPIE_BIT] <= 1'b1;
                mstatus_reg[MPP_BIT+:2] <= PRIV_MACHINE;
            end
            
            // CSR write operations
            if (csr_op != 2'b00) begin  // Not a read operation
                case (csr_addr)
                    CSR_MSTATUS: begin
                        case (csr_op)
                            2'b01: mstatus_reg <= csr_write_data & 64'h88;  // Write (only allow MIE and MPIE bits)
                            2'b10: mstatus_reg <= mstatus_reg | (csr_write_data & 64'h88);  // Set
                            2'b11: mstatus_reg <= mstatus_reg & ~(csr_write_data & 64'h88);  // Clear
                        endcase
                    end
                    CSR_MIE: begin
                        case (csr_op)
                            2'b01: mie_reg <= csr_write_data & 64'h888;  // Write (only MSIE, MTIE, MEIE)
                            2'b10: mie_reg <= mie_reg | (csr_write_data & 64'h888);  // Set
                            2'b11: mie_reg <= mie_reg & ~(csr_write_data & 64'h888);  // Clear
                        endcase
                    end
                    CSR_MTVEC: begin
                        case (csr_op)
                            2'b01: mtvec_reg <= csr_write_data;  // Write
                            2'b10: mtvec_reg <= mtvec_reg | csr_write_data;  // Set
                            2'b11: mtvec_reg <= mtvec_reg & ~csr_write_data;  // Clear
                        endcase
                    end
                    CSR_MSCRATCH: begin
                        case (csr_op)
                            2'b01: mscratch_reg <= csr_write_data;  // Write
                            2'b10: mscratch_reg <= mscratch_reg | csr_write_data;  // Set
                            2'b11: mscratch_reg <= mscratch_reg & ~csr_write_data;  // Clear
                        endcase
                    end
                    CSR_MEPC: begin
                        case (csr_op)
                            2'b01: mepc_reg <= csr_write_data & ~64'h3;  // Write (align to 4 bytes)
                            2'b10: mepc_reg <= mepc_reg | (csr_write_data & ~64'h3);  // Set
                            2'b11: mepc_reg <= mepc_reg & ~(csr_write_data & ~64'h3);  // Clear
                        endcase
                    end
                    CSR_MCAUSE: begin
                        case (csr_op)
                            2'b01: mcause_reg <= csr_write_data;  // Write
                            2'b10: mcause_reg <= mcause_reg | csr_write_data;  // Set
                            2'b11: mcause_reg <= mcause_reg & ~csr_write_data;  // Clear
                        endcase
                    end
                    CSR_MTVAL: begin
                        case (csr_op)
                            2'b01: mtval_reg <= csr_write_data;  // Write
                            2'b10: mtval_reg <= mtval_reg | csr_write_data;  // Set
                            2'b11: mtval_reg <= mtval_reg & ~csr_write_data;  // Clear
                        endcase
                    end
                    // Performance counters are read-only in this implementation
                    // Other CSRs
                    default: begin
                        // Not implemented or read-only
                    end
                endcase
            end
        end
    end

    // CSR read logic
    always_comb begin
        csr_error = 1'b0;
        case (csr_addr)
            // Machine Information Registers (read-only)
            CSR_MVENDORID: csr_read_data = mvendorid_reg;
            CSR_MARCHID: csr_read_data = marchid_reg;
            CSR_MIMPID: csr_read_data = mimpid_reg;
            CSR_MHARTID: csr_read_data = mhartid_reg;
            
            // Machine Trap Setup
            CSR_MSTATUS: csr_read_data = mstatus_reg;
            CSR_MISA: csr_read_data = misa_reg;
            CSR_MEDELEG: csr_read_data = medeleg_reg;
            CSR_MIDELEG: csr_read_data = mideleg_reg;
            CSR_MIE: csr_read_data = mie_reg;
            CSR_MTVEC: csr_read_data = mtvec_reg;
            
            // Machine Trap Handling
            CSR_MSCRATCH: csr_read_data = mscratch_reg;
            CSR_MEPC: csr_read_data = mepc_reg;
            CSR_MCAUSE: csr_read_data = mcause_reg;
            CSR_MTVAL: csr_read_data = mtval_reg;
            CSR_MIP: csr_read_data = mip_reg;
            
            // Performance Counters
            CSR_CYCLE: csr_read_data = cycle_reg;
            CSR_MCYCLE: csr_read_data = cycle_reg;
            CSR_TIME: csr_read_data = time_reg;
            CSR_INSTRET: csr_read_data = instret_reg;
            CSR_MINSTRET: csr_read_data = instret_reg;
            CSR_CYCLEH: csr_read_data = cycle_reg[63:32];
            CSR_TIMEH: csr_read_data = time_reg[63:32];
            CSR_INSTRETH: csr_read_data = instret_reg[63:32];
            CSR_MHPMCOUNTER3: csr_read_data = mhpmcounter3_reg;
            CSR_MHPMCOUNTER4: csr_read_data = mhpmcounter4_reg;
            CSR_MHPMCOUNTER5: csr_read_data = mhpmcounter5_reg;
            CSR_MHPMCOUNTER6: csr_read_data = mhpmcounter6_reg;
            CSR_MHPMCOUNTER7: csr_read_data = mhpmcounter7_reg;
            CSR_MHPMCOUNTER8: csr_read_data = mhpmcounter8_reg;
            default: begin
                csr_read_data = '0;
                csr_error = 1'b1;
            end
        endcase
    end

endmodule 