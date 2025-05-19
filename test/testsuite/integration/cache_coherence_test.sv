// Cache Coherence Integration Test
`timescale 1ns/1ps

module cache_coherence_test;
    // Parameters
    parameter DATA_WIDTH = 64;
    parameter ADDR_WIDTH = 64;
    parameter CACHE_SIZE = 32*1024;      // 32KB
    parameter CACHE_LINE_SIZE = 64;      // 64 bytes per line
    parameter ASSOCIATIVITY = 4;         // 4-way set associative
    parameter ID_WIDTH = 4;
    parameter NUM_CORES = 2;             // Test with 2 cores

    // Clock and reset
    logic clk;
    logic rst_n;
    
    // L1 D$ <-> Core interface for each core
    logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] cpu_addr;
    logic [NUM_CORES-1:0][DATA_WIDTH-1:0] cpu_write_data;
    logic [NUM_CORES-1:0][DATA_WIDTH-1:0] cpu_read_data;
    logic [NUM_CORES-1:0] cpu_read;
    logic [NUM_CORES-1:0] cpu_write;
    logic [NUM_CORES-1:0][2:0] cpu_size;
    logic [NUM_CORES-1:0] cpu_request;
    logic [NUM_CORES-1:0] cpu_ready;
    logic [NUM_CORES-1:0] cpu_error;
    
    // L1 D$ <-> L2$ interface for each core
    logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] l1_l2_addr;
    logic [NUM_CORES-1:0][DATA_WIDTH-1:0] l1_l2_write_data;
    logic [NUM_CORES-1:0][DATA_WIDTH-1:0] l1_l2_read_data;
    logic [NUM_CORES-1:0] l1_l2_read;
    logic [NUM_CORES-1:0] l1_l2_write;
    logic [NUM_CORES-1:0][ID_WIDTH-1:0] l1_l2_id;
    logic [NUM_CORES-1:0] l1_l2_request;
    logic [NUM_CORES-1:0] l1_l2_ready;
    logic [NUM_CORES-1:0] l1_l2_error;
    
    // Cache coherence signals between L1 D$ caches
    logic [NUM_CORES-1:0] snoop_request;
    logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] snoop_addr;
    logic [NUM_CORES-1:0] snoop_invalidate;
    logic [NUM_CORES-1:0] snoop_hit;
    logic [NUM_CORES-1:0][DATA_WIDTH-1:0] snoop_data;
    logic [NUM_CORES-1:0] snoop_ack;
    
    // L2$ <-> Memory interface
    logic [ADDR_WIDTH-1:0] l2_mem_addr;
    logic [DATA_WIDTH-1:0] l2_mem_write_data;
    logic [DATA_WIDTH-1:0] l2_mem_read_data;
    logic l2_mem_read;
    logic l2_mem_write;
    logic l2_mem_request;
    logic l2_mem_ready;
    logic l2_mem_error;
    
    // Simulated memory
    logic [7:0] sim_memory[1024*1024]; // 1MB simulated memory
    
    // Instantiate L1 data caches
    genvar i;
    generate
        for (i = 0; i < NUM_CORES; i++) begin : gen_l1_dcache
            l1_cache #(
                .DATA_WIDTH(DATA_WIDTH),
                .ADDR_WIDTH(ADDR_WIDTH),
                .CACHE_SIZE(CACHE_SIZE),
                .CACHE_LINE_SIZE(CACHE_LINE_SIZE),
                .ASSOCIATIVITY(ASSOCIATIVITY),
                .ID_WIDTH(ID_WIDTH),
                .TYPE("DATA")
            ) l1_dcache (
                .clk(clk),
                .rst_n(rst_n),
                
                // CPU interface
                .cpu_addr(cpu_addr[i]),
                .cpu_write_data(cpu_write_data[i]),
                .cpu_read_data(cpu_read_data[i]),
                .cpu_read(cpu_read[i]),
                .cpu_write(cpu_write[i]),
                .cpu_size(cpu_size[i]),
                .cpu_request(cpu_request[i]),
                .cpu_ready(cpu_ready[i]),
                .cpu_error(cpu_error[i]),
                
                // L2 interface
                .mem_addr(l1_l2_addr[i]),
                .mem_write_data(l1_l2_write_data[i]),
                .mem_read_data(l1_l2_read_data[i]),
                .mem_read(l1_l2_read[i]),
                .mem_write(l1_l2_write[i]),
                .mem_id(l1_l2_id[i]),
                .mem_request(l1_l2_request[i]),
                .mem_ready(l1_l2_ready[i]),
                .mem_error(l1_l2_error[i]),
                
                // Coherence interface
                .snoop_request(snoop_request[i]),
                .snoop_addr(snoop_addr[i]),
                .snoop_invalidate(snoop_invalidate[i]),
                .snoop_hit(snoop_hit[i]),
                .snoop_data(snoop_data[i]),
                .snoop_ack(snoop_ack[i])
            );
        end
    endgenerate
    
    // Instantiate L2 shared cache
    l2_cache #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .CACHE_SIZE(1024*1024),        // 1MB L2
        .CACHE_LINE_SIZE(CACHE_LINE_SIZE),
        .ASSOCIATIVITY(8),            // 8-way set associative
        .ID_WIDTH(ID_WIDTH),
        .NUM_CORES(NUM_CORES)
    ) l2_cache_inst (
        .clk(clk),
        .rst_n(rst_n),
        
        // L1 interface
        .l1_addr(l1_l2_addr),
        .l1_write_data(l1_l2_write_data),
        .l1_read_data(l1_l2_read_data),
        .l1_read(l1_l2_read),
        .l1_write(l1_l2_write),
        .l1_id(l1_l2_id),
        .l1_request(l1_l2_request),
        .l1_ready(l1_l2_ready),
        .l1_error(l1_l2_error),
        
        // Coherence signals to L1 caches
        .snoop_request(snoop_request),
        .snoop_addr(snoop_addr),
        .snoop_invalidate(snoop_invalidate),
        .snoop_hit(snoop_hit),
        .snoop_data(snoop_data),
        .snoop_ack(snoop_ack),
        
        // Memory interface
        .mem_addr(l2_mem_addr),
        .mem_write_data(l2_mem_write_data),
        .mem_read_data(l2_mem_read_data),
        .mem_read(l2_mem_read),
        .mem_write(l2_mem_write),
        .mem_request(l2_mem_request),
        .mem_ready(l2_mem_ready),
        .mem_error(l2_mem_error)
    );
    
    // Clock generation
    always #5 clk = ~clk;
    
    // Memory response simulation
    always @(posedge clk) begin
        if (l2_mem_request) begin
            // Simulate memory latency (10 cycles)
            repeat (9) @(posedge clk);
            
            if (l2_mem_read) begin
                // Read data
                l2_mem_read_data <= {
                    sim_memory[l2_mem_addr+7],
                    sim_memory[l2_mem_addr+6],
                    sim_memory[l2_mem_addr+5],
                    sim_memory[l2_mem_addr+4],
                    sim_memory[l2_mem_addr+3],
                    sim_memory[l2_mem_addr+2],
                    sim_memory[l2_mem_addr+1],
                    sim_memory[l2_mem_addr]
                };
                l2_mem_ready <= 1;
                l2_mem_error <= 0;
            end else if (l2_mem_write) begin
                // Write data
                sim_memory[l2_mem_addr] <= l2_mem_write_data[7:0];
                sim_memory[l2_mem_addr+1] <= l2_mem_write_data[15:8];
                sim_memory[l2_mem_addr+2] <= l2_mem_write_data[23:16];
                sim_memory[l2_mem_addr+3] <= l2_mem_write_data[31:24];
                sim_memory[l2_mem_addr+4] <= l2_mem_write_data[39:32];
                sim_memory[l2_mem_addr+5] <= l2_mem_write_data[47:40];
                sim_memory[l2_mem_addr+6] <= l2_mem_write_data[55:48];
                sim_memory[l2_mem_addr+7] <= l2_mem_write_data[63:56];
                l2_mem_ready <= 1;
                l2_mem_error <= 0;
            end
        end else begin
            l2_mem_ready <= 0;
        end
    end
    
    // Initialize memory
    initial begin
        for (int i = 0; i < 1024*1024; i++) begin
            sim_memory[i] = i & 8'hFF; // Simple pattern
        end
    end
    
    // Test sequence
    initial begin
        $display("Starting Cache Coherence Integration Test");
        
        // Initialize signals
        clk = 0;
        rst_n = 0;
        for (int i = 0; i < NUM_CORES; i++) begin
            cpu_addr[i] = 0;
            cpu_write_data[i] = 0;
            cpu_read[i] = 0;
            cpu_write[i] = 0;
            cpu_size[i] = 3'b011; // 8 bytes (double word)
            cpu_request[i] = 0;
        end
        
        // Apply reset
        #20;
        rst_n = 1;
        #20;
        
        // Test 1: Basic coherence - Write by Core 0, then read by Core 1
        $display("Test 1: Basic coherence - Write by Core 0, then read by Core 1");
        
        // Core 0 writes to address 0x1000
        cpu_addr[0] = 64'h1000;
        cpu_write_data[0] = 64'hDEADBEEF_CAFEBABE;
        cpu_read[0] = 0;
        cpu_write[0] = 1;
        cpu_request[0] = 1;
        
        // Wait for write to complete
        wait(cpu_ready[0]);
        #10;
        cpu_request[0] = 0;
        
        // Core 1 reads from the same address
        cpu_addr[1] = 64'h1000;
        cpu_read[1] = 1;
        cpu_write[1] = 0;
        cpu_request[1] = 1;
        
        // Wait for read to complete
        wait(cpu_ready[1]);
        #10;
        cpu_request[1] = 0;
        
        // Check data coherence
        if (cpu_read_data[1] != 64'hDEADBEEF_CAFEBABE) begin
            $display("ERROR: Coherence failure! Core 1 read 0x%h, expected 0x%h",
                     cpu_read_data[1], 64'hDEADBEEF_CAFEBABE);
            $finish;
        end
        $display("Test 1 PASSED");
        
        // Test 2: Core 1 modifies data, Core 0 sees the update
        $display("Test 2: Core 1 modifies data, Core 0 sees the update");
        
        // Core 1 modifies the address
        cpu_addr[1] = 64'h1000;
        cpu_write_data[1] = 64'h12345678_87654321;
        cpu_read[1] = 0;
        cpu_write[1] = 1;
        cpu_request[1] = 1;
        
        // Wait for write to complete
        wait(cpu_ready[1]);
        #10;
        cpu_request[1] = 0;
        
        // Core 0 reads from the same address
        cpu_addr[0] = 64'h1000;
        cpu_read[0] = 1;
        cpu_write[0] = 0;
        cpu_request[0] = 1;
        
        // Wait for read to complete
        wait(cpu_ready[0]);
        #10;
        cpu_request[0] = 0;
        
        // Check data coherence
        if (cpu_read_data[0] != 64'h12345678_87654321) begin
            $display("ERROR: Coherence failure! Core 0 read 0x%h, expected 0x%h",
                     cpu_read_data[0], 64'h12345678_87654321);
            $finish;
        end
        $display("Test 2 PASSED");
        
        // Test 3: Core 0 and Core 1 both read different locations, then swap
        $display("Test 3: Core 0 and Core 1 both read different locations, then swap");
        
        // Core 0 reads from address 0x2000
        cpu_addr[0] = 64'h2000;
        cpu_read[0] = 1;
        cpu_write[0] = 0;
        cpu_request[0] = 1;
        
        // Wait for read to complete
        wait(cpu_ready[0]);
        #10;
        cpu_request[0] = 0;
        
        // Save the data
        logic [63:0] core0_data = cpu_read_data[0];
        
        // Core 1 reads from address 0x3000
        cpu_addr[1] = 64'h3000;
        cpu_read[1] = 1;
        cpu_write[1] = 0;
        cpu_request[1] = 1;
        
        // Wait for read to complete
        wait(cpu_ready[1]);
        #10;
        cpu_request[1] = 0;
        
        // Save the data
        logic [63:0] core1_data = cpu_read_data[1];
        
        // Cores read from opposite addresses
        cpu_addr[0] = 64'h3000;
        cpu_read[0] = 1;
        cpu_write[0] = 0;
        cpu_request[0] = 1;
        
        // Wait for read to complete
        wait(cpu_ready[0]);
        #10;
        cpu_request[0] = 0;
        
        // Core 1 reads from Core 0's original address
        cpu_addr[1] = 64'h2000;
        cpu_read[1] = 1;
        cpu_write[1] = 0;
        cpu_request[1] = 1;
        
        // Wait for read to complete
        wait(cpu_ready[1]);
        #10;
        cpu_request[1] = 0;
        
        // Check data
        if (cpu_read_data[0] != core1_data) begin
            $display("ERROR: Core 0 read wrong data from address 0x3000");
            $finish;
        end
        if (cpu_read_data[1] != core0_data) begin
            $display("ERROR: Core 1 read wrong data from address 0x2000");
            $finish;
        end
        $display("Test 3 PASSED");
        
        // Test 4: Test cache invalidation
        $display("Test 4: Test cache invalidation");
        
        // Core 0 reads from address 0x4000
        cpu_addr[0] = 64'h4000;
        cpu_read[0] = 1;
        cpu_write[0] = 0;
        cpu_request[0] = 1;
        
        // Wait for read to complete
        wait(cpu_ready[0]);
        #10;
        cpu_request[0] = 0;
        
        // Capture original data
        logic [63:0] original_data = cpu_read_data[0];
        
        // Core 1 modifies the value at 0x4000
        cpu_addr[1] = 64'h4000;
        cpu_write_data[1] = 64'hAAAABBBB_CCCCDDDD;
        cpu_read[1] = 0;
        cpu_write[1] = 1;
        cpu_request[1] = 1;
        
        // Wait for write to complete
        wait(cpu_ready[1]);
        #10;
        cpu_request[1] = 0;
        
        // Core 0 reads from the same address again
        // Cache coherence should ensure it gets the new value
        cpu_addr[0] = 64'h4000;
        cpu_read[0] = 1;
        cpu_write[0] = 0;
        cpu_request[0] = 1;
        
        // Wait for read to complete
        wait(cpu_ready[0]);
        #10;
        cpu_request[0] = 0;
        
        // Verify the new value
        if (cpu_read_data[0] != 64'hAAAABBBB_CCCCDDDD) begin
            $display("ERROR: Cache invalidation failure! Core 0 read 0x%h, expected 0x%h",
                     cpu_read_data[0], 64'hAAAABBBB_CCCCDDDD);
            $finish;
        end
        $display("Test 4 PASSED");
        
        // Test 5: Test multiple writes to the same line
        $display("Test 5: Test multiple writes to the same line");
        
        // Core A writes to 0x5000
        cpu_addr[0] = 64'h5000;
        cpu_write_data[0] = 64'h11111111_11111111;
        cpu_read[0] = 0;
        cpu_write[0] = 1;
        cpu_request[0] = 1;
        
        // Wait for write to complete
        wait(cpu_ready[0]);
        #10;
        cpu_request[0] = 0;
        
        // Core B writes to 0x5000
        cpu_addr[1] = 64'h5000;
        cpu_write_data[1] = 64'h22222222_22222222;
        cpu_read[1] = 0;
        cpu_write[1] = 1;
        cpu_request[1] = 1;
        
        // Wait for write to complete
        wait(cpu_ready[1]);
        #10;
        cpu_request[1] = 0;
        
        // Core A writes to 0x5000 again
        cpu_addr[0] = 64'h5000;
        cpu_write_data[0] = 64'h33333333_33333333;
        cpu_read[0] = 0;
        cpu_write[0] = 1;
        cpu_request[0] = 1;
        
        // Wait for write to complete
        wait(cpu_ready[0]);
        #10;
        cpu_request[0] = 0;
        
        // Both cores read the final value
        // Core 0 reads
        cpu_addr[0] = 64'h5000;
        cpu_read[0] = 1;
        cpu_write[0] = 0;
        cpu_request[0] = 1;
        
        // Wait for read to complete
        wait(cpu_ready[0]);
        #10;
        cpu_request[0] = 0;
        
        // Core 1 reads
        cpu_addr[1] = 64'h5000;
        cpu_read[1] = 1;
        cpu_write[1] = 0;
        cpu_request[1] = 1;
        
        // Wait for read to complete
        wait(cpu_ready[1]);
        #10;
        cpu_request[1] = 0;
        
        // Both should see the final value
        if (cpu_read_data[0] != 64'h33333333_33333333) begin
            $display("ERROR: Core 0 sees wrong value after multiple writes");
            $finish;
        end
        if (cpu_read_data[1] != 64'h33333333_33333333) begin
            $display("ERROR: Core 1 sees wrong value after multiple writes");
            $finish;
        end
        $display("Test 5 PASSED");
        
        // All tests passed
        $display("All cache coherence tests PASSED!");
        $finish;
    end
    
    // Watchdog timer
    initial begin
        #200000; // 200us timeout
        $display("ERROR: Test timed out");
        $finish;
    end
    
    // Dump waveforms
    initial begin
        $dumpfile("cache_coherence_test.vcd");
        $dumpvars(0, cache_coherence_test);
    end
    
endmodule 