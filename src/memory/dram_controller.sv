module dram_controller #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter ROW_WIDTH = 13,    // Number of row address bits
    parameter COL_WIDTH = 10,    // Number of column address bits
    parameter BANK_WIDTH = 2,    // Number of bank address bits
    parameter SDRAM_DATA_WIDTH = 16,  // SDRAM data width
    parameter SDRAM_ADDR_WIDTH = 13,  // SDRAM address width
    parameter SDRAM_BANK_WIDTH = 2,   // SDRAM bank width
    parameter SDRAM_COL_WIDTH = 10,   // SDRAM column width
    parameter SDRAM_ROW_WIDTH = 13,   // SDRAM row width
    parameter BURST_LENGTH = 4,
    parameter REFRESH_INTERVAL = 7800  // 64ms at 100MHz
)(
    input  logic                    clk,           // System clock
    input  logic                    rst_n,         // Active low reset
    
    // Core interface
    input  logic [ADDR_WIDTH-1:0]   core_addr,     // Core address
    input  logic [DATA_WIDTH-1:0]   core_wdata,    // Core write data
    input  logic                    core_we,        // Core write enable
    input  logic [3:0]              core_be,        // Core byte enable
    output logic [DATA_WIDTH-1:0]   core_rdata,    // Core read data
    input  logic                    core_req,       // Core request
    output logic                    core_ack,       // Core acknowledge
    
    // SDRAM interface
    output logic [SDRAM_ADDR_WIDTH-1:0] sdram_addr,    // SDRAM address
    output logic [SDRAM_BANK_WIDTH-1:0] sdram_bank,    // SDRAM bank select
    output logic [SDRAM_DATA_WIDTH-1:0] sdram_dq_out,  // SDRAM data out
    input  logic [SDRAM_DATA_WIDTH-1:0] sdram_dq_in,   // SDRAM data in
    output logic                    sdram_cke,      // SDRAM clock enable
    output logic                    sdram_cs_n,     // SDRAM chip select
    output logic                    sdram_ras_n,    // SDRAM row address strobe
    output logic                    sdram_cas_n,    // SDRAM column address strobe
    output logic                    sdram_we_n,     // SDRAM write enable
    output logic [1:0]              sdram_dqm,      // SDRAM data mask
    inout  logic [SDRAM_DATA_WIDTH-1:0] sdram_dq,  // SDRAM data bus
    output logic                    sdram_dq_oe     // SDRAM data bus output enable
);

    // SDRAM timing parameters
    localparam TRC = 7;    // Row cycle time
    localparam TRCD = 2;   // Row to column delay
    localparam TRP = 2;    // Row precharge time
    localparam TWR = 2;    // Write recovery time
    localparam TRFC = 7;   // Refresh cycle time
    localparam TMRD = 2;   // Mode register set time
    localparam TREF = 7800;// Refresh interval (in clock cycles)
    
    // SDRAM commands
    localparam CMD_NOP = 4'b0111;
    localparam CMD_ACT = 4'b0011;
    localparam CMD_READ = 4'b0101;
    localparam CMD_WRITE = 4'b0100;
    localparam CMD_PRECHARGE = 4'b0010;
    localparam CMD_REFRESH = 4'b0001;
    localparam CMD_MRS = 4'b0000;
    
    // Controller states
    typedef enum logic [3:0] {
        INIT,           // Initialization
        IDLE,           // Idle state
        ACTIVE,         // Row active
        READ,           // Read operation
        WRITE,          // Write operation
        PRECHARGE,      // Precharge
        REFRESH,        // Refresh
        MODE_REG_SET    // Mode register set
    } state_t;
    
    state_t current_state, next_state;
    
    // Internal registers
    logic [ROW_WIDTH-1:0] current_row;
    logic [BANK_WIDTH-1:0] current_bank;
    logic [COL_WIDTH-1:0] current_col;
    logic [3:0] counter;
    logic [15:0] refresh_counter;
    logic [1:0] burst_counter;
    logic [DATA_WIDTH-1:0] read_buffer;
    logic [DATA_WIDTH-1:0] write_buffer;
    logic [3:0] byte_enable;
    
    // Address mapping
    logic [SDRAM_ADDR_WIDTH-1:0] row_addr;
    logic [SDRAM_ADDR_WIDTH-1:0] col_addr;
    logic [SDRAM_BANK_WIDTH-1:0] bank_addr;
    
    // Command generation
    logic [3:0] command;
    assign command = {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n};
    
    // Address and control signal generation
    always_comb begin
        case (current_state)
            INIT: begin
                sdram_cke = 1'b1;
                sdram_cs_n = 1'b0;
                sdram_ras_n = 1'b1;
                sdram_cas_n = 1'b1;
                sdram_we_n = 1'b1;
                sdram_addr = '0;
                sdram_bank = '0;
                sdram_dqm = 2'b11;
                sdram_dq_oe = 1'b0;
            end
            
            IDLE: begin
                sdram_cke = 1'b1;
                sdram_cs_n = 1'b0;
                sdram_ras_n = 1'b1;
                sdram_cas_n = 1'b1;
                sdram_we_n = 1'b1;
                sdram_addr = '0;
                sdram_bank = '0;
                sdram_dqm = 2'b11;
                sdram_dq_oe = 1'b0;
            end
            
            ACTIVE: begin
                sdram_cke = 1'b1;
                sdram_cs_n = 1'b0;
                sdram_ras_n = 1'b0;
                sdram_cas_n = 1'b1;
                sdram_we_n = 1'b1;
                sdram_addr = current_row;
                sdram_bank = current_bank;
                sdram_dqm = 2'b11;
                sdram_dq_oe = 1'b0;
            end
            
            READ: begin
                sdram_cke = 1'b1;
                sdram_cs_n = 1'b0;
                sdram_ras_n = 1'b1;
                sdram_cas_n = 1'b0;
                sdram_we_n = 1'b1;
                sdram_addr = {3'b000, current_col};
                sdram_bank = current_bank;
                sdram_dqm = 2'b00;
                sdram_dq_oe = 1'b0;
            end
            
            WRITE: begin
                sdram_cke = 1'b1;
                sdram_cs_n = 1'b0;
                sdram_ras_n = 1'b1;
                sdram_cas_n = 1'b0;
                sdram_we_n = 1'b0;
                sdram_addr = {3'b000, current_col};
                sdram_bank = current_bank;
                sdram_dqm = ~byte_enable[1:0];
                sdram_dq_oe = 1'b1;
            end
            
            PRECHARGE: begin
                sdram_cke = 1'b1;
                sdram_cs_n = 1'b0;
                sdram_ras_n = 1'b0;
                sdram_cas_n = 1'b1;
                sdram_we_n = 1'b0;
                sdram_addr = {10'b0, 1'b1, 2'b00};  // All banks
                sdram_bank = '0;
                sdram_dqm = 2'b11;
                sdram_dq_oe = 1'b0;
            end
            
            REFRESH: begin
                sdram_cke = 1'b1;
                sdram_cs_n = 1'b0;
                sdram_ras_n = 1'b0;
                sdram_cas_n = 1'b0;
                sdram_we_n = 1'b1;
                sdram_addr = '0;
                sdram_bank = '0;
                sdram_dqm = 2'b11;
                sdram_dq_oe = 1'b0;
            end
            
            MODE_REG_SET: begin
                sdram_cke = 1'b1;
                sdram_cs_n = 1'b0;
                sdram_ras_n = 1'b0;
                sdram_cas_n = 1'b0;
                sdram_we_n = 1'b0;
                sdram_addr = 13'b0000_0010_0000;  // CAS latency = 2, burst length = 2
                sdram_bank = '0;
                sdram_dqm = 2'b11;
                sdram_dq_oe = 1'b0;
            end
            
            default: begin
                sdram_cke = 1'b1;
                sdram_cs_n = 1'b1;
                sdram_ras_n = 1'b1;
                sdram_cas_n = 1'b1;
                sdram_we_n = 1'b1;
                sdram_addr = '0;
                sdram_bank = '0;
                sdram_dqm = 2'b11;
                sdram_dq_oe = 1'b0;
            end
        endcase
    end
    
    // Address mapping
    assign bank_addr = core_addr[ADDR_WIDTH-1:ADDR_WIDTH-SDRAM_BANK_WIDTH];
    assign row_addr = core_addr[ADDR_WIDTH-SDRAM_BANK_WIDTH-1:SDRAM_ADDR_WIDTH];
    assign col_addr = core_addr[SDRAM_ADDR_WIDTH-1:0];
    
    // State machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= INIT;
            counter <= '0;
            refresh_counter <= '0;
            burst_counter <= '0;
            current_row <= '0;
            current_bank <= '0;
            current_col <= '0;
            read_buffer <= '0;
            write_buffer <= '0;
            byte_enable <= '0;
            core_ack <= 1'b0;
            core_rdata <= '0;
        end else begin
            case (current_state)
                INIT: begin
                    if (counter < TMRD) begin
                        counter <= counter + 1;
                    end else begin
                        current_state <= MODE_REG_SET;
                        counter <= '0;
                    end
                end
                
                MODE_REG_SET: begin
                    if (counter < TMRD) begin
                        counter <= counter + 1;
                    end else begin
                        current_state <= IDLE;
                        counter <= '0;
                    end
                end
                
                IDLE: begin
                    core_ack <= 1'b0;
                    if (refresh_counter >= REFRESH_INTERVAL) begin
                        current_state <= REFRESH;
                        refresh_counter <= '0;
                    end else if (core_req) begin
                        current_state <= ACTIVE;
                        current_row <= row_addr;
                        current_bank <= bank_addr;
                        current_col <= col_addr;
                        byte_enable <= core_be;
                        write_buffer <= core_wdata;
                        counter <= '0;
                    end else begin
                        refresh_counter <= refresh_counter + 1;
                    end
                end
                
                ACTIVE: begin
                    if (counter < TRCD) begin
                        counter <= counter + 1;
                    end else begin
                        current_state <= core_we ? WRITE : READ;
                        counter <= '0;
                    end
                end
                
                READ: begin
                    if (counter == 0) begin
                        read_buffer[15:0] <= sdram_dq_in;
                        counter <= counter + 1;
                    end else if (counter == 1) begin
                        read_buffer[31:16] <= sdram_dq_in;
                        core_rdata <= read_buffer;
                        core_ack <= 1'b1;
                        current_state <= PRECHARGE;
                        counter <= '0;
                    end
                end
                
                WRITE: begin
                    if (counter == 0) begin
                        sdram_dq_out <= write_buffer[15:0];
                        counter <= counter + 1;
                    end else if (counter == 1) begin
                        sdram_dq_out <= write_buffer[31:16];
                        core_ack <= 1'b1;
                        current_state <= PRECHARGE;
                        counter <= '0;
                    end
                end
                
                PRECHARGE: begin
                    if (counter < TRP) begin
                        counter <= counter + 1;
                    end else begin
                        current_state <= IDLE;
                        counter <= '0;
                    end
                end
                
                REFRESH: begin
                    if (counter < TRFC) begin
                        counter <= counter + 1;
                    end else begin
                        current_state <= IDLE;
                        counter <= '0;
                    end
                end
                
                default: current_state <= INIT;
            endcase
        end
    end
    
    // Data bus control
    assign sdram_dq = sdram_dq_oe ? sdram_dq_out : {SDRAM_DATA_WIDTH{1'bz}};
    
endmodule 