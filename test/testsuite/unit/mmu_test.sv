// MMU Unit Test
`timescale 1ns/1ps

module mmu_test;
    // Parameters
    parameter DATA_WIDTH = 64;
    parameter ADDR_WIDTH = 64;
    parameter TLB_ENTRIES = 16;

    // Clock and reset
    logic clk;
    logic rst_n;
    
    // MMU interface
    logic [ADDR_WIDTH-1:0] virt_addr;
    logic read;
    logic write;
    logic [2:0] size;
    logic req;
    logic [ADDR_WIDTH-1:0] phys_addr;
    logic page_fault;
    logic access_fault;
    logic ack;
    
    // CSR interface
    logic tlb_flush;
    logic [ADDR_WIDTH-1:0] satp;
    logic sum;
    logic mxr;
    logic [1:0] current_mode;
    
    // Memory interface for page table walks
    logic [ADDR_WIDTH-1:0] mem_addr;
    logic mem_read;
    logic mem_write;
    logic [DATA_WIDTH-1:0] mem_write_data;
    logic [DATA_WIDTH-1:0] mem_read_data;
    logic mem_request;
    logic mem_ack;
    
    // Simulated memory storage
    logic [7:0] sim_memory[64*1024*1024]; // 64MB memory array
    
    // Instantiate MMU
    mmu #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .TLB_ENTRIES(TLB_ENTRIES)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        
        // Address translation interface
        .virt_addr(virt_addr),
        .read(read),
        .write(write),
        .size(size),
        .req(req),
        .phys_addr(phys_addr),
        .page_fault(page_fault),
        .access_fault(access_fault),
        .ack(ack),
        
        // CSR interface
        .tlb_flush(tlb_flush),
        .satp(satp),
        .sum(sum),
        .mxr(mxr),
        .current_mode(current_mode),
        
        // Memory interface for page table walks
        .mem_addr(mem_addr),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_write_data(mem_write_data),
        .mem_read_data(mem_read_data),
        .mem_request(mem_request),
        .mem_ack(mem_ack)
    );
    
    // Clock generation
    always #5 clk = ~clk;
    
    // Memory response simulation
    always @(posedge clk) begin
        if (mem_request) begin
            if (mem_read) begin
                // Read from simulated memory
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
                mem_ack <= 1;
            end else if (mem_write) begin
                // Write to simulated memory
                sim_memory[mem_addr] <= mem_write_data[7:0];
                sim_memory[mem_addr+1] <= mem_write_data[15:8];
                sim_memory[mem_addr+2] <= mem_write_data[23:16];
                sim_memory[mem_addr+3] <= mem_write_data[31:24];
                sim_memory[mem_addr+4] <= mem_write_data[39:32];
                sim_memory[mem_addr+5] <= mem_write_data[47:40];
                sim_memory[mem_addr+6] <= mem_write_data[55:48];
                sim_memory[mem_addr+7] <= mem_write_data[63:56];
                mem_ack <= 1;
            end
        end else begin
            mem_ack <= 0;
        end
    end
    
    // Tasks for test case setup
    task setup_page_table;
        // Create a simple page table for testing
        // Root page table at physical address 0x1000
        // Map virtual address 0x80000000 to physical address 0x10000000
        
        // Level 2 page table entry (PTE) - Points to the next level
        sim_memory[64'h1000] = 8'h01; // Valid bit set, pointer to level 1 PT
        sim_memory[64'h1001] = 8'h20; // Physical page number part 1
        sim_memory[64'h1002] = 8'h00; // Physical page number part 2
        sim_memory[64'h1003] = 8'h00; // Physical page number part 3
        sim_memory[64'h1004] = 8'h00; // Physical page number part 4
        sim_memory[64'h1005] = 8'h00; // Physical page number part 5
        sim_memory[64'h1006] = 8'h00; // Physical page number part 6
        sim_memory[64'h1007] = 8'h00; // Physical page number part 7
        
        // Level 1 page table entry - Points to the next level
        sim_memory[64'h2000] = 8'h01; // Valid bit set, pointer to level 0 PT
        sim_memory[64'h2001] = 8'h30; // Physical page number part 1
        sim_memory[64'h2002] = 8'h00; // Physical page number part 2
        sim_memory[64'h2003] = 8'h00; // Physical page number part 3
        sim_memory[64'h2004] = 8'h00; // Physical page number part 4
        sim_memory[64'h2005] = 8'h00; // Physical page number part 5
        sim_memory[64'h2006] = 8'h00; // Physical page number part 6
        sim_memory[64'h2007] = 8'h00; // Physical page number part 7
        
        // Level 0 page table entry - Points to the actual physical page
        sim_memory[64'h3000] = 8'hCF; // Valid bit set, Read/Write/Execute, User accessible
        sim_memory[64'h3001] = 8'h00; // Physical page number part 1
        sim_memory[64'h3002] = 8'h00; // Physical page number part 2
        sim_memory[64'h3003] = 8'h00; // Physical page number part 3
        sim_memory[64'h3004] = 8'h01; // Physical page number part 4 (0x10000000)
        sim_memory[64'h3005] = 8'h00; // Physical page number part 5
        sim_memory[64'h3006] = 8'h00; // Physical page number part 6
        sim_memory[64'h3007] = 8'h00; // Physical page number part 7
        
        // Set the SATP register to point to the root page table
        satp = {4'h8, 16'h0, 44'h1}; // Mode=Sv39, ASID=0, PPN=1 (physical page number)
    endtask
    
    // Test sequence
    initial begin
        $display("Starting MMU Unit Test");
        
        // Initialize signals
        clk = 0;
        rst_n = 0;
        virt_addr = 0;
        read = 0;
        write = 0;
        size = 3'b011; // 8 bytes (double word)
        req = 0;
        tlb_flush = 0;
        sum = 0;
        mxr = 0;
        current_mode = 2'b01; // Supervisor mode
        
        // Initialize memory
        for (int i = 0; i < 64*1024*1024; i++) begin
            sim_memory[i] = 8'h00;
        end
        
        // Apply reset
        #20;
        rst_n = 1;
        #20;
        
        // Setup page tables
        setup_page_table();
        
        // Testcase 1: Valid translation in supervisor mode
        $display("Test Case 1: Valid translation in supervisor mode");
        virt_addr = 64'h80000000; // Should translate to 0x10000000
        read = 1;
        write = 0;
        req = 1;
        
        // Wait for translation to complete
        wait(ack);
        #10;
        req = 0;
        
        // Check results
        if (page_fault) begin
            $display("ERROR: Unexpected page fault");
            $finish;
        end
        if (access_fault) begin
            $display("ERROR: Unexpected access fault");
            $finish;
        end
        if (phys_addr != 64'h10000000) begin
            $display("ERROR: Incorrect translation. Expected 0x10000000, got 0x%h", phys_addr);
            $finish;
        end
        $display("Test Case 1 PASSED");
        
        // Testcase 2: Using TLB for the same address (should be faster)
        $display("Test Case 2: TLB hit");
        virt_addr = 64'h80000000;
        read = 1;
        write = 0;
        req = 1;
        
        // Wait for translation to complete
        wait(ack);
        #10;
        req = 0;
        
        // Check results
        if (page_fault) begin
            $display("ERROR: Unexpected page fault");
            $finish;
        end
        if (access_fault) begin
            $display("ERROR: Unexpected access fault");
            $finish;
        end
        if (phys_addr != 64'h10000000) begin
            $display("ERROR: Incorrect translation. Expected 0x10000000, got 0x%h", phys_addr);
            $finish;
        end
        $display("Test Case 2 PASSED");
        
        // Testcase 3: TLB invalidation 
        $display("Test Case 3: TLB invalidation");
        tlb_flush = 1;
        #20;
        tlb_flush = 0;
        
        virt_addr = 64'h80000000;
        read = 1;
        write = 0;
        req = 1;
        
        // Wait for translation to complete
        wait(ack);
        #10;
        req = 0;
        
        // Check results
        if (page_fault) begin
            $display("ERROR: Unexpected page fault");
            $finish;
        end
        if (access_fault) begin
            $display("ERROR: Unexpected access fault");
            $finish;
        end
        if (phys_addr != 64'h10000000) begin
            $display("ERROR: Incorrect translation. Expected 0x10000000, got 0x%h", phys_addr);
            $finish;
        end
        $display("Test Case 3 PASSED");
        
        // Testcase 4: Access fault test
        $display("Test Case 4: Access fault test (write to read-only page)");
        
        // Modify page table entry to be read-only
        sim_memory[64'h3000] = 8'h8B; // Valid bit set, Read/Execute only
        
        // Flush TLB for the change to take effect
        tlb_flush = 1;
        #20;
        tlb_flush = 0;
        
        virt_addr = 64'h80000000;
        read = 0;
        write = 1; // Try to write
        req = 1;
        
        // Wait for translation to complete
        wait(ack);
        #10;
        req = 0;
        
        // Should get an access fault
        if (!access_fault) begin
            $display("ERROR: Expected access fault did not occur");
            $finish;
        end
        $display("Test Case 4 PASSED");
        
        // Testcase 5: Page fault test
        $display("Test Case 5: Page fault test (invalid page)");
        
        virt_addr = 64'h90000000; // Unmapped address
        read = 1;
        write = 0;
        req = 1;
        
        // Wait for translation to complete
        wait(ack);
        #10;
        req = 0;
        
        // Should get a page fault
        if (!page_fault) begin
            $display("ERROR: Expected page fault did not occur");
            $finish;
        end
        $display("Test Case 5 PASSED");
        
        // All tests passed
        $display("All MMU tests PASSED!");
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
        $dumpfile("mmu_test.vcd");
        $dumpvars(0, mmu_test);
    end
    
endmodule 