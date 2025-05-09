module ooo_execution_unit_tb;
    // Parameters
    parameter NUM_PHYSICAL_REGS = 64;
    parameter NUM_ARCH_REGS = 32;
    parameter ROB_ENTRIES = 64;
    parameter RS_ENTRIES = 32;
    parameter LSQ_ENTRIES = 32;
    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 32;
    
    // Clock and reset
    logic                     clk;
    logic                     rst_n;
    
    // Instruction fetch interface
    logic [31:0]             instruction;
    logic [31:0]             pc;
    logic                    fetch_stall;
    
    // Register file interface
    logic [31:0]             rf_read_data1;
    logic [31:0]             rf_read_data2;
    logic [4:0]              rf_read_addr1;
    logic [4:0]              rf_read_addr2;
    logic [4:0]              rf_write_addr;
    logic [31:0]             rf_write_data;
    logic                    rf_write_en;
    
    // Memory interface
    logic                    mem_req_valid;
    logic                    mem_req_is_load;
    logic [31:0]             mem_req_addr;
    logic [31:0]             mem_req_data;
    logic                    mem_req_ready;
    logic [31:0]             mem_resp_data;
    logic                    mem_resp_valid;
    
    // Branch interface
    logic                    branch_taken;
    logic [31:0]             branch_target;
    
    // Status
    logic                    busy;
    
    // Test counters
    int num_tests;
    int num_passed;
    
    // Helper task for checking memory operations
    task check_memory_operation(
        input logic [31:0] expected_addr,
        input logic expected_is_load,
        input logic [31:0] expected_data
    );
        wait(mem_req_valid);
        if (mem_req_addr !== expected_addr) begin
            $display("ERROR: Memory address mismatch. Expected: %h, Got: %h", expected_addr, mem_req_addr);
            num_passed--;
        end
        if (mem_req_is_load !== expected_is_load) begin
            $display("ERROR: Memory operation type mismatch. Expected load: %b, Got: %b", expected_is_load, mem_req_is_load);
            num_passed--;
        end
        if (!expected_is_load && mem_req_data !== expected_data) begin
            $display("ERROR: Store data mismatch. Expected: %h, Got: %h", expected_data, mem_req_data);
            num_passed--;
        end
        num_tests++;
        num_passed++;
        #10;
    endtask
    
    // Helper task for checking branch operations
    task check_branch_operation(
        input logic expected_taken,
        input logic [31:0] expected_target
    );
        #1; // Wait for branch resolution
        if (branch_taken !== expected_taken) begin
            $display("ERROR: Branch taken mismatch. Expected: %b, Got: %b", expected_taken, branch_taken);
            num_passed--;
        end
        if (expected_taken && branch_target !== expected_target) begin
            $display("ERROR: Branch target mismatch. Expected: %h, Got: %h", expected_target, branch_target);
            num_passed--;
        end
        num_tests++;
        num_passed++;
        #9; // Complete the cycle
    endtask
    
    // Helper task for checking arithmetic operations
    task check_arithmetic_operation(
        input logic [31:0] expected_result,
        input logic [4:0] expected_rd
    );
        #1; // Wait for operation completion
        if (rf_write_en && rf_write_addr !== expected_rd) begin
            $display("ERROR: Write address mismatch. Expected: %h, Got: %h", expected_rd, rf_write_addr);
            num_passed--;
        end
        if (rf_write_en && rf_write_data !== expected_result) begin
            $display("ERROR: Write data mismatch. Expected: %h, Got: %h", expected_result, rf_write_data);
            num_passed--;
        end
        num_tests++;
        num_passed++;
        #9; // Complete the cycle
    endtask
    
    // Helper task for providing memory response
    task provide_memory_response(input logic [31:0] data);
        mem_resp_data = data;
        mem_resp_valid = 1;
        #10;
        mem_resp_valid = 0;
    endtask
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Reset generation
    initial begin
        rst_n = 0;
        #10 rst_n = 1;
    end
    
    // DUT instantiation
    ooo_execution_unit #(
        .NUM_PHYSICAL_REGS(NUM_PHYSICAL_REGS),
        .NUM_ARCH_REGS(NUM_ARCH_REGS),
        .ROB_ENTRIES(ROB_ENTRIES),
        .RS_ENTRIES(RS_ENTRIES),
        .LSQ_ENTRIES(LSQ_ENTRIES),
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .instruction(instruction),
        .pc(pc),
        .fetch_stall(fetch_stall),
        .rf_read_data1(rf_read_data1),
        .rf_read_data2(rf_read_data2),
        .rf_read_addr1(rf_read_addr1),
        .rf_read_addr2(rf_read_addr2),
        .rf_write_addr(rf_write_addr),
        .rf_write_data(rf_write_data),
        .rf_write_en(rf_write_en),
        .mem_req_valid(mem_req_valid),
        .mem_req_is_load(mem_req_is_load),
        .mem_req_addr(mem_req_addr),
        .mem_req_data(mem_req_data),
        .mem_req_ready(mem_req_ready),
        .mem_resp_data(mem_resp_data),
        .mem_resp_valid(mem_resp_valid),
        .branch_taken(branch_taken),
        .branch_target(branch_target),
        .busy(busy)
    );
    
    // Test stimulus
    initial begin
        // Initialize inputs
        instruction = 0;
        pc = 0;
        rf_read_data1 = 0;
        rf_read_data2 = 0;
        mem_req_ready = 1;
        mem_resp_data = 0;
        mem_resp_valid = 0;
        
        // Wait for reset
        @(posedge rst_n);
        @(posedge clk);
        
        // Test case 1: Load instruction
        instruction = 32'h00002503;  // lw x10, 0(x0)
        pc = 32'h1000;
        rf_read_data1 = 32'h2000;
        @(posedge clk);
        
        // Test case 2: Store instruction
        instruction = 32'h00a02023;  // sw x10, 0(x0)
        pc = 32'h1004;
        rf_read_data1 = 32'h2004;
        rf_read_data2 = 32'h1234;
        @(posedge clk);
        
        // Test case 3: Add instruction
        instruction = 32'h00b50533;  // add x10, x10, x11
        pc = 32'h1008;
        rf_read_data1 = 32'h5;
        rf_read_data2 = 32'h3;
        @(posedge clk);
        
        // End simulation
        #100;
        $finish;
    end
    
    // Monitor
    always @(posedge clk) begin
        if (rst_n) begin
            $display("%t: rst_n=%b instruction=%h pc=%h fetch_stall=%b mem_req_valid=%b mem_req_is_load=%b mem_req_addr=%h mem_req_data=%h branch_taken=%b branch_target=%h",
                $time, rst_n, instruction, pc, fetch_stall, mem_req_valid, mem_req_is_load, mem_req_addr, mem_req_data, branch_taken, branch_target);
        end
    end

endmodule
