module perf_counters #(
    parameter DATA_WIDTH = 64,
    parameter NUM_COUNTERS = 32
)(
    input  logic                    clk,
    input  logic                    rst_n,
    
    // CSR interface
    input  logic [11:0]             csr_addr,
    input  logic [DATA_WIDTH-1:0]   csr_write_data,
    input  logic [1:0]              csr_op,
    output logic [DATA_WIDTH-1:0]   csr_read_data,
    output logic                    csr_valid,
    
    // Performance event inputs
    input  logic                    cycle_valid,
    input  logic                    instr_retire,
    input  logic                    branch_taken,
    input  logic                    branch_miss,
    input  logic                    l1_i_miss,
    input  logic                    l1_d_miss,
    input  logic                    l2_miss,
    input  logic                    tlb_miss,
    input  logic                    pipeline_stall,
    input  logic                    load_use_hazard,
    input  logic                    atomic_op,
    input  logic                    exception_taken,
    input  logic                    interrupt_taken,
    
    // Control signals
    input  logic [1:0]              privilege_mode,
    
    // Interrupt output
    output logic                    perf_interrupt
);

    // CSR addresses
    localparam CSR_MCYCLE      = 12'hB00;
    localparam CSR_MTIME       = 12'hB01;
    localparam CSR_MINSTRET    = 12'hB02;
    localparam CSR_MHPMCOUNTER3 = 12'hB03;
    localparam CSR_MHPMCOUNTER4 = 12'hB04;
    localparam CSR_MHPMCOUNTER5 = 12'hB05;
    localparam CSR_MHPMCOUNTER6 = 12'hB06;
    localparam CSR_MHPMCOUNTER7 = 12'hB07;
    localparam CSR_MHPMCOUNTER8 = 12'hB08;
    localparam CSR_MHPMCOUNTER9 = 12'hB09;
    localparam CSR_MHPMCOUNTER10 = 12'hB0A;
    localparam CSR_MHPMCOUNTER11 = 12'hB0B;
    localparam CSR_MHPMCOUNTER12 = 12'hB0C;
    localparam CSR_MHPMCOUNTER13 = 12'hB0D;
    localparam CSR_MHPMCOUNTER14 = 12'hB0E;
    localparam CSR_MHPMCOUNTER15 = 12'hB0F;
    localparam CSR_MHPMCOUNTER16 = 12'hB10;
    localparam CSR_MHPMCOUNTER17 = 12'hB11;
    localparam CSR_MHPMCOUNTER18 = 12'hB12;
    localparam CSR_MHPMCOUNTER19 = 12'hB13;
    localparam CSR_MHPMCOUNTER20 = 12'hB14;
    localparam CSR_MHPMCOUNTER21 = 12'hB15;
    localparam CSR_MHPMCOUNTER22 = 12'hB16;
    localparam CSR_MHPMCOUNTER23 = 12'hB17;
    localparam CSR_MHPMCOUNTER24 = 12'hB18;
    localparam CSR_MHPMCOUNTER25 = 12'hB19;
    localparam CSR_MHPMCOUNTER26 = 12'hB1A;
    localparam CSR_MHPMCOUNTER27 = 12'hB1B;
    localparam CSR_MHPMCOUNTER28 = 12'hB1C;
    localparam CSR_MHPMCOUNTER29 = 12'hB1D;
    localparam CSR_MHPMCOUNTER30 = 12'hB1E;
    localparam CSR_MHPMCOUNTER31 = 12'hB1F;
    
    // Event configuration CSRs
    localparam CSR_MHPMEVENT3  = 12'h323;
    localparam CSR_MHPMEVENT4  = 12'h324;
    localparam CSR_MHPMEVENT5  = 12'h325;
    localparam CSR_MHPMEVENT6  = 12'h326;
    localparam CSR_MHPMEVENT7  = 12'h327;
    localparam CSR_MHPMEVENT8  = 12'h328;
    localparam CSR_MHPMEVENT9  = 12'h329;
    localparam CSR_MHPMEVENT10 = 12'h32A;
    localparam CSR_MHPMEVENT11 = 12'h32B;
    localparam CSR_MHPMEVENT12 = 12'h32C;
    localparam CSR_MHPMEVENT13 = 12'h32D;
    localparam CSR_MHPMEVENT14 = 12'h32E;
    localparam CSR_MHPMEVENT15 = 12'h32F;
    localparam CSR_MHPMEVENT16 = 12'h330;
    localparam CSR_MHPMEVENT17 = 12'h331;
    localparam CSR_MHPMEVENT18 = 12'h332;
    localparam CSR_MHPMEVENT19 = 12'h333;
    localparam CSR_MHPMEVENT20 = 12'h334;
    localparam CSR_MHPMEVENT21 = 12'h335;
    localparam CSR_MHPMEVENT22 = 12'h336;
    localparam CSR_MHPMEVENT23 = 12'h337;
    localparam CSR_MHPMEVENT24 = 12'h338;
    localparam CSR_MHPMEVENT25 = 12'h339;
    localparam CSR_MHPMEVENT26 = 12'h33A;
    localparam CSR_MHPMEVENT27 = 12'h33B;
    localparam CSR_MHPMEVENT28 = 12'h33C;
    localparam CSR_MHPMEVENT29 = 12'h33D;
    localparam CSR_MHPMEVENT30 = 12'h33E;
    localparam CSR_MHPMEVENT31 = 12'h33F;
    
    // Performance event types
    localparam EVENT_CYCLES       = 6'd1;
    localparam EVENT_INSTRUCTIONS = 6'd2;
    localparam EVENT_BRANCHES     = 6'd3;
    localparam EVENT_BRANCH_MISSES = 6'd4;
    localparam EVENT_L1I_MISSES   = 6'd5;
    localparam EVENT_L1D_MISSES   = 6'd6;
    localparam EVENT_L2_MISSES    = 6'd7;
    localparam EVENT_TLB_MISSES   = 6'd8;
    localparam EVENT_STALLS       = 6'd9;
    localparam EVENT_LOAD_HAZARDS = 6'd10;
    localparam EVENT_ATOMICS      = 6'd11;
    localparam EVENT_EXCEPTIONS   = 6'd12;
    localparam EVENT_INTERRUPTS   = 6'd13;
    
    // Counter registers
    logic [63:0] mcycle;
    logic [63:0] mtime;
    logic [63:0] minstret;
    logic [63:0] mhpmcounter [3:31];
    
    // Event configuration registers
    logic [63:0] mhpmevent [3:31];
    
    // Internal signals
    logic [31:0] counter_events;
    logic [31:0] counter_enable;
    logic [31:0] counter_overflow;
    
    // Map performance events
    assign counter_events[EVENT_CYCLES] = cycle_valid;
    assign counter_events[EVENT_INSTRUCTIONS] = instr_retire;
    assign counter_events[EVENT_BRANCHES] = branch_taken;
    assign counter_events[EVENT_BRANCH_MISSES] = branch_miss;
    assign counter_events[EVENT_L1I_MISSES] = l1_i_miss;
    assign counter_events[EVENT_L1D_MISSES] = l1_d_miss;
    assign counter_events[EVENT_L2_MISSES] = l2_miss;
    assign counter_events[EVENT_TLB_MISSES] = tlb_miss;
    assign counter_events[EVENT_STALLS] = pipeline_stall;
    assign counter_events[EVENT_LOAD_HAZARDS] = load_use_hazard;
    assign counter_events[EVENT_ATOMICS] = atomic_op;
    assign counter_events[EVENT_EXCEPTIONS] = exception_taken;
    assign counter_events[EVENT_INTERRUPTS] = interrupt_taken;
    
    // Counter enable logic based on privilege mode
    genvar i;
    generate
        for (i = 3; i <= 31; i++) begin : gen_counter_enable
            always_comb begin
                // Enable counter based on event configuration
                logic [5:0] event_sel = mhpmevent[i][5:0];
                logic mode_filter = mhpmevent[i][63]; // Filter by mode
                
                if (event_sel == 0 || event_sel >= 32) begin
                    counter_enable[i] = 1'b0;
                end else if (mode_filter) begin
                    // Only count in specific modes
                    logic [1:0] count_modes = mhpmevent[i][62:61];
                    counter_enable[i] = counter_events[event_sel] & 
                                      (count_modes[privilege_mode] | ~mode_filter);
                end else begin
                    // Count in all modes
                    counter_enable[i] = counter_events[event_sel];
                end
            end
        end
    endgenerate
    
    // Counter update logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mcycle <= 64'h0;
            mtime <= 64'h0;
            minstret <= 64'h0;
            for (int j = 3; j <= 31; j++) begin
                mhpmcounter[j] <= 64'h0;
                mhpmevent[j] <= 64'h0;
            end
            counter_overflow <= 32'h0;
        end else begin
            // Always increment cycle counter
            mcycle <= mcycle + 1'b1;
            
            // Increment time counter (could be different from cycle)
            mtime <= mtime + 1'b1;
            
            // Increment instruction retire counter
            if (instr_retire) begin
                minstret <= minstret + 1'b1;
            end
            
            // Update programmable counters
            for (int j = 3; j <= 31; j++) begin
                if (counter_enable[j]) begin
                    logic [63:0] new_value = mhpmcounter[j] + 1'b1;
                    mhpmcounter[j] <= new_value;
                    
                    // Check for overflow
                    if (new_value == 64'h0) begin
                        counter_overflow[j] <= 1'b1;
                    end else begin
                        counter_overflow[j] <= 1'b0;
                    end
                end else begin
                    counter_overflow[j] <= 1'b0;
                end
            end
            
            // Handle CSR writes
            if (csr_op != 2'b00 && csr_valid) begin
                case (csr_addr)
                    CSR_MCYCLE: begin
                        case (csr_op)
                            2'b01: mcycle <= csr_write_data;
                            2'b10: mcycle <= mcycle | csr_write_data;
                            2'b11: mcycle <= mcycle & ~csr_write_data;
                        endcase
                    end
                    CSR_MTIME: begin
                        case (csr_op)
                            2'b01: mtime <= csr_write_data;
                            2'b10: mtime <= mtime | csr_write_data;
                            2'b11: mtime <= mtime & ~csr_write_data;
                        endcase
                    end
                    CSR_MINSTRET: begin
                        case (csr_op)
                            2'b01: minstret <= csr_write_data;
                            2'b10: minstret <= minstret | csr_write_data;
                            2'b11: minstret <= minstret & ~csr_write_data;
                        endcase
                    end
                    default: begin
                        // Handle programmable counters and events
                        if (csr_addr >= CSR_MHPMCOUNTER3 && csr_addr <= CSR_MHPMCOUNTER31) begin
                            int counter_idx = csr_addr - CSR_MHPMCOUNTER3 + 3;
                            case (csr_op)
                                2'b01: mhpmcounter[counter_idx] <= csr_write_data;
                                2'b10: mhpmcounter[counter_idx] <= mhpmcounter[counter_idx] | csr_write_data;
                                2'b11: mhpmcounter[counter_idx] <= mhpmcounter[counter_idx] & ~csr_write_data;
                            endcase
                        end else if (csr_addr >= CSR_MHPMEVENT3 && csr_addr <= CSR_MHPMEVENT31) begin
                            int event_idx = csr_addr - CSR_MHPMEVENT3 + 3;
                            case (csr_op)
                                2'b01: mhpmevent[event_idx] <= csr_write_data;
                                2'b10: mhpmevent[event_idx] <= mhpmevent[event_idx] | csr_write_data;
                                2'b11: mhpmevent[event_idx] <= mhpmevent[event_idx] & ~csr_write_data;
                            endcase
                        end
                    end
                endcase
            end
        end
    end
    
    // CSR read logic
    always_comb begin
        csr_read_data = 64'h0;
        csr_valid = 1'b1;
        
        case (csr_addr)
            CSR_MCYCLE: csr_read_data = mcycle;
            CSR_MTIME: csr_read_data = mtime;
            CSR_MINSTRET: csr_read_data = minstret;
            default: begin
                if (csr_addr >= CSR_MHPMCOUNTER3 && csr_addr <= CSR_MHPMCOUNTER31) begin
                    int counter_idx = csr_addr - CSR_MHPMCOUNTER3 + 3;
                    csr_read_data = mhpmcounter[counter_idx];
                end else if (csr_addr >= CSR_MHPMEVENT3 && csr_addr <= CSR_MHPMEVENT31) begin
                    int event_idx = csr_addr - CSR_MHPMEVENT3 + 3;
                    csr_read_data = mhpmevent[event_idx];
                end else begin
                    csr_valid = 1'b0;
                end
            end
        endcase
    end
    
    // Generate interrupt on counter overflow
    assign perf_interrupt = |counter_overflow;
    
endmodule 