module reset_sync (
    input  logic clk,
    input  logic rst_n,
    output logic rst
);

    logic rst_meta;
    logic rst_sync;

    // First stage - metastability prevention
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rst_meta <= 1'b1;
            rst_sync <= 1'b1;
        end else begin
            rst_meta <= 1'b0;
            rst_sync <= rst_meta;
        end
    end

    assign rst = rst_sync;

endmodule 