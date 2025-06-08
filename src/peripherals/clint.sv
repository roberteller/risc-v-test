module clint #(
    parameter NUM_CORES = 4,
    parameter ADDR_WIDTH = 64,
    parameter DATA_WIDTH = 64,
    parameter BASE_ADDR = 64'h02000000,
    parameter TIMER_FREQ = 10_000_000  // 10MHz timer frequency
)(
    input  logic                          clk,
    input  logic                          rst_n,
    
    // Memory interface (MMIO)
    input  logic [ADDR_WIDTH-1:0]         mmio_addr,
    input  logic [DATA_WIDTH-1:0]         mmio_write_data,
    output logic [DATA_WIDTH-1:0]         mmio_read_data,
    input  logic                          mmio_read,
    input  logic                          mmio_write,
    input  logic [7:0]                    mmio_byte_en,
    output logic                          mmio_ready,
    output logic                          mmio_error,
    
    // Interrupt outputs to cores
    output logic [NUM_CORES-1:0]          timer_interrupt,
    output logic [NUM_CORES-1:0]          software_interrupt
);

    // CLINT Register Map (relative to BASE_ADDR)
    // 0x0000-0x3FFF: Software interrupts (msip)
    // 0x4000-0xBFEF: Reserved  
    // 0xBFF8: mtime (64-bit)
    // 0xC000-0xFFFF: Timer compare registers (mtimecmp)
    
    localparam MSIP_BASE     = 16'h0000;  // Software interrupt registers
    localparam MTIME_ADDR    = 16'hBFF8;  // Timer register  
    localparam MTIMECMP_BASE = 16'hC000;  // Timer compare registers
    
    // Internal registers
    logic [63:0]                          mtime_reg;
    logic [NUM_CORES-1:0][63:0]           mtimecmp_reg;
    logic [NUM_CORES-1:0]                 msip_reg;
    
    // Timer prescaler for different timer frequency
    logic [31:0]                          timer_prescaler;
    logic                                 timer_tick;
    
    // Address decoding
    logic [15:0]                          local_addr;
    logic                                 addr_valid;
    logic                                 msip_access;
    logic                                 mtime_access;
    logic                                 mtimecmp_access;
    logic [2:0]                           core_index;
    
    assign local_addr = mmio_addr[15:0];
    assign addr_valid = (mmio_addr[ADDR_WIDTH-1:16] == BASE_ADDR[ADDR_WIDTH-1:16]);
    
    // Decode access type
    assign msip_access = addr_valid && (local_addr >= MSIP_BASE) && (local_addr < MTIME_ADDR);
    assign mtime_access = addr_valid && (local_addr == MTIME_ADDR);
    assign mtimecmp_access = addr_valid && (local_addr >= MTIMECMP_BASE);
    
    // Core index for msip and mtimecmp access
    assign core_index = msip_access ? local_addr[4:2] : 
                       mtimecmp_access ? ((local_addr - MTIMECMP_BASE) >> 3) : 3'b0;
    
    // Timer prescaler logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timer_prescaler <= 32'h0;
            timer_tick <= 1'b0;
        end else begin
            timer_tick <= 1'b0;
            if (timer_prescaler >= (100_000_000 / TIMER_FREQ - 1)) begin
                timer_prescaler <= 32'h0;
                timer_tick <= 1'b1;
            end else begin
                timer_prescaler <= timer_prescaler + 1'b1;
            end
        end
    end
    
    // Main register update logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mtime_reg <= 64'h0;
            mtimecmp_reg <= '{default: 64'hFFFFFFFFFFFFFFFF};
            msip_reg <= '0;
        end else begin
            // Update timer
            if (timer_tick) begin
                mtime_reg <= mtime_reg + 1'b1;
            end
            
            // Handle MMIO writes
            if (mmio_write && addr_valid) begin
                if (msip_access && core_index < NUM_CORES) begin
                    // Software interrupt register write
                    msip_reg[core_index] <= mmio_write_data[0];
                end else if (mtime_access) begin
                    // Timer register write (for OS)
                    mtime_reg <= mmio_write_data;
                end else if (mtimecmp_access && core_index < NUM_CORES) begin
                    // Timer compare register write
                    mtimecmp_reg[core_index] <= mmio_write_data;
                end
            end
        end
    end
    
    // MMIO read logic
    always_comb begin
        mmio_read_data = 64'h0;
        mmio_ready = 1'b1;
        mmio_error = 1'b0;
        
        if (mmio_read && addr_valid) begin
            if (msip_access && core_index < NUM_CORES) begin
                // Software interrupt register read
                mmio_read_data = {63'h0, msip_reg[core_index]};
            end else if (mtime_access) begin
                // Timer register read
                mmio_read_data = mtime_reg;
            end else if (mtimecmp_access && core_index < NUM_CORES) begin
                // Timer compare register read
                mmio_read_data = mtimecmp_reg[core_index];
            end else begin
                mmio_error = 1'b1;
            end
        end else if (mmio_read && !addr_valid) begin
            mmio_error = 1'b1;
        end
    end
    
    // Generate interrupts
    genvar i;
    generate
        for (i = 0; i < NUM_CORES; i++) begin : gen_interrupts
            // Timer interrupts: generated when mtime >= mtimecmp
            assign timer_interrupt[i] = (mtime_reg >= mtimecmp_reg[i]);
            
            // Software interrupts: controlled by msip registers
            assign software_interrupt[i] = msip_reg[i];
        end
    endgenerate
    
    // Debug outputs (for simulation/verification)
    `ifdef SIMULATION
    always @(posedge clk) begin
        if (mmio_write && addr_valid) begin
            $display("[CLINT] Write to 0x%08x = 0x%016x", mmio_addr, mmio_write_data);
        end
        if (mmio_read && addr_valid) begin
            $display("[CLINT] Read from 0x%08x = 0x%016x", mmio_addr, mmio_read_data);
        end
    end
    `endif
    
endmodule 
