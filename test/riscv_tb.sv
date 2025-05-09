module riscv_tb;
    // Parameters
    parameter DATA_WIDTH = 64;
    parameter ADDR_WIDTH = 64;
    parameter MEM_SIZE = 1024;
    parameter CLK_PERIOD = 10; // 100MHz clock

    // Signals
    logic clk;
    logic rst_n;
    logic [ADDR_WIDTH-1:0] pc;
    logic [DATA_WIDTH-1:0] alu_result;
    logic mem_write;
    logic [DATA_WIDTH-1:0] mem_data;
    logic [ADDR_WIDTH-1:0] mem_addr;

    // VCD dump file
    initial begin
        $dumpfile("sim/riscv.vcd");
        $dumpvars(0, riscv_tb);
    end

    // Instantiate the RISC-V core
    riscv_core #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .MEM_SIZE(MEM_SIZE)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .pc_out(pc),
        .alu_result_out(alu_result),
        .mem_write_out(mem_write),
        .mem_data_out(mem_data),
        .mem_addr_out(mem_addr)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Test stimulus
    initial begin
        // Initialize test program
        // Basic arithmetic
        dut.instruction_mem[0] = 32'h00500093;  // ADDI x1, x0, 5
        dut.instruction_mem[1] = 32'h00A00113;  // ADDI x2, x0, 10
        dut.instruction_mem[2] = 32'h002081B3;  // ADD x3, x1, x2
        dut.instruction_mem[3] = 32'h40208233;  // SUB x4, x2, x1

        // Load-use hazard test
        dut.instruction_mem[4] = 32'h00002183;  // LW x3, 0(x0)
        dut.instruction_mem[5] = 32'h00308233;  // ADD x4, x1, x3

        // Memory alignment test
        dut.instruction_mem[6] = 32'h00102023;  // SW x1, 0(x0)
        dut.instruction_mem[7] = 32'h00102223;  // SW x1, 4(x0)
        dut.instruction_mem[8] = 32'h00102423;  // SW x1, 8(x0)
        dut.instruction_mem[9] = 32'h00102623;  // SW x1, 12(x0)

        // CSR operations
        dut.instruction_mem[10] = 32'hC0002073;  // RDCYCLE x0
        dut.instruction_mem[11] = 32'hC0102073;  // RDTIME x0
        dut.instruction_mem[12] = 32'hC0202073;  // RDINSTRET x0
        dut.instruction_mem[13] = 32'hB032073;   // RDHPMCOUNTER3 x0 (branches)
        dut.instruction_mem[14] = 32'hB042073;   // RDHPMCOUNTER4 x0 (mispredicts)

        // Branch test
        dut.instruction_mem[15] = 32'h00208063;  // BEQ x1, x2, 0
        dut.instruction_mem[16] = 32'h00209063;  // BNE x1, x2, 0
        dut.instruction_mem[17] = 32'h0020A063;  // BLT x1, x2, 0
        dut.instruction_mem[18] = 32'h0020B063;  // BLTU x1, x2, 0

        // Reset sequence
        rst_n = 0;
        repeat(2) @(posedge clk);
        rst_n = 1;

        // Wait for program execution
        repeat(30) @(posedge clk);

        // Display results
        $display("\nTest Results:");
        $display("PC: 0x%h", pc);
        $display("\nRegister File Contents:");
        $display("x1 (5)      : 0x%h", dut.reg_file.registers[1]);
        $display("x2 (10)     : 0x%h", dut.reg_file.registers[2]);
        $display("x3 (15)     : 0x%h", dut.reg_file.registers[3]);
        $display("x4 (5)      : 0x%h", dut.reg_file.registers[4]);

        $display("\nMemory Contents:");
        $display("mem[0] (5)  : 0x%h", dut.data_mem[0]);
        $display("mem[1] (5)  : 0x%h", dut.data_mem[1]);
        $display("mem[2] (5)  : 0x%h", dut.data_mem[2]);
        $display("mem[3] (5)  : 0x%h", dut.data_mem[3]);

        $display("\nPerformance Counters:");
        $display("Cycles: %d", dut.perf_counters.cycles);
        $display("Instructions: %d", dut.perf_counters.instructions);
        $display("Branches: %d", dut.perf_counters.branches);
        $display("Branch Mispredicts: %d", dut.perf_counters.branch_mispredicts);
        $display("Loads: %d", dut.perf_counters.loads);
        $display("Stores: %d", dut.perf_counters.stores);
        $display("Load-Use Stalls: %d", dut.perf_counters.load_use_stalls);
        $display("Alignment Faults: %d", dut.perf_counters.alignment_faults);

        // Check results
        if (dut.reg_file.registers[1] === 64'h5 &&
            dut.reg_file.registers[2] === 64'hA &&
            dut.reg_file.registers[3] === 64'hF &&
            dut.reg_file.registers[4] === 64'h5 &&
            dut.data_mem[0] === 64'h5 &&
            dut.data_mem[1] === 64'h5 &&
            dut.data_mem[2] === 64'h5 &&
            dut.data_mem[3] === 64'h5) begin
            $display("\nTest PASSED!");
        end else begin
            $display("\nTest FAILED!");
        end

        $finish;
    end

    // Monitor changes
    initial begin
        $monitor("Time=%0t pc=0x%h alu_result=0x%h mem_write=%b mem_addr=0x%h",
                $time, pc, alu_result, mem_write, mem_addr);
    end

endmodule 