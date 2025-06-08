module opensbi_handler #(
    parameter DATA_WIDTH = 64,
    parameter ADDR_WIDTH = 64,
    parameter NUM_CORES = 4
)(
    input  logic                          clk,
    input  logic                          rst_n,
    
    // Core interface for SBI calls
    input  logic [NUM_CORES-1:0]          sbi_call_valid,
    input  logic [NUM_CORES-1:0][2:0]     sbi_fid,          // Function ID
    input  logic [NUM_CORES-1:0][2:0]     sbi_eid,          // Extension ID
    input  logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] sbi_arg0,
    input  logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] sbi_arg1,
    input  logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] sbi_arg2,
    input  logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] sbi_arg3,
    input  logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] sbi_arg4,
    input  logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] sbi_arg5,
    output logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] sbi_ret0,   // Return value
    output logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] sbi_ret1,   // Return error
    output logic [NUM_CORES-1:0]          sbi_call_complete,
    
    // Timer interface (CLINT)
    output logic [NUM_CORES-1:0][63:0]     timer_value,
    input  logic [63:0]                   mtime,
    output logic [NUM_CORES-1:0][63:0]     mtimecmp,
    output logic [NUM_CORES-1:0]          timer_interrupt_clear,
    
    // IPI interface (inter-processor interrupts)
    output logic [NUM_CORES-1:0]          ipi_send,
    output logic [NUM_CORES-1:0]          ipi_clear,
    input  logic [NUM_CORES-1:0]          hart_mask,
    
    // Console interface (UART)
    output logic [7:0]                    console_putchar,
    output logic                          console_putchar_valid,
    input  logic [7:0]                    console_getchar,
    input  logic                          console_getchar_valid,
    
    // System reset/shutdown
    output logic                          system_reset,
    output logic                          system_shutdown,
    
    // Hart state management
    input  logic [NUM_CORES-1:0][1:0]     hart_state,  // 0:stop, 1:start, 2:suspend
    output logic [NUM_CORES-1:0]          hart_start,
    output logic [NUM_CORES-1:0]          hart_stop,
    output logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] hart_start_addr
);

    // SBI Extension IDs (EID)
    localparam SBI_EXT_BASE      = 3'h0;   // Base extension
    localparam SBI_EXT_TIME      = 3'h1;   // Timer extension
    localparam SBI_EXT_IPI       = 3'h2;   // IPI extension
    localparam SBI_EXT_RFENCE    = 3'h3;   // Remote fence extension
    localparam SBI_EXT_HSM       = 3'h4;   // Hart state management
    localparam SBI_EXT_SRST      = 3'h5;   // System reset extension
    localparam SBI_EXT_CONSOLE   = 3'h6;   // Console extension (legacy)
    
    // SBI Function IDs (FID) for Base extension
    localparam SBI_BASE_GET_SPEC_VERSION = 3'h0;
    localparam SBI_BASE_GET_IMPL_ID      = 3'h1;
    localparam SBI_BASE_GET_IMPL_VERSION = 3'h2;
    localparam SBI_BASE_PROBE_EXTENSION  = 3'h3;
    localparam SBI_BASE_GET_MVENDORID    = 3'h4;
    localparam SBI_BASE_GET_MARCHID      = 3'h5;
    localparam SBI_BASE_GET_MIMPID       = 3'h6;
    
    // SBI Function IDs for Timer extension
    localparam SBI_TIME_SET_TIMER        = 3'h0;
    
    // SBI Function IDs for IPI extension
    localparam SBI_IPI_SEND_IPI          = 3'h0;
    
    // SBI Function IDs for HSM extension
    localparam SBI_HSM_HART_START        = 3'h0;
    localparam SBI_HSM_HART_STOP         = 3'h1;
    localparam SBI_HSM_HART_STATUS       = 3'h2;
    localparam SBI_HSM_HART_SUSPEND      = 3'h3;
    
    // SBI Function IDs for System Reset extension
    localparam SBI_SRST_SYSTEM_RESET     = 3'h0;
    
    // SBI Function IDs for Console extension (legacy)
    localparam SBI_CONSOLE_PUTCHAR       = 3'h0;
    localparam SBI_CONSOLE_GETCHAR       = 3'h1;
    
    // SBI Error codes
    localparam SBI_SUCCESS               = 64'h0;
    localparam SBI_ERR_FAILED           = 64'hFFFFFFFFFFFFFFFF;
    localparam SBI_ERR_NOT_SUPPORTED    = 64'hFFFFFFFFFFFFFFFE;
    localparam SBI_ERR_INVALID_PARAM    = 64'hFFFFFFFFFFFFFFFD;
    localparam SBI_ERR_DENIED           = 64'hFFFFFFFFFFFFFFFC;
    localparam SBI_ERR_INVALID_ADDRESS  = 64'hFFFFFFFFFFFFFFFB;
    localparam SBI_ERR_ALREADY_AVAILABLE = 64'hFFFFFFFFFFFFFFFA;
    
    // SBI Implementation details
    localparam SBI_SPEC_VERSION         = 64'h00020000;  // Version 2.0
    localparam SBI_IMPL_ID              = 64'h12345678;  // Custom implementation
    localparam SBI_IMPL_VERSION         = 64'h00010000;  // Version 1.0
    localparam SBI_MVENDORID            = 64'h0;         // Unspecified
    localparam SBI_MARCHID              = 64'h0;         // Unspecified  
    localparam SBI_MIMPID               = 64'h0;         // Unspecified
    
    // Internal registers
    logic [NUM_CORES-1:0][63:0] hart_timecmp;
    logic [NUM_CORES-1:0] hart_timer_pending;
    logic [NUM_CORES-1:0] hart_ipi_pending;
    
    // SBI call processing
    genvar core;
    generate
        for (core = 0; core < NUM_CORES; core++) begin : gen_sbi_handler
            
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    sbi_ret0[core] <= 64'h0;
                    sbi_ret1[core] <= 64'h0;
                    sbi_call_complete[core] <= 1'b0;
                    hart_timecmp[core] <= 64'hFFFFFFFFFFFFFFFF;
                    hart_timer_pending[core] <= 1'b0;
                    hart_ipi_pending[core] <= 1'b0;
                end else begin
                    sbi_call_complete[core] <= 1'b0;
                    
                    if (sbi_call_valid[core]) begin
                        case (sbi_eid[core])
                            SBI_EXT_BASE: begin
                                case (sbi_fid[core])
                                    SBI_BASE_GET_SPEC_VERSION: begin
                                        sbi_ret0[core] <= SBI_SPEC_VERSION;
                                        sbi_ret1[core] <= SBI_SUCCESS;
                                    end
                                    SBI_BASE_GET_IMPL_ID: begin
                                        sbi_ret0[core] <= SBI_IMPL_ID;
                                        sbi_ret1[core] <= SBI_SUCCESS;
                                    end
                                    SBI_BASE_GET_IMPL_VERSION: begin
                                        sbi_ret0[core] <= SBI_IMPL_VERSION;
                                        sbi_ret1[core] <= SBI_SUCCESS;
                                    end
                                    SBI_BASE_PROBE_EXTENSION: begin
                                        // Check if extension is supported
                                        case (sbi_arg0[core][2:0])
                                            SBI_EXT_BASE,
                                            SBI_EXT_TIME,
                                            SBI_EXT_IPI,
                                            SBI_EXT_HSM,
                                            SBI_EXT_SRST,
                                            SBI_EXT_CONSOLE: begin
                                                sbi_ret0[core] <= 64'h1;  // Extension available
                                                sbi_ret1[core] <= SBI_SUCCESS;
                                            end
                                            default: begin
                                                sbi_ret0[core] <= 64'h0;  // Extension not available
                                                sbi_ret1[core] <= SBI_SUCCESS;
                                            end
                                        endcase
                                    end
                                    SBI_BASE_GET_MVENDORID: begin
                                        sbi_ret0[core] <= SBI_MVENDORID;
                                        sbi_ret1[core] <= SBI_SUCCESS;
                                    end
                                    SBI_BASE_GET_MARCHID: begin
                                        sbi_ret0[core] <= SBI_MARCHID;
                                        sbi_ret1[core] <= SBI_SUCCESS;
                                    end
                                    SBI_BASE_GET_MIMPID: begin
                                        sbi_ret0[core] <= SBI_MIMPID;
                                        sbi_ret1[core] <= SBI_SUCCESS;
                                    end
                                    default: begin
                                        sbi_ret0[core] <= 64'h0;
                                        sbi_ret1[core] <= SBI_ERR_NOT_SUPPORTED;
                                    end
                                endcase
                            end
                            
                            SBI_EXT_TIME: begin
                                case (sbi_fid[core])
                                    SBI_TIME_SET_TIMER: begin
                                        hart_timecmp[core] <= sbi_arg0[core];
                                        sbi_ret0[core] <= 64'h0;
                                        sbi_ret1[core] <= SBI_SUCCESS;
                                    end
                                    default: begin
                                        sbi_ret0[core] <= 64'h0;
                                        sbi_ret1[core] <= SBI_ERR_NOT_SUPPORTED;
                                    end
                                endcase
                            end
                            
                            SBI_EXT_IPI: begin
                                case (sbi_fid[core])
                                    SBI_IPI_SEND_IPI: begin
                                        // Send IPI to hart mask
                                        for (int h = 0; h < NUM_CORES; h++) begin
                                            if (sbi_arg0[core][h]) begin
                                                hart_ipi_pending[h] <= 1'b1;
                                            end
                                        end
                                        sbi_ret0[core] <= 64'h0;
                                        sbi_ret1[core] <= SBI_SUCCESS;
                                    end
                                    default: begin
                                        sbi_ret0[core] <= 64'h0;
                                        sbi_ret1[core] <= SBI_ERR_NOT_SUPPORTED;
                                    end
                                endcase
                            end
                            
                            SBI_EXT_HSM: begin
                                case (sbi_fid[core])
                                    SBI_HSM_HART_START: begin
                                        logic [31:0] target_hart = sbi_arg0[core][31:0];
                                        if (target_hart < NUM_CORES) begin
                                            hart_start[target_hart] <= 1'b1;
                                            hart_start_addr[target_hart] <= sbi_arg1[core];
                                            sbi_ret0[core] <= 64'h0;
                                            sbi_ret1[core] <= SBI_SUCCESS;
                                        end else begin
                                            sbi_ret0[core] <= 64'h0;
                                            sbi_ret1[core] <= SBI_ERR_INVALID_PARAM;
                                        end
                                    end
                                    SBI_HSM_HART_STOP: begin
                                        hart_stop[core] <= 1'b1;
                                        sbi_ret0[core] <= 64'h0;
                                        sbi_ret1[core] <= SBI_SUCCESS;
                                    end
                                    SBI_HSM_HART_STATUS: begin
                                        logic [31:0] target_hart = sbi_arg0[core][31:0];
                                        if (target_hart < NUM_CORES) begin
                                            sbi_ret0[core] <= {62'h0, hart_state[target_hart]};
                                            sbi_ret1[core] <= SBI_SUCCESS;
                                        end else begin
                                            sbi_ret0[core] <= 64'h0;
                                            sbi_ret1[core] <= SBI_ERR_INVALID_PARAM;
                                        end
                                    end
                                    default: begin
                                        sbi_ret0[core] <= 64'h0;
                                        sbi_ret1[core] <= SBI_ERR_NOT_SUPPORTED;
                                    end
                                endcase
                            end
                            
                            SBI_EXT_SRST: begin
                                case (sbi_fid[core])
                                    SBI_SRST_SYSTEM_RESET: begin
                                        if (sbi_arg0[core] == 0) begin
                                            system_shutdown <= 1'b1;  // Shutdown
                                        end else begin
                                            system_reset <= 1'b1;     // Reset
                                        end
                                        sbi_ret0[core] <= 64'h0;
                                        sbi_ret1[core] <= SBI_SUCCESS;
                                    end
                                    default: begin
                                        sbi_ret0[core] <= 64'h0;
                                        sbi_ret1[core] <= SBI_ERR_NOT_SUPPORTED;
                                    end
                                endcase
                            end
                            
                            SBI_EXT_CONSOLE: begin
                                case (sbi_fid[core])
                                    SBI_CONSOLE_PUTCHAR: begin
                                        console_putchar <= sbi_arg0[core][7:0];
                                        console_putchar_valid <= 1'b1;
                                        sbi_ret0[core] <= 64'h0;
                                        sbi_ret1[core] <= SBI_SUCCESS;
                                    end
                                    SBI_CONSOLE_GETCHAR: begin
                                        if (console_getchar_valid) begin
                                            sbi_ret0[core] <= {56'h0, console_getchar};
                                            sbi_ret1[core] <= SBI_SUCCESS;
                                        end else begin
                                            sbi_ret0[core] <= 64'hFFFFFFFFFFFFFFFF;  // No char available
                                            sbi_ret1[core] <= SBI_SUCCESS;
                                        end
                                    end
                                    default: begin
                                        sbi_ret0[core] <= 64'h0;
                                        sbi_ret1[core] <= SBI_ERR_NOT_SUPPORTED;
                                    end
                                endcase
                            end
                            
                            default: begin
                                sbi_ret0[core] <= 64'h0;
                                sbi_ret1[core] <= SBI_ERR_NOT_SUPPORTED;
                            end
                        endcase
                        
                        sbi_call_complete[core] <= 1'b1;
                    end
                    
                    // Clear one-shot signals
                    if (hart_start[core]) hart_start[core] <= 1'b0;
                    if (hart_stop[core]) hart_stop[core] <= 1'b0;
                    if (console_putchar_valid) console_putchar_valid <= 1'b0;
                end
            end
        end
    endgenerate
    
    // Timer management
    assign timer_value = '{default: mtime};
    assign mtimecmp = hart_timecmp;
    
    // IPI management
    assign ipi_send = hart_ipi_pending;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hart_ipi_pending <= '0;
        end else begin
            // Clear IPI when acknowledged (simplified)
            for (int h = 0; h < NUM_CORES; h++) begin
                if (ipi_clear[h]) begin
                    hart_ipi_pending[h] <= 1'b0;
                end
            end
        end
    end
    
    // Debug output
    `ifdef SIMULATION
    always @(posedge clk) begin
        for (int c = 0; c < NUM_CORES; c++) begin
            if (sbi_call_valid[c]) begin
                $display("[SBI] Core %0d: EID=%0d FID=%0d ARG0=0x%016x", 
                        c, sbi_eid[c], sbi_fid[c], sbi_arg0[c]);
            end
            if (sbi_call_complete[c]) begin
                $display("[SBI] Core %0d: RET0=0x%016x RET1=0x%016x", 
                        c, sbi_ret0[c], sbi_ret1[c]);
            end
        end
    end
    `endif
    
endmodule 
