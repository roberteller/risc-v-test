module csr_file #(
    parameter DATA_WIDTH = 32,
    parameter CSR_WIDTH = 12
)(
    input  logic                    clk,
    input  logic                    rst_n,
    
    // CSR access interface
    input  logic [CSR_WIDTH-1:0]    addr,
    input  logic [DATA_WIDTH-1:0]   wdata,
    input  logic                    we,
    input  logic                    re,
    output logic [DATA_WIDTH-1:0]   rdata,
    
    // Interrupt interface
    input  logic                    m_ext_irq,
    input  logic                    s_ext_irq,
    input  logic                    m_timer_irq,
    input  logic                    m_soft_irq,
    
    // Privilege level
    input  logic [1:0]              current_privilege,
    
    // Trap interface
    output logic                    trap,
    output logic [3:0]              trap_cause
);

    // CSR addresses
    localparam MSTATUS    = 12'h300;
    localparam MISA       = 12'h301;
    localparam MEDELEG    = 12'h302;
    localparam MIDELEG    = 12'h303;
    localparam MIE        = 12'h304;
    localparam MTVEC      = 12'h305;
    localparam MSCRATCH   = 12'h340;
    localparam MEPC       = 12'h341;
    localparam MCAUSE     = 12'h342;
    localparam MTVAL      = 12'h343;
    localparam MIP        = 12'h344;
    localparam SATP       = 12'h180;
    
    // MSTATUS fields
    logic [DATA_WIDTH-1:0] mstatus;
    logic [1:0]            mpp;      // Previous privilege mode
    logic                  mpie;     // Previous interrupt enable
    logic                  mie;      // Machine interrupt enable
    
    // MISA fields
    logic [DATA_WIDTH-1:0] misa;
    
    // Interrupt and exception registers
    logic [DATA_WIDTH-1:0] mepc;     // Machine exception program counter
    logic [DATA_WIDTH-1:0] mcause;   // Machine exception cause
    logic [DATA_WIDTH-1:0] mtval;    // Machine trap value
    logic [DATA_WIDTH-1:0] mtvec;    // Machine trap vector base address
    logic [DATA_WIDTH-1:0] mscratch; // Machine scratch register
    
    // Interrupt enable and pending
    logic [DATA_WIDTH-1:0] mie;      // Machine interrupt enable
    logic [DATA_WIDTH-1:0] mip;      // Machine interrupt pending
    
    // Delegation registers
    logic [DATA_WIDTH-1:0] medeleg;  // Machine exception delegation
    logic [DATA_WIDTH-1:0] mideleg;  // Machine interrupt delegation
    
    // Supervisor address translation and protection
    logic [DATA_WIDTH-1:0] satp;     // Supervisor address translation and protection
    
    // CSR read
    always_comb begin
        rdata = '0;
        
        if (re) begin
            case (addr)
                MSTATUS:  rdata = mstatus;
                MISA:     rdata = misa;
                MEDELEG:  rdata = medeleg;
                MIDELEG:  rdata = mideleg;
                MIE:      rdata = mie;
                MTVEC:    rdata = mtvec;
                MSCRATCH: rdata = mscratch;
                MEPC:     rdata = mepc;
                MCAUSE:   rdata = mcause;
                MTVAL:    rdata = mtval;
                MIP:      rdata = mip;
                SATP:     rdata = satp;
                default:  rdata = '0;
            endcase
        end
    end
    
    // CSR write
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mstatus <= '0;
            misa <= 'h40001100;  // RV32IM
            medeleg <= '0;
            mideleg <= '0;
            mie <= '0;
            mtvec <= 'h80000000;
            mscratch <= '0;
            mepc <= '0;
            mcause <= '0;
            mtval <= '0;
            mip <= '0;
            satp <= '0;
        end else if (we) begin
            case (addr)
                MSTATUS:  mstatus <= wdata;
                MISA:     misa <= wdata;
                MEDELEG:  medeleg <= wdata;
                MIDELEG:  mideleg <= wdata;
                MIE:      mie <= wdata;
                MTVEC:    mtvec <= wdata;
                MSCRATCH: mscratch <= wdata;
                MEPC:     mepc <= wdata;
                MCAUSE:   mcause <= wdata;
                MTVAL:    mtval <= wdata;
                MIP:      mip <= wdata;
                SATP:     satp <= wdata;
            endcase
        end
    end
    
    // Interrupt handling
    always_comb begin
        trap = 1'b0;
        trap_cause = 4'b0000;
        
        // Check for interrupts
        if (mie[11] && mip[11] && current_privilege <= 2'b11) begin  // Machine external interrupt
            trap = 1'b1;
            trap_cause = 4'b1011;
        end else if (mie[7] && mip[7] && current_privilege <= 2'b11) begin  // Machine timer interrupt
            trap = 1'b1;
            trap_cause = 4'b0111;
        end else if (mie[3] && mip[3] && current_privilege <= 2'b11) begin  // Machine software interrupt
            trap = 1'b1;
            trap_cause = 4'b0011;
        end
    end
    
    // Update MIP register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mip <= '0;
        end else begin
            mip[11] <= m_ext_irq;   // Machine external interrupt
            mip[7]  <= m_timer_irq; // Machine timer interrupt
            mip[3]  <= m_soft_irq;  // Machine software interrupt
        end
    end
    
endmodule 