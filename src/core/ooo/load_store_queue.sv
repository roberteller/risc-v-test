module load_store_queue #(
    parameter LSQ_ENTRIES = 32,
    parameter LSQ_PTR_WIDTH = $clog2(LSQ_ENTRIES),
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter TAG_WIDTH = 6
)(
    input  logic                     clk,
    input  logic                     rst_n,
    
    // Dispatch interface
    input  logic                     dispatch_valid,
    input  logic                     is_load,
    input  logic [ADDR_WIDTH-1:0]    addr,
    input  logic [DATA_WIDTH-1:0]    store_data,
    input  logic [TAG_WIDTH-1:0]     rob_tag,
    output logic                     dispatch_ready,
    
    // Memory interface
    output logic                     mem_req_valid,
    output logic                     mem_req_is_load,
    output logic [ADDR_WIDTH-1:0]    mem_req_addr,
    output logic [DATA_WIDTH-1:0]    mem_req_data,
    input  logic                     mem_req_ready,
    input  logic [DATA_WIDTH-1:0]    mem_resp_data,
    input  logic                     mem_resp_valid,
    
    // Commit interface
    input  logic [TAG_WIDTH-1:0]     commit_tag,
    input  logic                     commit_valid,
    
    // Status
    output logic                     full,
    output logic                     empty
);

    // Entry structure
    typedef struct packed {
        logic                    valid;
        logic                    is_load;
        logic                    completed;
        logic [ADDR_WIDTH-1:0]   addr;
        logic [DATA_WIDTH-1:0]   data;
        logic [TAG_WIDTH-1:0]    rob_tag;
    } lsq_entry_t;
    
    // Storage
    lsq_entry_t [LSQ_ENTRIES-1:0] entries;
    logic [LSQ_PTR_WIDTH-1:0]     head_ptr;
    logic [LSQ_PTR_WIDTH-1:0]     tail_ptr;
    logic [LSQ_PTR_WIDTH:0]       count;
    
    // Status signals
    assign full = (count == LSQ_PTR_WIDTH'(LSQ_ENTRIES));
    assign empty = (count == '0);
    
    // Dispatch ready signal
    assign dispatch_ready = !full;
    
    // Memory request signals
    always_comb begin
        mem_req_valid = 1'b0;
        mem_req_is_load = 1'b0;
        mem_req_addr = '0;
        mem_req_data = '0;
        
        // Check for completed loads
        for (int i = 0; i < LSQ_ENTRIES; i++) begin
            logic [LSQ_PTR_WIDTH-1:0] ptr;
            ptr = (LSQ_PTR_WIDTH'(head_ptr) + LSQ_PTR_WIDTH'(i)) % LSQ_PTR_WIDTH'(LSQ_ENTRIES);
            if (entries[ptr].valid && entries[ptr].is_load && !entries[ptr].completed) begin
                mem_req_valid = 1'b1;
                mem_req_is_load = 1'b1;
                mem_req_addr = entries[ptr].addr;
                break;
            end
        end
    end
    
    // LSQ management
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            head_ptr <= '0;
            tail_ptr <= '0;
            count <= '0;
            for (int i = 0; i < LSQ_ENTRIES; i++) begin
                entries[i].valid <= 1'b0;
            end
        end else begin
            // Dispatch new entry
            if (dispatch_valid && dispatch_ready) begin
                entries[tail_ptr].valid <= 1'b1;
                entries[tail_ptr].is_load <= is_load;
                entries[tail_ptr].completed <= 1'b0;
                entries[tail_ptr].addr <= addr;
                entries[tail_ptr].data <= store_data;
                entries[tail_ptr].rob_tag <= rob_tag;
                
                tail_ptr <= tail_ptr + LSQ_PTR_WIDTH'(1);
                count <= count + LSQ_PTR_WIDTH'(1);
            end
            
            // Handle memory response
            if (mem_resp_valid) begin
                for (int i = 0; i < LSQ_ENTRIES; i++) begin
                    if (entries[i].valid && entries[i].is_load && !entries[i].completed) begin
                        entries[i].completed <= 1'b1;
                        entries[i].data <= mem_resp_data;
                        break;
                    end
                end
            end
            
            // Commit entry
            if (commit_valid) begin
                if (entries[head_ptr].valid && entries[head_ptr].rob_tag == commit_tag) begin
                    entries[head_ptr].valid <= 1'b0;
                    head_ptr <= head_ptr + LSQ_PTR_WIDTH'(1);
                    count <= count - LSQ_PTR_WIDTH'(1);
                end
            end
        end
    end

endmodule 
