module seg7_controller (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] data,
    output logic [7:0]  an,
    output logic [6:0]  seg
);

    // Parameters
    localparam REFRESH_RATE = 1000;  // 1kHz refresh rate
    localparam COUNTER_WIDTH = $clog2(REFRESH_RATE);
    
    // Internal signals
    logic [COUNTER_WIDTH-1:0] counter;
    logic [2:0] digit_select;
    logic [3:0] digit_data;
    
    // Counter for refresh rate
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 0;
        end else if (counter == REFRESH_RATE-1) begin
            counter <= 0;
        end else begin
            counter <= counter + 1;
        end
    end
    
    // Digit selection
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            digit_select <= 0;
        end else if (counter == REFRESH_RATE-1) begin
            digit_select <= digit_select + 1;
        end
    end
    
    // Digit data multiplexer
    always_comb begin
        case (digit_select)
            3'b000: digit_data = data[3:0];
            3'b001: digit_data = data[7:4];
            3'b010: digit_data = data[11:8];
            3'b011: digit_data = data[15:12];
            3'b100: digit_data = data[19:16];
            3'b101: digit_data = data[23:20];
            3'b110: digit_data = data[27:24];
            3'b111: digit_data = data[31:28];
        endcase
    end
    
    // Anode selection
    always_comb begin
        an = 8'b11111111;
        an[digit_select] = 1'b0;
    end
    
    // 7-segment decoder
    always_comb begin
        case (digit_data)
            4'h0: seg = 7'b1000000;  // 0
            4'h1: seg = 7'b1111001;  // 1
            4'h2: seg = 7'b0100100;  // 2
            4'h3: seg = 7'b0110000;  // 3
            4'h4: seg = 7'b0011001;  // 4
            4'h5: seg = 7'b0010010;  // 5
            4'h6: seg = 7'b0000010;  // 6
            4'h7: seg = 7'b1111000;  // 7
            4'h8: seg = 7'b0000000;  // 8
            4'h9: seg = 7'b0010000;  // 9
            4'hA: seg = 7'b0001000;  // A
            4'hB: seg = 7'b0000011;  // B
            4'hC: seg = 7'b1000110;  // C
            4'hD: seg = 7'b0100001;  // D
            4'hE: seg = 7'b0000110;  // E
            4'hF: seg = 7'b0001110;  // F
            default: seg = 7'b1111111;  // All segments off
        endcase
    end

endmodule 