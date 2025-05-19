// L1 Cache Unit Test
`timescale 1ns/1ps

module l1_cache_test;
    // Parameters
    parameter DATA_WIDTH = 64;
    parameter ADDR_WIDTH = 64;
    parameter CACHE_SIZE = 32*1024;      // 32KB
    parameter CACHE_LINE_SIZE = 64;      // 64 bytes per line
    parameter ASSOCIATIVITY = 4;         // 4-way set associative
    parameter ID_WIDTH = 4;
    parameter TYPE = "INSTRUCTION";      // Test with instruction cache

    // Clock and reset
    logic clk;
    logic rst_n;
    
    // CPU interface
    logic [ADDR_WIDTH-1:0] cpu_addr;
    logic [DATA_WIDTH-1:0] cpu_write_data;
    logic [DATA_WIDTH-1:0] cpu_read_data;
    logic cpu_read;
    logic cpu_write;
    logic [2:0] cpu_size;
    logic cpu_request;
    logic cpu_ready;
    logic cpu_error;
    
    // Memory/L2 interface
    logic [ADDR_WIDTH-1:0] mem_addr;
    logic [DATA_WIDTH-1:0] mem_write_data;
    logic [DATA_WIDTH-1:0] mem_read_data;
    logic mem_read;
    logic mem_write;
    logic [ID_WIDTH-1:0] mem_id;
    logic mem_request;
    logic mem_ready;
    logic mem_error;
    
    // Cache coherence interface - only used for data cache
    logic snoop_request;
    logic [ADDR_WIDTH-1:0] snoop_addr;
    logic snoop_invalidate;
    logic snoop_hit;
    logic [DATA_WIDTH-1:0] snoop_data;
    logic snoop_ack;
    
    // Simulated memory
    logic [7:0] sim_memory[1024*1024]; // 1MB simulated memory
    
    // Instantiate L1 cache
    l1_cache #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .CACHE_SIZE(CACHE_SIZE),
        .CACHE_LINE_SIZE(CACHE_LINE_SIZE),
        .ASSOCIATIVITY(ASSOCIATIVITY),
        .ID_WIDTH(ID_WIDTH),
        .TYPE(TYPE)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        
        // CPU interface
        .cpu_addr(cpu_addr),
        .cpu_write_data(cpu_write_data),
        .cpu_read_data(cpu_read_data),
        .cpu_read(cpu_read),
        .cpu_write(cpu_write),
        .cpu_size(cpu_size),
        .cpu_request(cpu_request),
        .cpu_ready(cpu_ready),
        .cpu_error(cpu_error),
        
        // Memory/L2 interface
        .mem_addr(mem_addr),
        .mem_write_data(mem_write_data),
        .mem_read_data(mem_read_data),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_id(mem_id),
        .mem_request(mem_request),
        .mem_ready(mem_ready),
        .mem_error(mem_error),
        
        // Cache coherence interface
        .snoop_request(snoop_request),
        .snoop_addr(snoop_addr),
        .snoop_invalidate(snoop_invalidate),
        .snoop_hit(snoop_hit),
        .snoop_data(snoop_data),
        .snoop_ack(snoop_ack)
    );
    
    // Clock generation
    always #5 clk = ~clk;
    
    // Memory response simulation
    always @(posedge clk) begin
        if (mem_request) begin
            // Simulate memory latency (5 cycles)
            repeat (4) @(posedge clk);
            
            if (mem_read) begin
                // Read a cache line (simplified for test)
                mem_read_data <= {
                    sim_memory[mem_addr+7],
                    sim_memory[mem_addr+6],
                    sim_memory[mem_addr+5],
                    sim_memory[mem_addr+4],
                    sim_memory[mem_addr+3],
                    sim_memory[mem_addr+2],
                    sim_memory[mem_addr+1],
                    sim_memory[mem_addr]
                };
                mem_ready <= 1;
                mem_error <= 0;
            end else if (mem_write) begin
                // Write a cache line (simplified for test)
                sim_memory[mem_addr] <= mem_write_data[7:0];
                sim_memory[mem_addr+1] <= mem_write_data[15:8];
                sim_memory[mem_addr+2] <= mem_write_data[23:16];
                sim_memory[mem_addr+3] <= mem_write_data[31:24];
                sim_memory[mem_addr+4] <= mem_write_data[39:32];
                sim_memory[mem_addr+5] <= mem_write_data[47:40];
                sim_memory[mem_addr+6] <= mem_write_data[55:48];
                sim_memory[mem_addr+7] <= mem_write_data[63:56];
                mem_ready <= 1;
                mem_error <= 0;
            end
        end else begin
            mem_ready <= 0;
        end
    end
    
    // Initialize memory with test pattern
    task initialize_memory;
        for (int i = 0; i < 1024*1024; i++) begin
            sim_memory[i] = i & 8'hFF; // Simple pattern
        end
    endtask
    
    // Test sequence
    initial begin
        $display("Starting L1 Cache Unit Test");
        
        // Initialize signals
        clk = 0;
        rst_n = 0;
        cpu_addr = 0;
        cpu_write_data = 0;
        cpu_read = 0;
        cpu_write = 0;
        cpu_size = 3'b011; // 8 bytes (double word)
        cpu_request = 0;
        
        // Initialize memory
        initialize_memory();
        
        // Apply reset
        #20;
        rst_n = 1;
        #20;
        
        // Testcase 1: Cache miss read
        $display("Test Case 1: Cache miss read");
        cpu_addr = 64'h1000;
        cpu_read = 1;
        cpu_write = 0;
        cpu_request = 1;
        
        // Wait for read to complete
        wait(cpu_ready);
        #10;
        cpu_request = 0;
        
        // Check data
        if (cpu_error) begin
            $display("ERROR: Unexpected error on read");
            $finish;
        end
        if (cpu_read_data != {
                sim_memory[64'h1007],
                sim_memory[64'h1006],
                sim_memory[64'h1005],
                sim_memory[64'h1004],
                sim_memory[64'h1003],
                sim_memory[64'h1002],
                sim_memory[64'h1001],
                sim_memory[64'h1000]
            }) begin
            $display("ERROR: Incorrect read data");
            $finish;
        end
        $display("Test Case 1 PASSED");
        
        // Testcase 2: Cache hit read
        $display("Test Case 2: Cache hit read");
        cpu_addr = 64'h1000; // Same address as previous read
        cpu_read = 1;
        cpu_write = 0;
        cpu_request = 1;
        
        // Wait for read to complete - should be faster (cache hit)
        wait(cpu_ready);
        #10;
        cpu_request = 0;
        
        // Check data
        if (cpu_error) begin
            $display("ERROR: Unexpected error on read");
            $finish;
        end
        if (cpu_read_data != {
                sim_memory[64'h1007],
                sim_memory[64'h1006],
                sim_memory[64'h1005],
                sim_memory[64'h1004],
                sim_memory[64'h1003],
                sim_memory[64'h1002],
                sim_memory[64'h1001],
                sim_memory[64'h1000]
            }) begin
            $display("ERROR: Incorrect read data");
            $finish;
        end
        $display("Test Case 2 PASSED");
        
        // Testcase 3: Read from a different set
        $display("Test Case 3: Read from different set");
        cpu_addr = 64'h2000; // Different set
        cpu_read = 1;
        cpu_write = 0;
        cpu_request = 1;
        
        // Wait for read to complete
        wait(cpu_ready);
        #10;
        cpu_request = 0;
        
        // Check data
        if (cpu_error) begin
            $display("ERROR: Unexpected error on read");
            $finish;
        end
        if (cpu_read_data != {
                sim_memory[64'h2007],
                sim_memory[64'h2006],
                sim_memory[64'h2005],
                sim_memory[64'h2004],
                sim_memory[64'h2003],
                sim_memory[64'h2002],
                sim_memory[64'h2001],
                sim_memory[64'h2000]
            }) begin
            $display("ERROR: Incorrect read data");
            $finish;
        end
        $display("Test Case 3 PASSED");
        
        // If testing data cache, also test write operations
        if (TYPE == "DATA") begin
            // Testcase 4: Write operation (write-through)
            $display("Test Case 4: Write operation");
            cpu_addr = 64'h3000;
            cpu_write_data = 64'hCAFEBABEDEADBEEF;
            cpu_read = 0;
            cpu_write = 1;
            cpu_request = 1;
            
            // Wait for write to complete
            wait(cpu_ready);
            #10;
            cpu_request = 0;
            
            // Check if the write was successful by reading it back
            cpu_addr = 64'h3000;
            cpu_read = 1;
            cpu_write = 0;
            cpu_request = 1;
            
            // Wait for read to complete
            wait(cpu_ready);
            #10;
            cpu_request = 0;
            
            // Check data
            if (cpu_error) begin
                $display("ERROR: Unexpected error on read after write");
                $finish;
            end
            if (cpu_read_data != 64'hCAFEBABEDEADBEEF) begin
                $display("ERROR: Incorrect read data after write");
                $finish;
            end
            $display("Test Case 4 PASSED");
        end else begin
            $display("Skipping write test for instruction cache");
        end
        
        // Testcase 5: Cache eviction test
        $display("Test Case 5: Cache eviction test");
        
        // Fill the cache with entries for the same set
        // For a 4-way set associative cache, we need at least 5 addresses
        // that map to the same set to cause an eviction
        for (int i = 0; i < 5; i++) begin
            // Use addresses that map to the same set but different tags
            // For simplicity, assuming set index bits are 5-10 and the rest are tag
            cpu_addr = 64'h4000 + (i * 64'h4000);
            cpu_read = 1;
            cpu_write = 0;
            cpu_request = 1;
            
            // Wait for read to complete
            wait(cpu_ready);
            #10;
            cpu_request = 0;
        end
        
        // Now read from the first address again - should be a miss
        cpu_addr = 64'h4000;
        cpu_read = 1;
        cpu_write = 0;
        cpu_request = 1;
        
        // Wait for read to complete
        wait(cpu_ready);
        #10;
        cpu_request = 0;
        
        // Can't easily check if it was a hit or miss without internal signals
        // But we can verify the data is correct
        if (cpu_error) begin
            $display("ERROR: Unexpected error on read after eviction");
            $finish;
        end
        if (cpu_read_data != {
                sim_memory[64'h4007],
                sim_memory[64'h4006],
                sim_memory[64'h4005],
                sim_memory[64'h4004],
                sim_memory[64'h4003],
                sim_memory[64'h4002],
                sim_memory[64'h4001],
                sim_memory[64'h4000]
            }) begin
            $display("ERROR: Incorrect read data after eviction");
            $finish;
        end
        $display("Test Case 5 PASSED");
        
        // All tests passed
        $display("All L1 Cache tests PASSED!");
        $finish;
    end
    
    // Watchdog timer
    initial begin
        #100000; // 100us timeout
        $display("ERROR: Test timed out");
        $finish;
    end
    
    // Dump waveforms
    initial begin
        $dumpfile("l1_cache_test.vcd");
        $dumpvars(0, l1_cache_test);
    end
    
endmodule 