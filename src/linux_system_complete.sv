module linux_system_complete #(
    parameter NUM_CORES = 4,
    parameter ADDR_WIDTH = 64,
    parameter DATA_WIDTH = 64,
    parameter CACHE_LINE_SIZE = 64,
    parameter L1_CACHE_SIZE = 32768,  // 32KB
    parameter L2_CACHE_SIZE = 1048576, // 1MB
    parameter MEMORY_SIZE = 536870912  // 512MB
)(
    input  logic                          clk,
    input  logic                          rst_n,
    
    // External memory interface
    output logic [ADDR_WIDTH-1:0]         mem_addr,
    output logic [DATA_WIDTH-1:0]         mem_write_data,
    input  logic [DATA_WIDTH-1:0]         mem_read_data,
    output logic                          mem_read,
    output logic                          mem_write,
    output logic [7:0]                    mem_byte_en,
    input  logic                          mem_ready,
    
    // UART interface
    output logic                          uart_tx,
    input  logic                          uart_rx,
    
    // Network PHY interface
    output logic [7:0]                    eth_tx_data,
    output logic                          eth_tx_valid,
    output logic                          eth_tx_sof,
    output logic                          eth_tx_eof,
    input  logic                          eth_tx_ready,
    input  logic [7:0]                    eth_rx_data,
    input  logic                          eth_rx_valid,
    input  logic                          eth_rx_sof,
    input  logic                          eth_rx_eof,
    input  logic                          eth_rx_error,
    input  logic                          eth_link_up,
    input  logic                          eth_link_speed,
    input  logic                          eth_link_duplex,
    
    // Storage interface (simplified - could be SD/SATA)
    output logic [31:0]                   storage_block_addr,
    output logic [4095:0]                 storage_write_data,  // 512 bytes
    input  logic [4095:0]                 storage_read_data,
    output logic                          storage_read,
    output logic                          storage_write,
    input  logic                          storage_ready,
    
    // System control
    output logic                          system_reset,
    output logic                          system_shutdown,
    
    // Debug interface
    output logic [NUM_CORES-1:0]          core_debug_halt,
    output logic [NUM_CORES-1:0][63:0]    core_debug_pc,
    output logic [31:0]                   debug_status
);

    // ================================================================
    // Internal Signals
    // ================================================================
    
    // Memory bus signals
    logic [ADDR_WIDTH-1:0]                bus_addr;
    logic [DATA_WIDTH-1:0]                bus_write_data;
    logic [DATA_WIDTH-1:0]                bus_read_data;
    logic                                 bus_read;
    logic                                 bus_write;
    logic [7:0]                           bus_byte_en;
    logic                                 bus_ready;
    logic                                 bus_error;
    
    // Core signals
    logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] core_inst_addr;
    logic [NUM_CORES-1:0][31:0]           core_inst_data;
    logic [NUM_CORES-1:0]                 core_inst_valid;
    logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] core_data_addr;
    logic [NUM_CORES-1:0][DATA_WIDTH-1:0] core_data_write;
    logic [NUM_CORES-1:0][DATA_WIDTH-1:0] core_data_read;
    logic [NUM_CORES-1:0]                 core_data_read_req;
    logic [NUM_CORES-1:0]                 core_data_write_req;
    logic [NUM_CORES-1:0][7:0]            core_data_byte_en;
    logic [NUM_CORES-1:0]                 core_data_ready;
    
    // Interrupt signals
    logic [NUM_CORES-1:0]                 timer_interrupt;
    logic [NUM_CORES-1:0]                 software_interrupt;
    logic [NUM_CORES-1:0]                 m_external_interrupt;
    logic [NUM_CORES-1:0]                 s_external_interrupt;
    
    // MMIO device signals
    logic [ADDR_WIDTH-1:0]                mmio_addr;
    logic [DATA_WIDTH-1:0]                mmio_write_data;
    logic [DATA_WIDTH-1:0]                mmio_read_data;
    logic                                 mmio_read;
    logic                                 mmio_write;
    logic [7:0]                           mmio_byte_en;
    logic                                 mmio_ready;
    logic                                 mmio_error;
    
    // CLINT signals
    logic [DATA_WIDTH-1:0]                clint_read_data;
    logic                                 clint_ready;
    logic                                 clint_error;
    logic                                 clint_select;
    
    // PLIC signals
    logic [DATA_WIDTH-1:0]                plic_read_data;
    logic                                 plic_ready;
    logic                                 plic_error;
    logic                                 plic_select;
    logic [31:0]                          interrupt_sources;
    
    // VirtIO block device signals
    logic [DATA_WIDTH-1:0]                virtio_blk_read_data;
    logic                                 virtio_blk_ready;
    logic                                 virtio_blk_error;
    logic                                 virtio_blk_select;
    logic                                 virtio_blk_interrupt;
    
    // VirtIO network device signals
    logic [DATA_WIDTH-1:0]                virtio_net_read_data;
    logic                                 virtio_net_ready;
    logic                                 virtio_net_error;
    logic                                 virtio_net_select;
    logic                                 virtio_net_interrupt;
    
    // UART signals
    logic [DATA_WIDTH-1:0]                uart_read_data;
    logic                                 uart_ready;
    logic                                 uart_error;
    logic                                 uart_select;
    logic                                 uart_interrupt;
    logic [7:0]                           uart_tx_data;
    logic                                 uart_tx_valid;
    logic [7:0]                           uart_rx_data;
    logic                                 uart_rx_valid;
    
    // SBI signals
    logic [NUM_CORES-1:0]                 sbi_call_valid;
    logic [NUM_CORES-1:0][2:0]            sbi_fid;
    logic [NUM_CORES-1:0][2:0]            sbi_eid;
    logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] sbi_arg0;
    logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] sbi_arg1;
    logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] sbi_arg2;
    logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] sbi_arg3;
    logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] sbi_arg4;
    logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] sbi_arg5;
    logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] sbi_ret0;
    logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] sbi_ret1;
    logic [NUM_CORES-1:0]                 sbi_call_complete;
    
    // DMA signals
    logic [ADDR_WIDTH-1:0]                dma_addr;
    logic [DATA_WIDTH-1:0]                dma_write_data;
    logic [DATA_WIDTH-1:0]                dma_read_data;
    logic                                 dma_read;
    logic                                 dma_write;
    logic                                 dma_request;
    logic                                 dma_ready;
    
    // ================================================================
    // Address Map
    // ================================================================
    localparam ADDR_CLINT_BASE    = 64'h02000000;  // CLINT
    localparam ADDR_PLIC_BASE     = 64'h0C000000;  // PLIC
    localparam ADDR_UART_BASE     = 64'h10000000;  // UART 16550
    localparam ADDR_VIRTIO_BLK    = 64'h10001000;  // VirtIO Block
    localparam ADDR_VIRTIO_NET    = 64'h10002000;  // VirtIO Network
    localparam ADDR_MEMORY_BASE   = 64'h80000000;  // Main memory
    
    // Address decode
    assign clint_select = (mmio_addr >= ADDR_CLINT_BASE) && 
                         (mmio_addr < ADDR_CLINT_BASE + 64'h10000);
    assign plic_select = (mmio_addr >= ADDR_PLIC_BASE) && 
                        (mmio_addr < ADDR_PLIC_BASE + 64'h400000);
    assign uart_select = (mmio_addr >= ADDR_UART_BASE) && 
                        (mmio_addr < ADDR_UART_BASE + 64'h1000);
    assign virtio_blk_select = (mmio_addr >= ADDR_VIRTIO_BLK) && 
                              (mmio_addr < ADDR_VIRTIO_BLK + 64'h1000);
    assign virtio_net_select = (mmio_addr >= ADDR_VIRTIO_NET) && 
                              (mmio_addr < ADDR_VIRTIO_NET + 64'h1000);
    
    // MMIO response mux
    always_comb begin
        mmio_read_data = 64'h0;
        mmio_ready = 1'b0;
        mmio_error = 1'b0;
        
        if (clint_select) begin
            mmio_read_data = clint_read_data;
            mmio_ready = clint_ready;
            mmio_error = clint_error;
        end else if (plic_select) begin
            mmio_read_data = plic_read_data;
            mmio_ready = plic_ready;
            mmio_error = plic_error;
        end else if (uart_select) begin
            mmio_read_data = uart_read_data;
            mmio_ready = uart_ready;
            mmio_error = uart_error;
        end else if (virtio_blk_select) begin
            mmio_read_data = virtio_blk_read_data;
            mmio_ready = virtio_blk_ready;
            mmio_error = virtio_blk_error;
        end else if (virtio_net_select) begin
            mmio_read_data = virtio_net_read_data;
            mmio_ready = virtio_net_ready;
            mmio_error = virtio_net_error;
        end else begin
            mmio_error = 1'b1;
            mmio_ready = 1'b1;
        end
    end
    
    // ================================================================
    // Multi-Core RISC-V System
    // ================================================================
    
    linux_multicore #(
        .NUM_CORES(NUM_CORES),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .CACHE_LINE_SIZE(CACHE_LINE_SIZE),
        .L1_CACHE_SIZE(L1_CACHE_SIZE),
        .L2_CACHE_SIZE(L2_CACHE_SIZE)
    ) multicore_system (
        .clk(clk),
        .rst_n(rst_n),
        
        // Memory interface
        .mem_addr(bus_addr),
        .mem_write_data(bus_write_data),
        .mem_read_data(bus_read_data),
        .mem_read(bus_read),
        .mem_write(bus_write),
        .mem_byte_en(bus_byte_en),
        .mem_ready(bus_ready),
        
        // MMIO interface
        .mmio_addr(mmio_addr),
        .mmio_write_data(mmio_write_data),
        .mmio_read_data(mmio_read_data),
        .mmio_read(mmio_read),
        .mmio_write(mmio_write),
        .mmio_byte_en(mmio_byte_en),
        .mmio_ready(mmio_ready),
        .mmio_error(mmio_error),
        
        // Interrupts
        .timer_interrupt(timer_interrupt),
        .software_interrupt(software_interrupt),
        .m_external_interrupt(m_external_interrupt),
        .s_external_interrupt(s_external_interrupt),
        
        // SBI interface
        .sbi_call_valid(sbi_call_valid),
        .sbi_fid(sbi_fid),
        .sbi_eid(sbi_eid),
        .sbi_arg0(sbi_arg0),
        .sbi_arg1(sbi_arg1),
        .sbi_arg2(sbi_arg2),
        .sbi_arg3(sbi_arg3),
        .sbi_arg4(sbi_arg4),
        .sbi_arg5(sbi_arg5),
        .sbi_ret0(sbi_ret0),
        .sbi_ret1(sbi_ret1),
        .sbi_call_complete(sbi_call_complete),
        
        // Debug interface
        .debug_halt(core_debug_halt),
        .debug_pc(core_debug_pc)
    );
    
    // ================================================================
    // CLINT (Core Local Interruptor)
    // ================================================================
    
    clint #(
        .NUM_CORES(NUM_CORES),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .BASE_ADDR(ADDR_CLINT_BASE),
        .TIMER_FREQ(10_000_000)
    ) clint_inst (
        .clk(clk),
        .rst_n(rst_n),
        
        .mmio_addr(mmio_addr),
        .mmio_write_data(mmio_write_data),
        .mmio_read_data(clint_read_data),
        .mmio_read(mmio_read && clint_select),
        .mmio_write(mmio_write && clint_select),
        .mmio_byte_en(mmio_byte_en),
        .mmio_ready(clint_ready),
        .mmio_error(clint_error),
        
        .timer_interrupt(timer_interrupt),
        .software_interrupt(software_interrupt)
    );
    
    // ================================================================
    // PLIC (Platform Level Interrupt Controller)
    // ================================================================
    
    // Collect interrupt sources
    assign interrupt_sources = {
        27'h0,                    // Reserved
        virtio_net_interrupt,     // VirtIO network
        virtio_blk_interrupt,     // VirtIO block
        uart_interrupt,           // UART
        2'b00                     // Reserved
    };
    
    plic #(
        .NUM_CORES(NUM_CORES),
        .NUM_SOURCES(32),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .BASE_ADDR(ADDR_PLIC_BASE),
        .MAX_PRIORITY(7)
    ) plic_inst (
        .clk(clk),
        .rst_n(rst_n),
        
        .interrupt_sources(interrupt_sources),
        .m_external_interrupt(m_external_interrupt),
        .s_external_interrupt(s_external_interrupt),
        
        .mmio_addr(mmio_addr),
        .mmio_write_data(mmio_write_data),
        .mmio_read_data(plic_read_data),
        .mmio_read(mmio_read && plic_select),
        .mmio_write(mmio_write && plic_select),
        .mmio_byte_en(mmio_byte_en),
        .mmio_ready(plic_ready),
        .mmio_error(plic_error)
    );
    
    // ================================================================
    // VirtIO Block Device
    // ================================================================
    
    virtio_blk #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .BASE_ADDR(ADDR_VIRTIO_BLK),
        .QUEUE_SIZE(256),
        .BLOCK_SIZE(512),
        .NUM_BLOCKS(1024*1024)
    ) virtio_blk_inst (
        .clk(clk),
        .rst_n(rst_n),
        
        .mmio_addr(mmio_addr),
        .mmio_write_data(mmio_write_data),
        .mmio_read_data(virtio_blk_read_data),
        .mmio_read(mmio_read && virtio_blk_select),
        .mmio_write(mmio_write && virtio_blk_select),
        .mmio_byte_en(mmio_byte_en),
        .mmio_ready(virtio_blk_ready),
        .mmio_error(virtio_blk_error),
        
        .dma_addr(dma_addr),
        .dma_write_data(dma_write_data),
        .dma_read_data(dma_read_data),
        .dma_read(dma_read),
        .dma_write(dma_write),
        .dma_request(dma_request),
        .dma_ready(dma_ready),
        
        .blk_interrupt(virtio_blk_interrupt),
        
        .storage_block_addr(storage_block_addr),
        .storage_write_data(storage_write_data),
        .storage_read_data(storage_read_data),
        .storage_read(storage_read),
        .storage_write(storage_write),
        .storage_ready(storage_ready)
    );
    
    // ================================================================
    // VirtIO Network Device
    // ================================================================
    
    virtio_net #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .BASE_ADDR(ADDR_VIRTIO_NET),
        .QUEUE_SIZE(256),
        .MTU_SIZE(1500),
        .MAC_ADDR(48'h525400123456)
    ) virtio_net_inst (
        .clk(clk),
        .rst_n(rst_n),
        
        .mmio_addr(mmio_addr),
        .mmio_write_data(mmio_write_data),
        .mmio_read_data(virtio_net_read_data),
        .mmio_read(mmio_read && virtio_net_select),
        .mmio_write(mmio_write && virtio_net_select),
        .mmio_byte_en(mmio_byte_en),
        .mmio_ready(virtio_net_ready),
        .mmio_error(virtio_net_error),
        
        .dma_addr(dma_addr),
        .dma_write_data(dma_write_data),
        .dma_read_data(dma_read_data),
        .dma_read(dma_read),
        .dma_write(dma_write),
        .dma_request(dma_request),
        .dma_ready(dma_ready),
        
        .net_interrupt(virtio_net_interrupt),
        
        .tx_data(eth_tx_data),
        .tx_valid(eth_tx_valid),
        .tx_sof(eth_tx_sof),
        .tx_eof(eth_tx_eof),
        .tx_ready(eth_tx_ready),
        
        .rx_data(eth_rx_data),
        .rx_valid(eth_rx_valid),
        .rx_sof(eth_rx_sof),
        .rx_eof(eth_rx_eof),
        .rx_error(eth_rx_error),
        
        .link_up(eth_link_up),
        .link_speed(eth_link_speed),
        .link_duplex(eth_link_duplex)
    );
    
    // ================================================================
    // OpenSBI Handler
    // ================================================================
    
    opensbi_handler #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .NUM_CORES(NUM_CORES)
    ) opensbi_inst (
        .clk(clk),
        .rst_n(rst_n),
        
        .sbi_call_valid(sbi_call_valid),
        .sbi_fid(sbi_fid),
        .sbi_eid(sbi_eid),
        .sbi_arg0(sbi_arg0),
        .sbi_arg1(sbi_arg1),
        .sbi_arg2(sbi_arg2),
        .sbi_arg3(sbi_arg3),
        .sbi_arg4(sbi_arg4),
        .sbi_arg5(sbi_arg5),
        .sbi_ret0(sbi_ret0),
        .sbi_ret1(sbi_ret1),
        .sbi_call_complete(sbi_call_complete),
        
        .timer_value(),
        .mtime(64'h0),  // Connect to CLINT's mtime
        .mtimecmp(),
        .timer_interrupt_clear(),
        
        .ipi_send(),
        .ipi_clear(),
        .hart_mask(4'b1111),
        
        .console_putchar(uart_tx_data),
        .console_putchar_valid(uart_tx_valid),
        .console_getchar(uart_rx_data),
        .console_getchar_valid(uart_rx_valid),
        
        .system_reset(system_reset),
        .system_shutdown(system_shutdown),
        
        .hart_state('{default: 2'b01}),
        .hart_start(),
        .hart_stop(),
        .hart_start_addr()
    );
    
    // ================================================================
    // Memory Controller
    // ================================================================
    
    // Simple memory arbiter between CPU and DMA
    assign mem_addr = dma_request ? dma_addr : bus_addr;
    assign mem_write_data = dma_request ? dma_write_data : bus_write_data;
    assign mem_read = dma_request ? dma_read : bus_read;
    assign mem_write = dma_request ? dma_write : bus_write;
    assign mem_byte_en = dma_request ? 8'hFF : bus_byte_en;
    
    assign bus_read_data = mem_read_data;
    assign bus_ready = mem_ready && !dma_request;
    assign dma_read_data = mem_read_data;
    assign dma_ready = mem_ready && dma_request;
    
    // ================================================================
    // UART Controller (simplified)
    // ================================================================
    
    // Simplified UART for console I/O
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uart_tx <= 1'b1;
            uart_rx_data <= 8'h0;
            uart_rx_valid <= 1'b0;
        end else begin
            uart_rx_valid <= 1'b0;
            
            // Simple UART transmit
            if (uart_tx_valid) begin
                uart_tx <= 1'b0;  // Simplified - should serialize properly
            end else begin
                uart_tx <= 1'b1;
            end
            
            // Simple UART receive (placeholder)
            if (!uart_rx) begin
                uart_rx_data <= 8'h0;  // Should deserialize properly
                uart_rx_valid <= 1'b1;
            end
        end
    end
    
    assign uart_read_data = 64'h0;
    assign uart_ready = 1'b1;
    assign uart_error = 1'b0;
    assign uart_interrupt = 1'b0;
    
    // ================================================================
    // Debug Status
    // ================================================================
    
    assign debug_status = {
        28'h0,
        system_shutdown,
        system_reset,
        |m_external_interrupt,
        |timer_interrupt
    };
    
endmodule 
