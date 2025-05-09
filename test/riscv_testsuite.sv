module riscv_testsuite;
    parameter DATA_WIDTH = 64;
    parameter ADDR_WIDTH = 64;
    parameter MEM_SIZE = 1024;
    parameter NUM_CORES = 4;

    logic clk;
    logic rst_n;
    logic [NUM_CORES-1:0] core_active;
    logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] pc_out;
    logic [NUM_CORES-1:0][DATA_WIDTH-1:0] alu_result_out;

    // Test results tracking
    int total_tests;
    int total_passed;
    int total_failed;

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Instantiate multicore system
    multicore #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .MEM_SIZE(MEM_SIZE),
        .NUM_CORES(NUM_CORES)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .core_active(core_active),
        .pc_out(pc_out),
        .alu_result_out(alu_result_out)
    );

    // Initialize shared memory with test data
    initial begin
        for (int i = 0; i < MEM_SIZE; i++) begin
            dut.shared_mem[i] = 64'h0000_0000_0000_0000;
        end
    end

    // Test program for each core
    initial begin
        // Initialize test counters
        total_tests = 0;
        total_passed = 0;
        total_failed = 0;

        // Initialize instruction memory for each core
        for (int i = 0; i < NUM_CORES; i++) begin
            for (int j = 0; j < MEM_SIZE; j++) begin
                dut.instruction_mem[i][j] = 32'h0000_0013; // NOP instruction
            end
        end

        // Core 0: Arithmetic Operations Test
        dut.instruction_mem[0][0] = 32'h00500093;  // ADDI x1, x0, 5
        dut.instruction_mem[0][1] = 32'h00A00113;  // ADDI x2, x0, 10
        dut.instruction_mem[0][2] = 32'h002081B3;  // ADD x3, x1, x2
        dut.instruction_mem[0][3] = 32'h40208233;  // SUB x4, x2, x1
        dut.instruction_mem[0][4] = 32'h00209293;  // SLLI x5, x1, 2
        dut.instruction_mem[0][5] = 32'h0020A313;  // SLTI x6, x1, 2
        dut.instruction_mem[0][6] = 32'h0020B393;  // SLTIU x7, x1, 2
        dut.instruction_mem[0][7] = 32'h0020C413;  // XORI x8, x1, 2
        dut.instruction_mem[0][8] = 32'h0020D493;  // SRLI x9, x1, 2
        dut.instruction_mem[0][9] = 32'h4020D513;  // SRAI x10, x1, 2
        dut.instruction_mem[0][10] = 32'h0020E593; // ORI x11, x1, 2
        dut.instruction_mem[0][11] = 32'h0020F613; // ANDI x12, x1, 2

        // Core 1: Memory Operations Test
        dut.instruction_mem[1][0] = 32'h00500093;  // ADDI x1, x0, 5
        dut.instruction_mem[1][1] = 32'h00102023;  // SW x1, 0(x0)
        dut.instruction_mem[1][2] = 32'h00002103;  // LW x2, 0(x0)
        dut.instruction_mem[1][3] = 32'h00102223;  // SW x1, 4(x0)
        dut.instruction_mem[1][4] = 32'h00402183;  // LW x3, 4(x0)
        dut.instruction_mem[1][5] = 32'h00102423;  // SW x1, 8(x0)
        dut.instruction_mem[1][6] = 32'h00802203;  // LW x4, 8(x0)
        dut.instruction_mem[1][7] = 32'h00100093;  // ADDI x1, x0, 1
        dut.instruction_mem[1][8] = 32'h00200113;  // ADDI x2, x0, 2
        dut.instruction_mem[1][9] = 32'h00300193;  // ADDI x3, x0, 3

        // Core 2: Branch Operations Test
        dut.instruction_mem[2][0] = 32'h00500093;  // ADDI x1, x0, 5
        dut.instruction_mem[2][1] = 32'h00500113;  // ADDI x2, x0, 5
        dut.instruction_mem[2][2] = 32'h00208463;  // BEQ x1, x2, 8
        dut.instruction_mem[2][3] = 32'h00100093;  // ADDI x1, x0, 1
        dut.instruction_mem[2][4] = 32'h00209463;  // BNE x1, x2, 8
        dut.instruction_mem[2][5] = 32'h00200113;  // ADDI x2, x0, 2
        dut.instruction_mem[2][6] = 32'h0020A463;  // BLT x1, x2, 8
        dut.instruction_mem[2][7] = 32'h00300193;  // ADDI x3, x0, 3
        dut.instruction_mem[2][8] = 32'h0020B463;  // BLTU x1, x2, 8
        dut.instruction_mem[2][9] = 32'h00400213;  // ADDI x4, x0, 4

        // Core 3: CSR Operations Test
        dut.instruction_mem[3][0] = 32'hC0002073;  // RDCYCLE x0
        dut.instruction_mem[3][1] = 32'hC0102073;  // RDTIME x0
        dut.instruction_mem[3][2] = 32'hC0202073;  // RDINSTRET x0
        dut.instruction_mem[3][3] = 32'h30102073;  // CSRRS x0, misa, x0
        dut.instruction_mem[3][4] = 32'h34202073;  // CSRRS x0, mcause, x0
        dut.instruction_mem[3][5] = 32'h34302073;  // CSRRS x0, mtval, x0
        dut.instruction_mem[3][6] = 32'h30002073;  // CSRRS x0, mstatus, x0
        dut.instruction_mem[3][7] = 32'h00100093;  // ADDI x1, x0, 1

        // Reset sequence
        rst_n = 0;
        repeat(5) @(posedge clk);
        rst_n = 1;

        // Wait for all cores to become active
        wait(core_active == 4'b1111);
        $display("\n=== RISC-V Multicore Test Suite ===");
        $display("Time %0t: All cores active", $time);

        // Wait for initialization
        repeat(10) @(posedge clk);

        // Test Core 0: Arithmetic Operations
        $display("\n=== Testing Core 0: Arithmetic Operations ===");
        repeat(20) @(posedge clk);
        
        // ADD test (5 + 10 = 15)
        if (dut.core_instances[0].reg_file.registers[3] === 64'h000000000000000F) begin
            $display("PASS: ADD test (x3 = x1 + x2)");
            total_passed++;
        end else begin
            $display("FAIL: ADD test - Expected: %h, Got: %h", 
                    64'h000000000000000F, 
                    dut.core_instances[0].reg_file.registers[3]);
            total_failed++;
        end
        total_tests++;

        // SUB test (10 - 5 = 5)
        if (dut.core_instances[0].reg_file.registers[4] === 64'h0000000000000005) begin
            $display("PASS: SUB test (x4 = x2 - x1)");
            total_passed++;
        end else begin
            $display("FAIL: SUB test - Expected: %h, Got: %h", 
                    64'h0000000000000005, 
                    dut.core_instances[0].reg_file.registers[4]);
            total_failed++;
        end
        total_tests++;

        // Test Core 1: Memory Operations
        $display("\n=== Testing Core 1: Memory Operations ===");
        repeat(20) @(posedge clk);

        // Memory write/read test
        if (dut.shared_mem[0] === 64'h0000000000000005) begin
            $display("PASS: Memory write test (mem[0] = 5)");
            total_passed++;
        end else begin
            $display("FAIL: Memory write test - Expected: %h, Got: %h", 
                    64'h0000000000000005, 
                    dut.shared_mem[0]);
            total_failed++;
        end
        total_tests++;

        // Test Core 2: Branch Operations
        $display("\n=== Testing Core 2: Branch Operations ===");
        repeat(20) @(posedge clk);

        // Branch test (BEQ taken)
        if (dut.core_instances[2].pc_out === 64'h0000000000000010) begin
            $display("PASS: Branch test (BEQ taken)");
            total_passed++;
        end else begin
            $display("FAIL: Branch test - Expected PC: %h, Got: %h", 
                    64'h0000000000000010, 
                    dut.core_instances[2].pc_out);
            total_failed++;
        end
        total_tests++;

        // Test Core 3: CSR Operations
        $display("\n=== Testing Core 3: CSR Operations ===");
        repeat(20) @(posedge clk);

        // CSR read test
        if (dut.core_instances[3].csr_unit.cycle_counter !== 64'h0) begin
            $display("PASS: CSR cycle counter incrementing");
            total_passed++;
        end else begin
            $display("FAIL: CSR cycle counter not incrementing");
            total_failed++;
        end
        total_tests++;

        // Print overall summary
        $display("\n=== Overall Test Summary ===");
        $display("Total Tests: %0d", total_tests);
        $display("Total Passed: %0d", total_passed);
        $display("Total Failed: %0d", total_failed);
        $display("Pass Rate: %0d%%", (total_passed * 100) / total_tests);

        // Additional debug information
        $display("\n=== Debug Information ===");
        $display("Core 0 PC: %h", pc_out[0]);
        $display("Core 1 PC: %h", pc_out[1]);
        $display("Core 2 PC: %h", pc_out[2]);
        $display("Core 3 PC: %h", pc_out[3]);

        $finish;
    end

    // Monitor memory access patterns
    always @(posedge clk) begin
        for (int i = 0; i < NUM_CORES; i++) begin
            if (dut.mem_request[i]) begin
                $display("Time %0t: Core %0d %s at address %h",
                    $time, i,
                    dut.mem_write[i] ? "wrote" : "read",
                    dut.mem_addr[i]);
            end
        end
    end

    // Monitor pipeline stages
    always @(posedge clk) begin
        for (int i = 0; i < NUM_CORES; i++) begin
            if (dut.core_active[i]) begin
                $display("Time %0t: Core %0d - IF: %h, ID: %h, EX: %h",
                    $time, i,
                    dut.core_instances[i].if_id_reg.instruction,
                    dut.core_instances[i].id_ex_reg.instruction,
                    dut.core_instances[i].ex_mem_reg.instruction);
            end
        end
    end

endmodule 