module clint #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
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
    
    // Timer interface
    input  logic [63:0]             time_value,
    
    // Interrupt outputs
    output logic                    m_timer_irq,
    output logic                    m_soft_irq,
    output logic                    s_timer_irq,
    output logic                    s_soft_irq
);

    // CLINT register addresses
    localparam MSIP_BASE    = 32'h02000000;  // Machine software interrupt pending
    localparam MTIMECMP_BASE = 32'h02004000;  // Machine timer compare
    localparam MTIME_BASE   = 32'h0200BFF8;  // Machine time
    
    // Registers
    logic [DATA_WIDTH-1:0] msip;     // Machine software interrupt pending
    logic [63:0]          mtimecmp;  // Machine timer compare
    logic [63:0]          mtime;     // Machine time
    
    // Register read
    always_comb begin
        rdata = '0;
        ack = 1'b0;
        
        if (re) begin
            case (addr)
                MSIP_BASE: begin
                    rdata = msip;
                    ack = 1'b1;
                end
                MTIMECMP_BASE: begin
                    rdata = mtimecmp[31:0];
                    ack = 1'b1;
                end
                MTIMECMP_BASE + 4: begin
                    rdata = mtimecmp[63:32];
                    ack = 1'b1;
                end
                MTIME_BASE: begin
                    rdata = mtime[31:0];
                    ack = 1'b1;
                end
                MTIME_BASE + 4: begin
                    rdata = mtime[63:32];
                    ack = 1'b1;
                end
            endcase
        end
    end
    
    // Register write
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            msip <= '0;
            mtimecmp <= '0;
            mtime <= '0;
        end else begin
            if (we) begin
                case (addr)
                    MSIP_BASE: begin
                        msip <= wdata;
                    end
                    MTIMECMP_BASE: begin
                        mtimecmp[31:0] <= wdata;
                    end
                    MTIMECMP_BASE + 4: begin
                        mtimecmp[63:32] <= wdata;
                    end
                endcase
            end
            
            // Update time register
            mtime <= time_value;
        end
    end
    
    // Generate interrupts
    always_comb begin
        // Machine timer interrupt
        m_timer_irq = (mtime >= mtimecmp);
        
        // Machine software interrupt
        m_soft_irq = msip[0];
        
        // Supervisor interrupts (if implemented)
        s_timer_irq = 1'b0;
        s_soft_irq = 1'b0;
    end
    
endmodule 