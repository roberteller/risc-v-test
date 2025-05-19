module l1_cache #(
    parameter DATA_WIDTH = 64,
    parameter ADDR_WIDTH = 64,
    parameter CACHE_SIZE = 32*1024,       // 32KB cache
    parameter LINE_SIZE = 64,             // 64-byte cache line
    parameter ASSOCIATIVITY = 4,          // 4-way set associative
    parameter ID_WIDTH = 4                // Core ID width
)(
    input  logic                       clk,
    input  logic                       rst_n,
    
    // CPU interface
    input  logic [ADDR_WIDTH-1:0]      cpu_addr,
    input  logic [DATA_WIDTH-1:0]      cpu_write_data,
    input  logic                       cpu_read,
    input  logic                       cpu_write,
    input  logic [2:0]                 cpu_size,  // 000:byte, 001:half, 010:word, 011:double
    input  logic                       cpu_request,
    output logic [DATA_WIDTH-1:0]      cpu_read_data,
    output logic                       cpu_ready,
    output logic                       cpu_error,
    
    // L2 cache interface
    output logic [ADDR_WIDTH-1:0]      l2_addr,
    output logic [DATA_WIDTH-1:0]      l2_write_data,
    output logic                       l2_read,
    output logic                       l2_write,
    output logic [ID_WIDTH-1:0]        l2_id,
    output logic                       l2_request,
    input  logic [DATA_WIDTH-1:0]      l2_read_data,
    input  logic                       l2_ready,
    input  logic                       l2_error,
    
    // Cache coherence signals
    input  logic                       snoop_request,
    input  logic [ADDR_WIDTH-1:0]      snoop_addr,
    input  logic                       snoop_invalidate,
    output logic                       snoop_hit,
    output logic [DATA_WIDTH-1:0]      snoop_data,
    output logic                       snoop_ack,
    
    // Performance counter outputs
    output logic [31:0]                cache_hits,
    output logic [31:0]                cache_misses,
    output logic [31:0]                cache_evictions,
    
    // Core ID for identification
    input  logic [ID_WIDTH-1:0]        core_id
);

    // Cache parameters calculation
    localparam LINE_WIDTH = LINE_SIZE * 8;  // Line width in bits
    localparam WORDS_PER_LINE = LINE_SIZE / (DATA_WIDTH/8);
    localparam NUM_SETS = (CACHE_SIZE / LINE_SIZE) / ASSOCIATIVITY;
    localparam SET_BITS = $clog2(NUM_SETS);
    localparam TAG_BITS = ADDR_WIDTH - SET_BITS - $clog2(LINE_SIZE);
    localparam WORD_INDEX_BITS = $clog2(WORDS_PER_LINE);
    
    // Cache state and tag array
    typedef struct packed {
        logic valid;
        logic dirty;
        logic [TAG_BITS-1:0] tag;
    } cache_tag_t;
    
    // Cache line type
    typedef struct packed {
        cache_tag_t tag;
        logic [LINE_WIDTH-1:0] data;
    } cache_line_t;
    
    // Cache organization
    cache_line_t cache_lines [0:NUM_SETS-1][0:ASSOCIATIVITY-1];
    
    // LRU tracking (pseudo-LRU for 4-way)
    logic [2:0] lru_bits [0:NUM_SETS-1];  // 3 bits for 4-way pseudo-LRU
    
    // Address breakdown
    logic [TAG_BITS-1:0] addr_tag;
    logic [SET_BITS-1:0] addr_set;
    logic [WORD_INDEX_BITS-1:0] addr_word;
    logic [$clog2(DATA_WIDTH/8)-1:0] addr_byte;
    
    // Cache FSM states
    typedef enum logic [3:0] {
        IDLE,
        CHECK_TAG,
        WRITE_BACK,
        FETCH_LINE,
        UPDATE_CACHE,
        HANDLE_CPU_OP,
        SNOOP_CHECK,
        SNOOP_RESPOND,
        SNOOP_INVALIDATE
    } cache_state_t;
    
    // State registers
    cache_state_t state, next_state;
    logic [ASSOCIATIVITY-1:0] way_hit;
    logic [$clog2(ASSOCIATIVITY)-1:0] hit_way;
    logic [$clog2(ASSOCIATIVITY)-1:0] victim_way;
    logic [ADDR_WIDTH-1:0] pending_addr;
    logic [DATA_WIDTH-1:0] pending_write_data;
    logic pending_read;
    logic pending_write;
    logic [2:0] pending_size;
    
    // Address breakdown
    assign addr_tag = cpu_addr[ADDR_WIDTH-1:ADDR_WIDTH-TAG_BITS];
    assign addr_set = cpu_addr[ADDR_WIDTH-TAG_BITS-1:ADDR_WIDTH-TAG_BITS-SET_BITS];
    assign addr_word = cpu_addr[$clog2(LINE_SIZE)-1:$clog2(DATA_WIDTH/8)];
    assign addr_byte = cpu_addr[$clog2(DATA_WIDTH/8)-1:0];
    
    // Snoop address breakdown
    logic [TAG_BITS-1:0] snoop_tag;
    logic [SET_BITS-1:0] snoop_set;
    assign snoop_tag = snoop_addr[ADDR_WIDTH-1:ADDR_WIDTH-TAG_BITS];
    assign snoop_set = snoop_addr[ADDR_WIDTH-TAG_BITS-1:ADDR_WIDTH-TAG_BITS-SET_BITS];
    
    // Byte enable generation
    function logic [DATA_WIDTH/8-1:0] get_byte_enable(logic [2:0] size, logic [$clog2(DATA_WIDTH/8)-1:0] addr_byte);
        logic [DATA_WIDTH/8-1:0] be;
        case (size)
            3'b000: begin // Byte
                be = 8'h01 << addr_byte;
            end
            3'b001: begin // Half word
                be = 8'h03 << {addr_byte[2:1], 1'b0};
            end
            3'b010: begin // Word
                be = 8'h0F << {addr_byte[2], 2'b00};
            end
            3'b011: begin // Double word
                be = 8'hFF;
            end
            default: be = 8'h00;
        endcase
        return be;
    endfunction
    
    // State machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            
            // Reset cache state
            for (int i = 0; i < NUM_SETS; i++) begin
                for (int j = 0; j < ASSOCIATIVITY; j++) begin
                    cache_lines[i][j].tag.valid <= 1'b0;
                    cache_lines[i][j].tag.dirty <= 1'b0;
                    cache_lines[i][j].tag.tag <= '0;
                    cache_lines[i][j].data <= '0;
                end
                lru_bits[i] <= '0;
            end
            
            // Reset counters
            cache_hits <= '0;
            cache_misses <= '0;
            cache_evictions <= '0;
            
            // Reset control signals
            pending_addr <= '0;
            pending_write_data <= '0;
            pending_read <= 1'b0;
            pending_write <= 1'b0;
            pending_size <= 3'b0;
        end else begin
            state <= next_state;
            
            // Update pending request info
            if (state == IDLE && cpu_request) begin
                pending_addr <= cpu_addr;
                pending_write_data <= cpu_write_data;
                pending_read <= cpu_read;
                pending_write <= cpu_write;
                pending_size <= cpu_size;
            end
            
            // Update LRU on hit
            if (state == CHECK_TAG && |way_hit) begin
                // Update pseudo-LRU bits based on accessed way
                case (hit_way)
                    2'b00: lru_bits[addr_set] <= {1'b1, 1'b0, lru_bits[addr_set][0]};
                    2'b01: lru_bits[addr_set] <= {1'b1, 1'b1, lru_bits[addr_set][0]};
                    2'b10: lru_bits[addr_set] <= {1'b0, lru_bits[addr_set][1], 1'b0};
                    2'b11: lru_bits[addr_set] <= {1'b0, lru_bits[addr_set][1], 1'b1};
                endcase
                
                // Update cache hit counter
                cache_hits <= cache_hits + 1'b1;
            end
            
            // Update cache line on miss
            if (state == UPDATE_CACHE) begin
                // Write fetched line to cache
                cache_lines[addr_set][victim_way].tag.valid <= 1'b1;
                cache_lines[addr_set][victim_way].tag.dirty <= 1'b0;
                cache_lines[addr_set][victim_way].tag.tag <= addr_tag;
                
                // Update data for the word we're currently reading
                for (int i = 0; i < WORDS_PER_LINE; i++) begin
                    cache_lines[addr_set][victim_way].data[i*DATA_WIDTH +: DATA_WIDTH] <= l2_read_data;
                end
                
                // Update LRU for this access
                case (victim_way)
                    2'b00: lru_bits[addr_set] <= {1'b1, 1'b0, lru_bits[addr_set][0]};
                    2'b01: lru_bits[addr_set] <= {1'b1, 1'b1, lru_bits[addr_set][0]};
                    2'b10: lru_bits[addr_set] <= {1'b0, lru_bits[addr_set][1], 1'b0};
                    2'b11: lru_bits[addr_set] <= {1'b0, lru_bits[addr_set][1], 1'b1};
                endcase
                
                // Update stats
                cache_misses <= cache_misses + 1'b1;
                if (cache_lines[addr_set][victim_way].tag.valid && cache_lines[addr_set][victim_way].tag.dirty) begin
                    cache_evictions <= cache_evictions + 1'b1;
                end
            end
            
            // Update cache on CPU write
            if (state == HANDLE_CPU_OP && pending_write) begin
                // Determine byte enables
                logic [DATA_WIDTH/8-1:0] byte_enable;
                byte_enable = get_byte_enable(pending_size, addr_byte);
                
                // Write data with byte enables
                for (int i = 0; i < DATA_WIDTH/8; i++) begin
                    if (byte_enable[i]) begin
                        cache_lines[addr_set][hit_way].data[addr_word*DATA_WIDTH + i*8 +: 8] <= 
                            pending_write_data[i*8 +: 8];
                    end
                end
                
                // Mark line as dirty
                cache_lines[addr_set][hit_way].tag.dirty <= 1'b1;
            end
            
            // Handle snoops
            if (state == SNOOP_INVALIDATE && snoop_hit) begin
                // Invalidate the line on request
                cache_lines[snoop_set][hit_way].tag.valid <= 1'b0;
            end
        end
    end
    
    // Next state logic
    always_comb begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (snoop_request) begin
                    next_state = SNOOP_CHECK;
                end else if (cpu_request) begin
                    next_state = CHECK_TAG;
                end
            end
            
            CHECK_TAG: begin
                if (|way_hit) begin
                    // Cache hit
                    next_state = HANDLE_CPU_OP;
                end else begin
                    // Cache miss
                    // If victim line is dirty, write back first
                    if (cache_lines[addr_set][victim_way].tag.valid && 
                        cache_lines[addr_set][victim_way].tag.dirty) begin
                        next_state = WRITE_BACK;
                    end else begin
                        next_state = FETCH_LINE;
                    end
                end
            end
            
            WRITE_BACK: begin
                if (l2_ready) begin
                    next_state = FETCH_LINE;
                end
            end
            
            FETCH_LINE: begin
                if (l2_ready && !l2_error) begin
                    next_state = UPDATE_CACHE;
                end else if (l2_error) begin
                    next_state = IDLE;  // Error handling
                end
            end
            
            UPDATE_CACHE: begin
                next_state = HANDLE_CPU_OP;
            end
            
            HANDLE_CPU_OP: begin
                next_state = IDLE;
            end
            
            SNOOP_CHECK: begin
                next_state = SNOOP_RESPOND;
            end
            
            SNOOP_RESPOND: begin
                if (snoop_invalidate && snoop_hit) begin
                    next_state = SNOOP_INVALIDATE;
                end else begin
                    next_state = IDLE;
                end
            end
            
            SNOOP_INVALIDATE: begin
                next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // Hit detection and way selection
    always_comb begin
        way_hit = '0;
        hit_way = '0;
        
        // Check for a hit in any way
        for (int i = 0; i < ASSOCIATIVITY; i++) begin
            if (cache_lines[addr_set][i].tag.valid && 
                cache_lines[addr_set][i].tag.tag == addr_tag) begin
                way_hit[i] = 1'b1;
                hit_way = i[$clog2(ASSOCIATIVITY)-1:0];
            end
        end
        
        // LRU victim selection (pseudo-LRU algorithm)
        case (lru_bits[addr_set][2])
            1'b0: begin
                case (lru_bits[addr_set][1])
                    1'b0: victim_way = 2'b00;
                    1'b1: victim_way = 2'b01;
                endcase
            end
            1'b1: begin
                case (lru_bits[addr_set][0])
                    1'b0: victim_way = 2'b10;
                    1'b1: victim_way = 2'b11;
                endcase
            end
        endcase
    end
    
    // Snoop logic
    logic [ASSOCIATIVITY-1:0] snoop_way_hit;
    logic [$clog2(ASSOCIATIVITY)-1:0] snoop_hit_way;
    
    always_comb begin
        snoop_way_hit = '0;
        snoop_hit_way = '0;
        snoop_hit = 1'b0;
        snoop_data = '0;
        
        // Check for a hit on snoop
        for (int i = 0; i < ASSOCIATIVITY; i++) begin
            if (cache_lines[snoop_set][i].tag.valid && 
                cache_lines[snoop_set][i].tag.tag == snoop_tag) begin
                snoop_way_hit[i] = 1'b1;
                snoop_hit_way = i[$clog2(ASSOCIATIVITY)-1:0];
                snoop_hit = 1'b1;
                // Return data from correct word in the cache line
                snoop_data = cache_lines[snoop_set][i].data[0 +: DATA_WIDTH];
            end
        end
        
        // Only acknowledge in SNOOP_RESPOND state
        snoop_ack = (state == SNOOP_RESPOND);
    end
    
    // CPU interface
    always_comb begin
        cpu_ready = (state == HANDLE_CPU_OP);
        cpu_error = 1'b0;  // Default no error
        
        // Read data from cache
        if (state == HANDLE_CPU_OP && pending_read) begin
            cpu_read_data = cache_lines[addr_set][hit_way].data[addr_word*DATA_WIDTH +: DATA_WIDTH];
        end else begin
            cpu_read_data = '0;
        end
    end
    
    // L2 interface
    always_comb begin
        l2_addr = '0;
        l2_write_data = '0;
        l2_read = 1'b0;
        l2_write = 1'b0;
        l2_id = core_id;
        l2_request = 1'b0;
        
        case (state)
            WRITE_BACK: begin
                // Writing back a dirty line
                l2_addr = {cache_lines[addr_set][victim_way].tag.tag, addr_set, {$clog2(LINE_SIZE){1'b0}}};
                // The complete line would be written, using just the first word as an example
                l2_write_data = cache_lines[addr_set][victim_way].data[0 +: DATA_WIDTH];
                l2_write = 1'b1;
                l2_request = 1'b1;
            end
            
            FETCH_LINE: begin
                // Fetching a new line
                l2_addr = {addr_tag, addr_set, {$clog2(LINE_SIZE){1'b0}}};
                l2_read = 1'b1;
                l2_request = 1'b1;
            end
        endcase
    end

endmodule 