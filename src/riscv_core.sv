module riscv_core #(
    parameter DATA_WIDTH = 64,
    parameter ADDR_WIDTH = 64,
    parameter MEM_SIZE = 1024
)(
    input  logic                     clk,
    input  logic                     rst_n,
    input  logic [2:0]              core_id,
    input  logic [31:0]             instruction_in,
    output logic [ADDR_WIDTH-1:0]    pc_out,
    output logic [DATA_WIDTH-1:0]    alu_result_out,
    output logic                     mem_request,
    output logic                     mem_write,
    output logic [ADDR_WIDTH-1:0]    mem_addr,
    output logic [DATA_WIDTH-1:0]    mem_data,
    input  logic [DATA_WIDTH-1:0]    mem_read_data,
    output logic                     core_active
);

    // Pipeline registers
    typedef struct packed {
        logic [31:0] instruction;
        logic [ADDR_WIDTH-1:0] pc;
    } if_id_reg_t;

    typedef struct packed {
        logic [31:0] instruction;
        logic [ADDR_WIDTH-1:0] pc;
        logic [DATA_WIDTH-1:0] rs1_data;
        logic [DATA_WIDTH-1:0] rs2_data;
        logic [DATA_WIDTH-1:0] immediate;
        logic reg_write;
        logic mem_read;
        logic mem_write;
        logic branch;
        logic alu_src;
        logic [3:0] alu_control;
        logic [1:0] mem_to_reg;
        logic [4:0] rs1_addr;
        logic [4:0] rs2_addr;
        logic [4:0] rd_addr;
    } id_ex_reg_t;

    typedef struct packed {
        logic [31:0] instruction;
        logic [ADDR_WIDTH-1:0] pc;
        logic [DATA_WIDTH-1:0] alu_result;
        logic [DATA_WIDTH-1:0] rs2_data;
        logic reg_write;
        logic mem_read;
        logic mem_write;
        logic [1:0] mem_to_reg;
        logic [4:0] rd_addr;
    } ex_mem_reg_t;

    typedef struct packed {
        logic [31:0] instruction;
        logic [ADDR_WIDTH-1:0] pc;
        logic [DATA_WIDTH-1:0] alu_result;
        logic [DATA_WIDTH-1:0] mem_data;
        logic reg_write;
        logic [1:0] mem_to_reg;
        logic [4:0] rd_addr;
    } mem_wb_reg_t;

    // Pipeline registers
    if_id_reg_t if_id_reg;
    id_ex_reg_t id_ex_reg;
    ex_mem_reg_t ex_mem_reg;
    mem_wb_reg_t mem_wb_reg;

    // Internal signals
    logic [ADDR_WIDTH-1:0] pc;
    logic [31:0] instruction;
    logic [DATA_WIDTH-1:0] rs1_data, rs2_data;
    logic [DATA_WIDTH-1:0] immediate;
    logic [DATA_WIDTH-1:0] alu_operand_a;
    logic [DATA_WIDTH-1:0] alu_operand_b;
    logic [DATA_WIDTH-1:0] alu_result;
    logic [DATA_WIDTH-1:0] write_data;
    logic zero_flag;
    logic branch_taken;
    logic [ADDR_WIDTH-1:0] branch_target;

    // Control signals
    logic reg_write;
    logic mem_read;
    logic branch;
    logic alu_src;
    logic [3:0] alu_control;
    logic [1:0] mem_to_reg;
    logic mem_write_ctrl;

    // Hazard detection signals
    logic stall_if;
    logic stall_id;
    logic flush_id;
    logic flush_ex;
    logic forward_rs1;
    logic forward_rs2;
    logic [1:0] forward_rs1_sel;
    logic [1:0] forward_rs2_sel;

    // Memory alignment check signals
    logic mem_align_error;
    logic [1:0] mem_align_type;  // 00: byte, 01: half, 10: word, 11: double
    logic [7:0] mem_byte_en;

    // Performance counters
    typedef struct packed {
        logic [63:0] cycles;
        logic [63:0] instructions;
        logic [63:0] branches;
        logic [63:0] branch_mispredicts;
        logic [63:0] loads;
        logic [63:0] stores;
        logic [63:0] load_use_stalls;
        logic [63:0] alignment_faults;
    } perf_counters_t;

    perf_counters_t perf_counters;

    // Module instantiations
    register_file #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(5)
    ) reg_file (
        .clk(clk),
        .rst_n(rst_n),
        .write_enable(mem_wb_reg.reg_write),
        .write_addr(mem_wb_reg.rd_addr),
        .write_data(write_data),
        .read_addr_1(if_id_reg.instruction[19:15]),
        .read_addr_2(if_id_reg.instruction[24:20]),
        .read_data_1(rs1_data),
        .read_data_2(rs2_data)
    );

    alu #(
        .DATA_WIDTH(DATA_WIDTH)
    ) alu_unit (
        .operand_a(alu_operand_a),
        .operand_b(alu_operand_b),
        .alu_control(id_ex_reg.alu_control),
        .result(alu_result),
        .zero_flag(zero_flag)
    );

    immediate_generator imm_gen (
        .instruction(if_id_reg.instruction),
        .immediate(immediate)
    );

    control_unit ctrl_unit (
        .instruction(if_id_reg.instruction),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write_ctrl),
        .branch(branch),
        .alu_src(alu_src),
        .alu_control(alu_control),
        .mem_to_reg(mem_to_reg)
    );

    // Hazard detection logic
    always_comb begin
        // Load-use hazard detection
        stall_if = 1'b0;
        stall_id = 1'b0;
        flush_id = 1'b0;
        flush_ex = 1'b0;

        if (id_ex_reg.mem_read && 
            ((id_ex_reg.rd_addr == if_id_reg.instruction[19:15]) ||
             (id_ex_reg.rd_addr == if_id_reg.instruction[24:20]))) begin
            stall_if = 1'b1;
            stall_id = 1'b1;
            flush_ex = 1'b1;
        end

        // Branch hazard
        if (branch_taken) begin
            flush_id = 1'b1;
            flush_ex = 1'b1;
        end
    end

    // Forwarding logic
    always_comb begin
        forward_rs1 = 1'b0;
        forward_rs2 = 1'b0;
        forward_rs1_sel = 2'b00;
        forward_rs2_sel = 2'b00;

        // EX-EX forwarding
        if (ex_mem_reg.reg_write && 
            (ex_mem_reg.rd_addr != 0) && 
            (ex_mem_reg.rd_addr == id_ex_reg.rs1_addr)) begin
            forward_rs1 = 1'b1;
            forward_rs1_sel = 2'b01;
        end
        if (ex_mem_reg.reg_write && 
            (ex_mem_reg.rd_addr != 0) && 
            (ex_mem_reg.rd_addr == id_ex_reg.rs2_addr)) begin
            forward_rs2 = 1'b1;
            forward_rs2_sel = 2'b01;
        end

        // MEM-EX forwarding
        if (mem_wb_reg.reg_write && 
            (mem_wb_reg.rd_addr != 0) && 
            (mem_wb_reg.rd_addr == id_ex_reg.rs1_addr) && 
            !forward_rs1) begin
            forward_rs1 = 1'b1;
            forward_rs1_sel = 2'b10;
        end
        if (mem_wb_reg.reg_write && 
            (mem_wb_reg.rd_addr != 0) && 
            (mem_wb_reg.rd_addr == id_ex_reg.rs2_addr) && 
            !forward_rs2) begin
            forward_rs2 = 1'b1;
            forward_rs2_sel = 2'b10;
        end
    end

    // Branch target calculation
    assign branch_target = id_ex_reg.pc + id_ex_reg.immediate;
    assign branch_taken = id_ex_reg.branch & zero_flag;

    // ALU operand selection with forwarding
    always_comb begin
        case (forward_rs1_sel)
            2'b00: alu_operand_a = id_ex_reg.rs1_data;
            2'b01: alu_operand_a = ex_mem_reg.alu_result;
            2'b10: alu_operand_a = write_data;
            default: alu_operand_a = id_ex_reg.rs1_data;
        endcase

        case (forward_rs2_sel)
            2'b00: alu_operand_b = id_ex_reg.alu_src ? id_ex_reg.immediate : id_ex_reg.rs2_data;
            2'b01: alu_operand_b = id_ex_reg.alu_src ? id_ex_reg.immediate : ex_mem_reg.alu_result;
            2'b10: alu_operand_b = id_ex_reg.alu_src ? id_ex_reg.immediate : write_data;
            default: alu_operand_b = id_ex_reg.alu_src ? id_ex_reg.immediate : id_ex_reg.rs2_data;
        endcase
    end

    // Instruction Fetch Stage
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= '0;
            if_id_reg <= '0;
        end else begin
            if (stall_if) begin
                // Keep current values
            end else if (branch_taken) begin
                pc <= branch_target;
                if_id_reg <= '0; // Flush pipeline on branch
            end else begin
                pc <= pc + 4;
                if_id_reg.instruction <= instruction_in;
                if_id_reg.pc <= pc;
            end
        end
    end

    // Instruction Decode Stage
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            id_ex_reg <= '0;
        end else if (stall_id) begin
            // Keep current values
        end else if (flush_id) begin
            id_ex_reg <= '0;
        end else begin
            id_ex_reg.instruction <= if_id_reg.instruction;
            id_ex_reg.pc <= if_id_reg.pc;
            id_ex_reg.rs1_data <= rs1_data;
            id_ex_reg.rs2_data <= rs2_data;
            id_ex_reg.immediate <= immediate;
            id_ex_reg.reg_write <= reg_write;
            id_ex_reg.mem_read <= mem_read;
            id_ex_reg.mem_write <= mem_write_ctrl;
            id_ex_reg.branch <= branch;
            id_ex_reg.alu_src <= alu_src;
            id_ex_reg.alu_control <= alu_control;
            id_ex_reg.mem_to_reg <= mem_to_reg;
            id_ex_reg.rs1_addr <= if_id_reg.instruction[19:15];
            id_ex_reg.rs2_addr <= if_id_reg.instruction[24:20];
            id_ex_reg.rd_addr <= if_id_reg.instruction[11:7];
        end
    end

    // Execute Stage
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ex_mem_reg <= '0;
        end else if (flush_ex) begin
            ex_mem_reg <= '0;
        end else begin
            ex_mem_reg.instruction <= id_ex_reg.instruction;
            ex_mem_reg.pc <= id_ex_reg.pc;
            ex_mem_reg.alu_result <= alu_result;
            ex_mem_reg.rs2_data <= id_ex_reg.rs2_data;
            ex_mem_reg.reg_write <= id_ex_reg.reg_write;
            ex_mem_reg.mem_read <= id_ex_reg.mem_read;
            ex_mem_reg.mem_write <= id_ex_reg.mem_write;
            ex_mem_reg.mem_to_reg <= id_ex_reg.mem_to_reg;
            ex_mem_reg.rd_addr <= id_ex_reg.rd_addr;
        end
    end

    // Memory alignment check
    always_comb begin
        mem_align_error = 1'b0;
        mem_byte_en = 8'hFF;  // Default: all bytes enabled

        if (ex_mem_reg.mem_read || ex_mem_reg.mem_write) begin
            case (ex_mem_reg.instruction[14:12])  // funct3
                3'b000: begin  // LB/LBU/SB
                    mem_align_type = 2'b00;
                    case (ex_mem_reg.alu_result[2:0])
                        3'b000: mem_byte_en = 8'h01;
                        3'b001: mem_byte_en = 8'h02;
                        3'b010: mem_byte_en = 8'h04;
                        3'b011: mem_byte_en = 8'h08;
                        3'b100: mem_byte_en = 8'h10;
                        3'b101: mem_byte_en = 8'h20;
                        3'b110: mem_byte_en = 8'h40;
                        3'b111: mem_byte_en = 8'h80;
                    endcase
                end
                3'b001: begin  // LH/LHU/SH
                    mem_align_type = 2'b01;
                    if (ex_mem_reg.alu_result[0] != 1'b0) begin
                        mem_align_error = 1'b1;
                    end
                    case (ex_mem_reg.alu_result[2:1])
                        2'b00: mem_byte_en = 8'h03;
                        2'b01: mem_byte_en = 8'h0C;
                        2'b10: mem_byte_en = 8'h30;
                        2'b11: mem_byte_en = 8'hC0;
                    endcase
                end
                3'b010: begin  // LW/LWU/SW
                    mem_align_type = 2'b10;
                    if (ex_mem_reg.alu_result[1:0] != 2'b00) begin
                        mem_align_error = 1'b1;
                    end
                    mem_byte_en = 8'h0F;  // Always use lower word for SW
                end
                3'b011: begin  // LD/SD
                    mem_align_type = 2'b11;
                    if (ex_mem_reg.alu_result[2:0] != 3'b000) begin
                        mem_align_error = 1'b1;
                    end
                    mem_byte_en = 8'hFF;
                end
                default: begin
                    mem_align_error = 1'b1;
                end
            endcase
        end
    end

    // Memory interface
    assign mem_request = ex_mem_reg.mem_read || ex_mem_reg.mem_write;
    assign mem_write = ex_mem_reg.mem_write && !mem_align_error;
    assign mem_addr = ex_mem_reg.alu_result;
    assign mem_data = ex_mem_reg.rs2_data;

    // Memory stage with shared memory interface
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_wb_reg <= '0;
        end else begin
            // Memory read with alignment check
            if (ex_mem_reg.mem_read && !mem_align_error) begin
                logic [DATA_WIDTH-1:0] aligned_data;
                aligned_data = mem_read_data & mem_byte_en;
                
                // Sign extension for load instructions
                case (ex_mem_reg.instruction[14:12])  // funct3
                    3'b000: begin  // LB
                        aligned_data = {{56{aligned_data[7]}}, aligned_data[7:0]};
                    end
                    3'b001: begin  // LH
                        aligned_data = {{48{aligned_data[15]}}, aligned_data[15:0]};
                    end
                    3'b010: begin  // LW
                        aligned_data = {{32{aligned_data[31]}}, aligned_data[31:0]};
                    end
                    default: begin  // LBU, LHU, LWU, LD
                        aligned_data = aligned_data;
                    end
                endcase
                
                mem_wb_reg.mem_data <= aligned_data;
            end else begin
                mem_wb_reg.mem_data <= '0;
            end
            
            mem_wb_reg.instruction <= ex_mem_reg.instruction;
            mem_wb_reg.pc <= ex_mem_reg.pc;
            mem_wb_reg.alu_result <= ex_mem_reg.alu_result;
            mem_wb_reg.reg_write <= ex_mem_reg.reg_write;
            mem_wb_reg.mem_to_reg <= ex_mem_reg.mem_to_reg;
            mem_wb_reg.rd_addr <= ex_mem_reg.rd_addr;
        end
    end

    // Writeback Stage
    always_comb begin
        case (mem_wb_reg.mem_to_reg)
            2'b00: write_data = mem_wb_reg.alu_result;
            2'b01: write_data = mem_wb_reg.mem_data;
            2'b10: write_data = mem_wb_reg.pc + 4;
            default: write_data = mem_wb_reg.alu_result;
        endcase
    end

    // Performance counter update logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            perf_counters <= '0;
        end else begin
            // Cycle counter
            perf_counters.cycles <= perf_counters.cycles + 1;

            // Instruction counter
            if (!stall_if) begin
                perf_counters.instructions <= perf_counters.instructions + 1;
            end

            // Branch counter
            if (id_ex_reg.branch) begin
                perf_counters.branches <= perf_counters.branches + 1;
            end

            // Branch mispredict counter
            if (id_ex_reg.branch && branch_taken) begin
                perf_counters.branch_mispredicts <= perf_counters.branch_mispredicts + 1;
            end

            // Load counter
            if (ex_mem_reg.mem_read) begin
                perf_counters.loads <= perf_counters.loads + 1;
            end

            // Store counter
            if (ex_mem_reg.mem_write) begin
                perf_counters.stores <= perf_counters.stores + 1;
            end

            // Load-use stall counter
            if (stall_if && id_ex_reg.mem_read) begin
                perf_counters.load_use_stalls <= perf_counters.load_use_stalls + 1;
            end

            // Alignment fault counter
            if (mem_align_error) begin
                perf_counters.alignment_faults <= perf_counters.alignment_faults + 1;
            end
        end
    end

    // Core active status
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            core_active <= 1'b0;
        end else begin
            core_active <= 1'b1;  // Core is active when not in reset
        end
    end

    // Output assignments
    assign pc_out = pc;
    assign alu_result_out = alu_result;

endmodule 