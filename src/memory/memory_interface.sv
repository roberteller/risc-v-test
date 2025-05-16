module memory_interface #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter SDRAM_DATA_WIDTH = 16,
    parameter SDRAM_ADDR_WIDTH = 13,
    parameter SDRAM_BANK_WIDTH = 2
)(
    input  logic                    clk,
    input  logic                    rst_n,
    
    // RISC-V core interface
    input  logic [ADDR_WIDTH-1:0]   core_addr,
    input  logic [DATA_WIDTH-1:0]   core_wdata,
    input  logic                    core_we,
    input  logic [3:0]              core_be,
    output logic [DATA_WIDTH-1:0]   core_rdata,
    input  logic                    core_req,
    output logic                    core_ack,
    
    // DRAM interface
    output logic [ADDR_WIDTH-1:0]   dram_addr,
    output logic [DATA_WIDTH-1:0]   dram_wdata,
    output logic                    dram_we,
    output logic [3:0]              dram_be,
    input  logic [DATA_WIDTH-1:0]   dram_rdata,
    output logic                    dram_req,
    input  logic                    dram_ack,
    
    // Boot ROM interface
    output logic [ADDR_WIDTH-1:0]   rom_addr,
    output logic                    rom_req,
    input  logic [DATA_WIDTH-1:0]   rom_rdata,
    input  logic                    rom_ack,
    
    // CLINT interface
    output logic [ADDR_WIDTH-1:0]   clint_addr,
    output logic [DATA_WIDTH-1:0]   clint_wdata,
    output logic                    clint_we,
    output logic                    clint_re,
    input  logic [DATA_WIDTH-1:0]   clint_rdata,
    output logic                    clint_req,
    input  logic                    clint_ack,
    
    // PLIC interface
    output logic [ADDR_WIDTH-1:0]   plic_addr,
    output logic [DATA_WIDTH-1:0]   plic_wdata,
    output logic                    plic_we,
    output logic                    plic_re,
    input  logic [DATA_WIDTH-1:0]   plic_rdata,
    output logic                    plic_req,
    input  logic                    plic_ack,
    
    // UART interface
    output logic [ADDR_WIDTH-1:0]   uart_addr,
    output logic [DATA_WIDTH-1:0]   uart_wdata,
    output logic                    uart_we,
    output logic                    uart_re,
    input  logic [DATA_WIDTH-1:0]   uart_rdata,
    output logic                    uart_req,
    input  logic                    uart_ack
);

    // Memory map
    localparam ROM_BASE     = 32'h0000_0000;
    localparam ROM_SIZE     = 32'h0000_1000;  // 4KB
    localparam DRAM_BASE    = 32'h8000_0000;
    localparam DRAM_SIZE    = 32'h1000_0000;  // 256MB
    localparam CLINT_BASE   = 32'h0200_0000;
    localparam CLINT_SIZE   = 32'h0001_0000;  // 64KB
    localparam PLIC_BASE    = 32'h0C00_0000;
    localparam PLIC_SIZE    = 32'h0400_0000;  // 64MB
    localparam UART_BASE    = 32'h1000_0000;
    localparam UART_SIZE    = 32'h0000_1000;  // 4KB
    
    // Address decoding
    logic [4:0] device_sel;
    assign device_sel = 
        (core_addr >= ROM_BASE && core_addr < ROM_BASE + ROM_SIZE) ? 5'b00001 :
        (core_addr >= DRAM_BASE && core_addr < DRAM_BASE + DRAM_SIZE) ? 5'b00010 :
        (core_addr >= CLINT_BASE && core_addr < CLINT_BASE + CLINT_SIZE) ? 5'b00100 :
        (core_addr >= PLIC_BASE && core_addr < PLIC_BASE + PLIC_SIZE) ? 5'b01000 :
        (core_addr >= UART_BASE && core_addr < UART_BASE + UART_SIZE) ? 5'b10000 :
        5'b00000;
    
    // Device request signals
    logic rom_req_int;
    logic dram_req_int;
    logic clint_req_int;
    logic plic_req_int;
    logic uart_req_int;
    
    // Device acknowledge signals
    logic rom_ack_int;
    logic dram_ack_int;
    logic clint_ack_int;
    logic plic_ack_int;
    logic uart_ack_int;
    
    // Device read data
    logic [DATA_WIDTH-1:0] rom_rdata_int;
    logic [DATA_WIDTH-1:0] dram_rdata_int;
    logic [DATA_WIDTH-1:0] clint_rdata_int;
    logic [DATA_WIDTH-1:0] plic_rdata_int;
    logic [DATA_WIDTH-1:0] uart_rdata_int;
    
    // Generate device requests
    assign rom_req_int = core_req && device_sel[0];
    assign dram_req_int = core_req && device_sel[1];
    assign clint_req_int = core_req && device_sel[2];
    assign plic_req_int = core_req && device_sel[3];
    assign uart_req_int = core_req && device_sel[4];
    
    // Connect device interfaces
    assign rom_addr = core_addr;
    assign rom_req = rom_req_int;
    assign rom_ack_int = rom_ack;
    assign rom_rdata_int = rom_rdata;
    
    assign dram_addr = core_addr;
    assign dram_wdata = core_wdata;
    assign dram_we = core_we;
    assign dram_be = core_be;
    assign dram_req = dram_req_int;
    assign dram_ack_int = dram_ack;
    assign dram_rdata_int = dram_rdata;
    
    assign clint_addr = core_addr;
    assign clint_wdata = core_wdata;
    assign clint_we = core_we;
    assign clint_re = !core_we;
    assign clint_req = clint_req_int;
    assign clint_ack_int = clint_ack;
    assign clint_rdata_int = clint_rdata;
    
    assign plic_addr = core_addr;
    assign plic_wdata = core_wdata;
    assign plic_we = core_we;
    assign plic_re = !core_we;
    assign plic_req = plic_req_int;
    assign plic_ack_int = plic_ack;
    assign plic_rdata_int = plic_rdata;
    
    assign uart_addr = core_addr;
    assign uart_wdata = core_wdata;
    assign uart_we = core_we;
    assign uart_re = !core_we;
    assign uart_req = uart_req_int;
    assign uart_ack_int = uart_ack;
    assign uart_rdata_int = uart_rdata;
    
    // Core acknowledge and read data
    always_comb begin
        case (device_sel)
            5'b00001: begin
                core_ack = rom_ack_int;
                core_rdata = rom_rdata_int;
            end
            5'b00010: begin
                core_ack = dram_ack_int;
                core_rdata = dram_rdata_int;
            end
            5'b00100: begin
                core_ack = clint_ack_int;
                core_rdata = clint_rdata_int;
            end
            5'b01000: begin
                core_ack = plic_ack_int;
                core_rdata = plic_rdata_int;
            end
            5'b10000: begin
                core_ack = uart_ack_int;
                core_rdata = uart_rdata_int;
            end
            default: begin
                core_ack = 1'b0;
                core_rdata = '0;
            end
        endcase
    end
    
endmodule 