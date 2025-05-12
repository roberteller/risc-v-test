module memory_controller #(
    parameter MEM_SIZE = 1024*1024  // 1MB memory
)(
    input  logic        clk,
    input  logic        rst,
    input  logic        read,
    input  logic        write,
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    output logic [31:0] rdata,
    output logic        ready
);

    // Memory array
    logic [31:0] memory [0:MEM_SIZE/4-1];
    
    // Address translation
    logic [31:0] word_addr;
    assign word_addr = addr >> 2;  // Convert byte address to word address
    
    // Read operation
    always_ff @(posedge clk) begin
        if (read && word_addr < MEM_SIZE/4) begin
            rdata <= memory[word_addr];
        end else begin
            rdata <= 32'h0;
        end
    end
    
    // Write operation
    always_ff @(posedge clk) begin
        if (write && word_addr < MEM_SIZE/4) begin
            memory[word_addr] <= wdata;
        end
    end
    
    // Ready signal generation
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            ready <= 1'b0;
        end else begin
            ready <= read | write;
        end
    end

endmodule 