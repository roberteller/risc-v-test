module debug_interface (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] pc,
    input  logic [31:0] instruction,
    input  logic [31:0] debug_data,
    input  logic        debug_valid,
    input  logic [3:0]  btn,
    output logic [7:0]  led,
    output logic [7:0]  an,
    output logic [6:0]  seg,
    output logic        uart_tx,
    input  logic        uart_rx
);

    // Parameters
    localparam CLK_FREQ = 100_000_000;  // 100 MHz
    localparam BAUD_RATE = 115200;
    
    // Internal signals
    logic [31:0] display_data;
    logic [2:0]  display_select;
    logic        uart_ready;
    logic [7:0]  uart_data;
    logic        uart_valid;
    
    // Display selection based on buttons
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            display_select <= 3'b000;
        end else begin
            case (btn)
                4'b0001: display_select <= 3'b000;  // PC
                4'b0010: display_select <= 3'b001;  // Instruction
                4'b0100: display_select <= 3'b010;  // Debug data
                default: display_select <= display_select;
            endcase
        end
    end
    
    // Display data multiplexer
    always_comb begin
        case (display_select)
            3'b000: display_data = pc;
            3'b001: display_data = instruction;
            3'b010: display_data = debug_data;
            default: display_data = 32'h0;
        endcase
    end
    
    // LED display
    assign led = {display_select, debug_valid, 4'b0000};
    
    // 7-segment display controller
    seg7_controller seg7_ctrl (
        .clk(clk),
        .rst(rst),
        .data(display_data),
        .an(an),
        .seg(seg)
    );
    
    // UART transmitter
    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) uart_tx_inst (
        .clk(clk),
        .rst(rst),
        .data(uart_data),
        .valid(uart_valid),
        .ready(uart_ready),
        .tx(uart_tx)
    );
    
    // Debug data transmission
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            uart_valid <= 1'b0;
            uart_data <= 8'h00;
        end else if (debug_valid && uart_ready) begin
            uart_valid <= 1'b1;
            uart_data <= debug_data[7:0];
        end else begin
            uart_valid <= 1'b0;
        end
    end

endmodule 