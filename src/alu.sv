module alu #(
    parameter DATA_WIDTH = 64
)(
    input  logic [DATA_WIDTH-1:0] operand_a,
    input  logic [DATA_WIDTH-1:0] operand_b,
    input  logic [3:0]           alu_control,
    input  logic [4:0]           amo_op,         // Atomic operation type
    input  logic                 word_operation, // 1 for 32-bit, 0 for 64-bit
    output logic [DATA_WIDTH-1:0] result,
    output logic                 zero_flag,
    output logic                 less_than_flag,
    output logic                 less_than_unsigned_flag,
    output logic                 overflow_flag
);

    // ALU Control Signals
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

    // AMO Operation Types
    localparam AMO_SWAP = 5'b00001;
    localparam AMO_ADD  = 5'b00000;
    localparam AMO_XOR  = 5'b00100;
    localparam AMO_AND  = 5'b01100;
    localparam AMO_OR   = 5'b01000;
    localparam AMO_MIN  = 5'b10000;
    localparam AMO_MAX  = 5'b10100;
    localparam AMO_MINU = 5'b11000;
    localparam AMO_MAXU = 5'b11100;

    logic signed [DATA_WIDTH-1:0] signed_a, signed_b;
    logic [5:0] shamt;
    logic [DATA_WIDTH-1:0] add_result;
    logic [DATA_WIDTH-1:0] sub_result;
    logic [DATA_WIDTH-1:0] amo_result;
    logic [31:0] word_a, word_b;
    logic [31:0] word_result;

    assign signed_a = operand_a;
    assign signed_b = operand_b;
    assign shamt = operand_b[5:0];
    
    // Sign-extended 32-bit words for RV64 W-instructions
    assign word_a = operand_a[31:0];
    assign word_b = operand_b[31:0];
    
    // Addition and subtraction results
    assign add_result = operand_a + operand_b;
    assign sub_result = operand_a - operand_b;

    // Flag generation
    assign zero_flag = (result == '0);
    assign less_than_flag = signed_a < signed_b;
    assign less_than_unsigned_flag = operand_a < operand_b;
    // Detect overflow in addition/subtraction
    assign overflow_flag = (alu_control == ALU_ADD) ? 
        ((operand_a[DATA_WIDTH-1] == operand_b[DATA_WIDTH-1]) && (result[DATA_WIDTH-1] != operand_a[DATA_WIDTH-1])) :
        ((alu_control == ALU_SUB) ? 
            ((operand_a[DATA_WIDTH-1] != operand_b[DATA_WIDTH-1]) && (result[DATA_WIDTH-1] != operand_a[DATA_WIDTH-1])) : 
            1'b0);

    // Atomic memory operation logic
    always_comb begin
        amo_result = '0;
        case (amo_op)
            AMO_SWAP: amo_result = operand_b;
            AMO_ADD:  amo_result = operand_a + operand_b;
            AMO_XOR:  amo_result = operand_a ^ operand_b;
            AMO_AND:  amo_result = operand_a & operand_b;
            AMO_OR:   amo_result = operand_a | operand_b;
            AMO_MIN:  amo_result = signed_a < signed_b ? operand_a : operand_b;
            AMO_MAX:  amo_result = signed_a > signed_b ? operand_a : operand_b;
            AMO_MINU: amo_result = operand_a < operand_b ? operand_a : operand_b;
            AMO_MAXU: amo_result = operand_a > operand_b ? operand_a : operand_b;
            default:  amo_result = operand_a;
        endcase
    end

    // Main ALU operation
    always_comb begin
        result = '0;
        if (word_operation) begin
            // 32-bit operations with sign extension for RV64
            case (alu_control)
                ALU_ADD:  result = {{32{add_result[31]}}, add_result[31:0]};
                ALU_SUB:  result = {{32{sub_result[31]}}, sub_result[31:0]};
                ALU_SLL:  result = {{32{1'b0}}, word_a << word_b[4:0]};
                ALU_SLT:  result = {63'b0, $signed(word_a) < $signed(word_b)};
                ALU_SLTU: result = {63'b0, word_a < word_b};
                ALU_XOR:  result = {{32{1'b0}}, word_a ^ word_b};
                ALU_SRL:  result = {{32{1'b0}}, word_a >> word_b[4:0]};
                ALU_SRA:  result = {{32{1'b0}}, $signed(word_a) >>> word_b[4:0]};
                ALU_OR:   result = {{32{1'b0}}, word_a | word_b};
                ALU_AND:  result = {{32{1'b0}}, word_a & word_b};
                ALU_MIN:  result = {{32{1'b0}}, $signed(word_a) < $signed(word_b) ? word_a : word_b};
                ALU_MAX:  result = {{32{1'b0}}, $signed(word_a) > $signed(word_b) ? word_a : word_b};
                ALU_AMO:  result = {{32{amo_result[31]}}, amo_result[31:0]};
                default:  result = {{32{add_result[31]}}, add_result[31:0]};
            endcase
        end else begin
            // Full 64-bit operations
            case (alu_control)
                ALU_ADD:  result = add_result;
                ALU_SUB:  result = sub_result;
                ALU_SLL:  result = operand_a << shamt;
                ALU_SLT:  result = {63'b0, signed_a < signed_b};
                ALU_SLTU: result = {63'b0, operand_a < operand_b};
                ALU_XOR:  result = operand_a ^ operand_b;
                ALU_SRL:  result = operand_a >> shamt;
                ALU_SRA:  result = signed_a >>> shamt;
                ALU_OR:   result = operand_a | operand_b;
                ALU_AND:  result = operand_a & operand_b;
                ALU_MIN:  result = signed_a < signed_b ? operand_a : operand_b;
                ALU_MAX:  result = signed_a > signed_b ? operand_a : operand_b;
                ALU_LR:   result = operand_a;  // Just pass address for LR
                ALU_SC:   result = operand_a;  // Address for SC
                ALU_AMO:  result = amo_result;
                default:  result = operand_a + operand_b;
            endcase
        end
    end

endmodule 
