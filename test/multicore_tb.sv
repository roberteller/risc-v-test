module multicore_tb;
    parameter DATA_WIDTH = 64;
    parameter ADDR_WIDTH = 64;
    parameter MEM_SIZE = 1024;
    parameter NUM_CORES = 4;

    logic clk;
    logic rst_n;
    logic [NUM_CORES-1:0] core_active;
    logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] pc_out;
    logic [NUM_CORES-1:0][DATA_WIDTH-1:0] alu_result_out;

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

    // Test program for each core
    initial begin
        // Initialize instruction memory for each core
        // Core 0: Basic arithmetic
        dut.instruction_mem[0][0] = 32'h00500093;  // ADDI x1, x0, 5
        dut.instruction_mem[0][1] = 32'h00A00113;  // ADDI x2, x0, 10
        dut.instruction_mem[0][2] = 32'h002081B3;  // ADD x3, x1, x2
        dut.instruction_mem[0][3] = 32'h40208233;  // SUB x4, x2, x1

        // Core 1: Memory operations
        dut.instruction_mem[1][0] = 32'h00002183;  // LW x3, 0(x0)
        dut.instruction_mem[1][1] = 32'h00102023;  // SW x1, 0(x0)
        dut.instruction_mem[1][2] = 32'h00102223;  // SW x1, 4(x0)
        dut.instruction_mem[1][3] = 32'h00102423;  // SW x1, 8(x0)

        // Core 2: Branch operations
        dut.instruction_mem[2][0] = 32'h00208063;  // BEQ x1, x2, 0
        dut.instruction_mem[2][1] = 32'h00209063;  // BNE x1, x2, 0
        dut.instruction_mem[2][2] = 32'h0020A063;  // BLT x1, x2, 0
        dut.instruction_mem[2][3] = 32'h0020B063;  // BLTU x1, x2, 0

        // Core 3: CSR operations
        dut.instruction_mem[3][0] = 32'hC0002073;  // RDCYCLE x0
        dut.instruction_mem[3][1] = 32'hC0102073;  // RDTIME x0
        dut.instruction_mem[3][2] = 32'hC0202073;  // RDINSTRET x0
        dut.instruction_mem[3][3] = 32'hB032073;   // RDHPMCOUNTER3 x0

        // Initialize
        rst_n = 0;
        #20;
        rst_n = 1;

        // Wait for all cores to become active
        wait(core_active == 4'b1111);

        // Monitor core activity
        $display("Time %0t: All cores active", $time);
        for (int i = 0; i < NUM_CORES; i++) begin
            $display("Core %0d PC: %0h", i, pc_out[i]);
        end

        // Run for a while
        #1000;

        // Check results
        for (int i = 0; i < NUM_CORES; i++) begin
            $display("Core %0d final state:", i);
            $display("  PC: %0h", pc_out[i]);
            $display("  ALU Result: %0h", alu_result_out[i]);
        end

        $finish;
    end

    // Monitor memory access patterns
    always @(posedge clk) begin
        for (int i = 0; i < NUM_CORES; i++) begin
            if (dut.mem_request[i]) begin
                $display("Time %0t: Core %0d %s at address %0h",
                    $time, i,
                    dut.mem_write[i] ? "wrote" : "read",
                    dut.mem_addr[i]);
            end
        end
    end

endmodule 