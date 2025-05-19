module linux_multicore_tb;

    // Simulation parameters
    parameter DATA_WIDTH = 64;
    parameter ADDR_WIDTH = 64;
    parameter MEM_SIZE = 64 * 1024 * 1024;  // 64MB for simulation
    parameter NUM_CORES = 4;
    parameter ID_WIDTH = 4;
    parameter L1_CACHE_SIZE = 32 * 1024;    // 32KB L1
    parameter L2_CACHE_SIZE = 1024 * 1024;  // 1MB L2
    parameter CACHE_LINE_SIZE = 64;         // 64 bytes per line
    parameter CLK_PERIOD = 10;              // 10ns (100MHz)
    parameter SIM_TIME = 100000;            // Simulation length in ns
    parameter BOOT_ADDR = 64'h80000000;     // Linux entry point
    
    // Clock and reset
    logic clk;
    logic rst_n;
    
    // Core status
    logic [NUM_CORES-1:0] core_active;
    
    // Memory interface
    logic [ADDR_WIDTH-1:0] mem_addr;
    logic [DATA_WIDTH-1:0] mem_write_data;
    logic                  mem_read;
    logic                  mem_write;
    logic [7:0]            mem_byte_en;
    logic                  mem_request;
    logic [DATA_WIDTH-1:0] mem_read_data;
    logic                  mem_ready;
    logic                  mem_error;
    
    // Debug outputs
    logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] pc_out;
    logic [NUM_CORES-1:0][DATA_WIDTH-1:0] alu_result_out;
    
    // External interrupts
    logic m_ext_interrupt;
    logic s_ext_interrupt;
    
    // UART interface
    logic uart_rx;
    logic uart_tx;
    
    // Boot selection
    logic enable_linux;
    logic [ADDR_WIDTH-1:0] boot_addr;
    
    // Simulated memory
    logic [7:0] main_memory [0:MEM_SIZE-1];
    
    // Instantiate the multicore processor
    linux_multicore #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .MEM_SIZE(MEM_SIZE),
        .NUM_CORES(NUM_CORES),
        .ID_WIDTH(ID_WIDTH),
        .L1_CACHE_SIZE(L1_CACHE_SIZE),
        .L2_CACHE_SIZE(L2_CACHE_SIZE),
        .CACHE_LINE_SIZE(CACHE_LINE_SIZE)
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
        
        // External interrupts
        .m_ext_interrupt(m_ext_interrupt),
        .s_ext_interrupt(s_ext_interrupt),
        
        // UART interface
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        
        // Boot selection
        .enable_linux(enable_linux),
        .boot_addr(boot_addr)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Memory simulation
    always_ff @(posedge clk) begin
        mem_ready <= 1'b0;
        mem_error <= 1'b0;
        
        if (mem_request) begin
            if (mem_addr < MEM_SIZE) begin
                if (mem_read) begin
                    // Read data from memory
                    mem_read_data <= {
                        main_memory[mem_addr+7],
                        main_memory[mem_addr+6],
                        main_memory[mem_addr+5],
                        main_memory[mem_addr+4],
                        main_memory[mem_addr+3],
                        main_memory[mem_addr+2],
                        main_memory[mem_addr+1],
                        main_memory[mem_addr]
                    };
                    mem_ready <= 1'b1;
                end
                else if (mem_write) begin
                    // Write data to memory
                    if (mem_byte_en[0]) main_memory[mem_addr] <= mem_write_data[7:0];
                    if (mem_byte_en[1]) main_memory[mem_addr+1] <= mem_write_data[15:8];
                    if (mem_byte_en[2]) main_memory[mem_addr+2] <= mem_write_data[23:16];
                    if (mem_byte_en[3]) main_memory[mem_addr+3] <= mem_write_data[31:24];
                    if (mem_byte_en[4]) main_memory[mem_addr+4] <= mem_write_data[39:32];
                    if (mem_byte_en[5]) main_memory[mem_addr+5] <= mem_write_data[47:40];
                    if (mem_byte_en[6]) main_memory[mem_addr+6] <= mem_write_data[55:48];
                    if (mem_byte_en[7]) main_memory[mem_addr+7] <= mem_write_data[63:56];
                    mem_ready <= 1'b1;
                end
            end else begin
                // Invalid memory access
                mem_error <= 1'b1;
                mem_ready <= 1'b1;
            end
        end
    end
    
    // Initialize test vectors and memory
    initial begin
        // Load test program
        automatic int i;
        for (i = 0; i < MEM_SIZE; i++) begin
            main_memory[i] = 0;
        end
        
        // Sample test program - you would typically load a full program from file
        // Simple test code - 8 instructions to verify system works
        // This is a simple program that increments a register and stores to memory
        main_memory[BOOT_ADDR+0] = 8'h13; // addi x1, x0, 1     # r1 = 1
        main_memory[BOOT_ADDR+1] = 8'h05;
        main_memory[BOOT_ADDR+2] = 8'h10;
        main_memory[BOOT_ADDR+3] = 8'h00;
        
        main_memory[BOOT_ADDR+4] = 8'h93; // addi x3, x0, 16    # r3 = 16 (memory address)
        main_memory[BOOT_ADDR+5] = 8'h01;
        main_memory[BOOT_ADDR+6] = 8'h00;
        main_memory[BOOT_ADDR+7] = 8'h01;
        
        main_memory[BOOT_ADDR+8] = 8'h23; // sw x1, 0(x3)       # mem[16] = r1
        main_memory[BOOT_ADDR+9] = 8'h20;
        main_memory[BOOT_ADDR+10] = 8'h11;
        main_memory[BOOT_ADDR+11] = 8'h00;
        
        main_memory[BOOT_ADDR+12] = 8'h93; // addi x3, x3, 4    # r3 = r3 + 4
        main_memory[BOOT_ADDR+13] = 8'h81;
        main_memory[BOOT_ADDR+14] = 8'h41;
        main_memory[BOOT_ADDR+15] = 8'h00;
        
        main_memory[BOOT_ADDR+16] = 8'h13; // addi x2, x0, 2    # r2 = 2
        main_memory[BOOT_ADDR+17] = 8'h01;
        main_memory[BOOT_ADDR+18] = 8'h20;
        main_memory[BOOT_ADDR+19] = 8'h00;
        
        main_memory[BOOT_ADDR+20] = 8'h33; // add x1, x1, x2    # r1 = r1 + r2
        main_memory[BOOT_ADDR+21] = 8'h85;
        main_memory[BOOT_ADDR+22] = 8'h21;
        main_memory[BOOT_ADDR+23] = 8'h00;
        
        main_memory[BOOT_ADDR+24] = 8'h23; // sw x1, 0(x3)      # mem[20] = r1
        main_memory[BOOT_ADDR+25] = 8'h20;
        main_memory[BOOT_ADDR+26] = 8'h11;
        main_memory[BOOT_ADDR+27] = 8'h00;
        
        main_memory[BOOT_ADDR+28] = 8'h6f; // j -28             # jump to beginning
        main_memory[BOOT_ADDR+29] = 8'hf0;
        main_memory[BOOT_ADDR+30] = 8'h5f;
        main_memory[BOOT_ADDR+31] = 8'hfe;
        
        // Setup simulation parameters
        rst_n = 0;
        enable_linux = 0;  // For test, just simple program
        boot_addr = BOOT_ADDR;
        m_ext_interrupt = 0;
        s_ext_interrupt = 0;
        uart_rx = 1;  // Idle high
        
        // Release reset after 100ns
        #100 rst_n = 1;
    end
    
    // Simulation timeout
    initial begin
        #SIM_TIME;
        $display("Simulation timeout after %0d ns", SIM_TIME);
        // Report the final PC values of each core
        for (int i = 0; i < NUM_CORES; i++) begin
            $display("Core %0d PC: %h", i, pc_out[i]);
        end
        $finish;
    end
    
    // Monitor system activity
    always @(posedge clk) begin
        if (mem_write && mem_ready) begin
            $display("Time: %0t, Memory write: addr=0x%h, data=0x%h", $time, mem_addr, mem_write_data);
        end
        
        if (mem_read && mem_ready) begin
            $display("Time: %0t, Memory read: addr=0x%h, data=0x%h", $time, mem_addr, mem_read_data);
        end
        
        // Monitor PC of each core
        for (int i = 0; i < NUM_CORES; i++) begin
            static logic [ADDR_WIDTH-1:0] last_pc[NUM_CORES];
            if (pc_out[i] != last_pc[i]) begin
                $display("Time: %0t, Core %0d PC: %h", $time, i, pc_out[i]);
                last_pc[i] = pc_out[i];
            end
        end
    end
    
endmodule 