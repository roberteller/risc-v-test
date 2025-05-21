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
    output logic [1:0]  csr_op,
    output logic        is_fence,
    output logic        is_ecall,
    output logic        is_ebreak,
    output logic        is_mret,
    output logic        is_atomic
);

    // Instruction fields
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic [4:0] rs1, rs2, rd;
    
    assign opcode = instruction[6:0];
    assign funct3 = instruction[14:12];
    assign funct7 = instruction[31:25];
    assign rs1 = instruction[19:15];
    assign rs2 = instruction[24:20];
    assign rd = instruction[11:7];

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
    localparam ALU_MIN  = 4'b1010;
    localparam ALU_MAX  = 4'b1011;
    localparam ALU_LR   = 4'b1100;
    localparam ALU_SC   = 4'b1101;
    localparam ALU_AMO  = 4'b1110;

    // CSR operation values
    localparam CSR_READ  = 2'b00;
    localparam CSR_WRITE = 2'b01;
    localparam CSR_SET   = 2'b10;
    localparam CSR_CLEAR = 2'b11;

    // Atomic operation types
    localparam AMO_SWAP = 3'b000;
    localparam AMO_ADD  = 3'b001;
    localparam AMO_XOR  = 3'b010;
    localparam AMO_AND  = 3'b011;
    localparam AMO_OR   = 3'b100;
    localparam AMO_MIN  = 3'b101;
    localparam AMO_MAX  = 3'b110;
    localparam AMO_MINU = 3'b111;
    localparam AMO_MAXU = 3'b111;

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
        is_fence = 1'b0;
        is_ecall = 1'b0;
        is_ebreak = 1'b0;
        is_mret = 1'b0;
        is_atomic = 1'b0;

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
                    // RV64M extension - Multiply/Divide
                    10'b0000001_000: alu_control = ALU_ADD;  // MUL (needs special handling)
                    10'b0000001_001: alu_control = ALU_ADD;  // MULH
                    10'b0000001_010: alu_control = ALU_ADD;  // MULHSU
                    10'b0000001_011: alu_control = ALU_ADD;  // MULHU
                    10'b0000001_100: alu_control = ALU_ADD;  // DIV
                    10'b0000001_101: alu_control = ALU_ADD;  // DIVU
                    10'b0000001_110: alu_control = ALU_ADD;  // REM
                    10'b0000001_111: alu_control = ALU_ADD;  // REMU
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

            7'b1110011: begin // System instructions
                if (funct3 == 3'b000) begin
                    case (instruction[31:20])
                        12'b0000_0000_0000: is_ecall = 1'b1;  // ECALL
                        12'b0000_0000_0001: is_ebreak = 1'b1; // EBREAK
                        12'b0011_0000_0010: is_mret = 1'b1;   // MRET
                        default: begin
                            // Illegal instruction, handle in exception detection
                        end
                    endcase
                end else begin
                    // CSR instructions
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
            end

            7'b0001111: begin // FENCE instructions
                case (funct3)
                    3'b000: is_fence = 1'b1;  // FENCE
                    3'b001: is_fence = 1'b1;  // FENCE.I
                    default: begin
                        // Illegal instruction, handle in exception detection
                    end
                endcase
            end

            7'b0101111: begin // Atomic operations (RV64A)
                is_atomic = 1'b1;
                reg_write = 1'b1;
                case (funct3)
                    3'b010: begin // 32-bit atomic
                        case (funct7[6:2])
                            5'b00010: begin // LR.W
                                mem_read = 1'b1;
                                alu_control = ALU_LR;
                                mem_to_reg = 2'b01;
                            end
                            5'b00011: begin // SC.W
                                mem_write = 1'b1;
                                alu_control = ALU_SC;
                            end
                            5'b00001: begin // AMOSWAP.W
                                mem_read = 1'b1;
                                mem_write = 1'b1;
                                alu_control = ALU_AMO;
                                mem_to_reg = 2'b01;
                            end
                            5'b00000: begin // AMOADD.W
                                mem_read = 1'b1;
                                mem_write = 1'b1;
                                alu_control = ALU_AMO;
                                mem_to_reg = 2'b01;
                            end
                            5'b00100: begin // AMOXOR.W
                                mem_read = 1'b1;
                                mem_write = 1'b1;
                                alu_control = ALU_AMO;
                                mem_to_reg = 2'b01;
                            end
                            5'b01100: begin // AMOAND.W
                                mem_read = 1'b1;
                                mem_write = 1'b1;
                                alu_control = ALU_AMO;
                                mem_to_reg = 2'b01;
                            end
                            5'b01000: begin // AMOOR.W
                                mem_read = 1'b1;
                                mem_write = 1'b1;
                                alu_control = ALU_AMO;
                                mem_to_reg = 2'b01;
                            end
                            5'b10000: begin // AMOMIN.W
                                mem_read = 1'b1;
                                mem_write = 1'b1;
                                alu_control = ALU_AMO;
                                mem_to_reg = 2'b01;
                            end
                            5'b10100: begin // AMOMAX.W
                                mem_read = 1'b1;
                                mem_write = 1'b1;
                                alu_control = ALU_AMO;
                                mem_to_reg = 2'b01;
                            end
                            5'b11000: begin // AMOMINU.W
                                mem_read = 1'b1;
                                mem_write = 1'b1;
                                alu_control = ALU_AMO;
                                mem_to_reg = 2'b01;
                            end
                            5'b11100: begin // AMOMAXU.W
                                mem_read = 1'b1;
                                mem_write = 1'b1;
                                alu_control = ALU_AMO;
                                mem_to_reg = 2'b01;
                            end
                            default: begin
                                // Illegal instruction, handle in exception detection
                            end
                        endcase
                    end
                    3'b011: begin // 64-bit atomic (same operations but for 64-bit)
                        case (funct7[6:2])
                            5'b00010: begin // LR.D
                                mem_read = 1'b1;
                                alu_control = ALU_LR;
                                mem_to_reg = 2'b01;
                            end
                            5'b00011: begin // SC.D
                                mem_write = 1'b1;
                                alu_control = ALU_SC;
                            end
                            5'b00001: begin // AMOSWAP.D
                                mem_read = 1'b1;
                                mem_write = 1'b1;
                                alu_control = ALU_AMO;
                                mem_to_reg = 2'b01;
                            end
                            5'b00000: begin // AMOADD.D
                                mem_read = 1'b1;
                                mem_write = 1'b1;
                                alu_control = ALU_AMO;
                                mem_to_reg = 2'b01;
                            end
                            5'b00100: begin // AMOXOR.D
                                mem_read = 1'b1;
                                mem_write = 1'b1;
                                alu_control = ALU_AMO;
                                mem_to_reg = 2'b01;
                            end
                            5'b01100: begin // AMOAND.D
                                mem_read = 1'b1;
                                mem_write = 1'b1;
                                alu_control = ALU_AMO;
                                mem_to_reg = 2'b01;
                            end
                            5'b01000: begin // AMOOR.D
                                mem_read = 1'b1;
                                mem_write = 1'b1;
                                alu_control = ALU_AMO;
                                mem_to_reg = 2'b01;
                            end
                            5'b10000: begin // AMOMIN.D
                                mem_read = 1'b1;
                                mem_write = 1'b1;
                                alu_control = ALU_AMO;
                                mem_to_reg = 2'b01;
                            end
                            5'b10100: begin // AMOMAX.D
                                mem_read = 1'b1;
                                mem_write = 1'b1;
                                alu_control = ALU_AMO;
                                mem_to_reg = 2'b01;
                            end
                            5'b11000: begin // AMOMINU.D
                                mem_read = 1'b1;
                                mem_write = 1'b1;
                                alu_control = ALU_AMO;
                                mem_to_reg = 2'b01;
                            end
                            5'b11100: begin // AMOMAXU.D
                                mem_read = 1'b1;
                                mem_write = 1'b1;
                                alu_control = ALU_AMO;
                                mem_to_reg = 2'b01;
                            end
                            default: begin
                                // Illegal instruction, handle in exception detection
                            end
                        endcase
                    end
                    default: begin
                        // Illegal instruction, handle in exception detection
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
                is_fence = 1'b0;
                is_ecall = 1'b0;
                is_ebreak = 1'b0;
                is_mret = 1'b0;
                is_atomic = 1'b0;
            end
        endcase
    end

endmodule 