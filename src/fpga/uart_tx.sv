module uart_tx #(
    parameter CLK_FREQ = 100_000_000,  // 100 MHz
    parameter BAUD_RATE = 115200
)(
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] data,
    input  logic       valid,
    output logic       ready,
    output logic       tx
);

    // Parameters
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam COUNTER_WIDTH = $clog2(CLKS_PER_BIT);
    
    // States
    typedef enum logic [1:0] {
        IDLE,
        START,
        DATA,
        STOP
    } state_t;
    
    // Internal signals
    state_t state;
    logic [COUNTER_WIDTH-1:0] counter;
    logic [2:0] bit_count;
    logic [7:0] shift_reg;
    
    // State machine
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            counter <= 0;
            bit_count <= 0;
            shift_reg <= 8'h00;
            tx <= 1'b1;
            ready <= 1'b1;
        end else begin
            case (state)
                IDLE: begin
                    if (valid) begin
                        state <= START;
                        counter <= 0;
                        shift_reg <= data;
                        ready <= 1'b0;
                    end
                end
                
                START: begin
                    tx <= 1'b0;
                    if (counter == CLKS_PER_BIT-1) begin
                        state <= DATA;
                        counter <= 0;
                        bit_count <= 0;
                    end else begin
                        counter <= counter + 1;
                    end
                end
                
                DATA: begin
                    tx <= shift_reg[0];
                    if (counter == CLKS_PER_BIT-1) begin
                        counter <= 0;
                        shift_reg <= {1'b0, shift_reg[7:1]};
                        if (bit_count == 7) begin
                            state <= STOP;
                        end else begin
                            bit_count <= bit_count + 1;
                        end
                    end else begin
                        counter <= counter + 1;
                    end
                end
                
                STOP: begin
                    tx <= 1'b1;
                    if (counter == CLKS_PER_BIT-1) begin
                        state <= IDLE;
                        ready <= 1'b1;
                    end else begin
                        counter <= counter + 1;
                    end
                end
            endcase
        end
    end

endmodule 