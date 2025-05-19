// Multicore Performance Regression Test
`timescale 1ns/1ps

module multicore_performance_test;
    // Parameters
    parameter DATA_WIDTH = 64;
    parameter ADDR_WIDTH = 64;
    parameter BOOT_ADDR = 64'h1000;
    parameter NUM_CORES = 4;
    parameter BENCHMARK_ITERATIONS = 100;

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
    logic [7:0] sim_memory[256*1024*1024]; // 256MB simulated memory
    
    // Performance metrics
    int total_cycles;
    int instructions_executed[NUM_CORES];
    int memory_accesses[NUM_CORES];
    int memory_conflicts;
    real ipc[NUM_CORES]; // Instructions per cycle
    
    // Barrier synchronization memory locations for multicore tests
    parameter BARRIER_START = 64'h20000;
    parameter SHARED_DATA_START = 64'h30000;
    parameter CORE_LOCAL_START = 64'h40000;
    
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
    
    // Track performance metrics
    always @(posedge clk) begin
        if (rst_n) begin
            total_cycles <= total_cycles + 1;
            
            // Count memory accesses and conflicts
            if (mem_request) begin
                for (int i = 0; i < NUM_CORES; i++) begin
                    if (mem_addr >= (CORE_LOCAL_START + i*64'h10000) && 
                        mem_addr < (CORE_LOCAL_START + (i+1)*64'h10000)) begin
                        memory_accesses[i] <= memory_accesses[i] + 1;
                    end
                end
                
                // Check for access to shared data - potential conflict
                if (mem_addr >= SHARED_DATA_START && mem_addr < CORE_LOCAL_START) begin
                    memory_conflicts <= memory_conflicts + 1;
                end
            end
            
            // Calculate instructions executed based on program counter changes
            // This is approximate as we don't have perfect visibility into the pipeline
            for (int i = 0; i < NUM_CORES; i++) begin
                if (pc_out[i] != '0 && pc_out[i] != BOOT_ADDR && core_active[i]) begin
                    instructions_executed[i] <= instructions_executed[i] + 1;
                end
            end
        end
    end
    
    // Memory response simulation with variable latency
    always @(posedge clk) begin
        if (mem_request) begin
            int latency;
            
            // Simulate variable memory latency based on address regions
            if (mem_addr < 64'h10000) begin
                // Fast memory region (e.g., cache-like)
                latency = 1;
            end else if (mem_addr >= SHARED_DATA_START && mem_addr < CORE_LOCAL_START) begin
                // Shared data with contention
                latency = 3 + ($random % 3); // 3-5 cycles
            end else begin
                // Regular memory
                latency = 2; 
            end
            
            // Apply the latency
            repeat (latency - 1) @(posedge clk);
            
            if (mem_read) begin
                // Read data from memory
                logic [DATA_WIDTH-1:0] read_data;
                for (int i = 0; i < 8; i++) begin
                    if (mem_byte_en[i]) begin
                        read_data[i*8 +: 8] = sim_memory[mem_addr + i];
                    else begin
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
    
    // Set up the parallel matrix multiplication test program
    task load_matrix_mult_program;
        // Program data:
        // - Matrix A at SHARED_DATA_START
        // - Matrix B at SHARED_DATA_START + 0x1000
        // - Result Matrix C at SHARED_DATA_START + 0x2000
        // - Each core computes a portion of the result
        
        // Initialize matrices A and B with test data
        for (int i = 0; i < 64; i++) begin
            for (int j = 0; j < 64; j++) begin
                // Matrix A (64x64)
                sim_memory[SHARED_DATA_START + (i*64 + j)] = i + j;
                
                // Matrix B (64x64)
                sim_memory[SHARED_DATA_START + 0x1000 + (i*64 + j)] = i - j;
                
                // Initialize result matrix C to 0
                sim_memory[SHARED_DATA_START + 0x2000 + (i*64 + j)] = 0;
            end
        end
        
        // Set up the barrier for synchronization
        for (int i = 0; i < NUM_CORES; i++) begin
            sim_memory[BARRIER_START + i] = 0; // Not ready yet
        end
        
        // Boot code for each core
        for (int core = 0; core < NUM_CORES; core++) begin
            int code_offset = core * 0x100; // Each core gets its own code space
            
            // Load core ID
            // li a0, <core_id>
            sim_memory[BOOT_ADDR + code_offset + 0] = 8'h13;
            sim_memory[BOOT_ADDR + code_offset + 1] = 8'h05;
            sim_memory[BOOT_ADDR + code_offset + 2] = core & 8'hFF;
            sim_memory[BOOT_ADDR + code_offset + 3] = 8'h00;
            
            // Calculate work division based on core ID
            // Calculate start row: core_id * (64/NUM_CORES)
            // li a1, 64/NUM_CORES
            sim_memory[BOOT_ADDR + code_offset + 4] = 8'h93;
            sim_memory[BOOT_ADDR + code_offset + 5] = 8'h05;
            sim_memory[BOOT_ADDR + code_offset + 6] = (64/NUM_CORES) & 8'hFF;
            sim_memory[BOOT_ADDR + code_offset + 7] = 8'h00;
            
            // mul a1, a0, a1  # a1 = start row
            sim_memory[BOOT_ADDR + code_offset + 8] = 8'hB3;
            sim_memory[BOOT_ADDR + code_offset + 9] = 8'h85;
            sim_memory[BOOT_ADDR + code_offset + 10] = 8'h05;
            sim_memory[BOOT_ADDR + code_offset + 11] = 8'h02;
            
            // Calculate end row: start row + (64/NUM_CORES)
            // addi a2, a1, 64/NUM_CORES
            sim_memory[BOOT_ADDR + code_offset + 12] = 8'h13;
            sim_memory[BOOT_ADDR + code_offset + 13] = 8'h06;
            sim_memory[BOOT_ADDR + code_offset + 14] = (64/NUM_CORES) & 8'hFF;
            sim_memory[BOOT_ADDR + code_offset + 15] = 8'h00;
            
            // Load matrix addresses
            // li a3, SHARED_DATA_START      # Matrix A address
            sim_memory[BOOT_ADDR + code_offset + 16] = 8'h37;
            sim_memory[BOOT_ADDR + code_offset + 17] = 8'h26;
            sim_memory[BOOT_ADDR + code_offset + 18] = (SHARED_DATA_START >> 16) & 8'hFF;
            sim_memory[BOOT_ADDR + code_offset + 19] = (SHARED_DATA_START >> 24) & 8'hFF;
            
            // li a4, SHARED_DATA_START+0x1000  # Matrix B address
            sim_memory[BOOT_ADDR + code_offset + 20] = 8'h37;
            sim_memory[BOOT_ADDR + code_offset + 21] = 8'h27;
            sim_memory[BOOT_ADDR + code_offset + 22] = ((SHARED_DATA_START+0x1000) >> 16) & 8'hFF;
            sim_memory[BOOT_ADDR + code_offset + 23] = ((SHARED_DATA_START+0x1000) >> 24) & 8'hFF;
            
            // li a5, SHARED_DATA_START+0x2000  # Result Matrix C address
            sim_memory[BOOT_ADDR + code_offset + 24] = 8'h37;
            sim_memory[BOOT_ADDR + code_offset + 25] = 8'h27;
            sim_memory[BOOT_ADDR + code_offset + 26] = ((SHARED_DATA_START+0x2000) >> 16) & 8'hFF;
            sim_memory[BOOT_ADDR + code_offset + 27] = ((SHARED_DATA_START+0x2000) >> 24) & 8'hFF;
            
            // Matrix multiplication loop (simplified for memory constraints)
            // Outer loop - for each row assigned to this core
            // mv t0, a1       # Initialize row counter with start row
            sim_memory[BOOT_ADDR + code_offset + 28] = 8'h33;
            sim_memory[BOOT_ADDR + code_offset + 29] = 8'h83;
            sim_memory[BOOT_ADDR + code_offset + 30] = 8'h05;
            sim_memory[BOOT_ADDR + code_offset + 31] = 8'h00;
            
            // outer_loop:
            // bge t0, a2, done # If row >= end_row, we're done
            sim_memory[BOOT_ADDR + code_offset + 32] = 8'h63;
            sim_memory[BOOT_ADDR + code_offset + 33] = 8'h50;
            sim_memory[BOOT_ADDR + code_offset + 34] = 8'hC3;
            sim_memory[BOOT_ADDR + code_offset + 35] = 8'h0A;
            
            // li t1, 0        # Initialize column counter
            sim_memory[BOOT_ADDR + code_offset + 36] = 8'h93;
            sim_memory[BOOT_ADDR + code_offset + 37] = 8'h03;
            sim_memory[BOOT_ADDR + code_offset + 38] = 8'h00;
            sim_memory[BOOT_ADDR + code_offset + 39] = 8'h00;
            
            // inner_loop_col:
            // li t2, 64       # Number of columns
            sim_memory[BOOT_ADDR + code_offset + 40] = 8'h13;
            sim_memory[BOOT_ADDR + code_offset + 41] = 8'h04;
            sim_memory[BOOT_ADDR + code_offset + 42] = 8'h00;
            sim_memory[BOOT_ADDR + code_offset + 43] = 8'h04;
            
            // bge t1, t2, next_row # If col >= 64, go to next row
            sim_memory[BOOT_ADDR + code_offset + 44] = 8'h63;
            sim_memory[BOOT_ADDR + code_offset + 45] = 8'hD0;
            sim_memory[BOOT_ADDR + code_offset + 46] = 8'h43;
            sim_memory[BOOT_ADDR + code_offset + 47] = 8'h08;
            
            // li t3, 0        # Initialize k counter (for dot product)
            sim_memory[BOOT_ADDR + code_offset + 48] = 8'h93;
            sim_memory[BOOT_ADDR + code_offset + 49] = 8'h04;
            sim_memory[BOOT_ADDR + code_offset + 50] = 8'h00;
            sim_memory[BOOT_ADDR + code_offset + 51] = 8'h00;
            
            // li t4, 0        # Initialize sum
            sim_memory[BOOT_ADDR + code_offset + 52] = 8'h13;
            sim_memory[BOOT_ADDR + code_offset + 53] = 8'h05;
            sim_memory[BOOT_ADDR + code_offset + 54] = 8'h00;
            sim_memory[BOOT_ADDR + code_offset + 55] = 8'h00;
            
            // inner_loop_k:
            // bge t3, t2, store_result # If k >= 64, store result
            sim_memory[BOOT_ADDR + code_offset + 56] = 8'h63;
            sim_memory[BOOT_ADDR + code_offset + 57] = 8'h50;
            sim_memory[BOOT_ADDR + code_offset + 58] = 8'h44;
            sim_memory[BOOT_ADDR + code_offset + 59] = 8'h06;
            
            // Calculate address for A[row][k]
            // mul t5, t0, t2  # row * 64
            sim_memory[BOOT_ADDR + code_offset + 60] = 8'h33;
            sim_memory[BOOT_ADDR + code_offset + 61] = 8'h86;
            sim_memory[BOOT_ADDR + code_offset + 62] = 8'h43;
            sim_memory[BOOT_ADDR + code_offset + 63] = 8'h02;
            
            // add t5, t5, t3  # + k
            sim_memory[BOOT_ADDR + code_offset + 64] = 8'h33;
            sim_memory[BOOT_ADDR + code_offset + 65] = 8'h06;
            sim_memory[BOOT_ADDR + code_offset + 66] = 8'hD6;
            sim_memory[BOOT_ADDR + code_offset + 67] = 8'h00;
            
            // add t5, a3, t5  # Base address + offset
            sim_memory[BOOT_ADDR + code_offset + 68] = 8'h33;
            sim_memory[BOOT_ADDR + code_offset + 69] = 8'h86;
            sim_memory[BOOT_ADDR + code_offset + 70] = 8'hD6;
            sim_memory[BOOT_ADDR + code_offset + 71] = 8'h00;
            
            // lbu t6, 0(t5)   # Load A[row][k]
            sim_memory[BOOT_ADDR + code_offset + 72] = 8'h83;
            sim_memory[BOOT_ADDR + code_offset + 73] = 8'hCF;
            sim_memory[BOOT_ADDR + code_offset + 74] = 8'h06;
            sim_memory[BOOT_ADDR + code_offset + 75] = 8'h00;
            
            // Calculate address for B[k][col]
            // mul t5, t3, t2  # k * 64
            sim_memory[BOOT_ADDR + code_offset + 76] = 8'h33;
            sim_memory[BOOT_ADDR + code_offset + 77] = 8'h86;
            sim_memory[BOOT_ADDR + code_offset + 78] = 8'h44;
            sim_memory[BOOT_ADDR + code_offset + 79] = 8'h02;
            
            // add t5, t5, t1  # + col
            sim_memory[BOOT_ADDR + code_offset + 80] = 8'h33;
            sim_memory[BOOT_ADDR + code_offset + 81] = 8'h06;
            sim_memory[BOOT_ADDR + code_offset + 82] = 8'h36;
            sim_memory[BOOT_ADDR + code_offset + 83] = 8'h00;
            
            // add t5, a4, t5  # Base address + offset
            sim_memory[BOOT_ADDR + code_offset + 84] = 8'h33;
            sim_memory[BOOT_ADDR + code_offset + 85] = 8'h86;
            sim_memory[BOOT_ADDR + code_offset + 86] = 8'h76;
            sim_memory[BOOT_ADDR + code_offset + 87] = 8'h00;
            
            // lbu t0, 0(t5)   # Load B[k][col] (temporary use t0)
            sim_memory[BOOT_ADDR + code_offset + 88] = 8'h03;
            sim_memory[BOOT_ADDR + code_offset + 89] = 8'h83;
            sim_memory[BOOT_ADDR + code_offset + 90] = 8'h06;
            sim_memory[BOOT_ADDR + code_offset + 91] = 8'h00;
            
            // mul t0, t6, t0  # A[row][k] * B[k][col]
            sim_memory[BOOT_ADDR + code_offset + 92] = 8'h33;
            sim_memory[BOOT_ADDR + code_offset + 93] = 8'h03;
            sim_memory[BOOT_ADDR + code_offset + 94] = 8'h03;
            sim_memory[BOOT_ADDR + code_offset + 95] = 8'h03;
            
            // add t4, t4, t0  # sum += A[row][k] * B[k][col]
            sim_memory[BOOT_ADDR + code_offset + 96] = 8'h33;
            sim_memory[BOOT_ADDR + code_offset + 97] = 8'h85;
            sim_memory[BOOT_ADDR + code_offset + 98] = 8'h05;
            sim_memory[BOOT_ADDR + code_offset + 99] = 8'h00;
            
            // Restore row counter
            // mv t0, a1
            sim_memory[BOOT_ADDR + code_offset + 100] = 8'h33;
            sim_memory[BOOT_ADDR + code_offset + 101] = 8'h83;
            sim_memory[BOOT_ADDR + code_offset + 102] = 8'h05;
            sim_memory[BOOT_ADDR + code_offset + 103] = 8'h00;
            
            // addi t3, t3, 1  # k++
            sim_memory[BOOT_ADDR + code_offset + 104] = 8'h93;
            sim_memory[BOOT_ADDR + code_offset + 105] = 8'h84;
            sim_memory[BOOT_ADDR + code_offset + 106] = 8'h14;
            sim_memory[BOOT_ADDR + code_offset + 107] = 8'h00;
            
            // j inner_loop_k
            sim_memory[BOOT_ADDR + code_offset + 108] = 8'h6F;
            sim_memory[BOOT_ADDR + code_offset + 109] = 8'hF0;
            sim_memory[BOOT_ADDR + code_offset + 110] = 8'h9F;
            sim_memory[BOOT_ADDR + code_offset + 111] = 8'hFA;
            
            // store_result:
            // Calculate address for C[row][col]
            // mul t5, t0, t2  # row * 64
            sim_memory[BOOT_ADDR + code_offset + 112] = 8'h33;
            sim_memory[BOOT_ADDR + code_offset + 113] = 8'h86;
            sim_memory[BOOT_ADDR + code_offset + 114] = 8'h43;
            sim_memory[BOOT_ADDR + code_offset + 115] = 8'h02;
            
            // add t5, t5, t1  # + col
            sim_memory[BOOT_ADDR + code_offset + 116] = 8'h33;
            sim_memory[BOOT_ADDR + code_offset + 117] = 8'h06;
            sim_memory[BOOT_ADDR + code_offset + 118] = 8'h36;
            sim_memory[BOOT_ADDR + code_offset + 119] = 8'h00;
            
            // add t5, a5, t5  # Base address + offset
            sim_memory[BOOT_ADDR + code_offset + 120] = 8'h33;
            sim_memory[BOOT_ADDR + code_offset + 121] = 8'h86;
            sim_memory[BOOT_ADDR + code_offset + 122] = 8'hA6;
            sim_memory[BOOT_ADDR + code_offset + 123] = 8'h00;
            
            // sb t4, 0(t5)    # Store result to C[row][col]
            sim_memory[BOOT_ADDR + code_offset + 124] = 8'h23;
            sim_memory[BOOT_ADDR + code_offset + 125] = 8'h00;
            sim_memory[BOOT_ADDR + code_offset + 126] = 8'h56;
            sim_memory[BOOT_ADDR + code_offset + 127] = 8'h00;
            
            // addi t1, t1, 1  # col++
            sim_memory[BOOT_ADDR + code_offset + 128] = 8'h93;
            sim_memory[BOOT_ADDR + code_offset + 129] = 8'h83;
            sim_memory[BOOT_ADDR + code_offset + 130] = 8'h13;
            sim_memory[BOOT_ADDR + code_offset + 131] = 8'h00;
            
            // j inner_loop_col
            sim_memory[BOOT_ADDR + code_offset + 132] = 8'h6F;
            sim_memory[BOOT_ADDR + code_offset + 133] = 8'h00;
            sim_memory[BOOT_ADDR + code_offset + 134] = 8'h00;
            sim_memory[BOOT_ADDR + code_offset + 135] = 8'hF8;
            
            // next_row:
            // addi t0, t0, 1  # row++
            sim_memory[BOOT_ADDR + code_offset + 136] = 8'h13;
            sim_memory[BOOT_ADDR + code_offset + 137] = 8'h03;
            sim_memory[BOOT_ADDR + code_offset + 138] = 8'h13;
            sim_memory[BOOT_ADDR + code_offset + 139] = 8'h00;
            
            // j outer_loop
            sim_memory[BOOT_ADDR + code_offset + 140] = 8'h6F;
            sim_memory[BOOT_ADDR + code_offset + 141] = 8'h00;
            sim_memory[BOOT_ADDR + code_offset + 142] = 8'h00;
            sim_memory[BOOT_ADDR + code_offset + 143] = 8'hF6;
            
            // done:
            // Set barrier flag indicating this core is done
            // li t0, BARRIER_START
            sim_memory[BOOT_ADDR + code_offset + 144] = 8'h37;
            sim_memory[BOOT_ADDR + code_offset + 145] = 8'h23;
            sim_memory[BOOT_ADDR + code_offset + 146] = (BARRIER_START >> 16) & 8'hFF;
            sim_memory[BOOT_ADDR + code_offset + 147] = (BARRIER_START >> 24) & 8'hFF;
            
            // add t0, t0, a0  # Add core ID offset
            sim_memory[BOOT_ADDR + code_offset + 148] = 8'h33;
            sim_memory[BOOT_ADDR + code_offset + 149] = 8'h83;
            sim_memory[BOOT_ADDR + code_offset + 150] = 8'h05;
            sim_memory[BOOT_ADDR + code_offset + 151] = 8'h00;
            
            // li t1, 1        # Ready flag
            sim_memory[BOOT_ADDR + code_offset + 152] = 8'h93;
            sim_memory[BOOT_ADDR + code_offset + 153] = 8'h03;
            sim_memory[BOOT_ADDR + code_offset + 154] = 8'h10;
            sim_memory[BOOT_ADDR + code_offset + 155] = 8'h00;
            
            // sb t1, 0(t0)    # Mark as ready
            sim_memory[BOOT_ADDR + code_offset + 156] = 8'h23;
            sim_memory[BOOT_ADDR + code_offset + 157] = 8'h00;
            sim_memory[BOOT_ADDR + code_offset + 158] = 8'h13;
            sim_memory[BOOT_ADDR + code_offset + 159] = 8'h00;
            
            // Infinite loop when done
            // done_loop:
            // j done_loop
            sim_memory[BOOT_ADDR + code_offset + 160] = 8'h6F;
            sim_memory[BOOT_ADDR + code_offset + 161] = 8'h00;
            sim_memory[BOOT_ADDR + code_offset + 162] = 8'h00;
            sim_memory[BOOT_ADDR + code_offset + 163] = 8'h00;
        end
    endtask
    
    // Calculate and display performance metrics
    task display_performance_metrics;
        $display("Performance Metrics:");
        $display("--------------------");
        $display("Total cycles: %0d", total_cycles);
        
        for (int i = 0; i < NUM_CORES; i++) begin
            ipc[i] = real'(instructions_executed[i]) / real'(total_cycles);
            $display("Core %0d:", i);
            $display("  Instructions executed: %0d", instructions_executed[i]);
            $display("  Memory accesses: %0d", memory_accesses[i]);
            $display("  IPC: %f", ipc[i]);
        end
        
        $display("Memory conflicts: %0d", memory_conflicts);
        
        // Check matrix multiplication result
        int errors = 0;
        for (int i = 0; i < 64; i++) begin
            for (int j = 0; j < 64; j++) begin
                int expected = 0;
                for (int k = 0; k < 64; k++) begin
                    expected += (i + k) * (k - j);
                end
                expected &= 255; // truncate to byte size
                
                byte actual = sim_memory[SHARED_DATA_START + 0x2000 + (i*64 + j)];
                if (actual != expected) begin
                    errors++;
                    if (errors <= 5) begin
                        // Limit output to first 5 errors
                        $display("Matrix error at [%0d][%0d]: Expected %0d, got %0d", i, j, expected, actual);
                    end
                end
            end
        end
        
        if (errors == 0) begin
            $display("Matrix multiplication result is correct!");
        } else {
            $display("Matrix multiplication has %0d errors.", errors);
        end
    endtask
    
    // Initialize simulation
    initial begin
        $display("Starting Multicore Performance Regression Test");
        
        // Initialize signals
        clk = 0;
        rst_n = 0;
        m_ext_interrupt = 0;
        s_ext_interrupt = 0;
        uart_rx = 1;
        enable_linux = 0;
        
        // Initialize performance metrics
        total_cycles = 0;
        memory_conflicts = 0;
        for (int i = 0; i < NUM_CORES; i++) begin
            instructions_executed[i] = 0;
            memory_accesses[i] = 0;
            ipc[i] = 0.0;
        end
        
        // Initialize memory
        for (int i = 0; i < 256*1024*1024; i++) begin
            sim_memory[i] = 8'h00;
        end
        
        // Load test program
        load_matrix_mult_program();
        
        // Apply reset
        #20;
        rst_n = 1;
        
        // Run until all cores are done
        while (1) begin
            byte barrier_flags = 0;
            for (int i = 0; i < NUM_CORES; i++) begin
                barrier_flags |= sim_memory[BARRIER_START + i];
            end
            
            if (barrier_flags == ((1 << NUM_CORES) - 1)) begin
                // All cores are done
                break;
            end
            
            if (total_cycles > 200000) begin
                $display("ERROR: Test timed out before all cores completed");
                break;
            end
            
            #10; // Continue simulation
        end
        
        // Display performance metrics
        display_performance_metrics();
        
        // Compare with previous results (using hardcoded reference values)
        // In a real system, we'd load these from a file
        real reference_ipc[NUM_CORES] = '{0.12, 0.11, 0.10, 0.09};
        
        // Calculate regression percentage
        for (int i = 0; i < NUM_CORES; i++) begin
            real perf_delta = ((ipc[i] / reference_ipc[i]) - 1.0) * 100.0;
            if (perf_delta < -5.0) begin
                $display("REGRESSION: Core %0d performance dropped by %f%%", i, -perf_delta);
            else if (perf_delta > 5.0) begin
                $display("IMPROVEMENT: Core %0d performance improved by %f%%", i, perf_delta);
            end else begin
                $display("STABLE: Core %0d performance change (%f%%) within acceptable range", i, perf_delta);
            end
        end
        
        $finish;
    end
    
    // Watchdog timer
    initial begin
        #500000; // 500us timeout
        $display("ERROR: Test watchdog timeout");
        $finish;
    end
    
    // Dump waveforms
    initial begin
        $dumpfile("multicore_performance_test.vcd");
        $dumpvars(0, multicore_performance_test);
    end
    
endmodule 