module control_unit(
    input  logic [31:0] instruction,
    output logic        reg_write,
    output logic        mem_read,
    output logic        mem_write,
    output logic        branch,
    output logic        alu_src,
    output logic [3:0]  alu_control,
    output logic [1:0]  mem_to_reg,
    output logic        csr_read,
    output logic        csr_write,
    output logic [1:0]  csr_op
);

    // Instruction fields
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;
    
    assign opcode = instruction[6:0];
    assign funct3 = instruction[14:12];
    assign funct7 = instruction[31:25];

    // ALU control values
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_SLL  = 4'b0010;
    localparam ALU_SLT  = 4'b0011;
    localparam ALU_SLTU = 4'b0100;
    localparam ALU_XOR  = 4'b0101;
    localparam ALU_SRL  = 4'b0110;
    localparam ALU_SRA  = 4'b0111;
    localparam ALU_OR   = 4'b1000;
    localparam ALU_AND  = 4'b1001;

    // CSR operation values
    localparam CSR_READ  = 2'b00;
    localparam CSR_WRITE = 2'b01;
    localparam CSR_SET   = 2'b10;
    localparam CSR_CLEAR = 2'b11;

    always_comb begin
        // Default values
        reg_write = 1'b0;
        mem_read = 1'b0;
        mem_write = 1'b0;
        branch = 1'b0;
        alu_src = 1'b0;
        alu_control = ALU_ADD;
        mem_to_reg = 2'b00;
        csr_read = 1'b0;
        csr_write = 1'b0;
        csr_op = CSR_READ;

        unique case (opcode)
            7'b0110011: begin // R-type
                reg_write = 1'b1;
                unique case ({funct7, funct3})
                    10'b0000000_000: alu_control = ALU_ADD;  // ADD
                    10'b0100000_000: alu_control = ALU_SUB;  // SUB
                    10'b0000000_001: alu_control = ALU_SLL;  // SLL
                    10'b0000000_010: alu_control = ALU_SLT;  // SLT
                    10'b0000000_011: alu_control = ALU_SLTU; // SLTU
                    10'b0000000_100: alu_control = ALU_XOR;  // XOR
                    10'b0000000_101: alu_control = ALU_SRL;  // SRL
                    10'b0100000_101: alu_control = ALU_SRA;  // SRA
                    10'b0000000_110: alu_control = ALU_OR;   // OR
                    10'b0000000_111: alu_control = ALU_AND;  // AND
                    default: alu_control = ALU_ADD;
                endcase
            end

            7'b0010011: begin // I-type ALU
                reg_write = 1'b1;
                alu_src = 1'b1;
                unique case (funct3)
                    3'b000: alu_control = ALU_ADD;  // ADDI
                    3'b001: alu_control = ALU_SLL;  // SLLI
                    3'b010: alu_control = ALU_SLT;  // SLTI
                    3'b011: alu_control = ALU_SLTU; // SLTIU
                    3'b100: alu_control = ALU_XOR;  // XORI
                    3'b101: alu_control = (instruction[30] ? ALU_SRA : ALU_SRL); // SRAI/SRLI
                    3'b110: alu_control = ALU_OR;   // ORI
                    3'b111: alu_control = ALU_AND;  // ANDI
                    default: alu_control = ALU_ADD;
                endcase
            end

            7'b0000011: begin // Load
                reg_write = 1'b1;
                mem_read = 1'b1;
                alu_src = 1'b1;
                mem_to_reg = 2'b01;
            end

            7'b0100011: begin // Store
                mem_write = 1'b1;
                alu_src = 1'b1;
            end

            7'b1100011: begin // Branch
                branch = 1'b1;
                unique case (funct3)
                    3'b000: alu_control = ALU_SUB; // BEQ
                    3'b001: alu_control = ALU_SUB; // BNE
                    3'b100: alu_control = ALU_SLT; // BLT
                    3'b101: alu_control = ALU_SLT; // BGE
                    3'b110: alu_control = ALU_SLTU; // BLTU
                    3'b111: alu_control = ALU_SLTU; // BGEU
                    default: alu_control = ALU_SUB;
                endcase
            end

            7'b0110111: begin // LUI
                reg_write = 1'b1;
                alu_src = 1'b1;
                alu_control = ALU_ADD;
            end

            7'b0010111: begin // AUIPC
                reg_write = 1'b1;
                alu_src = 1'b1;
                alu_control = ALU_ADD;
            end

            7'b1101111: begin // JAL
                reg_write = 1'b1;
                mem_to_reg = 2'b10;
            end

            7'b1100111: begin // JALR
                reg_write = 1'b1;
                alu_src = 1'b1;
                mem_to_reg = 2'b10;
            end

            7'b1110011: begin // CSR instructions
                reg_write = 1'b1;
                csr_read = 1'b1;
                csr_write = 1'b1;
                unique case (funct3)
                    3'b001: csr_op = CSR_WRITE; // CSRRW
                    3'b010: csr_op = CSR_SET;   // CSRRS
                    3'b011: csr_op = CSR_CLEAR; // CSRRC
                    3'b101: csr_op = CSR_WRITE; // CSRRWI
                    3'b110: csr_op = CSR_SET;   // CSRRSI
                    3'b111: csr_op = CSR_CLEAR; // CSRRCI
                    default: begin
                        csr_read = 1'b0;
                        csr_write = 1'b0;
                    end
                endcase
            end

            default: begin
                reg_write = 1'b0;
                mem_read = 1'b0;
                mem_write = 1'b0;
                branch = 1'b0;
                alu_src = 1'b0;
                alu_control = ALU_ADD;
                mem_to_reg = 2'b00;
                csr_read = 1'b0;
                csr_write = 1'b0;
                csr_op = CSR_READ;
            end
        endcase
    end

endmodule 