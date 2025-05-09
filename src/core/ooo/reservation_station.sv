module reservation_station #(
    parameter RS_ENTRIES = 32,
    parameter RS_PTR_WIDTH = $clog2(RS_ENTRIES),
    parameter DATA_WIDTH = 32,
    parameter TAG_WIDTH = 6
)(
    input  logic                     clk,
    input  logic                     rst_n,
    
    // Dispatch interface
    input  logic                     dispatch_valid,
    input  logic [31:0]             dispatch_instruction,
    input  logic [DATA_WIDTH-1:0]   dispatch_rs1_data,
    input  logic [DATA_WIDTH-1:0]   dispatch_rs2_data,
    input  logic                    dispatch_rs1_ready,
    input  logic                    dispatch_rs2_ready,
    input  logic [TAG_WIDTH-1:0]    dispatch_rs1_tag,
    input  logic [TAG_WIDTH-1:0]    dispatch_rs2_tag,
    output logic                    dispatch_ready,
    output logic [RS_PTR_WIDTH-1:0] dispatch_tag,
    
    // Writeback interface
    input  logic [TAG_WIDTH-1:0]    wb_tag,
    input  logic [DATA_WIDTH-1:0]   wb_data,
    input  logic                    wb_valid,
    
    // Execution interface
    output logic                    exec_valid,
    output logic [31:0]            exec_instruction,
    output logic [DATA_WIDTH-1:0]   exec_rs1_data,
    output logic [DATA_WIDTH-1:0]   exec_rs2_data,
    input  logic                    exec_ready
);

    // Entry structure
    typedef struct packed {
        logic                    valid;
        logic [31:0]            instruction;
        logic [DATA_WIDTH-1:0]   rs1_data;
        logic [DATA_WIDTH-1:0]   rs2_data;
        logic                    rs1_ready;
        logic                    rs2_ready;
        logic [TAG_WIDTH-1:0]    rs1_tag;
        logic [TAG_WIDTH-1:0]    rs2_tag;
    } rs_entry_t;
    
    // Storage
    rs_entry_t [RS_ENTRIES-1:0] entries;
    logic [RS_PTR_WIDTH-1:0]    head_ptr;
    logic [RS_PTR_WIDTH-1:0]    tail_ptr;
    logic [RS_PTR_WIDTH:0]      count;
    
    // Status signals
    logic full;
    logic empty;
    assign full = (count == RS_ENTRIES);
    assign empty = (count == 0);
    
    // Dispatch ready signal
    assign dispatch_ready = !full;
    
    // Dispatch tag output
    assign dispatch_tag = tail_ptr;
    
    // Execution output
    assign exec_valid = !empty && entries[head_ptr].rs1_ready && entries[head_ptr].rs2_ready;
    assign exec_instruction = entries[head_ptr].instruction;
    assign exec_rs1_data = entries[head_ptr].rs1_data;
    assign exec_rs2_data = entries[head_ptr].rs2_data;
    
    // RS management
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            head_ptr <= '0;
            tail_ptr <= '0;
            count <= '0;
            for (int i = 0; i < RS_ENTRIES; i++) begin
                entries[i].valid <= 1'b0;
            end
        end else begin
            // Dispatch new entry
            if (dispatch_valid && dispatch_ready) begin
                entries[tail_ptr].valid <= 1'b1;
                entries[tail_ptr].instruction <= dispatch_instruction;
                entries[tail_ptr].rs1_data <= dispatch_rs1_data;
                entries[tail_ptr].rs2_data <= dispatch_rs2_data;
                entries[tail_ptr].rs1_ready <= dispatch_rs1_ready;
                entries[tail_ptr].rs2_ready <= dispatch_rs2_ready;
                entries[tail_ptr].rs1_tag <= dispatch_rs1_tag;
                entries[tail_ptr].rs2_tag <= dispatch_rs2_tag;
                
                tail_ptr <= tail_ptr + 1'b1;
                count <= count + 1'b1;
            end
            
            // Execute entry
            if (exec_valid && exec_ready) begin
                entries[head_ptr].valid <= 1'b0;
                head_ptr <= head_ptr + 1'b1;
                count <= count - 1'b1;
            end
            
            // Update ready entries with writeback data
            if (wb_valid) begin
                for (int i = 0; i < RS_ENTRIES; i++) begin
                    if (entries[i].valid) begin
                        if (!entries[i].rs1_ready && entries[i].rs1_tag == wb_tag) begin
                            entries[i].rs1_ready <= 1'b1;
                            entries[i].rs1_data <= wb_data;
                        end
                        if (!entries[i].rs2_ready && entries[i].rs2_tag == wb_tag) begin
                            entries[i].rs2_ready <= 1'b1;
                            entries[i].rs2_data <= wb_data;
                        end
                    end
                end
            end
        end
    end

endmodule 
