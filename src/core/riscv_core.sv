module riscv_core #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter REG_WIDTH = 5,
    parameter CSR_WIDTH = 12,
    parameter TLB_ENTRIES = 16
)(
    input  logic                    clk,
    input  logic                    rst_n,
    
    // Memory Interface
    output logic [ADDR_WIDTH-1:0]   mem_addr,
    output logic [DATA_WIDTH-1:0]   mem_wdata,
    output logic                    mem_we,
    output logic [3:0]              mem_be,
    input  logic [DATA_WIDTH-1:0]   mem_rdata,
    output logic                    mem_req,
    input  logic                    mem_ack,
    
    // Interrupt Interface
    input  logic                    m_ext_irq,
    input  logic                    s_ext_irq,
    input  logic                    m_timer_irq,
    input  logic                    m_soft_irq,
    
    // Debug Interface
    output logic [DATA_WIDTH-1:0]   pc,
    output logic [DATA_WIDTH-1:0]   instruction,
    output logic                    trap,
    output logic [3:0]              trap_cause
);

    // Internal signals
    logic [DATA_WIDTH-1:0]          pc_next;
    logic [DATA_WIDTH-1:0]          pc_plus_4;
    logic [DATA_WIDTH-1:0]          instruction_decoded;
    logic [DATA_WIDTH-1:0]          rs1_data;
    logic [DATA_WIDTH-1:0]          rs2_data;
    logic [DATA_WIDTH-1:0]          alu_result;
    logic [DATA_WIDTH-1:0]          csr_data;
    logic [DATA_WIDTH-1:0]          imm;
    logic [DATA_WIDTH-1:0]          branch_target;
    logic                           branch_taken;
    logic                           mem_access;
    logic                           csr_access;
    logic                           illegal_instruction;
    
    // Privilege level signals
    logic [1:0]                     current_privilege;
    logic [1:0]                     next_privilege;
    logic                           privilege_change;
    
    // MMU signals
    logic [ADDR_WIDTH-1:0]          virt_addr;
    logic [ADDR_WIDTH-1:0]          phys_addr;
    logic                           tlb_hit;
    logic                           tlb_miss;
    logic                           page_fault;
    logic [1:0]                     access_type;  // 00: instr, 01: load, 10: store
    
    // CSR signals
    logic [CSR_WIDTH-1:0]           csr_addr;
    logic [DATA_WIDTH-1:0]          csr_wdata;
    logic                           csr_we;
    logic                           csr_re;
    
    // Instantiate modules
    register_file #(
        .DATA_WIDTH(DATA_WIDTH),
        .REG_WIDTH(REG_WIDTH)
    ) reg_file (
        .clk(clk),
        .rst_n(rst_n),
        .rs1_addr(instruction_decoded[19:15]),
        .rs2_addr(instruction_decoded[24:20]),
        .rd_addr(instruction_decoded[11:7]),
        .rd_data(alu_result),
        .rd_we(reg_write),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );
    
    alu #(
        .DATA_WIDTH(DATA_WIDTH)
    ) alu_inst (
        .operand_a(rs1_data),
        .operand_b(alu_operand_b),
        .operation(alu_operation),
        .result(alu_result),
        .zero(zero_flag),
        .carry(carry_flag),
        .overflow(overflow_flag)
    );
    
    control_unit control_inst (
        .instruction(instruction_decoded),
        .zero_flag(zero_flag),
        .carry_flag(carry_flag),
        .overflow_flag(overflow_flag),
        .current_privilege(current_privilege),
        .alu_operation(alu_operation),
        .alu_operand_b_sel(alu_operand_b_sel),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .branch(branch),
        .jump(jump),
        .csr_access(csr_access),
        .csr_operation(csr_operation),
        .illegal_instruction(illegal_instruction),
        .privilege_change(privilege_change),
        .next_privilege(next_privilege)
    );
    
    immediate_generator imm_gen (
        .instruction(instruction_decoded),
        .immediate(imm)
    );
    
    mmu #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .TLB_ENTRIES(TLB_ENTRIES)
    ) mmu_inst (
        .clk(clk),
        .rst_n(rst_n),
        .virt_addr(virt_addr),
        .access_type(access_type),
        .current_privilege(current_privilege),
        .satp(satp),
        .phys_addr(phys_addr),
        .tlb_hit(tlb_hit),
        .tlb_miss(tlb_miss),
        .page_fault(page_fault)
    );
    
    csr_file #(
        .DATA_WIDTH(DATA_WIDTH),
        .CSR_WIDTH(CSR_WIDTH)
    ) csr_inst (
        .clk(clk),
        .rst_n(rst_n),
        .addr(csr_addr),
        .wdata(csr_wdata),
        .we(csr_we),
        .re(csr_re),
        .rdata(csr_data),
        .m_ext_irq(m_ext_irq),
        .s_ext_irq(s_ext_irq),
        .m_timer_irq(m_timer_irq),
        .m_soft_irq(m_soft_irq),
        .current_privilege(current_privilege),
        .trap(trap),
        .trap_cause(trap_cause)
    );
    
    // Main control logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 'h80000000;  // Reset vector
            current_privilege <= 2'b11;  // Start in Machine mode
        end else begin
            if (trap) begin
                pc <= csr_data;  // Trap vector
                current_privilege <= next_privilege;
            end else if (branch_taken) begin
                pc <= branch_target;
            end else begin
                pc <= pc_plus_4;
            end
        end
    end
    
    // Memory access control
    always_comb begin
        mem_addr = phys_addr;
        mem_wdata = rs2_data;
        mem_we = mem_write;
        mem_be = 4'b1111;  // Default to word access
        mem_req = mem_read | mem_write;
        
        // Handle byte/halfword accesses
        case (instruction_decoded[13:12])
            2'b00: mem_be = 4'b0001;  // Byte
            2'b01: mem_be = 4'b0011;  // Halfword
            2'b10: mem_be = 4'b1111;  // Word
            default: mem_be = 4'b1111;
        endcase
    end
    
    // Debug outputs
    assign pc = pc;
    assign instruction = instruction_decoded;
    
endmodule 