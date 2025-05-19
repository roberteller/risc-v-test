// Supervisor Mode and Virtual Memory Functional Test
`timescale 1ns/1ps

module supervisor_mode_test;
    // Parameters
    parameter DATA_WIDTH = 64;
    parameter ADDR_WIDTH = 64;
    parameter BOOT_ADDR = 64'h1000;
    parameter NUM_CORES = 1;

    // Clock and reset
    logic clk;
    logic rst_n;
    
    // Core control and status
    logic [NUM_CORES-1:0] core_active;
    
    // External interrupt interface
    logic m_ext_interrupt;
    logic s_ext_interrupt;
    
    // UART interface
    logic uart_rx;
    logic uart_tx;
    
    // Boot selection
    logic enable_linux;
    
    // Debug signals
    logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] pc_out;
    logic [NUM_CORES-1:0][DATA_WIDTH-1:0] alu_result_out;
    
    // Memory interface
    logic [ADDR_WIDTH-1:0] mem_addr;
    logic [DATA_WIDTH-1:0] mem_write_data;
    logic mem_read;
    logic mem_write;
    logic [7:0] mem_byte_en;
    logic mem_request;
    logic [DATA_WIDTH-1:0] mem_read_data;
    logic mem_ready;
    logic mem_error;
    
    // Simulated memory
    logic [7:0] sim_memory[16*1024*1024]; // 16MB simulated memory
    
    // Instantiate the multicore CPU
    linux_multicore #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .NUM_CORES(NUM_CORES),
        .BOOT_ADDR(BOOT_ADDR)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .core_active(core_active),
        
        // Memory interface
        .mem_addr(mem_addr),
        .mem_write_data(mem_write_data),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_byte_en(mem_byte_en),
        .mem_request(mem_request),
        .mem_read_data(mem_read_data),
        .mem_ready(mem_ready),
        .mem_error(mem_error),
        
        // Debug outputs
        .pc_out(pc_out),
        .alu_result_out(alu_result_out),
        
        // External interrupt interface
        .m_ext_interrupt(m_ext_interrupt),
        .s_ext_interrupt(s_ext_interrupt),
        
        // UART interface for console
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        
        // Boot selection
        .enable_linux(enable_linux)
    );
    
    // Clock generation
    always #5 clk = ~clk;
    
    // Memory response simulation
    always @(posedge clk) begin
        if (mem_request) begin
            // Simulate memory latency (2 cycles)
            repeat (1) @(posedge clk);
            
            if (mem_read) begin
                // Read data from memory
                logic [DATA_WIDTH-1:0] read_data;
                for (int i = 0; i < 8; i++) begin
                    if (mem_byte_en[i]) begin
                        read_data[i*8 +: 8] = sim_memory[mem_addr + i];
                    end else begin
                        read_data[i*8 +: 8] = 8'h00;
                    end
                end
                mem_read_data <= read_data;
                mem_ready <= 1;
                mem_error <= 0;
            end else if (mem_write) begin
                // Write data to memory
                for (int i = 0; i < 8; i++) begin
                    if (mem_byte_en[i]) begin
                        sim_memory[mem_addr + i] <= mem_write_data[i*8 +: 8];
                    end
                end
                mem_ready <= 1;
                mem_error <= 0;
            end
        end else begin
            mem_ready <= 0;
        end
    end
    
    // Load test program into memory
    task load_test_program;
        // Test program:
        // 1. Setup page table in machine mode
        // 2. Initialize satp register
        // 3. Switch to supervisor mode
        // 4. Test load/store with virtual addresses
        // 5. Test page fault handling
        
        // Simple page table setup at physical 0x2000
        // Map virtual 0x80000000 to physical 0x3000
        
        //----- Machine mode setup code -----//
        // Set up the page table at 0x2000
        
        // li a0, 0x2000               # a0 = page table address
        sim_memory[BOOT_ADDR+0] = 8'h37;  // lui a0, 0x2
        sim_memory[BOOT_ADDR+1] = 8'h25;
        sim_memory[BOOT_ADDR+2] = 8'h00;
        sim_memory[BOOT_ADDR+3] = 8'h00;
        
        // li a1, 0x21                 # PTE: valid, read, write + PPN=8 (0x3000)
        sim_memory[BOOT_ADDR+4] = 8'h93;  // addi a1, zero, 0x21
        sim_memory[BOOT_ADDR+5] = 8'h05;
        sim_memory[BOOT_ADDR+6] = 8'h10;
        sim_memory[BOOT_ADDR+7] = 8'h00;
        
        // li a2, 0x8                  # PPN=8 (0x3000 >> 12)
        sim_memory[BOOT_ADDR+8] = 8'h13;  // addi a2, zero, 0x8
        sim_memory[BOOT_ADDR+9] = 8'h06;
        sim_memory[BOOT_ADDR+10] = 8'h80;
        sim_memory[BOOT_ADDR+11] = 8'h00;
        
        // slli a2, a2, 10             # Shift PPN to bit position 10
        sim_memory[BOOT_ADDR+12] = 8'h13;
        sim_memory[BOOT_ADDR+13] = 8'h96;
        sim_memory[BOOT_ADDR+14] = 8'hA6;
        sim_memory[BOOT_ADDR+15] = 8'h00;
        
        // or a1, a1, a2               # Combine PPN with PTE flags
        sim_memory[BOOT_ADDR+16] = 8'hB3;
        sim_memory[BOOT_ADDR+17] = 8'h85;
        sim_memory[BOOT_ADDR+18] = 8'hC5;
        sim_memory[BOOT_ADDR+19] = 8'h00;
        
        // sd a1, 0(a0)                # Store PTE at the page table
        sim_memory[BOOT_ADDR+20] = 8'h23;
        sim_memory[BOOT_ADDR+21] = 8'hB0;
        sim_memory[BOOT_ADDR+22] = 8'h15;
        sim_memory[BOOT_ADDR+23] = 8'h00;
        
        // Set up satp register for Sv39 paging
        // li t0, 0x2000 >> 12         # PPN = physical page number of table
        sim_memory[BOOT_ADDR+24] = 8'h93;  // addi t0, zero, 0x2
        sim_memory[BOOT_ADDR+25] = 8'h02;
        sim_memory[BOOT_ADDR+26] = 8'h20;
        sim_memory[BOOT_ADDR+27] = 8'h00;
        
        // li t1, 8 << 60              # Mode = Sv39 (8) in satp upper bits
        sim_memory[BOOT_ADDR+28] = 8'h37;  // lui t1, 0x80000
        sim_memory[BOOT_ADDR+29] = 8'h03;
        sim_memory[BOOT_ADDR+30] = 8'h00;
        sim_memory[BOOT_ADDR+31] = 8'h80;
        
        sim_memory[BOOT_ADDR+32] = 8'h13;  // addi t1, t1, 0
        sim_memory[BOOT_ADDR+33] = 8'h83;
        sim_memory[BOOT_ADDR+34] = 8'h03;
        sim_memory[BOOT_ADDR+35] = 8'h00;
        
        sim_memory[BOOT_ADDR+36] = 8'h37;  // lui t2, 0
        sim_memory[BOOT_ADDR+37] = 8'h03;
        sim_memory[BOOT_ADDR+38] = 8'h00;
        sim_memory[BOOT_ADDR+39] = 8'h00;
        
        sim_memory[BOOT_ADDR+40] = 8'h33;  // or t1, t1, t0
        sim_memory[BOOT_ADDR+41] = 8'h83;
        sim_memory[BOOT_ADDR+42] = 8'h02;
        sim_memory[BOOT_ADDR+43] = 8'h03;
        
        // csrw satp, t1               # Set the satp register for paging
        sim_memory[BOOT_ADDR+44] = 8'h73;
        sim_memory[BOOT_ADDR+45] = 8'h90;
        sim_memory[BOOT_ADDR+46] = 8'h03;
        sim_memory[BOOT_ADDR+47] = 8'h18;
        
        // Set up a stack at physical 0x8000
        // li sp, 0x8000
        sim_memory[BOOT_ADDR+48] = 8'h37;  // lui sp, 0x8
        sim_memory[BOOT_ADDR+49] = 8'h21;
        sim_memory[BOOT_ADDR+50] = 8'h00;
        sim_memory[BOOT_ADDR+51] = 8'h00;
        
        // Store some test data to verify later
        // li t0, 0xdeadbeef           # Test data
        sim_memory[BOOT_ADDR+52] = 8'hB7;  // lui t0, 0xDEADB
        sim_memory[BOOT_ADDR+53] = 8'h02;
        sim_memory[BOOT_ADDR+54] = 8'hAD;
        sim_memory[BOOT_ADDR+55] = 8'hDE;
        
        sim_memory[BOOT_ADDR+56] = 8'h93;  // addi t0, t0, 0xEEF
        sim_memory[BOOT_ADDR+57] = 8'h82;
        sim_memory[BOOT_ADDR+58] = 8'hF8;
        sim_memory[BOOT_ADDR+59] = 8'hEE;
        
        // li t1, 0x3000               # Physical address for data
        sim_memory[BOOT_ADDR+60] = 8'h37;  // lui t1, 0x3
        sim_memory[BOOT_ADDR+61] = 8'h03;
        sim_memory[BOOT_ADDR+62] = 8'h00;
        sim_memory[BOOT_ADDR+63] = 8'h00;
        
        // sd t0, 0(t1)                # Store test data at physical 0x3000
        sim_memory[BOOT_ADDR+64] = 8'h23;
        sim_memory[BOOT_ADDR+65] = 8'hB0;
        sim_memory[BOOT_ADDR+66] = 8'h53;
        sim_memory[BOOT_ADDR+67] = 8'h00;
        
        // Prepare values for supervisor mode
        // li t0, 0x80000000           # Virtual address to access
        sim_memory[BOOT_ADDR+68] = 8'h37;  // lui t0, 0x80000
        sim_memory[BOOT_ADDR+69] = 8'h02;
        sim_memory[BOOT_ADDR+70] = 8'h00;
        sim_memory[BOOT_ADDR+71] = 8'h80;
        
        // la t1, s_mode_entry         # Address to jump to in S-mode
        sim_memory[BOOT_ADDR+72] = 8'h97;  // auipc t1, 0
        sim_memory[BOOT_ADDR+73] = 8'h02;
        sim_memory[BOOT_ADDR+74] = 8'h00;
        sim_memory[BOOT_ADDR+75] = 8'h00;
        
        sim_memory[BOOT_ADDR+76] = 8'h93;  // addi t1, t1, 40
        sim_memory[BOOT_ADDR+77] = 8'h82;
        sim_memory[BOOT_ADDR+78] = 8'h82;
        sim_memory[BOOT_ADDR+79] = 8'h02;
        
        // Set up MSTATUS for switching to S-mode
        // li t2, 0x1200               # MPP = 01 (Supervisor mode), MPIE = 1
        sim_memory[BOOT_ADDR+80] = 8'h93;  // addi t2, zero, 0x1200
        sim_memory[BOOT_ADDR+81] = 8'h03;
        sim_memory[BOOT_ADDR+82] = 8'h00;
        sim_memory[BOOT_ADDR+83] = 8'h12;
        
        // csrw mstatus, t2            # Set mstatus
        sim_memory[BOOT_ADDR+84] = 8'h73;
        sim_memory[BOOT_ADDR+85] = 8'h90;
        sim_memory[BOOT_ADDR+86] = 8'h03;
        sim_memory[BOOT_ADDR+87] = 8'h30;
        
        // csrw mepc, t1               # Set mepc to S-mode entry
        sim_memory[BOOT_ADDR+88] = 8'h73;
        sim_memory[BOOT_ADDR+89] = 8'h90;
        sim_memory[BOOT_ADDR+90] = 8'h13;
        sim_memory[BOOT_ADDR+91] = 8'h34;
        
        // mret                        # Return to S-mode
        sim_memory[BOOT_ADDR+92] = 8'h73;
        sim_memory[BOOT_ADDR+93] = 8'h00;
        sim_memory[BOOT_ADDR+94] = 8'h20;
        sim_memory[BOOT_ADDR+95] = 8'h30;
        
        //----- Supervisor mode code (virtual addresses) -----//
        // s_mode_entry:
        // ld t2, 0(t0)                # Load from virtual address 0x80000000
        sim_memory[BOOT_ADDR+96] = 8'h83;  // ld t2, 0(t0)
        sim_memory[BOOT_ADDR+97] = 8'h33;
        sim_memory[BOOT_ADDR+98] = 8'h05;
        sim_memory[BOOT_ADDR+99] = 8'h00;
        
        // sd t2, 8(t0)                # Store to virtual address 0x80000008
        sim_memory[BOOT_ADDR+100] = 8'h23;
        sim_memory[BOOT_ADDR+101] = 8'hB4;
        sim_memory[BOOT_ADDR+102] = 8'h05;
        sim_memory[BOOT_ADDR+103] = 8'h00;
        
        // li a0, 0x12345678           # New test data
        sim_memory[BOOT_ADDR+104] = 8'h37;  // lui a0, 0x12345
        sim_memory[BOOT_ADDR+105] = 8'h25;
        sim_memory[BOOT_ADDR+106] = 8'h45;
        sim_memory[BOOT_ADDR+107] = 8'h12;
        
        sim_memory[BOOT_ADDR+108] = 8'h13;  // addi a0, a0, 0x678
        sim_memory[BOOT_ADDR+109] = 8'h05;
        sim_memory[BOOT_ADDR+110] = 8'h86;
        sim_memory[BOOT_ADDR+111] = 8'h67;
        
        // sd a0, 0(t0)                # Update virtual address 0x80000000
        sim_memory[BOOT_ADDR+112] = 8'h23;
        sim_memory[BOOT_ADDR+113] = 8'hB0;
        sim_memory[BOOT_ADDR+114] = 8'h05;
        sim_memory[BOOT_ADDR+115] = 8'h00;
        
        // ld a1, 0(t0)                # Verify the update
        sim_memory[BOOT_ADDR+116] = 8'h83;
        sim_memory[BOOT_ADDR+117] = 8'hB5;
        sim_memory[BOOT_ADDR+118] = 8'h05;
        sim_memory[BOOT_ADDR+119] = 8'h00;
        
        // Try to access a non-mapped address - should cause a page fault
        // li t3, 0x90000000           # Unmapped virtual address
        sim_memory[BOOT_ADDR+120] = 8'h37;  // lui t3, 0x90000
        sim_memory[BOOT_ADDR+121] = 8'h03;
        sim_memory[BOOT_ADDR+122] = 8'h00;
        sim_memory[BOOT_ADDR+123] = 8'h90;
        
        // ld a2, 0(t3)                # This should cause a page fault
        sim_memory[BOOT_ADDR+124] = 8'h03;
        sim_memory[BOOT_ADDR+125] = 8'h36;
        sim_memory[BOOT_ADDR+126] = 8'h03;
        sim_memory[BOOT_ADDR+127] = 8'h00;
        
        // Trap handler should redirect here after page fault
        // li a3, 0xAABBCCDD           # Load recognizable pattern to indicate trap handled
        sim_memory[BOOT_ADDR+128] = 8'h37;  // lui a3, 0xAABBC
        sim_memory[BOOT_ADDR+129] = 8'h26;
        sim_memory[BOOT_ADDR+130] = 8'hBC;
        sim_memory[BOOT_ADDR+131] = 8'hAA;
        
        sim_memory[BOOT_ADDR+132] = 8'h93;  // addi a3, a3, 0xDD
        sim_memory[BOOT_ADDR+133] = 8'h86;
        sim_memory[BOOT_ADDR+134] = 8'hD8;
        sim_memory[BOOT_ADDR+135] = 8'h0D;
        
        // j exit                      # Jump to exit
        sim_memory[BOOT_ADDR+136] = 8'h6F;
        sim_memory[BOOT_ADDR+137] = 8'h00;
        sim_memory[BOOT_ADDR+138] = 8'h00;
        sim_memory[BOOT_ADDR+139] = 8'h01;
        
        // exit:
        // Test is complete, loop forever
        // j .                         # Infinite loop
        sim_memory[BOOT_ADDR+140] = 8'h6F;
        sim_memory[BOOT_ADDR+141] = 8'h00;
        sim_memory[BOOT_ADDR+142] = 8'h00;
        sim_memory[BOOT_ADDR+143] = 8'h00;
        
        // Set up trap handlers in M-mode
        // li t0, m_trap_handler       # Load address of M-mode trap handler
        sim_memory[BOOT_ADDR+144] = 8'h17;  // auipc t0, 0
        sim_memory[BOOT_ADDR+145] = 8'h02;
        sim_memory[BOOT_ADDR+146] = 8'h00;
        sim_memory[BOOT_ADDR+147] = 8'h00;
        
        sim_memory[BOOT_ADDR+148] = 8'h93;  // addi t0, t0, 36
        sim_memory[BOOT_ADDR+149] = 8'h82;
        sim_memory[BOOT_ADDR+150] = 8'h42;
        sim_memory[BOOT_ADDR+151] = 8'h00;
        
        // csrw mtvec, t0              # Set trap vector
        sim_memory[BOOT_ADDR+152] = 8'h73;
        sim_memory[BOOT_ADDR+153] = 8'h90;
        sim_memory[BOOT_ADDR+154] = 8'h02;
        sim_memory[BOOT_ADDR+155] = 8'h30;
        
        // li t0, s_trap_handler       # Load address of S-mode trap handler
        sim_memory[BOOT_ADDR+156] = 8'h17;  // auipc t0, 0
        sim_memory[BOOT_ADDR+157] = 8'h02;
        sim_memory[BOOT_ADDR+158] = 8'h00;
        sim_memory[BOOT_ADDR+159] = 8'h00;
        
        sim_memory[BOOT_ADDR+160] = 8'h93;  // addi t0, t0, 48
        sim_memory[BOOT_ADDR+161] = 8'h82;
        sim_memory[BOOT_ADDR+162] = 8'h02;
        sim_memory[BOOT_ADDR+163] = 8'h03;
        
        // csrw stvec, t0              # Set S-mode trap vector
        sim_memory[BOOT_ADDR+164] = 8'h73;
        sim_memory[BOOT_ADDR+165] = 8'h10;
        sim_memory[BOOT_ADDR+166] = 8'h02;
        sim_memory[BOOT_ADDR+167] = 8'h10;
        
        // trap handlers
        // m_trap_handler:
        // csrr t0, mcause             # Read cause of trap
        sim_memory[BOOT_ADDR+168] = 8'h73;
        sim_memory[BOOT_ADDR+169] = 8'h22;
        sim_memory[BOOT_ADDR+170] = 8'h20;
        sim_memory[BOOT_ADDR+171] = 8'h34;
        
        // csrr t1, mepc               # Read trap EPC
        sim_memory[BOOT_ADDR+172] = 8'h73;
        sim_memory[BOOT_ADDR+173] = 8'h22;
        sim_memory[BOOT_ADDR+174] = 8'h10;
        sim_memory[BOOT_ADDR+175] = 8'h34;
        
        // addi t1, t1, 4              # Skip trap instruction
        sim_memory[BOOT_ADDR+176] = 8'h93;
        sim_memory[BOOT_ADDR+177] = 8'h82;
        sim_memory[BOOT_ADDR+178] = 8'h42;
        sim_memory[BOOT_ADDR+179] = 8'h00;
        
        // csrw mepc, t1               # Update mepc
        sim_memory[BOOT_ADDR+180] = 8'h73;
        sim_memory[BOOT_ADDR+181] = 8'h10;
        sim_memory[BOOT_ADDR+182] = 8'h12;
        sim_memory[BOOT_ADDR+183] = 8'h34;
        
        // mret                        # Return from trap
        sim_memory[BOOT_ADDR+184] = 8'h73;
        sim_memory[BOOT_ADDR+185] = 8'h00;
        sim_memory[BOOT_ADDR+186] = 8'h20;
        sim_memory[BOOT_ADDR+187] = 8'h30;
        
        // s_trap_handler:
        // csrr t0, scause             # Read cause of trap
        sim_memory[BOOT_ADDR+188] = 8'h73;
        sim_memory[BOOT_ADDR+189] = 8'h22;
        sim_memory[BOOT_ADDR+190] = 8'h20;
        sim_memory[BOOT_ADDR+191] = 8'h14;
        
        // csrr t1, sepc               # Read trap EPC
        sim_memory[BOOT_ADDR+192] = 8'h73;
        sim_memory[BOOT_ADDR+193] = 8'h22;
        sim_memory[BOOT_ADDR+194] = 8'h10;
        sim_memory[BOOT_ADDR+195] = 8'h14;
        
        // addi t1, t1, 4              # Skip faulting instruction
        sim_memory[BOOT_ADDR+196] = 8'h93;
        sim_memory[BOOT_ADDR+197] = 8'h82;
        sim_memory[BOOT_ADDR+198] = 8'h42;
        sim_memory[BOOT_ADDR+199] = 8'h00;
        
        // csrw sepc, t1               # Update sepc to skip faulting instruction
        sim_memory[BOOT_ADDR+200] = 8'h73;
        sim_memory[BOOT_ADDR+201] = 8'h10;
        sim_memory[BOOT_ADDR+202] = 8'h12;
        sim_memory[BOOT_ADDR+203] = 8'h14;
        
        // sret                        # Return from trap
        sim_memory[BOOT_ADDR+204] = 8'h73;
        sim_memory[BOOT_ADDR+205] = 8'h00;
        sim_memory[BOOT_ADDR+206] = 8'h20;
        sim_memory[BOOT_ADDR+207] = 8'h10;
    endtask
    
    // Initialize simulation
    initial begin
        $display("Starting Supervisor Mode and Virtual Memory Test");
        
        // Initialize signals
        clk = 0;
        rst_n = 0;
        m_ext_interrupt = 0;
        s_ext_interrupt = 0;
        uart_rx = 1;
        enable_linux = 0;
        
        // Initialize memory
        for (int i = 0; i < 16*1024*1024; i++) begin
            sim_memory[i] = 8'h00;
        end
        
        // Load test program
        load_test_program();
        
        // Apply reset
        #20;
        rst_n = 1;
        
        // Run the simulation for a while
        #50000;
        
        // Check test completion
        if ((pc_out[0] >= BOOT_ADDR+140) && (pc_out[0] <= BOOT_ADDR+143)) begin
            $display("Test completed successfully!");
            
            // Verify physical memory at 0x3000 has the updated value
            logic [63:0] final_value = {
                sim_memory[64'h3007],
                sim_memory[64'h3006],
                sim_memory[64'h3005],
                sim_memory[64'h3004],
                sim_memory[64'h3003],
                sim_memory[64'h3002],
                sim_memory[64'h3001],
                sim_memory[64'h3000]
            };
            
            if (final_value == 64'h12345678) begin
                $display("Virtual memory translation is working correctly!");
            end else begin
                $display("ERROR: Unexpected memory value at physical address 0x3000: 0x%h", final_value);
            end
            
            // Check if trap handler was executed (A3 should have a specific value)
            if (alu_result_out[0] == 64'hAABBCCDD) begin
                $display("Page fault handling is working correctly!");
            end else begin
                $display("ERROR: Page fault handler either did not execute or did not set A3 correctly");
            end
        end else begin
            $display("ERROR: Test did not complete successfully. Final PC = 0x%h", pc_out[0]);
        end
        
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
        $dumpfile("supervisor_mode_test.vcd");
        $dumpvars(0, supervisor_mode_test);
    end
    
endmodule 