module boot_rom #(
    parameter DATA_WIDTH = 64,
    parameter ADDR_WIDTH = 64,
    parameter ROM_SIZE = 4096,      // 4KB boot ROM
    parameter ROM_FILE = "boot.hex"  // Hex file to load boot code from
)(
    input  logic                    clk,
    input  logic                    rst_n,
    
    // CPU interface
    input  logic [ADDR_WIDTH-1:0]   addr,
    input  logic                    request,
    output logic [DATA_WIDTH-1:0]   read_data,
    output logic                    ready,
    output logic                    error
);

    // ROM storage
    logic [31:0] rom_mem [0:ROM_SIZE/4-1];  // Store 32-bit instructions
    
    // Initialize ROM from hex file
    initial begin
        $readmemh(ROM_FILE, rom_mem);
    end
    
    // State machine for ROM access
    typedef enum logic [1:0] {
        IDLE,
        READ,
        COMPLETE
    } rom_state_t;
    
    rom_state_t state, next_state;
    logic [ADDR_WIDTH-1:0] addr_reg;
    
    // State machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            addr_reg <= '0;
        end else begin
            state <= next_state;
            
            if (state == IDLE && request) begin
                addr_reg <= addr;
            end
        end
    end
    
    // Next state logic
    always_comb begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (request) begin
                    next_state = READ;
                end
            end
            
            READ: begin
                next_state = COMPLETE;
            end
            
            COMPLETE: begin
                next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // ROM access logic
    always_comb begin
        // Default values
        read_data = 64'h0;
        ready = (state == COMPLETE);
        error = 1'b0;
        
        // Check address bounds
        if (addr_reg < ROM_SIZE) begin
            // ROM address calculation
            logic [$clog2(ROM_SIZE/4)-1:0] rom_addr;
            rom_addr = addr_reg[$clog2(ROM_SIZE)-1:2];  // Word aligned
            
            // Return data depending on address alignment
            if (addr_reg[2]) begin
                // Upper 32 bits (Most RV64 instructions are still 32-bit)
                read_data = {32'h0, rom_mem[rom_addr]};
            end else begin
                // Lower 32 bits (Most instructions will be fetched from here)
                read_data = {32'h0, rom_mem[rom_addr]};
            end
        end else begin
            // Out of bounds
            error = (state == COMPLETE);
        end
    end

    // ROM contents for Linux booting
    // This would typically contain code that:
    // 1. Sets up initial stack pointer
    // 2. Initializes MMU and page tables
    // 3. Enables caches
    // 4. Jumps to Linux kernel entry point
    
    // Sample boot ROM code (this would come from the hex file in actual implementation)
    // initial begin
    //     // At reset vector, just after power-on
    //     rom_mem[0] = 32'h00000297;  // auipc t0, 0        # Get PC
    //     rom_mem[1] = 32'h02028593;  // addi a1, t0, 32    # DTB address
    //     rom_mem[2] = 32'h00100293;  // addi t0, zero, 1   # hart ID 0
    //     rom_mem[3] = 32'h00000537;  // lui a0, 0x0        # Linux entry 0x80000000
    //     rom_mem[4] = 32'h80050513;  // addi a0, a0, 0x800 # high 32 bits
    //     rom_mem[5] = 32'h00050067;  // jalr zero, a0, 0   # Jump to Linux entry point
    //     // Fill in the rest with NOPs
    //     for (int i = 6; i < ROM_SIZE/4; i++) begin
    //         rom_mem[i] = 32'h00000013;  // addi x0, x0, 0 (NOP)
    //     end
    // end

endmodule 