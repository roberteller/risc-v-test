module dram_controller_tb;
    // Parameters
    localparam DATA_WIDTH = 32;
    localparam ADDR_WIDTH = 32;
    localparam SDRAM_DATA_WIDTH = 16;
    localparam SDRAM_ADDR_WIDTH = 13;
    localparam SDRAM_BANK_WIDTH = 2;
    localparam CLK_PERIOD = 10;  // 100MHz clock
    
    // Signals
    logic                    clk;
    logic                    rst_n;
    
    // Core interface
    logic [ADDR_WIDTH-1:0]   core_addr;
    logic [DATA_WIDTH-1:0]   core_wdata;
    logic                    core_we;
    logic [3:0]              core_be;
    logic [DATA_WIDTH-1:0]   core_rdata;
    logic                    core_req;
    logic                    core_ack;
    
    // SDRAM interface
    logic [SDRAM_ADDR_WIDTH-1:0] sdram_addr;
    logic [SDRAM_BANK_WIDTH-1:0] sdram_bank;
    logic [SDRAM_DATA_WIDTH-1:0] sdram_dq_out;
    logic [SDRAM_DATA_WIDTH-1:0] sdram_dq_in;
    logic                    sdram_cke;
    logic                    sdram_cs_n;
    logic                    sdram_ras_n;
    logic                    sdram_cas_n;
    logic                    sdram_we_n;
    logic [1:0]              sdram_dqm;
    wire  [SDRAM_DATA_WIDTH-1:0] sdram_dq;
    logic                    sdram_dq_oe;
    
    // SDRAM model signals
    logic [SDRAM_DATA_WIDTH-1:0] sdram_data;
    logic [SDRAM_DATA_WIDTH-1:0] sdram_data_out;
    logic                    sdram_data_oe;
    
    // Instantiate DUT
    dram_controller #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .SDRAM_DATA_WIDTH(SDRAM_DATA_WIDTH),
        .SDRAM_ADDR_WIDTH(SDRAM_ADDR_WIDTH),
        .SDRAM_BANK_WIDTH(SDRAM_BANK_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .core_addr(core_addr),
        .core_wdata(core_wdata),
        .core_we(core_we),
        .core_be(core_be),
        .core_rdata(core_rdata),
        .core_req(core_req),
        .core_ack(core_ack),
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
    
    // SDRAM model
    sdram_model #(
        .DATA_WIDTH(SDRAM_DATA_WIDTH),
        .ADDR_WIDTH(SDRAM_ADDR_WIDTH),
        .BANK_WIDTH(SDRAM_BANK_WIDTH)
    ) sdram (
        .clk(clk),
        .cke(sdram_cke),
        .cs_n(sdram_cs_n),
        .ras_n(sdram_ras_n),
        .cas_n(sdram_cas_n),
        .we_n(sdram_we_n),
        .addr(sdram_addr),
        .bank(sdram_bank),
        .dqm(sdram_dqm),
        .dq(sdram_dq)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // VCD dump
    initial begin
        $dumpfile("sim/dram_controller.vcd");
        $dumpvars(0, dram_controller_tb);
    end
    
    // Test sequence
    initial begin
        // Initialize
        rst_n = 0;
        core_addr = '0;
        core_wdata = '0;
        core_we = 0;
        core_be = 4'hF;
        core_req = 0;
        
        // Wait for initialization
        repeat(10) @(posedge clk);
        rst_n = 1;
        repeat(20) @(posedge clk);
        
        // Test 1: Single write and read
        $display("Test 1: Single write and read");
        write_word(32'h8000_0000, 32'h1234_5678);
        read_word(32'h8000_0000, 32'h1234_5678);
        
        // Test 2: Burst write and read
        $display("Test 2: Burst write and read");
        write_burst(32'h8000_0000, 4);
        read_burst(32'h8000_0000, 4);
        
        // Test 3: Bank interleaving
        $display("Test 3: Bank interleaving");
        write_interleaved(32'h8000_0000, 4);
        read_interleaved(32'h8000_0000, 4);
        
        // Test 4: Byte enables
        $display("Test 4: Byte enables");
        write_byte_enable(32'h8000_0000);
        
        // Test 5: Refresh
        $display("Test 5: Refresh");
        wait_for_refresh();
        
        // End simulation
        repeat(10) @(posedge clk);
        $display("All tests completed");
        $finish;
    end
    
    // Tasks
    task write_word(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data);
        @(posedge clk);
        core_addr = addr;
        core_wdata = data;
        core_we = 1;
        core_req = 1;
        wait(core_ack);
        @(posedge clk);
        core_req = 0;
        core_we = 0;
        repeat(5) @(posedge clk);
    endtask
    
    task read_word(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] expected);
        @(posedge clk);
        core_addr = addr;
        core_we = 0;
        core_req = 1;
        wait(core_ack);
        if (core_rdata !== expected)
            $error("Read data mismatch: expected %h, got %h", expected, core_rdata);
        @(posedge clk);
        core_req = 0;
        repeat(5) @(posedge clk);
    endtask
    
    task write_burst(input [ADDR_WIDTH-1:0] base_addr, input [3:0] length);
        for (int i = 0; i < length; i++) begin
            write_word(base_addr + (i << 2), 32'h1000_0000 + i);
        end
    endtask
    
    task read_burst(input [ADDR_WIDTH-1:0] base_addr, input [3:0] length);
        for (int i = 0; i < length; i++) begin
            read_word(base_addr + (i << 2), 32'h1000_0000 + i);
        end
    endtask
    
    task write_interleaved(input [ADDR_WIDTH-1:0] base_addr, input [3:0] length);
        for (int i = 0; i < length; i++) begin
            write_word(base_addr + (i << 4), 32'h2000_0000 + i);
        end
    endtask
    
    task read_interleaved(input [ADDR_WIDTH-1:0] base_addr, input [3:0] length);
        for (int i = 0; i < length; i++) begin
            read_word(base_addr + (i << 4), 32'h2000_0000 + i);
        end
    endtask
    
    task write_byte_enable(input [ADDR_WIDTH-1:0] addr);
        @(posedge clk);
        core_addr = addr;
        core_wdata = 32'hAABB_CCDD;
        core_we = 1;
        core_be = 4'b0011;  // Write only lower half
        core_req = 1;
        wait(core_ack);
        @(posedge clk);
        core_req = 0;
        core_we = 0;
        core_be = 4'hF;
        repeat(5) @(posedge clk);
        
        // Read back and verify
        read_word(addr, 32'h0000_CCDD);
    endtask
    
    task wait_for_refresh;
        // Wait for refresh counter to reach threshold
        repeat(7800) @(posedge clk);
    endtask
    
endmodule

// SDRAM model
module sdram_model #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 13,
    parameter BANK_WIDTH = 2
)(
    input  logic                    clk,
    input  logic                    cke,
    input  logic                    cs_n,
    input  logic                    ras_n,
    input  logic                    cas_n,
    input  logic                    we_n,
    input  logic [ADDR_WIDTH-1:0]   addr,
    input  logic [BANK_WIDTH-1:0]   bank,
    input  logic [1:0]              dqm,
    inout  wire [DATA_WIDTH-1:0]    dq
);

    // Memory array
    logic [DATA_WIDTH-1:0] memory [0:2**(ADDR_WIDTH+BANK_WIDTH)-1];
    
    // Internal signals
    logic [ADDR_WIDTH-1:0] current_row [0:2**BANK_WIDTH-1];
    logic [BANK_WIDTH-1:0] current_bank;
    logic [ADDR_WIDTH-1:0] current_col;
    logic [DATA_WIDTH-1:0] dq_out;
    logic                  dq_oe;
    
    // Command decode
    logic [3:0] command;
    assign command = {cs_n, ras_n, cas_n, we_n};
    
    // Data bus control
    assign dq = dq_oe ? dq_out : {DATA_WIDTH{1'bz}};
    
    // Command handling
    always_ff @(posedge clk) begin
        if (cke) begin
            case (command)
                4'b0000: begin  // Load Mode Register
                    // Handle mode register set
                end
                
                4'b0001: begin  // Refresh
                    // Handle refresh
                end
                
                4'b0010: begin  // Precharge
                    // Handle precharge
                end
                
                4'b0011: begin  // Activate
                    current_row[bank] <= addr;
                    current_bank <= bank;
                end
                
                4'b0100: begin  // Write
                    if (!dqm[0]) memory[{current_bank, current_row[current_bank], addr[9:0]}] <= dq;
                    dq_oe <= 1'b0;
                end
                
                4'b0101: begin  // Read
                    dq_out <= memory[{current_bank, current_row[current_bank], addr[9:0]}];
                    dq_oe <= 1'b1;
                end
                
                default: begin
                    dq_oe <= 1'b0;
                end
            endcase
        end
    end
    
endmodule 