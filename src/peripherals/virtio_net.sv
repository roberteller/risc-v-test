module virtio_net #(
    parameter ADDR_WIDTH = 64,
    parameter DATA_WIDTH = 64,
    parameter BASE_ADDR = 64'h10002000,
    parameter QUEUE_SIZE = 256,
    parameter MTU_SIZE = 1500,
    parameter MAC_ADDR = 48'h525400123456  // Default MAC address
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
    
    // DMA interface for guest memory access
    output logic [ADDR_WIDTH-1:0]         dma_addr,
    output logic [DATA_WIDTH-1:0]         dma_write_data,
    input  logic [DATA_WIDTH-1:0]         dma_read_data,
    output logic                          dma_read,
    output logic                          dma_write,
    output logic                          dma_request,
    input  logic                          dma_ready,
    
    // Interrupt output
    output logic                          net_interrupt,
    
    // External network interface (simplified PHY)
    output logic [7:0]                    tx_data,
    output logic                          tx_valid,
    output logic                          tx_sof,    // Start of frame
    output logic                          tx_eof,    // End of frame
    input  logic                          tx_ready,
    
    input  logic [7:0]                    rx_data,
    input  logic                          rx_valid,
    input  logic                          rx_sof,
    input  logic                          rx_eof,
    input  logic                          rx_error,
    
    // Link status
    input  logic                          link_up,
    input  logic                          link_speed,  // 0: 100Mbps, 1: 1Gbps
    input  logic                          link_duplex  // 0: half, 1: full
);

    // VirtIO Network Device Configuration
    typedef struct packed {
        logic [47:0] mac;
        logic [15:0] status;
        logic [15:0] max_virtqueue_pairs;
        logic [15:0] mtu;
        logic [31:0] speed;
        logic [7:0]  duplex;
        logic [7:0]  rss_max_key_size;
        logic [15:0] rss_max_indirection_table_length;
        logic [31:0] supported_hash_types;
    } virtio_net_config_t;
    
    // VirtIO registers (inheriting from base VirtIO)
    logic [31:0] device_features_sel;
    logic [31:0] driver_features_sel;
    logic [63:0] device_features;
    logic [63:0] driver_features;
    logic [31:0] queue_sel;
    logic [31:0] queue_num;
    logic        queue_ready;
    logic [7:0]  device_status;
    logic [31:0] interrupt_status;
    logic [63:0] queue_desc_addr;
    logic [63:0] queue_avail_addr;
    logic [63:0] queue_used_addr;
    
    // Network-specific configuration
    virtio_net_config_t net_config;
    
    // Queue indices (VirtIO net typically has RX and TX queues)
    localparam QUEUE_RX = 0;
    localparam QUEUE_TX = 1;
    localparam QUEUE_CTRL = 2;  // Control queue (optional)
    
    // VirtIO net feature bits
    localparam VIRTIO_NET_F_CSUM = 0;
    localparam VIRTIO_NET_F_GUEST_CSUM = 1;
    localparam VIRTIO_NET_F_CTRL_GUEST_OFFLOADS = 2;
    localparam VIRTIO_NET_F_MTU = 3;
    localparam VIRTIO_NET_F_MAC = 5;
    localparam VIRTIO_NET_F_STATUS = 16;
    localparam VIRTIO_NET_F_CTRL_VQ = 17;
    localparam VIRTIO_NET_F_CTRL_RX = 18;
    localparam VIRTIO_NET_F_CTRL_VLAN = 19;
    localparam VIRTIO_NET_F_GUEST_ANNOUNCE = 21;
    localparam VIRTIO_NET_F_MQ = 22;
    
    // Network packet buffer
    typedef struct packed {
        logic [47:0] dst_mac;
        logic [47:0] src_mac;
        logic [15:0] ethertype;
        logic [MTU_SIZE*8-1:0] payload;
        logic [31:0] crc;
    } ethernet_frame_t;
    
    // TX/RX state machines
    typedef enum logic [2:0] {
        NET_IDLE,
        NET_READ_DESC,
        NET_DMA_TRANSFER,
        NET_TRANSMIT,
        NET_UPDATE_USED,
        NET_COMPLETE
    } net_state_t;
    
    net_state_t tx_state, rx_state;
    
    // Packet buffers
    logic [MTU_SIZE*8-1:0] tx_buffer;
    logic [MTU_SIZE*8-1:0] rx_buffer;
    logic [15:0] tx_length;
    logic [15:0] rx_length;
    logic [15:0] tx_byte_count;
    logic [15:0] rx_byte_count;
    
    // Address decoding
    logic [11:0] local_addr;
    logic        addr_valid;
    logic        config_access;
    
    assign local_addr = mmio_addr[11:0];
    assign addr_valid = (mmio_addr[ADDR_WIDTH-1:12] == BASE_ADDR[ADDR_WIDTH-1:12]);
    assign config_access = addr_valid && (local_addr >= 12'h100);  // Config space starts at 0x100
    
    // Initialize network configuration
    initial begin
        net_config.mac = MAC_ADDR;
        net_config.status = 16'h0001;  // Link up
        net_config.max_virtqueue_pairs = 16'h0001;
        net_config.mtu = MTU_SIZE[15:0];
        net_config.speed = 32'd1000;  // 1000 Mbps
        net_config.duplex = 8'h01;    // Full duplex
        net_config.rss_max_key_size = 8'h00;
        net_config.rss_max_indirection_table_length = 16'h0000;
        net_config.supported_hash_types = 32'h00000000;
    end
    
    // Device features (what the device supports)
    assign device_features = (64'h1 << VIRTIO_NET_F_MAC) |
                           (64'h1 << VIRTIO_NET_F_STATUS) |
                           (64'h1 << VIRTIO_NET_F_MTU) |
                           (64'h1 << VIRTIO_NET_F_CTRL_VQ);
    
    // Register read/write logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            device_features_sel <= 32'h0;
            driver_features_sel <= 32'h0;
            driver_features <= 64'h0;
            queue_sel <= 32'h0;
            queue_num <= 32'h0;
            queue_ready <= 1'b0;
            device_status <= 8'h0;
            interrupt_status <= 32'h0;
            queue_desc_addr <= 64'h0;
            queue_avail_addr <= 64'h0;
            queue_used_addr <= 64'h0;
        end else begin
            // Handle MMIO writes
            if (mmio_write && addr_valid && !config_access) begin
                // Standard VirtIO register writes
                case (local_addr)
                    12'h014: device_features_sel <= mmio_write_data[31:0];
                    12'h024: driver_features_sel <= mmio_write_data[31:0];
                    12'h020: begin
                        if (driver_features_sel == 0) begin
                            driver_features[31:0] <= mmio_write_data[31:0];
                        end else begin
                            driver_features[63:32] <= mmio_write_data[31:0];
                        end
                    end
                    12'h030: queue_sel <= mmio_write_data[31:0];
                    12'h038: queue_num <= mmio_write_data[31:0];
                    12'h044: queue_ready <= mmio_write_data[0];
                    12'h050: begin
                        // Queue notification - start packet processing
                        if (mmio_write_data[31:0] == QUEUE_TX && queue_ready) begin
                            tx_state <= NET_READ_DESC;
                        end
                    end
                    12'h064: interrupt_status <= interrupt_status & ~mmio_write_data[31:0];
                    12'h070: device_status <= mmio_write_data[7:0];
                    12'h080: queue_desc_addr[31:0] <= mmio_write_data[31:0];
                    12'h084: queue_desc_addr[63:32] <= mmio_write_data[31:0];
                    12'h090: queue_avail_addr[31:0] <= mmio_write_data[31:0];
                    12'h094: queue_avail_addr[63:32] <= mmio_write_data[31:0];
                    12'hA0: queue_used_addr[31:0] <= mmio_write_data[31:0];
                    12'hA4: queue_used_addr[63:32] <= mmio_write_data[31:0];
                endcase
            end
            
            // Update network status based on PHY
            net_config.status[0] <= link_up;
            net_config.speed <= link_speed ? 32'd1000 : 32'd100;
            net_config.duplex <= {7'h0, link_duplex};
        end
    end
    
    // MMIO read logic
    always_comb begin
        mmio_read_data = 64'h0;
        mmio_ready = 1'b1;
        mmio_error = 1'b0;
        
        if (mmio_read && addr_valid) begin
            if (config_access) begin
                // Network device configuration space
                case (local_addr[7:0])
                    8'h00: mmio_read_data = {16'h0, net_config.mac[47:32]};   // MAC high
                    8'h04: mmio_read_data = {32'h0, net_config.mac[31:0]};    // MAC low
                    8'h08: mmio_read_data = {48'h0, net_config.status};       // Status
                    8'h0A: mmio_read_data = {48'h0, net_config.max_virtqueue_pairs};
                    8'h0C: mmio_read_data = {48'h0, net_config.mtu};         // MTU
                    8'h10: mmio_read_data = {32'h0, net_config.speed};       // Speed
                    8'h14: mmio_read_data = {56'h0, net_config.duplex};      // Duplex
                    default: mmio_error = 1'b1;
                endcase
            end else begin
                // Standard VirtIO registers
                case (local_addr)
                    12'h000: mmio_read_data = {32'h0, 32'h74726976};         // Magic
                    12'h004: mmio_read_data = {32'h0, 32'h00000002};         // Version
                    12'h008: mmio_read_data = {32'h0, 32'h00000001};         // Device ID (network)
                    12'h00C: mmio_read_data = {32'h0, 32'h12345678};         // Vendor ID
                    12'h010: begin
                        if (device_features_sel == 0) begin
                            mmio_read_data = {32'h0, device_features[31:0]};
                        end else begin
                            mmio_read_data = {32'h0, device_features[63:32]};
                        end
                    end
                    12'h034: mmio_read_data = {32'h0, QUEUE_SIZE[31:0]};     // Queue num max
                    12'h044: mmio_read_data = {63'h0, queue_ready};          // Queue ready
                    12'h060: mmio_read_data = {32'h0, interrupt_status};     // Interrupt status
                    12'h070: mmio_read_data = {56'h0, device_status};        // Status
                    default: mmio_error = 1'b1;
                endcase
            end
        end else if (mmio_read && !addr_valid) begin
            mmio_error = 1'b1;
        end
    end
    
    // TX state machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_state <= NET_IDLE;
            tx_length <= 16'h0;
            tx_byte_count <= 16'h0;
            tx_buffer <= '0;
        end else begin
            case (tx_state)
                NET_IDLE: begin
                    // Wait for queue notification
                end
                
                NET_READ_DESC: begin
                    // Read descriptor chain from guest memory via DMA
                    // Simplified: assume we have the packet data
                    tx_state <= NET_DMA_TRANSFER;
                end
                
                NET_DMA_TRANSFER: begin
                    // Transfer packet data from guest memory
                    if (dma_ready) begin
                        tx_buffer <= dma_read_data[MTU_SIZE*8-1:0];
                        tx_length <= dma_read_data[15:0];  // Assume length in first word
                        tx_state <= NET_TRANSMIT;
                    end
                end
                
                NET_TRANSMIT: begin
                    // Transmit packet to PHY
                    if (tx_ready) begin
                        tx_state <= NET_UPDATE_USED;
                    end
                end
                
                NET_UPDATE_USED: begin
                    // Update used ring in guest memory
                    tx_state <= NET_COMPLETE;
                end
                
                NET_COMPLETE: begin
                    // Generate interrupt and return to idle
                    interrupt_status[0] <= 1'b1;
                    tx_state <= NET_IDLE;
                end
            endcase
        end
    end
    
    // RX state machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_state <= NET_IDLE;
            rx_length <= 16'h0;
            rx_byte_count <= 16'h0;
            rx_buffer <= '0;
        end else begin
            case (rx_state)
                NET_IDLE: begin
                    // Wait for incoming packet
                    if (rx_valid && rx_sof) begin
                        rx_state <= NET_READ_DESC;
                        rx_byte_count <= 16'h0;
                    end
                end
                
                NET_READ_DESC: begin
                    // Read available descriptors for RX
                    rx_state <= NET_DMA_TRANSFER;
                end
                
                NET_DMA_TRANSFER: begin
                    // Receive packet data and store in buffer
                    if (rx_valid) begin
                        rx_buffer <= rx_buffer | (rx_data << (rx_byte_count * 8));
                        rx_byte_count <= rx_byte_count + 1'b1;
                        
                        if (rx_eof) begin
                            rx_length <= rx_byte_count + 1'b1;
                            rx_state <= NET_UPDATE_USED;
                        end
                    end
                end
                
                NET_UPDATE_USED: begin
                    // Transfer received packet to guest memory via DMA
                    if (dma_ready) begin
                        rx_state <= NET_COMPLETE;
                    end
                end
                
                NET_COMPLETE: begin
                    // Generate interrupt for received packet
                    interrupt_status[1] <= 1'b1;
                    rx_state <= NET_IDLE;
                end
            endcase
        end
    end
    
    // TX PHY interface
    logic tx_in_progress;
    logic [15:0] tx_phy_count;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_in_progress <= 1'b0;
            tx_phy_count <= 16'h0;
            tx_data <= 8'h0;
            tx_valid <= 1'b0;
            tx_sof <= 1'b0;
            tx_eof <= 1'b0;
        end else begin
            tx_sof <= 1'b0;
            tx_eof <= 1'b0;
            
            if (tx_state == NET_TRANSMIT && !tx_in_progress) begin
                // Start transmission
                tx_in_progress <= 1'b1;
                tx_phy_count <= 16'h0;
                tx_sof <= 1'b1;
                tx_valid <= 1'b1;
            end else if (tx_in_progress && tx_ready) begin
                // Continue transmission
                tx_data <= tx_buffer[tx_phy_count*8 +: 8];
                tx_phy_count <= tx_phy_count + 1'b1;
                
                if (tx_phy_count >= tx_length - 1) begin
                    // End transmission
                    tx_in_progress <= 1'b0;
                    tx_valid <= 1'b0;
                    tx_eof <= 1'b1;
                end
            end else if (!tx_in_progress) begin
                tx_valid <= 1'b0;
            end
        end
    end
    
    // Generate interrupt signal
    assign net_interrupt = |interrupt_status;
    
    // Debug outputs
    `ifdef SIMULATION
    always @(posedge clk) begin
        if (mmio_write && addr_valid) begin
            $display("[VirtIO-NET] Write to 0x%08x = 0x%016x", mmio_addr, mmio_write_data);
        end
        if (mmio_read && addr_valid) begin
            $display("[VirtIO-NET] Read from 0x%08x = 0x%016x", mmio_addr, mmio_read_data);
        end
        if (tx_state != NET_IDLE) begin
            $display("[VirtIO-NET] TX State: %s, Length: %0d", tx_state.name, tx_length);
        end
        if (rx_state != NET_IDLE) begin
            $display("[VirtIO-NET] RX State: %s, Length: %0d", rx_state.name, rx_length);
        end
        if (tx_valid && tx_sof) begin
            $display("[VirtIO-NET] TX Start: Length=%0d MAC=%012x", tx_length, net_config.mac);
        end
        if (rx_valid && rx_sof) begin
            $display("[VirtIO-NET] RX Start: MAC=%012x", net_config.mac);
        end
    end
    `endif
    
endmodule 
