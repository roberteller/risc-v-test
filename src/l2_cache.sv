module l2_cache #(
    parameter DATA_WIDTH = 64,
    parameter ADDR_WIDTH = 64,
    parameter CACHE_SIZE = 1024*1024,     // 1MB shared L2 cache
    parameter LINE_SIZE = 64,             // 64-byte cache line
    parameter ASSOCIATIVITY = 8,          // 8-way set associative
    parameter NUM_CORES = 4,              // Number of cores
    parameter ID_WIDTH = 4                // Core ID width
)(
    input  logic                           clk,
    input  logic                           rst_n,
    
    // L1 interface
    input  logic [NUM_CORES-1:0][ADDR_WIDTH-1:0]  l1_addr,
    input  logic [NUM_CORES-1:0][DATA_WIDTH-1:0]  l1_write_data,
    input  logic [NUM_CORES-1:0]                  l1_read,
    input  logic [NUM_CORES-1:0]                  l1_write,
    input  logic [NUM_CORES-1:0][ID_WIDTH-1:0]    l1_id,
    input  logic [NUM_CORES-1:0]                  l1_request,
    output logic [NUM_CORES-1:0][DATA_WIDTH-1:0]  l1_read_data,
    output logic [NUM_CORES-1:0]                  l1_ready,
    output logic [NUM_CORES-1:0]                  l1_error,
    
    // Memory interface
    output logic [ADDR_WIDTH-1:0]           mem_addr,
    output logic [LINE_SIZE*8-1:0]          mem_write_data,
    output logic                            mem_read,
    output logic                            mem_write,
    output logic                            mem_request,
    input  logic [LINE_SIZE*8-1:0]          mem_read_data,
    input  logic                            mem_ready,
    input  logic                            mem_error,
    
    // Performance counter outputs
    output logic [31:0]                     cache_hits,
    output logic [31:0]                     cache_misses,
    output logic [31:0]                     cache_evictions
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
        logic [NUM_CORES-1:0] shared;  // Track sharing state for each core
    } cache_tag_t;
    
    // Cache line type
    typedef struct packed {
        cache_tag_t tag;
        logic [LINE_WIDTH-1:0] data;
    } cache_line_t;
    
    // Cache organization
    cache_line_t cache_lines [0:NUM_SETS-1][0:ASSOCIATIVITY-1];
    
    // LRU tracking (pseudo-LRU for 8-way)
    logic [6:0] lru_bits [0:NUM_SETS-1];  // 7 bits for 8-way pseudo-LRU
    
    // Address breakdown
    logic [TAG_BITS-1:0] addr_tag [NUM_CORES-1:0];
    logic [SET_BITS-1:0] addr_set [NUM_CORES-1:0];
    logic [WORD_INDEX_BITS-1:0] addr_word [NUM_CORES-1:0];
    
    // Cache FSM states
    typedef enum logic [3:0] {
        IDLE,
        ARBITRATE,
        CHECK_TAG,
        WRITE_BACK,
        FETCH_LINE,
        UPDATE_CACHE,
        HANDLE_REQUEST,
        COHERENCE_UPDATE
    } cache_state_t;
    
    // State registers
    cache_state_t state, next_state;
    logic [NUM_CORES-1:0] core_grant;
    logic [$clog2(NUM_CORES)-1:0] selected_core;
    logic [ASSOCIATIVITY-1:0] way_hit;
    logic [$clog2(ASSOCIATIVITY)-1:0] hit_way;
    logic [$clog2(ASSOCIATIVITY)-1:0] victim_way;
    logic [ADDR_WIDTH-1:0] pending_addr;
    logic [DATA_WIDTH-1:0] pending_write_data;
    logic pending_read;
    logic pending_write;
    logic [ID_WIDTH-1:0] pending_core_id;
    
    // Address parsing for each core
    generate
        for (genvar i = 0; i < NUM_CORES; i++) begin : gen_addr_parse
            assign addr_tag[i] = l1_addr[i][ADDR_WIDTH-1:ADDR_WIDTH-TAG_BITS];
            assign addr_set[i] = l1_addr[i][ADDR_WIDTH-TAG_BITS-1:ADDR_WIDTH-TAG_BITS-SET_BITS];
            assign addr_word[i] = l1_addr[i][$clog2(LINE_SIZE)-1:$clog2(DATA_WIDTH/8)];
        end
    endgenerate
    
    // Round-robin arbiter with fixed priority
    logic [NUM_CORES-1:0] request_queue;
    logic [$clog2(NUM_CORES)-1:0] current_priority;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_priority <= '0;
        end else if (state == HANDLE_REQUEST) begin
            // Update priority after handling a request
            current_priority <= (current_priority == NUM_CORES-1) ? '0 : current_priority + 1'b1;
        end
    end
    
    always_comb begin
        // Default: no grants
        core_grant = '0;
        selected_core = '0;
        
        if (state == ARBITRATE) begin
            // Round-robin priority selection
            logic [NUM_CORES-1:0] shifted_requests;
            logic [NUM_CORES-1:0] shifted_grants;
            logic [NUM_CORES-1:0] unshifted_grants;
            
            // Rotate requests based on current priority
            shifted_requests = {l1_request, l1_request} >> current_priority;
            
            // Fixed priority arbitration on rotated requests (find first 1)
            shifted_grants = '0;
            for (int i = 0; i < NUM_CORES; i++) begin
                if (shifted_requests[i] && !|shifted_grants) begin
                    shifted_grants[i] = 1'b1;
                end
            end
            
            // Rotate grants back to match original request ordering
            unshifted_grants = {shifted_grants, shifted_grants} << current_priority;
            core_grant = unshifted_grants[NUM_CORES-1:0];
            
            // Determine which core was granted
            for (int i = 0; i < NUM_CORES; i++) begin
                if (core_grant[i]) begin
                    selected_core = i[$clog2(NUM_CORES)-1:0];
                end
            end
        end
    end
    
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
                    cache_lines[i][j].tag.shared <= '0;
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
            pending_core_id <= '0;
        end else begin
            state <= next_state;
            
            // Update pending request info when a core is granted
            if (state == ARBITRATE && |core_grant) begin
                pending_addr <= l1_addr[selected_core];
                pending_write_data <= l1_write_data[selected_core];
                pending_read <= l1_read[selected_core];
                pending_write <= l1_write[selected_core];
                pending_core_id <= l1_id[selected_core];
            end
            
            // Update LRU on hit
            if (state == CHECK_TAG && |way_hit) begin
                // Update LRU bits (simplified for 8-way)
                // This is a basic update, a more complex pseudo-LRU would be implemented in practice
                for (int i = 0; i < 7; i++) begin
                    // Toggle appropriate bits based on hit way
                    if (i == hit_way) begin
                        lru_bits[addr_set[selected_core]][i] <= ~lru_bits[addr_set[selected_core]][i];
                    end
                end
                
                // Update sharing state
                cache_lines[addr_set[selected_core]][hit_way].tag.shared[pending_core_id] <= 1'b1;
                
                // Mark as dirty if writing
                if (pending_write) begin
                    cache_lines[addr_set[selected_core]][hit_way].tag.dirty <= 1'b1;
                end
                
                // Update cache hit counter
                cache_hits <= cache_hits + 1'b1;
            end
            
            // Update cache line on miss
            if (state == UPDATE_CACHE) begin
                // Write fetched line to cache
                cache_lines[addr_set[selected_core]][victim_way].tag.valid <= 1'b1;
                cache_lines[addr_set[selected_core]][victim_way].tag.dirty <= pending_write ? 1'b1 : 1'b0;
                cache_lines[addr_set[selected_core]][victim_way].tag.tag <= addr_tag[selected_core];
                cache_lines[addr_set[selected_core]][victim_way].tag.shared <= '0;
                cache_lines[addr_set[selected_core]][victim_way].tag.shared[pending_core_id] <= 1'b1;  // Mark as shared by requesting core
                
                // Copy data from memory
                cache_lines[addr_set[selected_core]][victim_way].data <= mem_read_data;
                
                // Update LRU bits
                // This is a basic update, a more complex pseudo-LRU would be implemented in practice
                for (int i = 0; i < 7; i++) begin
                    // Toggle appropriate bits based on victim way
                    if (i == victim_way) begin
                        lru_bits[addr_set[selected_core]][i] <= ~lru_bits[addr_set[selected_core]][i];
                    end
                end
                
                // Update stats
                cache_misses <= cache_misses + 1'b1;
                if (cache_lines[addr_set[selected_core]][victim_way].tag.valid && 
                    cache_lines[addr_set[selected_core]][victim_way].tag.dirty) begin
                    cache_evictions <= cache_evictions + 1'b1;
                end
            end
            
            // Update cache on write
            if (state == HANDLE_REQUEST && pending_write) begin
                // Single word write
                cache_lines[addr_set[selected_core]][hit_way].data[addr_word[selected_core]*DATA_WIDTH +: DATA_WIDTH] <= pending_write_data;
                cache_lines[addr_set[selected_core]][hit_way].tag.dirty <= 1'b1;
            end
            
            // Coherence update
            if (state == COHERENCE_UPDATE) begin
                // Invalidate sharing status for all cores except the writing one
                if (pending_write) begin
                    for (int i = 0; i < NUM_CORES; i++) begin
                        if (i != pending_core_id) begin
                            cache_lines[addr_set[selected_core]][hit_way].tag.shared[i] <= 1'b0;
                        end
                    end
                end
            end
        end
    end
    
    // Next state logic
    always_comb begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (|l1_request) begin
                    next_state = ARBITRATE;
                end
            end
            
            ARBITRATE: begin
                if (|core_grant) begin
                    next_state = CHECK_TAG;
                end
            end
            
            CHECK_TAG: begin
                if (|way_hit) begin
                    // Cache hit
                    if (pending_write && |cache_lines[addr_set[selected_core]][hit_way].tag.shared) begin
                        // Need to handle write to shared line
                        next_state = COHERENCE_UPDATE;
                    end else begin
                        next_state = HANDLE_REQUEST;
                    end
                end else begin
                    // Cache miss
                    // If victim line is dirty, write back first
                    if (cache_lines[addr_set[selected_core]][victim_way].tag.valid && 
                        cache_lines[addr_set[selected_core]][victim_way].tag.dirty) begin
                        next_state = WRITE_BACK;
                    end else begin
                        next_state = FETCH_LINE;
                    end
                end
            end
            
            WRITE_BACK: begin
                if (mem_ready) begin
                    next_state = FETCH_LINE;
                end
            end
            
            FETCH_LINE: begin
                if (mem_ready && !mem_error) begin
                    next_state = UPDATE_CACHE;
                end else if (mem_error) begin
                    next_state = IDLE;  // Error handling
                end
            end
            
            UPDATE_CACHE: begin
                next_state = HANDLE_REQUEST;
            end
            
            HANDLE_REQUEST: begin
                next_state = IDLE;
            end
            
            COHERENCE_UPDATE: begin
                next_state = HANDLE_REQUEST;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // Hit detection and way selection
    always_comb begin
        way_hit = '0;
        hit_way = '0;
        
        // Check for hit in any way
        for (int i = 0; i < ASSOCIATIVITY; i++) begin
            if (state == CHECK_TAG && 
                cache_lines[addr_set[selected_core]][i].tag.valid && 
                cache_lines[addr_set[selected_core]][i].tag.tag == addr_tag[selected_core]) begin
                way_hit[i] = 1'b1;
                hit_way = i[$clog2(ASSOCIATIVITY)-1:0];
            end
        end
        
        // Simple LRU victim selection (would be more complex in real implementation)
        victim_way = '0;
        for (int i = 0; i < ASSOCIATIVITY; i++) begin
            // Select first invalid line as victim
            if (!cache_lines[addr_set[selected_core]][i].tag.valid && victim_way == '0) begin
                victim_way = i[$clog2(ASSOCIATIVITY)-1:0];
            end
        end
        
        // If no invalid line, select based on LRU
        if (victim_way == '0) begin
            // Find way with lowest LRU priority (most bits set to 0)
            logic [ASSOCIATIVITY-1:0] lru_priorities;
            for (int i = 0; i < ASSOCIATIVITY; i++) begin
                // Count how many bits in LRU are set for this way
                lru_priorities[i] = ^lru_bits[addr_set[selected_core]];
            end
            
            // Find first way with priority 0
            for (int i = 0; i < ASSOCIATIVITY; i++) begin
                if (!lru_priorities[i] && victim_way == '0) begin
                    victim_way = i[$clog2(ASSOCIATIVITY)-1:0];
                end
            end
        end
    end
    
    // L1 interface
    always_comb begin
        // Default values
        for (int i = 0; i < NUM_CORES; i++) begin
            l1_ready[i] = 1'b0;
            l1_error[i] = 1'b0;
            l1_read_data[i] = '0;
        end
        
        // Set outputs for the selected core
        if (state == HANDLE_REQUEST) begin
            l1_ready[selected_core] = 1'b1;
            l1_error[selected_core] = 1'b0;
            
            if (pending_read) begin
                l1_read_data[selected_core] = cache_lines[addr_set[selected_core]][hit_way].data[addr_word[selected_core]*DATA_WIDTH +: DATA_WIDTH];
            end
        end
    end
    
    // Memory interface
    always_comb begin
        mem_addr = '0;
        mem_write_data = '0;
        mem_read = 1'b0;
        mem_write = 1'b0;
        mem_request = 1'b0;
        
        case (state)
            WRITE_BACK: begin
                // Write back dirty line
                mem_addr = {cache_lines[addr_set[selected_core]][victim_way].tag.tag, 
                           addr_set[selected_core], 
                           {$clog2(LINE_SIZE){1'b0}}};
                mem_write_data = cache_lines[addr_set[selected_core]][victim_way].data;
                mem_write = 1'b1;
                mem_request = 1'b1;
            end
            
            FETCH_LINE: begin
                // Fetch line from memory
                mem_addr = {addr_tag[selected_core], 
                           addr_set[selected_core], 
                           {$clog2(LINE_SIZE){1'b0}}};
                mem_read = 1'b1;
                mem_request = 1'b1;
            end
        endcase
    end

endmodule 
