module csr #(
    parameter DATA_WIDTH = 64
)(
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic [11:0]            csr_addr,
    input  logic [DATA_WIDTH-1:0]   csr_write_data,
    input  logic [1:0]             csr_op,  // 00: read, 01: write, 10: set, 11: clear
    output logic [DATA_WIDTH-1:0]   csr_read_data,
    output logic                    csr_error,
    
    // Performance counter inputs
    input  logic [63:0]            cycles,
    input  logic [63:0]            instructions,
    input  logic [63:0]            branches,
    input  logic [63:0]            branch_mispredicts,
    input  logic [63:0]            loads,
    input  logic [63:0]            stores,
    input  logic [63:0]            load_use_stalls,
    input  logic [63:0]            alignment_faults
);

    // CSR addresses
    localparam CSR_CYCLE     = 12'hC00;
    localparam CSR_TIME      = 12'hC01;
    localparam CSR_INSTRET   = 12'hC02;
    localparam CSR_CYCLEH    = 12'hC80;
    localparam CSR_TIMEH     = 12'hC81;
    localparam CSR_INSTRETH  = 12'hC82;
    
    // Performance counters
    localparam CSR_MHPMCOUNTER3  = 12'hB03;  // Branches
    localparam CSR_MHPMCOUNTER4  = 12'hB04;  // Branch mispredicts
    localparam CSR_MHPMCOUNTER5  = 12'hB05;  // Loads
    localparam CSR_MHPMCOUNTER6  = 12'hB06;  // Stores
    localparam CSR_MHPMCOUNTER7  = 12'hB07;  // Load-use stalls
    localparam CSR_MHPMCOUNTER8  = 12'hB08;  // Alignment faults

    // CSR registers
    logic [DATA_WIDTH-1:0] cycle_reg;
    logic [DATA_WIDTH-1:0] time_reg;
    logic [DATA_WIDTH-1:0] instret_reg;
    logic [DATA_WIDTH-1:0] mhpmcounter3_reg;
    logic [DATA_WIDTH-1:0] mhpmcounter4_reg;
    logic [DATA_WIDTH-1:0] mhpmcounter5_reg;
    logic [DATA_WIDTH-1:0] mhpmcounter6_reg;
    logic [DATA_WIDTH-1:0] mhpmcounter7_reg;
    logic [DATA_WIDTH-1:0] mhpmcounter8_reg;

    // CSR write logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_reg <= '0;
            time_reg <= '0;
            instret_reg <= '0;
            mhpmcounter3_reg <= '0;
            mhpmcounter4_reg <= '0;
            mhpmcounter5_reg <= '0;
            mhpmcounter6_reg <= '0;
            mhpmcounter7_reg <= '0;
            mhpmcounter8_reg <= '0;
        end else begin
            // Update performance counters
            cycle_reg <= cycles;
            time_reg <= $time;
            instret_reg <= instructions;
            mhpmcounter3_reg <= branches;
            mhpmcounter4_reg <= branch_mispredicts;
            mhpmcounter5_reg <= loads;
            mhpmcounter6_reg <= stores;
            mhpmcounter7_reg <= load_use_stalls;
            mhpmcounter8_reg <= alignment_faults;

            // CSR write operations
            if (csr_op != 2'b00) begin  // Not a read operation
                case (csr_addr)
                    CSR_CYCLE: begin
                        case (csr_op)
                            2'b01: cycle_reg <= csr_write_data;  // Write
                            2'b10: cycle_reg <= cycle_reg | csr_write_data;  // Set
                            2'b11: cycle_reg <= cycle_reg & ~csr_write_data;  // Clear
                        endcase
                    end
                    CSR_TIME: begin
                        case (csr_op)
                            2'b01: time_reg <= csr_write_data;
                            2'b10: time_reg <= time_reg | csr_write_data;
                            2'b11: time_reg <= time_reg & ~csr_write_data;
                        endcase
                    end
                    CSR_INSTRET: begin
                        case (csr_op)
                            2'b01: instret_reg <= csr_write_data;
                            2'b10: instret_reg <= instret_reg | csr_write_data;
                            2'b11: instret_reg <= instret_reg & ~csr_write_data;
                        endcase
                    end
                    CSR_MHPMCOUNTER3: begin
                        case (csr_op)
                            2'b01: mhpmcounter3_reg <= csr_write_data;
                            2'b10: mhpmcounter3_reg <= mhpmcounter3_reg | csr_write_data;
                            2'b11: mhpmcounter3_reg <= mhpmcounter3_reg & ~csr_write_data;
                        endcase
                    end
                    CSR_MHPMCOUNTER4: begin
                        case (csr_op)
                            2'b01: mhpmcounter4_reg <= csr_write_data;
                            2'b10: mhpmcounter4_reg <= mhpmcounter4_reg | csr_write_data;
                            2'b11: mhpmcounter4_reg <= mhpmcounter4_reg & ~csr_write_data;
                        endcase
                    end
                    CSR_MHPMCOUNTER5: begin
                        case (csr_op)
                            2'b01: mhpmcounter5_reg <= csr_write_data;
                            2'b10: mhpmcounter5_reg <= mhpmcounter5_reg | csr_write_data;
                            2'b11: mhpmcounter5_reg <= mhpmcounter5_reg & ~csr_write_data;
                        endcase
                    end
                    CSR_MHPMCOUNTER6: begin
                        case (csr_op)
                            2'b01: mhpmcounter6_reg <= csr_write_data;
                            2'b10: mhpmcounter6_reg <= mhpmcounter6_reg | csr_write_data;
                            2'b11: mhpmcounter6_reg <= mhpmcounter6_reg & ~csr_write_data;
                        endcase
                    end
                    CSR_MHPMCOUNTER7: begin
                        case (csr_op)
                            2'b01: mhpmcounter7_reg <= csr_write_data;
                            2'b10: mhpmcounter7_reg <= mhpmcounter7_reg | csr_write_data;
                            2'b11: mhpmcounter7_reg <= mhpmcounter7_reg & ~csr_write_data;
                        endcase
                    end
                    CSR_MHPMCOUNTER8: begin
                        case (csr_op)
                            2'b01: mhpmcounter8_reg <= csr_write_data;
                            2'b10: mhpmcounter8_reg <= mhpmcounter8_reg | csr_write_data;
                            2'b11: mhpmcounter8_reg <= mhpmcounter8_reg & ~csr_write_data;
                        endcase
                    end
                endcase
            end
        end
    end

    // CSR read logic
    always_comb begin
        csr_error = 1'b0;
        case (csr_addr)
            CSR_CYCLE: csr_read_data = cycle_reg;
            CSR_TIME: csr_read_data = time_reg;
            CSR_INSTRET: csr_read_data = instret_reg;
            CSR_CYCLEH: csr_read_data = cycle_reg[63:32];
            CSR_TIMEH: csr_read_data = time_reg[63:32];
            CSR_INSTRETH: csr_read_data = instret_reg[63:32];
            CSR_MHPMCOUNTER3: csr_read_data = mhpmcounter3_reg;
            CSR_MHPMCOUNTER4: csr_read_data = mhpmcounter4_reg;
            CSR_MHPMCOUNTER5: csr_read_data = mhpmcounter5_reg;
            CSR_MHPMCOUNTER6: csr_read_data = mhpmcounter6_reg;
            CSR_MHPMCOUNTER7: csr_read_data = mhpmcounter7_reg;
            CSR_MHPMCOUNTER8: csr_read_data = mhpmcounter8_reg;
            default: begin
                csr_read_data = '0;
                csr_error = 1'b1;
            end
        endcase
    end

endmodule 