module immediate_generator(
    input  logic [31:0] instruction,
    output logic [63:0] immediate
);

    // Opcode field
    logic [6:0] opcode;
    assign opcode = instruction[6:0];

    always_comb begin
        immediate = '0; // Default value
        unique case (opcode)
            7'b0010011,  // I-type ALU
            7'b0000011,  // Load
            7'b1100111:  // JALR
                immediate = {{52{instruction[31]}}, instruction[31:20]};

            7'b0100011:  // S-type (Store)
                immediate = {{52{instruction[31]}}, instruction[31:25], instruction[11:7]};

            7'b1100011:  // B-type (Branch)
                immediate = {{52{instruction[31]}}, instruction[7], instruction[30:25], 
                           instruction[11:8], 1'b0};

            7'b0110111,  // U-type (LUI)
            7'b0010111:  // U-type (AUIPC)
                immediate = {{32{instruction[31]}}, instruction[31:12], 12'b0};

            7'b1101111:  // J-type (JAL)
                immediate = {{44{instruction[31]}}, instruction[19:12], instruction[20],
                           instruction[30:21], 1'b0};

            default:
                immediate = '0;
        endcase
    end

endmodule 
