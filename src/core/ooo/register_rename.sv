module register_rename #(
    parameter NUM_PHYSICAL_REGS = 64,
    parameter NUM_ARCH_REGS = 32,
    parameter TAG_WIDTH = 6  // Changed to match physical register width
)(
    input  logic                     clk,
    input  logic                     rst_n,
    
    // Dispatch interface
    input  logic                     dispatch_valid,
    
    // Rename interface
    input  logic [4:0]              rename_rs1,
    input  logic [4:0]              rename_rs2,
    input  logic [4:0]              rename_rd,
    output logic [TAG_WIDTH-1:0]    rename_rs1_tag,
    output logic [TAG_WIDTH-1:0]    rename_rs2_tag,
    output logic [TAG_WIDTH-1:0]    rename_rd_tag,
    output logic                    rename_rs1_ready,
    output logic                    rename_rs2_ready,
    
    // Free list interface
    output logic                    free_list_read,
    input  logic [TAG_WIDTH-1:0]    free_list_tag,
    input  logic                    free_list_valid,
    
    // Commit interface
    input  logic [4:0]              commit_rd,
    input  logic [TAG_WIDTH-1:0]    commit_tag,
    input  logic                    commit_valid,
    
    // Writeback interface
    input  logic [TAG_WIDTH-1:0]    wb_tag,
    input  logic                    wb_valid
);

    // Register rename table
    logic [TAG_WIDTH-1:0] rename_table [NUM_ARCH_REGS-1:0];
    logic                 reg_ready [NUM_PHYSICAL_REGS-1:0];
    
    // Drive free list read signal
    assign free_list_read = dispatch_valid;
    
    // Drive rename tags
    assign rename_rs1_tag = rename_table[rename_rs1];
    assign rename_rs2_tag = rename_table[rename_rs2];
    assign rename_rd_tag = free_list_tag;
    
    // Register rename management
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Initialize rename table with architectural registers
            for (int i = 0; i < NUM_ARCH_REGS; i++) begin
                rename_table[i] <= TAG_WIDTH'(i);
                reg_ready[i] <= 1'b1;
            end
            // Initialize remaining physical registers as not ready
            for (int i = NUM_ARCH_REGS; i < NUM_PHYSICAL_REGS; i++) begin
                reg_ready[i] <= 1'b0;
            end
        end else begin
            // Commit
            if (commit_valid) begin
                reg_ready[commit_tag[TAG_WIDTH-1:0]] <= 1'b1;
            end
            
            // Writeback
            if (wb_valid) begin
                reg_ready[wb_tag[TAG_WIDTH-1:0]] <= 1'b1;
            end
            
            // Rename
            if (dispatch_valid && free_list_valid) begin
                rename_table[rename_rd] <= free_list_tag;
                reg_ready[free_list_tag[TAG_WIDTH-1:0]] <= 1'b0;
            end
        end
    end
    
    // Drive ready signals
    assign rename_rs1_ready = reg_ready[rename_table[rename_rs1][TAG_WIDTH-1:0]];
    assign rename_rs2_ready = reg_ready[rename_table[rename_rs2][TAG_WIDTH-1:0]];

endmodule 
