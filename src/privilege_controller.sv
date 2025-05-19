module privilege_controller #(
    parameter DATA_WIDTH = 64
)(
    input  logic                    clk,
    input  logic                    rst_n,
    
    // Current privilege mode output
    output logic [1:0]              current_mode,  // 00:U, 01:S, 11:M
    
    // Exception interface
    input  logic                    exception_valid,
    input  logic [3:0]              exception_code,
    input  logic                    exception_interrupt,
    input  logic [DATA_WIDTH-1:0]   exception_value,
    input  logic [DATA_WIDTH-1:0]   exception_pc,
    input  logic [DATA_WIDTH-1:0]   exception_instr,
    
    // Trap vector selectors
    input  logic [DATA_WIDTH-1:0]   mtvec_reg,
    input  logic [DATA_WIDTH-1:0]   stvec_reg,
    
    // Return from exception instructions
    input  logic                    execute_mret,
    input  logic                    execute_sret,
    
    // Delegated exceptions/interrupts
    input  logic [DATA_WIDTH-1:0]   medeleg_reg,
    input  logic [DATA_WIDTH-1:0]   mideleg_reg,
    
    // Return target
    output logic [DATA_WIDTH-1:0]   return_pc,
    
    // Exception trigger signals to CSRs
    output logic                    m_exception_valid,
    output logic [3:0]              m_exception_code,
    output logic [DATA_WIDTH-1:0]   m_exception_value,
    output logic [DATA_WIDTH-1:0]   m_exception_pc,
    output logic [DATA_WIDTH-1:0]   m_exception_instr,
    output logic                    m_return_from_exception,
    
    output logic                    s_exception_valid,
    output logic [3:0]              s_exception_code,
    output logic [DATA_WIDTH-1:0]   s_exception_value,
    output logic [DATA_WIDTH-1:0]   s_exception_pc,
    output logic [DATA_WIDTH-1:0]   s_exception_instr,
    output logic                    s_return_from_exception,
    
    // Status register fields
    input  logic                    mstatus_mie,   // M-mode interrupt enable
    input  logic                    mstatus_sie,   // S-mode interrupt enable
    input  logic [1:0]              mstatus_mpp,   // M-mode previous privilege
    input  logic                    mstatus_spp,   // S-mode previous privilege
    
    // Return PC from CSRs
    input  logic [DATA_WIDTH-1:0]   mepc_reg,      // M-mode exception PC
    input  logic [DATA_WIDTH-1:0]   sepc_reg       // S-mode exception PC
);

    // Internal state
    logic [1:0] next_mode;
    logic [DATA_WIDTH-1:0] trap_vector;
    logic delegated_to_s;
    
    // Register current mode
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_mode <= 2'b11;  // Reset to M-mode
        end else begin
            current_mode <= next_mode;
        end
    end
    
    // Determine if exception/interrupt is delegated to S-mode
    always_comb begin
        delegated_to_s = 1'b0;
        
        if (exception_valid) begin
            if (exception_interrupt) begin
                // Check interrupt delegation
                if (mideleg_reg[exception_code]) begin
                    delegated_to_s = 1'b1;
                end
            end else begin
                // Check exception delegation
                if (medeleg_reg[exception_code]) begin
                    delegated_to_s = 1'b1;
                end
            end
        end
    end
    
    // Next mode and trap vector determination
    always_comb begin
        next_mode = current_mode;
        trap_vector = '0;
        
        // Exception handling
        if (exception_valid) begin
            if (delegated_to_s && current_mode < 2'b11) begin
                // Exception delegated to S-mode and we're not in M-mode
                next_mode = 2'b01;  // Switch to S-mode
                trap_vector = {stvec_reg[DATA_WIDTH-1:2], 2'b00};
                
                // Add vector offset for interrupts if vectored mode
                if (exception_interrupt && stvec_reg[0]) begin
                    trap_vector = trap_vector + (exception_code << 2);
                end
            end else begin
                // Handle in M-mode
                next_mode = 2'b11;  // Switch to M-mode
                trap_vector = {mtvec_reg[DATA_WIDTH-1:2], 2'b00};
                
                // Add vector offset for interrupts if vectored mode
                if (exception_interrupt && mtvec_reg[0]) begin
                    trap_vector = trap_vector + (exception_code << 2);
                end
            end
        end
        
        // Return from exception
        if (execute_mret) begin
            next_mode = mstatus_mpp;  // Restore previous mode from MPP
            trap_vector = mepc_reg;
        end else if (execute_sret) begin
            next_mode = {1'b0, mstatus_spp};  // Restore previous mode from SPP
            trap_vector = sepc_reg;
        end
    end
    
    // Exception signals to CSRs
    always_comb begin
        // Default values
        m_exception_valid = 1'b0;
        m_exception_code = 4'h0;
        m_exception_value = '0;
        m_exception_pc = '0;
        m_exception_instr = '0;
        m_return_from_exception = 1'b0;
        
        s_exception_valid = 1'b0;
        s_exception_code = 4'h0;
        s_exception_value = '0;
        s_exception_pc = '0;
        s_exception_instr = '0;
        s_return_from_exception = 1'b0;
        
        // Route exception to appropriate CSR module
        if (exception_valid) begin
            if (delegated_to_s && current_mode < 2'b11) begin
                // Exception delegated to S-mode
                s_exception_valid = 1'b1;
                s_exception_code = exception_code;
                s_exception_value = exception_value;
                s_exception_pc = exception_pc;
                s_exception_instr = exception_instr;
            end else begin
                // Exception handled in M-mode
                m_exception_valid = 1'b1;
                m_exception_code = exception_code;
                m_exception_value = exception_value;
                m_exception_pc = exception_pc;
                m_exception_instr = exception_instr;
            end
        end
        
        // Route return signals
        if (execute_mret) begin
            m_return_from_exception = 1'b1;
        end else if (execute_sret) begin
            s_return_from_exception = 1'b1;
        end
    end
    
    // Output return PC
    assign return_pc = trap_vector;

endmodule 