module top #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter SDRAM_DATA_WIDTH = 16,
    parameter SDRAM_ADDR_WIDTH = 13,
    parameter SDRAM_BANK_WIDTH = 2
)(
    input  logic                    clk,
    input  logic                    rst_n,
    
    // SDRAM interface
    output logic [SDRAM_ADDR_WIDTH-1:0] sdram_addr,
    output logic [SDRAM_BANK_WIDTH-1:0] sdram_bank,
    output logic [SDRAM_DATA_WIDTH-1:0] sdram_dq_out,
    input  logic [SDRAM_DATA_WIDTH-1:0] sdram_dq_in,
    output logic                    sdram_cke,
    output logic                    sdram_cs_n,
    output logic                    sdram_ras_n,
    output logic                    sdram_cas_n,
    output logic                    sdram_we_n,
    output logic [1:0]              sdram_dqm,
    inout  logic [SDRAM_DATA_WIDTH-1:0] sdram_dq,
    output logic                    sdram_dq_oe,
    
    // UART interface
    input  logic                    uart_rx,
    output logic                    uart_tx
);

    // Internal signals
    logic [ADDR_WIDTH-1:0]   core_addr;
    logic [DATA_WIDTH-1:0]   core_wdata;
    logic                    core_we;
    logic [3:0]              core_be;
    logic [DATA_WIDTH-1:0]   core_rdata;
    logic                    core_req;
    logic                    core_ack;
    
    // Memory interface signals
    logic [ADDR_WIDTH-1:0]   dram_addr;
    logic [DATA_WIDTH-1:0]   dram_wdata;
    logic                    dram_we;
    logic [3:0]              dram_be;
    logic [DATA_WIDTH-1:0]   dram_rdata;
    logic                    dram_req;
    logic                    dram_ack;
    
    logic [ADDR_WIDTH-1:0]   rom_addr;
    logic                    rom_req;
    logic [DATA_WIDTH-1:0]   rom_rdata;
    logic                    rom_ack;
    
    logic [ADDR_WIDTH-1:0]   clint_addr;
    logic [DATA_WIDTH-1:0]   clint_wdata;
    logic                    clint_we;
    logic                    clint_re;
    logic [DATA_WIDTH-1:0]   clint_rdata;
    logic                    clint_req;
    logic                    clint_ack;
    
    logic [ADDR_WIDTH-1:0]   plic_addr;
    logic [DATA_WIDTH-1:0]   plic_wdata;
    logic                    plic_we;
    logic                    plic_re;
    logic [DATA_WIDTH-1:0]   plic_rdata;
    logic                    plic_req;
    logic                    plic_ack;
    
    logic [ADDR_WIDTH-1:0]   uart_addr;
    logic [DATA_WIDTH-1:0]   uart_wdata;
    logic                    uart_we;
    logic                    uart_re;
    logic [DATA_WIDTH-1:0]   uart_rdata;
    logic                    uart_req;
    logic                    uart_ack;
    
    // Interrupt signals
    logic                    m_ext_irq;
    logic                    s_ext_irq;
    logic                    m_timer_irq;
    logic                    m_soft_irq;
    
    // Instantiate RISC-V core
    riscv_core #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) core (
        .clk(clk),
        .rst_n(rst_n),
        .mem_addr(core_addr),
        .mem_wdata(core_wdata),
        .mem_we(core_we),
        .mem_be(core_be),
        .mem_rdata(core_rdata),
        .mem_req(core_req),
        .mem_ack(core_ack),
        .m_ext_irq(m_ext_irq),
        .s_ext_irq(s_ext_irq),
        .m_timer_irq(m_timer_irq),
        .m_soft_irq(m_soft_irq)
    );
    
    // Instantiate memory interface
    memory_interface #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .SDRAM_DATA_WIDTH(SDRAM_DATA_WIDTH),
        .SDRAM_ADDR_WIDTH(SDRAM_ADDR_WIDTH),
        .SDRAM_BANK_WIDTH(SDRAM_BANK_WIDTH)
    ) mem_if (
        .clk(clk),
        .rst_n(rst_n),
        .core_addr(core_addr),
        .core_wdata(core_wdata),
        .core_we(core_we),
        .core_be(core_be),
        .core_rdata(core_rdata),
        .core_req(core_req),
        .core_ack(core_ack),
        .dram_addr(dram_addr),
        .dram_wdata(dram_wdata),
        .dram_we(dram_we),
        .dram_be(dram_be),
        .dram_rdata(dram_rdata),
        .dram_req(dram_req),
        .dram_ack(dram_ack),
        .rom_addr(rom_addr),
        .rom_req(rom_req),
        .rom_rdata(rom_rdata),
        .rom_ack(rom_ack),
        .clint_addr(clint_addr),
        .clint_wdata(clint_wdata),
        .clint_we(clint_we),
        .clint_re(clint_re),
        .clint_rdata(clint_rdata),
        .clint_req(clint_req),
        .clint_ack(clint_ack),
        .plic_addr(plic_addr),
        .plic_wdata(plic_wdata),
        .plic_we(plic_we),
        .plic_re(plic_re),
        .plic_rdata(plic_rdata),
        .plic_req(plic_req),
        .plic_ack(plic_ack),
        .uart_addr(uart_addr),
        .uart_wdata(uart_wdata),
        .uart_we(uart_we),
        .uart_re(uart_re),
        .uart_rdata(uart_rdata),
        .uart_req(uart_req),
        .uart_ack(uart_ack)
    );
    
    // Instantiate DRAM controller
    dram_controller #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .SDRAM_DATA_WIDTH(SDRAM_DATA_WIDTH),
        .SDRAM_ADDR_WIDTH(SDRAM_ADDR_WIDTH),
        .SDRAM_BANK_WIDTH(SDRAM_BANK_WIDTH)
    ) dram_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .core_addr(dram_addr),
        .core_wdata(dram_wdata),
        .core_we(dram_we),
        .core_be(dram_be),
        .core_rdata(dram_rdata),
        .core_req(dram_req),
        .core_ack(dram_ack),
        .sdram_addr(sdram_addr),
        .sdram_bank(sdram_bank),
        .sdram_dq_out(sdram_dq_out),
        .sdram_dq_in(sdram_dq_in),
        .sdram_cke(sdram_cke),
        .sdram_cs_n(sdram_cs_n),
        .sdram_ras_n(sdram_ras_n),
        .sdram_cas_n(sdram_cas_n),
        .sdram_we_n(sdram_we_n),
        .sdram_dqm(sdram_dqm),
        .sdram_dq(sdram_dq),
        .sdram_dq_oe(sdram_dq_oe)
    );
    
    // Instantiate CLINT
    clint #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) clint_inst (
        .clk(clk),
        .rst_n(rst_n),
        .addr(clint_addr),
        .wdata(clint_wdata),
        .we(clint_we),
        .re(clint_re),
        .rdata(clint_rdata),
        .ack(clint_ack),
        .time_value(64'h0),  // TODO: Add timer
        .m_timer_irq(m_timer_irq),
        .m_soft_irq(m_soft_irq),
        .s_timer_irq(),
        .s_soft_irq()
    );
    
    // Instantiate PLIC
    plic #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .NUM_SOURCES(32),
        .NUM_CONTEXTS(2)
    ) plic_inst (
        .clk(clk),
        .rst_n(rst_n),
        .addr(plic_addr),
        .wdata(plic_wdata),
        .we(plic_we),
        .re(plic_re),
        .rdata(plic_rdata),
        .ack(plic_ack),
        .irq_sources(32'h0),  // TODO: Connect external interrupts
        .m_ext_irq({m_ext_irq, 1'b0}),
        .s_ext_irq({s_ext_irq, 1'b0})
    );
    
    // Instantiate UART
    uart #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) uart_inst (
        .clk(clk),
        .rst_n(rst_n),
        .addr(uart_addr),
        .wdata(uart_wdata),
        .we(uart_we),
        .re(uart_re),
        .rdata(uart_rdata),
        .ack(uart_ack),
        .rx(uart_rx),
        .tx(uart_tx)
    );
    
    // Instantiate Boot ROM
    boot_rom #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) rom_inst (
        .clk(clk),
        .rst_n(rst_n),
        .addr(rom_addr),
        .rdata(rom_rdata),
        .req(rom_req),
        .ack(rom_ack)
    );
    
endmodule 