module reorder_buffer #(
    parameter ROB_ENTRIES = 64,
    parameter ROB_PTR_WIDTH = $clog2(ROB_ENTRIES),
    parameter TAG_WIDTH = 6
)(
    input  logic                     clk,
    input  logic                     rst_n,
    
    // Dispatch interface
    input  logic                     dispatch_valid,
    input  logic [TAG_WIDTH-1:0]     dispatch_tag,
    input  logic [TAG_WIDTH-1:0]     dispatch_phys_reg,
    input  logic                     dispatch_is_load,
    input  logic                     dispatch_is_store,
    
    // Commit interface
    output logic                     commit_valid,
    output logic [TAG_WIDTH-1:0]     commit_tag,
    output logic [TAG_WIDTH-1:0]     commit_phys_reg,
    output logic                     commit_is_load,
    output logic                     commit_is_store,
    
    // Status
    output logic                     full,
    output logic                     empty
);

    // Entry structure
    typedef struct packed {
        logic                    valid;
        logic                    ready;
        logic [TAG_WIDTH-1:0]    tag;
        logic [TAG_WIDTH-1:0]    phys_reg;
        logic                    is_load;
        logic                    is_store;
    } rob_entry_t;
    
    // Storage
    rob_entry_t [ROB_ENTRIES-1:0] entries;
    logic [ROB_PTR_WIDTH-1:0]     head_ptr;
    logic [ROB_PTR_WIDTH-1:0]     tail_ptr;
    logic [ROB_PTR_WIDTH:0]       count;
    
    // Status signals
    assign full  = (count == ROB_ENTRIES);
    assign empty = (count == 0);
    
    // ROB management
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            head_ptr <= '0;
            tail_ptr <= '0;
            count <= '0;
            for (int i = 0; i < ROB_ENTRIES; i++) begin
                entries[i].valid <= 1'b0;
            end
        end else begin
            // Dispatch new entry
            if (dispatch_valid && !full) begin
                entries[tail_ptr].valid <= 1'b1;
                entries[tail_ptr].ready <= 1'b0;
                entries[tail_ptr].tag <= dispatch_tag;
                entries[tail_ptr].phys_reg <= dispatch_phys_reg;
                entries[tail_ptr].is_load <= dispatch_is_load;
                entries[tail_ptr].is_store <= dispatch_is_store;
                
                tail_ptr <= tail_ptr + ROB_PTR_WIDTH'(1);
                count <= count + ROB_PTR_WIDTH'(1);
            end
            
            // Commit entry
            if (!empty && entries[head_ptr].ready) begin
                commit_valid <= 1'b1;
                commit_tag <= entries[head_ptr].tag;
                commit_phys_reg <= entries[head_ptr].phys_reg;
                commit_is_load <= entries[head_ptr].is_load;
                commit_is_store <= entries[head_ptr].is_store;
                
                entries[head_ptr].valid <= 1'b0;
                head_ptr <= head_ptr + ROB_PTR_WIDTH'(1);
                count <= count - ROB_PTR_WIDTH'(1);
            end else begin
                commit_valid <= 1'b0;
            end
        end
    end

endmodule
