module ooo_execution_unit #(
    parameter NUM_PHYSICAL_REGS = 64,
    parameter NUM_ARCH_REGS = 32,
    parameter ROB_ENTRIES = 64,
    parameter RS_ENTRIES = 32,
    parameter LSQ_ENTRIES = 32,
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter TAG_WIDTH = 5,
    parameter ROB_PTR_WIDTH = $clog2(ROB_ENTRIES),
    parameter RS_PTR_WIDTH = $clog2(RS_ENTRIES),
    parameter LSQ_PTR_WIDTH = $clog2(LSQ_ENTRIES)
)(
    input  logic                     clk,
    input  logic                     rst_n,
    
    // Instruction fetch interface
    input  logic [31:0]              instruction,
    input  logic [ADDR_WIDTH-1:0]    pc,
    output logic                     fetch_stall,
    
    // Register file interface
    input  logic [DATA_WIDTH-1:0]    rf_read_data1,
    input  logic [DATA_WIDTH-1:0]    rf_read_data2,
    output logic [4:0]               rf_read_addr1,
    output logic [4:0]               rf_read_addr2,
    output logic [4:0]               rf_write_addr,
    output logic [DATA_WIDTH-1:0]    rf_write_data,
    output logic                     rf_write_en,
    
    // Memory interface
    output logic                     mem_req_valid,
    output logic                     mem_req_is_load,
    output logic [ADDR_WIDTH-1:0]    mem_req_addr,
    output logic [DATA_WIDTH-1:0]    mem_req_data,
    input  logic                     mem_req_ready,
    input  logic [DATA_WIDTH-1:0]    mem_resp_data,
    input  logic                     mem_resp_valid,
    
    // Branch interface
    output logic                     branch_taken,
    output logic [ADDR_WIDTH-1:0]    branch_target,
    
    // Status
    output logic                     busy
);

    // Internal signals
    logic                     dispatch_valid;
    logic                     dispatch_ready;
    logic [TAG_WIDTH-1:0]     dispatch_rob_tag;
    logic [TAG_WIDTH-1:0]     dispatch_phys_reg;
    logic                     dispatch_is_load;
    logic                     dispatch_is_store;
    logic [ADDR_WIDTH-1:0]    dispatch_addr;
    logic [DATA_WIDTH-1:0]    dispatch_store_data;
    
    // ROB status signals
    logic                     rob_full;
    logic                     rob_empty;
    
    // Commit signals
    logic                     commit_valid;
    logic [TAG_WIDTH-1:0]     commit_tag;
    logic [TAG_WIDTH-1:0]     commit_phys_reg;
    logic                     commit_is_load;
    logic                     commit_is_store;
    
    // RS signals
    logic                     rs_dispatch_valid;
    logic                     rs_dispatch_ready;
    logic [TAG_WIDTH-1:0]     rs_dispatch_tag;
    logic [TAG_WIDTH-1:0]     rs_dispatch_phys_reg;
    logic                     exec_valid;
    logic [31:0]             exec_instruction;
    logic [DATA_WIDTH-1:0]    exec_rs1_data;
    logic [DATA_WIDTH-1:0]    exec_rs2_data;
    logic                     exec_ready;
    
    // LSQ signals
    logic                     lsq_dispatch_valid;
    logic                     lsq_dispatch_ready;
    logic [TAG_WIDTH-1:0]     lsq_dispatch_tag;
    logic                     lsq_full;
    logic                     lsq_empty;
    
    // Free list signals
    logic                     free_list_empty;
    logic                     free_list_full;
    logic                     free_list_read;
    logic [TAG_WIDTH-1:0]     free_list_tag;
    logic                     free_list_valid;
    
    // Writeback signals
    logic                     wb_valid;
    logic [TAG_WIDTH-1:0]     wb_tag;
    logic [DATA_WIDTH-1:0]    wb_data;
    
    // Rename signals
    logic [4:0]              rename_rs1;
    logic [4:0]              rename_rs2;
    logic [4:0]              rename_rd;
    logic [TAG_WIDTH-1:0]    rename_rs1_tag;
    logic [TAG_WIDTH-1:0]    rename_rs2_tag;
    logic [TAG_WIDTH-1:0]    rename_rd_tag;
    logic                    rename_rs1_ready;
    logic                    rename_rs2_ready;
    
    // Instantiate components
    reorder_buffer #(
        .ROB_ENTRIES(ROB_ENTRIES),
        .ROB_PTR_WIDTH(ROB_PTR_WIDTH),
        .TAG_WIDTH(TAG_WIDTH)
    ) rob (
        .clk(clk),
        .rst_n(rst_n),
        .dispatch_valid(dispatch_valid),
        .dispatch_ready(dispatch_ready),
        .dispatch_tag(dispatch_rob_tag),
        .dispatch_phys_reg(dispatch_phys_reg),
        .dispatch_is_load(dispatch_is_load),
        .dispatch_is_store(dispatch_is_store),
        .commit_valid(commit_valid),
        .commit_tag(commit_tag),
        .commit_phys_reg(commit_phys_reg),
        .commit_is_load(commit_is_load),
        .commit_is_store(commit_is_store),
        .full(rob_full),
        .empty(rob_empty)
    );
    
    reservation_station #(
        .RS_ENTRIES(RS_ENTRIES),
        .RS_PTR_WIDTH(RS_PTR_WIDTH)
    ) rs (
        .clk(clk),
        .rst_n(rst_n),
        .dispatch_valid(rs_dispatch_valid),
        .dispatch_instruction(instruction),
        .dispatch_rs1_data(rf_read_data1),
        .dispatch_rs2_data(rf_read_data2),
        .dispatch_rs1_ready(rename_rs1_ready),
        .dispatch_rs2_ready(rename_rs2_ready),
        .dispatch_rs1_tag(rename_rs1_tag),
        .dispatch_rs2_tag(rename_rs2_tag),
        .dispatch_ready(rs_dispatch_ready),
        .dispatch_tag(rs_dispatch_tag),
        .wb_tag(wb_tag),
        .wb_data(wb_data),
        .wb_valid(wb_valid),
        .exec_valid(exec_valid),
        .exec_instruction(exec_instruction),
        .exec_rs1_data(exec_rs1_data),
        .exec_rs2_data(exec_rs2_data),
        .exec_ready(exec_ready)
    );
    
    register_rename #(
        .NUM_PHYSICAL_REGS(NUM_PHYSICAL_REGS),
        .NUM_ARCH_REGS(NUM_ARCH_REGS),
        .TAG_WIDTH(TAG_WIDTH)
    ) rename (
        .clk(clk),
        .rst_n(rst_n),
        .dispatch_valid(dispatch_valid),
        .dispatch_ready(dispatch_ready),
        .rename_rs1(rename_rs1),
        .rename_rs2(rename_rs2),
        .rename_rd(rename_rd),
        .rename_rs1_tag(rename_rs1_tag),
        .rename_rs2_tag(rename_rs2_tag),
        .rename_rd_tag(rename_rd_tag),
        .rename_rs1_ready(rename_rs1_ready),
        .rename_rs2_ready(rename_rs2_ready),
        .free_list_read(free_list_read),
        .free_list_tag(free_list_tag),
        .free_list_valid(free_list_valid),
        .commit_rd(rf_write_addr),
        .commit_tag(commit_tag),
        .commit_valid(commit_valid),
        .wb_tag(wb_tag),
        .wb_valid(wb_valid)
    );
    
    free_list #(
        .NUM_PHYSICAL_REGS(NUM_PHYSICAL_REGS),
        .TAG_WIDTH(TAG_WIDTH)
    ) free_list (
        .clk(clk),
        .rst_n(rst_n),
        .read(free_list_read),
        .read_tag(free_list_tag),
        .read_valid(free_list_valid),
        .return_tag(commit_phys_reg),
        .return_valid(commit_valid),
        .empty(free_list_empty),
        .full(free_list_full)
    );
    
    load_store_queue #(
        .LSQ_ENTRIES(LSQ_ENTRIES),
        .LSQ_PTR_WIDTH(LSQ_PTR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) lsq (
        .clk(clk),
        .rst_n(rst_n),
        .dispatch_valid(lsq_dispatch_valid),
        .is_load(dispatch_is_load),
        .addr(dispatch_addr),
        .store_data(dispatch_store_data),
        .rob_tag(dispatch_rob_tag),
        .dispatch_ready(lsq_dispatch_ready),
        .mem_req_valid(mem_req_valid),
        .mem_req_is_load(mem_req_is_load),
        .mem_req_addr(mem_req_addr),
        .mem_req_data(mem_req_data),
        .mem_req_ready(mem_req_ready),
        .mem_resp_data(mem_resp_data),
        .mem_resp_valid(mem_resp_valid),
        .commit_tag(commit_tag),
        .commit_valid(commit_valid),
        .full(lsq_full),
        .empty(lsq_empty)
    );
    
    // Instruction decode and dispatch logic
    always_comb begin
        // Default values
        dispatch_valid = 1'b0;
        dispatch_is_load = 1'b0;
        dispatch_is_store = 1'b0;
        dispatch_addr = '0;
        dispatch_store_data = '0;
        rename_rs1 = instruction[19:15];
        rename_rs2 = instruction[24:20];
        rename_rd = instruction[11:7];
        
        // Decode instruction
        case (instruction[6:0])
            7'b0000011: begin // Load
                dispatch_valid = 1'b1;
                dispatch_is_load = 1'b1;
                dispatch_addr = rf_read_data1 + {{20{instruction[31]}}, instruction[31:20]};
            end
            7'b0100011: begin // Store
                dispatch_valid = 1'b1;
                dispatch_is_store = 1'b1;
                dispatch_addr = rf_read_data1 + {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
                dispatch_store_data = rf_read_data2;
            end
            // Add other instruction types here
        endcase
    end
    
    // Stall logic
    assign fetch_stall = !dispatch_ready || !rs_dispatch_ready || !lsq_dispatch_ready;
    
    // Status
    assign busy = fetch_stall;

    // Drive register file interface
    assign rf_read_addr1 = rename_rs1;
    assign rf_read_addr2 = rename_rs2;
    assign rf_write_addr = commit_valid ? commit_phys_reg[4:0] : '0;
    assign rf_write_data = wb_data;
    assign rf_write_en = commit_valid;

    // Drive branch interface
    assign branch_taken = 1'b0;  // TODO: Implement branch prediction
    assign branch_target = '0;   // TODO: Implement branch target calculation

    // Drive dispatch signals
    assign rs_dispatch_valid = dispatch_valid && !dispatch_is_load && !dispatch_is_store;
    assign lsq_dispatch_valid = dispatch_valid && (dispatch_is_load || dispatch_is_store);

    // Drive writeback signals
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wb_valid <= 1'b0;
            wb_tag <= '0;
            wb_data <= '0;
        end else begin
            if (exec_valid) begin
                wb_valid <= 1'b1;
                wb_tag <= TAG_WIDTH'(exec_instruction[11:7]);  // rd field
                wb_data <= exec_rs1_data;  // TODO: Implement ALU
            end else begin
                wb_valid <= 1'b0;
            end
        end
    end

    // Drive exec_ready
    assign exec_ready = !wb_valid;  // Ready to execute when not writing back

    // Drive dispatch_phys_reg
    assign dispatch_phys_reg = rename_rd_tag;

endmodule 
