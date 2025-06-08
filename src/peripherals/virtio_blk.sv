module virtio_blk #(
    parameter ADDR_WIDTH = 64,
    parameter DATA_WIDTH = 64,
    parameter BASE_ADDR = 64'h10001000,
    parameter QUEUE_SIZE = 256,
    parameter BLOCK_SIZE = 512,
    parameter NUM_BLOCKS = 1024*1024  // 512MB storage
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
    output logic                          blk_interrupt,
    
    // External storage interface (simplified)
    output logic [31:0]                   storage_block_addr,
    output logic [BLOCK_SIZE*8-1:0]       storage_write_data,
    input  logic [BLOCK_SIZE*8-1:0]       storage_read_data,
    output logic                          storage_read,
    output logic                          storage_write,
    input  logic                          storage_ready
);

    // VirtIO register offsets
    localparam VIRTIO_MMIO_MAGIC_VALUE      = 32'h00;
    localparam VIRTIO_MMIO_VERSION          = 32'h04;
    localparam VIRTIO_MMIO_DEVICE_ID        = 32'h08;
    localparam VIRTIO_MMIO_VENDOR_ID        = 32'h0C;
    localparam VIRTIO_MMIO_DEVICE_FEATURES  = 32'h10;
    localparam VIRTIO_MMIO_DEVICE_FEATURES_SEL = 32'h14;
    localparam VIRTIO_MMIO_DRIVER_FEATURES  = 32'h20;
    localparam VIRTIO_MMIO_DRIVER_FEATURES_SEL = 32'h24;
    localparam VIRTIO_MMIO_QUEUE_SEL        = 32'h30;
    localparam VIRTIO_MMIO_QUEUE_NUM_MAX    = 32'h34;
    localparam VIRTIO_MMIO_QUEUE_NUM        = 32'h38;
    localparam VIRTIO_MMIO_QUEUE_READY      = 32'h44;
    localparam VIRTIO_MMIO_QUEUE_NOTIFY     = 32'h50;
    localparam VIRTIO_MMIO_INTERRUPT_STATUS = 32'h60;
    localparam VIRTIO_MMIO_INTERRUPT_ACK    = 32'h64;
    localparam VIRTIO_MMIO_STATUS           = 32'h70;
    localparam VIRTIO_MMIO_QUEUE_DESC_LOW   = 32'h80;
    localparam VIRTIO_MMIO_QUEUE_DESC_HIGH  = 32'h84;
    localparam VIRTIO_MMIO_QUEUE_AVAIL_LOW  = 32'h90;
    localparam VIRTIO_MMIO_QUEUE_AVAIL_HIGH = 32'h94;
    localparam VIRTIO_MMIO_QUEUE_USED_LOW   = 32'hA0;
    localparam VIRTIO_MMIO_QUEUE_USED_HIGH  = 32'hA4;
    
    // VirtIO constants
    localparam VIRTIO_MAGIC     = 32'h74726976;  // "virt"
    localparam VIRTIO_VERSION   = 32'h00000002;  // Version 2
    localparam VIRTIO_DEVICE_BLK = 32'h00000002; // Block device
    localparam VIRTIO_VENDOR    = 32'h12345678;  // Custom vendor ID
    
    // VirtIO block request types
    localparam VIRTIO_BLK_T_IN  = 32'h00000000;  // Read
    localparam VIRTIO_BLK_T_OUT = 32'h00000001;  // Write
    
    // Device status bits
    localparam VIRTIO_STATUS_ACKNOWLEDGE = 8'h01;
    localparam VIRTIO_STATUS_DRIVER      = 8'h02;
    localparam VIRTIO_STATUS_DRIVER_OK   = 8'h04;
    localparam VIRTIO_STATUS_FEATURES_OK = 8'h08;
    localparam VIRTIO_STATUS_FAILED      = 8'h80;
    
    // Register storage
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
    
    // Queue state
    logic [15:0] last_avail_idx;
    logic [15:0] last_used_idx;
    
    // Address decoding
    logic [11:0] local_addr;
    logic        addr_valid;
    
    assign local_addr = mmio_addr[11:0];
    assign addr_valid = (mmio_addr[ADDR_WIDTH-1:12] == BASE_ADDR[ADDR_WIDTH-1:12]);
    
    // VirtIO block device features
    assign device_features = 64'h0;  // Basic block device, no special features
    
    // Request processing state machine
    typedef enum logic [2:0] {
        IDLE,
        READ_DESC,
        PROCESS_REQUEST,
        DMA_TRANSFER,
        UPDATE_USED,
        COMPLETE
    } req_state_t;
    
    req_state_t req_state;
    
    // Current request being processed
    typedef struct packed {
        logic [31:0] req_type;
        logic [63:0] sector;
        logic [ADDR_WIDTH-1:0] data_addr;
        logic [31:0] data_len;
        logic [ADDR_WIDTH-1:0] status_addr;
    } virtio_blk_req_t;
    
    virtio_blk_req_t current_req;
    logic [15:0] current_desc_idx;
    logic [31:0] bytes_transferred;
    
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
            last_avail_idx <= 16'h0;
            last_used_idx <= 16'h0;
        end else begin
            // Handle MMIO writes
            if (mmio_write && addr_valid) begin
                case (local_addr)
                    VIRTIO_MMIO_DEVICE_FEATURES_SEL: device_features_sel <= mmio_write_data[31:0];
                    VIRTIO_MMIO_DRIVER_FEATURES_SEL: driver_features_sel <= mmio_write_data[31:0];
                    VIRTIO_MMIO_DRIVER_FEATURES: begin
                        if (driver_features_sel == 0) begin
                            driver_features[31:0] <= mmio_write_data[31:0];
                        end else begin
                            driver_features[63:32] <= mmio_write_data[31:0];
                        end
                    end
                    VIRTIO_MMIO_QUEUE_SEL: queue_sel <= mmio_write_data[31:0];
                    VIRTIO_MMIO_QUEUE_NUM: queue_num <= mmio_write_data[31:0];
                    VIRTIO_MMIO_QUEUE_READY: queue_ready <= mmio_write_data[0];
                    VIRTIO_MMIO_QUEUE_NOTIFY: begin
                        // Queue notification - trigger request processing
                        if (mmio_write_data[31:0] == queue_sel && queue_ready) begin
                            // Start processing available descriptors
                            req_state <= READ_DESC;
                        end
                    end
                    VIRTIO_MMIO_INTERRUPT_ACK: interrupt_status <= interrupt_status & ~mmio_write_data[31:0];
                    VIRTIO_MMIO_STATUS: device_status <= mmio_write_data[7:0];
                    VIRTIO_MMIO_QUEUE_DESC_LOW: queue_desc_addr[31:0] <= mmio_write_data[31:0];
                    VIRTIO_MMIO_QUEUE_DESC_HIGH: queue_desc_addr[63:32] <= mmio_write_data[31:0];
                    VIRTIO_MMIO_QUEUE_AVAIL_LOW: queue_avail_addr[31:0] <= mmio_write_data[31:0];
                    VIRTIO_MMIO_QUEUE_AVAIL_HIGH: queue_avail_addr[63:32] <= mmio_write_data[31:0];
                    VIRTIO_MMIO_QUEUE_USED_LOW: queue_used_addr[31:0] <= mmio_write_data[31:0];
                    VIRTIO_MMIO_QUEUE_USED_HIGH: queue_used_addr[63:32] <= mmio_write_data[31:0];
                endcase
            end
        end
    end
    
    // MMIO read logic
    always_comb begin
        mmio_read_data = 64'h0;
        mmio_ready = 1'b1;
        mmio_error = 1'b0;
        
        if (mmio_read && addr_valid) begin
            case (local_addr)
                VIRTIO_MMIO_MAGIC_VALUE: mmio_read_data = {32'h0, VIRTIO_MAGIC};
                VIRTIO_MMIO_VERSION: mmio_read_data = {32'h0, VIRTIO_VERSION};
                VIRTIO_MMIO_DEVICE_ID: mmio_read_data = {32'h0, VIRTIO_DEVICE_BLK};
                VIRTIO_MMIO_VENDOR_ID: mmio_read_data = {32'h0, VIRTIO_VENDOR};
                VIRTIO_MMIO_DEVICE_FEATURES: begin
                    if (device_features_sel == 0) begin
                        mmio_read_data = {32'h0, device_features[31:0]};
                    end else begin
                        mmio_read_data = {32'h0, device_features[63:32]};
                    end
                end
                VIRTIO_MMIO_QUEUE_NUM_MAX: mmio_read_data = {32'h0, QUEUE_SIZE[31:0]};
                VIRTIO_MMIO_QUEUE_READY: mmio_read_data = {63'h0, queue_ready};
                VIRTIO_MMIO_INTERRUPT_STATUS: mmio_read_data = {32'h0, interrupt_status};
                VIRTIO_MMIO_STATUS: mmio_read_data = {56'h0, device_status};
                default: mmio_error = 1'b1;
            endcase
        end else if (mmio_read && !addr_valid) begin
            mmio_error = 1'b1;
        end
    end
    
    // Request processing state machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_state <= IDLE;
            current_req <= '0;
            current_desc_idx <= 16'h0;
            bytes_transferred <= 32'h0;
        end else begin
            case (req_state)
                IDLE: begin
                    // Wait for queue notification
                end
                
                READ_DESC: begin
                    // Read descriptor from guest memory
                    // This would involve DMA reads to fetch the descriptor chain
                    // For simplicity, assume we have the request parsed
                    req_state <= PROCESS_REQUEST;
                end
                
                PROCESS_REQUEST: begin
                    // Decode the request type and start storage operation
                    if (current_req.req_type == VIRTIO_BLK_T_IN) begin
                        storage_read <= 1'b1;
                        storage_block_addr <= current_req.sector[31:0];
                    end else if (current_req.req_type == VIRTIO_BLK_T_OUT) begin
                        storage_write <= 1'b1;
                        storage_block_addr <= current_req.sector[31:0];
                    end
                    req_state <= DMA_TRANSFER;
                end
                
                DMA_TRANSFER: begin
                    // Transfer data between guest memory and storage
                    if (storage_ready) begin
                        storage_read <= 1'b0;
                        storage_write <= 1'b0;
                        req_state <= UPDATE_USED;
                    end
                end
                
                UPDATE_USED: begin
                    // Update used ring in guest memory
                    last_used_idx <= last_used_idx + 1'b1;
                    req_state <= COMPLETE;
                end
                
                COMPLETE: begin
                    // Generate interrupt and return to idle
                    interrupt_status[0] <= 1'b1;  // Used ring update
                    req_state <= IDLE;
                end
            endcase
        end
    end
    
    // Generate interrupt signal
    assign blk_interrupt = |interrupt_status;
    
    // Storage interface (simple implementation)
    assign storage_write_data = '0;  // TODO: Connect to DMA data
    
    // Debug outputs
    `ifdef SIMULATION
    always @(posedge clk) begin
        if (mmio_write && addr_valid) begin
            $display("[VirtIO-BLK] Write to 0x%08x = 0x%016x", mmio_addr, mmio_write_data);
        end
        if (mmio_read && addr_valid) begin
            $display("[VirtIO-BLK] Read from 0x%08x = 0x%016x", mmio_addr, mmio_read_data);
        end
        if (req_state != IDLE) begin
            $display("[VirtIO-BLK] State: %s", req_state.name);
        end
    end
    `endif
    
endmodule
