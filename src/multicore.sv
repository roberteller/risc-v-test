module multicore #(
    parameter DATA_WIDTH = 64,
    parameter ADDR_WIDTH = 64,
    parameter MEM_SIZE = 1024,
    parameter NUM_CORES = 4
)(
    input  logic                     clk,
    input  logic                     rst_n,
    output logic [NUM_CORES-1:0]     core_active,
    output logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] pc_out,
    output logic [NUM_CORES-1:0][DATA_WIDTH-1:0] alu_result_out
);

    // Core identification
    logic [NUM_CORES-1:0][2:0] core_id;
    genvar i;
    generate
        for (i = 0; i < NUM_CORES; i++) begin : gen_core_id
            assign core_id[i] = i[2:0];
        end
    endgenerate

    // Instruction memory (separate for each core)
    logic [31:0] instruction_mem [NUM_CORES-1:0][0:MEM_SIZE-1];
    logic [NUM_CORES-1:0][31:0] instruction;

    // Shared data memory system
    logic [DATA_WIDTH-1:0] shared_mem [0:MEM_SIZE-1];
    logic [NUM_CORES-1:0] mem_request;
    logic [NUM_CORES-1:0] mem_write;
    logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] mem_addr;
    logic [NUM_CORES-1:0][DATA_WIDTH-1:0] mem_data;
    logic [NUM_CORES-1:0][DATA_WIDTH-1:0] mem_read_data;

    // Memory arbiter
    logic [1:0] current_core;
    logic mem_busy;
    logic [NUM_CORES-1:0] grant;

    // Round-robin memory arbiter
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_core <= '0;
            mem_busy <= 1'b0;
            grant <= '0;
        end else begin
            if (!mem_busy) begin
                // Priority encoder for next requesting core
                grant <= '0;
                if (mem_request[0]) begin
                    current_core <= 2'd0;
                    grant[0] <= 1'b1;
                    mem_busy <= 1'b1;
                end else if (mem_request[1]) begin
                    current_core <= 2'd1;
                    grant[1] <= 1'b1;
                    mem_busy <= 1'b1;
                end else if (mem_request[2]) begin
                    current_core <= 2'd2;
                    grant[2] <= 1'b1;
                    mem_busy <= 1'b1;
                end else if (mem_request[3]) begin
                    current_core <= 2'd3;
                    grant[3] <= 1'b1;
                    mem_busy <= 1'b1;
                end
            end else begin
                mem_busy <= 1'b0;
                grant <= '0;
            end
        end
    end

    // Memory access logic
    generate
        for (i = 0; i < NUM_CORES; i++) begin : gen_mem_access
            always_ff @(posedge clk) begin
                if (grant[i]) begin
                    if (mem_write[i]) begin
                        shared_mem[mem_addr[i][ADDR_WIDTH-1:3]] <= mem_data[i];
                    end
                    mem_read_data[i] <= shared_mem[mem_addr[i][ADDR_WIDTH-1:3]];
                end
            end
        end
    endgenerate

    // Instruction fetch logic
    generate
        for (i = 0; i < NUM_CORES; i++) begin : gen_instr_fetch
            logic [$clog2(MEM_SIZE)-1:0] instr_addr;
            assign instr_addr = pc_out[i][ADDR_WIDTH-1:2];
            assign instruction[i] = instruction_mem[i][instr_addr];
        end
    endgenerate

    // Core instances
    generate
        for (i = 0; i < NUM_CORES; i++) begin : gen_cores
            riscv_core #(
                .DATA_WIDTH(DATA_WIDTH),
                .ADDR_WIDTH(ADDR_WIDTH),
                .MEM_SIZE(MEM_SIZE)
            ) core (
                .clk(clk),
                .rst_n(rst_n),
                .core_id(core_id[i]),
                .instruction_in(instruction[i]),
                .pc_out(pc_out[i]),
                .alu_result_out(alu_result_out[i]),
                .mem_request(mem_request[i]),
                .mem_write(mem_write[i]),
                .mem_addr(mem_addr[i]),
                .mem_data(mem_data[i]),
                .mem_read_data(mem_read_data[i]),
                .core_active(core_active[i])
            );
        end
    endgenerate

endmodule 