module control_unit (
    input  logic [31:0]             instruction,
    input  logic                    zero_flag,
    input  logic                    carry_flag,
    input  logic                    overflow_flag,
    input  logic [1:0]              current_privilege,
    
    // ALU control
    output logic [3:0]              alu_operation,
    output logic [1:0]              alu_operand_b_sel,
    
    // Register file control
    output logic                    reg_write,
    output logic [1:0]              reg_write_sel,
    
    // Memory control
    output logic                    mem_read,
    output logic                    mem_write,
    output logic [1:0]              mem_access_type,  // 00: byte, 01: half, 10: word
    
    // Branch and jump control
    output logic                    branch,
    output logic                    jump,
    
    // CSR control
    output logic                    csr_access,
    output logic [1:0]              csr_operation,    // 00: read, 01: write, 10: set, 11: clear
    output logic                    illegal_instruction,
    
    // Privilege control
    output logic                    privilege_change,
    output logic [1:0]              next_privilege
);

    // Instruction fields
    logic [6:0]  opcode;
    logic [2:0]  funct3;
    logic [6:0]  funct7;
    logic [11:0] csr_addr;
    
    assign opcode = instruction[6:0];
    assign funct3 = instruction[14:12];
    assign funct7 = instruction[31:25];
    assign csr_addr = instruction[31:20];
    
    // Decode instruction
    always_comb begin
        // Default values
        alu_operation = 4'b0000;
        alu_operand_b_sel = 2'b00;
        reg_write = 1'b0;
        reg_write_sel = 2'b00;
        mem_read = 1'b0;
        mem_write = 1'b0;
        mem_access_type = 2'b10;  // Default to word
        branch = 1'b0;
        jump = 1'b0;
        csr_access = 1'b0;
        csr_operation = 2'b00;
        illegal_instruction = 1'b0;
        privilege_change = 1'b0;
        next_privilege = current_privilege;
        
        case (opcode)
            // R-type instructions
            7'b0110011: begin
                reg_write = 1'b1;
                alu_operand_b_sel = 2'b00;  // Use rs2
                case (funct3)
                    3'b000: alu_operation = funct7[5] ? 4'b0001 : 4'b0000;  // ADD/SUB
                    3'b001: alu_operation = 4'b0010;  // SLL
                    3'b010: alu_operation = 4'b0011;  // SLT
                    3'b011: alu_operation = 4'b0100;  // SLTU
                    3'b100: alu_operation = 4'b0101;  // XOR
                    3'b101: alu_operation = funct7[5] ? 4'b0111 : 4'b0110;  // SRL/SRA
                    3'b110: alu_operation = 4'b1000;  // OR
                    3'b111: alu_operation = 4'b1001;  // AND
                endcase
            end
            
            // I-type instructions
            7'b0010011: begin
                reg_write = 1'b1;
                alu_operand_b_sel = 2'b01;  // Use immediate
                case (funct3)
                    3'b000: alu_operation = 4'b0000;  // ADDI
                    3'b001: alu_operation = 4'b0010;  // SLLI
                    3'b010: alu_operation = 4'b0011;  // SLTI
                    3'b011: alu_operation = 4'b0100;  // SLTIU
                    3'b100: alu_operation = 4'b0101;  // XORI
                    3'b101: alu_operation = funct7[5] ? 4'b0111 : 4'b0110;  // SRLI/SRAI
                    3'b110: alu_operation = 4'b1000;  // ORI
                    3'b111: alu_operation = 4'b1001;  // ANDI
                endcase
            end
            
            // Load instructions
            7'b0000011: begin
                reg_write = 1'b1;
                mem_read = 1'b1;
                alu_operand_b_sel = 2'b01;  // Use immediate
                alu_operation = 4'b0000;    // ADD for address calculation
                case (funct3)
                    3'b000: mem_access_type = 2'b00;  // LB
                    3'b001: mem_access_type = 2'b01;  // LH
                    3'b010: mem_access_type = 2'b10;  // LW
                    3'b100: mem_access_type = 2'b00;  // LBU
                    3'b101: mem_access_type = 2'b01;  // LHU
                    default: illegal_instruction = 1'b1;
                endcase
            end
            
            // Store instructions
            7'b0100011: begin
                mem_write = 1'b1;
                alu_operand_b_sel = 2'b01;  // Use immediate
                alu_operation = 4'b0000;    // ADD for address calculation
                case (funct3)
                    3'b000: mem_access_type = 2'b00;  // SB
                    3'b001: mem_access_type = 2'b01;  // SH
                    3'b010: mem_access_type = 2'b10;  // SW
                    default: illegal_instruction = 1'b1;
                endcase
            end
            
            // Branch instructions
            7'b1100011: begin
                branch = 1'b1;
                alu_operand_b_sel = 2'b00;  // Use rs2
                case (funct3)
                    3'b000: alu_operation = 4'b1010;  // BEQ
                    3'b001: alu_operation = 4'b1011;  // BNE
                    3'b100: alu_operation = 4'b1100;  // BLT
                    3'b101: alu_operation = 4'b1101;  // BGE
                    3'b110: alu_operation = 4'b1110;  // BLTU
                    3'b111: alu_operation = 4'b1111;  // BGEU
                endcase
            end
            
            // Jump and link
            7'b1101111: begin  // JAL
                reg_write = 1'b1;
                jump = 1'b1;
                reg_write_sel = 2'b01;  // Write PC+4
            end
            
            7'b1100111: begin  // JALR
                reg_write = 1'b1;
                jump = 1'b1;
                reg_write_sel = 2'b01;  // Write PC+4
                alu_operand_b_sel = 2'b01;  // Use immediate
                alu_operation = 4'b0000;    // ADD for target calculation
            end
            
            // CSR instructions
            7'b1110011: begin
                case (funct3)
                    3'b001: begin  // CSRRW
                        csr_access = 1'b1;
                        csr_operation = 2'b01;  // Write
                        reg_write = 1'b1;
                    end
                    3'b010: begin  // CSRRS
                        csr_access = 1'b1;
                        csr_operation = 2'b10;  // Set
                        reg_write = 1'b1;
                    end
                    3'b011: begin  // CSRRC
                        csr_access = 1'b1;
                        csr_operation = 2'b11;  // Clear
                        reg_write = 1'b1;
                    end
                    3'b101: begin  // CSRRWI
                        csr_access = 1'b1;
                        csr_operation = 2'b01;  // Write
                        reg_write = 1'b1;
                    end
                    3'b110: begin  // CSRRSI
                        csr_access = 1'b1;
                        csr_operation = 2'b10;  // Set
                        reg_write = 1'b1;
                    end
                    3'b111: begin  // CSRRCI
                        csr_access = 1'b1;
                        csr_operation = 2'b11;  // Clear
                        reg_write = 1'b1;
                    end
                    default: illegal_instruction = 1'b1;
                endcase
                
                // Check CSR access permissions
                if (csr_access) begin
                    case (csr_addr[11:10])
                        2'b00: begin  // User CSRs
                            if (current_privilege < 2'b00) illegal_instruction = 1'b1;
                        end
                        2'b01: begin  // Supervisor CSRs
                            if (current_privilege < 2'b01) illegal_instruction = 1'b1;
                        end
                        2'b11: begin  // Machine CSRs
                            if (current_privilege < 2'b11) illegal_instruction = 1'b1;
                        end
                    endcase
                end
            end
            
            // Environment call and breakpoint
            7'b1110011: begin
                if (funct3 == 3'b000) begin
                    case (instruction[31:20])
                        12'h000: begin  // ECALL
                            privilege_change = 1'b1;
                            next_privilege = 2'b11;  // Enter M-mode
                        end
                        12'h001: begin  // EBREAK
                            // Handle breakpoint
                        end
                        default: illegal_instruction = 1'b1;
                    endcase
                end
            end
            
            default: illegal_instruction = 1'b1;
        endcase
    end
    
endmodule 