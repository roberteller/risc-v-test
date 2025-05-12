module riscv_fpga_top (
    input  logic        clk,           // System clock
    input  logic        rst_n,         // Active low reset
    input  logic [3:0]  btn,           // Push buttons
    output logic [7:0]  led,           // LEDs
    output logic [7:0]  an,            // 7-segment display anodes
    output logic [6:0]  seg,           // 7-segment display segments
    output logic        uart_tx,       // UART transmit
    input  logic        uart_rx        // UART receive
);

    // Parameters
    localparam CLK_FREQ = 100_000_000;  // 100 MHz
    localparam BAUD_RATE = 115200;
    localparam MEM_SIZE = 1024*1024;    // 1MB memory

    // Internal signals
    logic        sys_clk;
    logic        sys_rst;
    logic [31:0] pc;
    logic [31:0] instruction;
    logic        mem_read;
    logic        mem_write;
    logic [31:0] mem_addr;
    logic [31:0] mem_wdata;
    logic [31:0] mem_rdata;
    logic        mem_ready;
    logic [31:0] debug_data;
    logic        debug_valid;

    // Clock and reset generation
    clk_wiz_0 clk_wiz (
        .clk_in1(clk),
        .clk_out1(sys_clk),
        .reset(!rst_n),
        .locked()
    );

    // Reset synchronizer
    reset_sync reset_sync_inst (
        .clk(sys_clk),
        .rst_n(rst_n),
        .rst(sys_rst)
    );

    // RISC-V core instance
    riscv_core #(
        .MEM_SIZE(MEM_SIZE)
    ) core (
        .clk(sys_clk),
        .rst(sys_rst),
        .pc(pc),
        .instruction(instruction),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_rdata(mem_rdata),
        .mem_ready(mem_ready),
        .debug_data(debug_data),
        .debug_valid(debug_valid)
    );

    // Memory controller
    memory_controller #(
        .MEM_SIZE(MEM_SIZE)
    ) mem_ctrl (
        .clk(sys_clk),
        .rst(sys_rst),
        .read(mem_read),
        .write(mem_write),
        .addr(mem_addr),
        .wdata(mem_wdata),
        .rdata(mem_rdata),
        .ready(mem_ready)
    );

    // Debug interface
    debug_interface debug_if (
        .clk(sys_clk),
        .rst(sys_rst),
        .pc(pc),
        .instruction(instruction),
        .debug_data(debug_data),
        .debug_valid(debug_valid),
        .btn(btn),
        .led(led),
        .an(an),
        .seg(seg),
        .uart_tx(uart_tx),
        .uart_rx(uart_rx)
    );

endmodule 