module alu #(
    parameter DATA_WIDTH = 64
)(
    input  logic [DATA_WIDTH-1:0] operand_a,
    input  logic [DATA_WIDTH-1:0] operand_b,
    input  logic [3:0]           alu_control,
    output logic [DATA_WIDTH-1:0] result,
    output logic                 zero_flag
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

    logic signed [DATA_WIDTH-1:0] signed_a, signed_b;
    logic [5:0] shamt;

    assign signed_a = operand_a;
    assign signed_b = operand_b;
    assign shamt = operand_b[5:0];

    always_comb begin
        case (alu_control)
            ALU_ADD:  result = operand_a + operand_b;
            ALU_SUB:  result = operand_a - operand_b;
            ALU_SLL:  result = operand_a << shamt;
            ALU_SLT:  result = {63'b0, signed_a < signed_b};
            ALU_SLTU: result = {63'b0, operand_a < operand_b};
            ALU_XOR:  result = operand_a ^ operand_b;
            ALU_SRL:  result = operand_a >> shamt;
            ALU_SRA:  result = signed_a >>> shamt;
            ALU_OR:   result = operand_a | operand_b;
            ALU_AND:  result = operand_a & operand_b;
            default:  result = '0;
        endcase
    end

    // Zero flag for branch instructions
    assign zero_flag = (result == '0);

endmodule 