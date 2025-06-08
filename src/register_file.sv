module register_file #(
    parameter DATA_WIDTH = 64,
    parameter ADDR_WIDTH = 5  // 5 bits for 32 registers
)(
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic                    write_enable,
    input  logic [ADDR_WIDTH-1:0]   write_addr,
    input  logic [DATA_WIDTH-1:0]   write_data,
    input  logic [ADDR_WIDTH-1:0]   read_addr_1,
    input  logic [ADDR_WIDTH-1:0]   read_addr_2,
    output logic [DATA_WIDTH-1:0]   read_data_1,
    output logic [DATA_WIDTH-1:0]   read_data_2
);

    // Register file with 32 64-bit registers
    logic [DATA_WIDTH-1:0] registers [2**ADDR_WIDTH-1:0];

    // Asynchronous read
    assign read_data_1 = (read_addr_1 == '0) ? '0 : registers[read_addr_1];
    assign read_data_2 = (read_addr_2 == '0) ? '0 : registers[read_addr_2];

    // Synchronous write
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all registers to 0
            for (int i = 0; i < 2**ADDR_WIDTH; i++) begin
                registers[i] <= '0;
            end
        end else if (write_enable && write_addr != '0) begin
            // x0 is hardwired to 0, cannot be written
            registers[write_addr] <= write_data;
        end
    end

endmodule 
