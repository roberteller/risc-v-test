module linux_multicore #(
    parameter DATA_WIDTH = 64,
    parameter ADDR_WIDTH = 64,
    parameter MEM_SIZE = 1024*1024*512,    // 512MB memory
    parameter NUM_CORES = 4,
    parameter ID_WIDTH = 4,
    parameter L1_CACHE_SIZE = 32*1024,     // 32KB L1 per core
    parameter L2_CACHE_SIZE = 1024*1024,   // 1MB shared L2
    parameter CACHE_LINE_SIZE = 64         // 64 bytes per line
)(
    input  logic                     clk,
    input  logic                     rst_n,
    output logic [NUM_CORES-1:0]     core_active,
    
    // Memory interface
    output logic [ADDR_WIDTH-1:0]    mem_addr,
    output logic [DATA_WIDTH-1:0]    mem_write_data,
    output logic                     mem_read,
    output logic                     mem_write,
    output logic [7:0]               mem_byte_en,
    output logic                     mem_request,
    input  logic [DATA_WIDTH-1:0]    mem_read_data,
    input  logic                     mem_ready,
    input  logic                     mem_error,
    
    // Debug outputs
    output logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] pc_out,
    output logic [NUM_CORES-1:0][DATA_WIDTH-1:0] alu_result_out,
    
    // External interrupt interface
    input  logic                     m_ext_interrupt,
    input  logic                     s_ext_interrupt,
    
    // UART interface for console
    input  logic                     uart_rx,
    output logic                     uart_tx,
    
    // Boot selection
    input  logic                     enable_linux,   // 1: Linux boot, 0: Simple test mode
    input  logic [ADDR_WIDTH-1:0]    boot_addr       // Address to start execution from
);

    // =============================
    // Internal wires and parameters
    // =============================
    
    // Core <-> L1-I$ interface
    logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] core_instr_addr;
    logic [NUM_CORES-1:0][31:0]           core_instruction;
    logic [NUM_CORES-1:0]                 core_instr_request;
    logic [NUM_CORES-1:0]                 core_instr_ready;
    logic [NUM_CORES-1:0]                 core_instr_error;
    
    // Core <-> L1-D$ interface
    logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] core_data_addr;
    logic [NUM_CORES-1:0][DATA_WIDTH-1:0] core_data_write;
    logic [NUM_CORES-1:0][DATA_WIDTH-1:0] core_data_read;
    logic [NUM_CORES-1:0]                 core_data_read_en;
    logic [NUM_CORES-1:0]                 core_data_write_en;
    logic [NUM_CORES-1:0][2:0]            core_data_size;
    logic [NUM_CORES-1:0]                 core_data_request;
    logic [NUM_CORES-1:0]                 core_data_ready;
    logic [NUM_CORES-1:0]                 core_data_error;
    
    // L1 I$ <-> L2$ interface
    logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] l1i_l2_addr;
    logic [NUM_CORES-1:0][DATA_WIDTH-1:0] l1i_l2_write_data;
    logic [NUM_CORES-1:0]                 l1i_l2_read;
    logic [NUM_CORES-1:0]                 l1i_l2_write;
    logic [NUM_CORES-1:0][ID_WIDTH-1:0]   l1i_l2_id;
    logic [NUM_CORES-1:0]                 l1i_l2_request;
    logic [NUM_CORES-1:0][DATA_WIDTH-1:0] l1i_l2_read_data;
    logic [NUM_CORES-1:0]                 l1i_l2_ready;
    logic [NUM_CORES-1:0]                 l1i_l2_error;
    
    // L1 D$ <-> L2$ interface
    logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] l1d_l2_addr;
    logic [NUM_CORES-1:0][DATA_WIDTH-1:0] l1d_l2_write_data;
    logic [NUM_CORES-1:0]                 l1d_l2_read;
    logic [NUM_CORES-1:0]                 l1d_l2_write;
    logic [NUM_CORES-1:0][ID_WIDTH-1:0]   l1d_l2_id;
    logic [NUM_CORES-1:0]                 l1d_l2_request;
    logic [NUM_CORES-1:0][DATA_WIDTH-1:0] l1d_l2_read_data;
    logic [NUM_CORES-1:0]                 l1d_l2_ready;
    logic [NUM_CORES-1:0]                 l1d_l2_error;
    
    // Cache coherence signals
    logic [NUM_CORES-1:0]                 l1d_snoop_request;
    logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] l1d_snoop_addr;
    logic [NUM_CORES-1:0]                 l1d_snoop_invalidate;
    logic [NUM_CORES-1:0]                 l1d_snoop_hit;
    logic [NUM_CORES-1:0][DATA_WIDTH-1:0] l1d_snoop_data;
    logic [NUM_CORES-1:0]                 l1d_snoop_ack;
    
    // Combined L1 <-> L2 interfaces
    logic [NUM_CORES*2-1:0][ADDR_WIDTH-1:0] l1_l2_addr;
    logic [NUM_CORES*2-1:0][DATA_WIDTH-1:0] l1_l2_write_data;
    logic [NUM_CORES*2-1:0]                 l1_l2_read;
    logic [NUM_CORES*2-1:0]                 l1_l2_write;
    logic [NUM_CORES*2-1:0][ID_WIDTH-1:0]   l1_l2_id;
    logic [NUM_CORES*2-1:0]                 l1_l2_request;
    logic [NUM_CORES*2-1:0][DATA_WIDTH-1:0] l1_l2_read_data;
    logic [NUM_CORES*2-1:0]                 l1_l2_ready;
    logic [NUM_CORES*2-1:0]                 l1_l2_error;
    
    // L2$ <-> Memory interface
    logic [ADDR_WIDTH-1:0]           l2_mem_addr;
    logic [CACHE_LINE_SIZE*8-1:0]    l2_mem_write_data;
    logic                            l2_mem_read;
    logic                            l2_mem_write;
    logic                            l2_mem_request;
    logic [CACHE_LINE_SIZE*8-1:0]    l2_mem_read_data;
    logic                            l2_mem_ready;
    logic                            l2_mem_error;
    
    // MMU interfaces for each core
    logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] mmu_instr_virt_addr;
    logic [NUM_CORES-1:0]                 mmu_instr_read;
    logic [NUM_CORES-1:0]                 mmu_instr_write;
    logic [NUM_CORES-1:0][2:0]            mmu_instr_size;
    logic [NUM_CORES-1:0]                 mmu_instr_req;
    logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] mmu_instr_phys_addr;
    logic [NUM_CORES-1:0]                 mmu_instr_page_fault;
    logic [NUM_CORES-1:0]                 mmu_instr_access_fault;
    logic [NUM_CORES-1:0]                 mmu_instr_ack;
    
    logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] mmu_data_virt_addr;
    logic [NUM_CORES-1:0]                 mmu_data_read;
    logic [NUM_CORES-1:0]                 mmu_data_write;
    logic [NUM_CORES-1:0][2:0]            mmu_data_size;
    logic [NUM_CORES-1:0]                 mmu_data_req;
    logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] mmu_data_phys_addr;
    logic [NUM_CORES-1:0]                 mmu_data_page_fault;
    logic [NUM_CORES-1:0]                 mmu_data_access_fault;
    logic [NUM_CORES-1:0]                 mmu_data_ack;
    
    // CSR interfaces for MMU
    logic [NUM_CORES-1:0]                 mmu_tlb_flush;
    logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] satp_reg;
    logic [NUM_CORES-1:0]                 mstatus_sum;
    logic [NUM_CORES-1:0]                 mstatus_mxr;
    logic [NUM_CORES-1:0][1:0]            current_mode;
    
    // Memory interface for page table walks
    logic [NUM_CORES-1:0][ADDR_WIDTH-1:0] ptw_mem_addr;
    logic [NUM_CORES-1:0]                 ptw_mem_read;
    logic [NUM_CORES-1:0]                 ptw_mem_write;
    logic [NUM_CORES-1:0][DATA_WIDTH-1:0] ptw_mem_write_data;
    logic [NUM_CORES-1:0][DATA_WIDTH-1:0] ptw_mem_read_data;
    logic [NUM_CORES-1:0]                 ptw_mem_request;
    logic [NUM_CORES-1:0]                 ptw_mem_ack;
    
    // Interrupt signals
    logic [NUM_CORES-1:0]                 timer_interrupt;
    logic [NUM_CORES-1:0]                 software_interrupt;
    
    // Core identification
    logic [NUM_CORES-1:0][2:0] core_id;
    genvar i;
    generate
        for (i = 0; i < NUM_CORES; i++) begin : gen_core_id
            assign core_id[i] = i[2:0];
        end
    endgenerate
    
    // =====================
    // Core instances
    // =====================
    generate
        for (i = 0; i < NUM_CORES; i++) begin : gen_cores
            riscv_core #(
                .DATA_WIDTH(DATA_WIDTH),
                .ADDR_WIDTH(ADDR_WIDTH),
                .ENABLE_FPU(1),
                .ENABLE_AMO(1),
                .ENABLE_VECTOR(0),
                .ENABLE_COMPRESSED(1),
                .ENABLE_MMU(1),
                .RESET_VECTOR(boot_addr)
            ) core (
                .clk(clk),
                .rst_n(rst_n),
                .core_id(core_id[i]),
                
                // Instruction interface
                .instr_addr(mmu_instr_virt_addr[i]),
                .instruction_in(core_instruction[i]),
                .instr_request(mmu_instr_req[i]),
                .instr_ready(core_instr_ready[i]),
                .instr_error(core_instr_error[i]),
                
                // Data interface
                .data_addr(mmu_data_virt_addr[i]),
                .data_write(core_data_write[i]),
                .data_read(core_data_read[i]),
                .data_read_en(mmu_data_read[i]),
                .data_write_en(mmu_data_write[i]),
                .data_size(mmu_data_size[i]),
                .data_request(mmu_data_req[i]),
                .data_ready(core_data_ready[i]),
                .data_error(core_data_error[i]),
                
                // Interrupt interface
                .m_ext_irq(m_ext_interrupt),
                .s_ext_irq(s_ext_interrupt),
                .m_timer_irq(timer_interrupt[i]),
                .m_soft_irq(software_interrupt[i]),
                
                // MMU interface
                .satp_out(satp_reg[i]),
                .mstatus_sum(mstatus_sum[i]),
                .mstatus_mxr(mstatus_mxr[i]),
                .current_mode(current_mode[i]),
                .tlb_flush(mmu_tlb_flush[i]),
                
                // Exceptions
                .instr_page_fault(mmu_instr_page_fault[i]),
                .load_page_fault(mmu_data_page_fault[i] && mmu_data_read[i]),
                .store_page_fault(mmu_data_page_fault[i] && mmu_data_write[i]),
                .instr_access_fault(mmu_instr_access_fault[i]),
                .load_access_fault(mmu_data_access_fault[i] && mmu_data_read[i]),
                .store_access_fault(mmu_data_access_fault[i] && mmu_data_write[i]),
                
                // Debug interface
                .pc_out(pc_out[i]),
                .alu_result_out(alu_result_out[i]),
                .core_active(core_active[i])
            );
        end
    endgenerate
    
    // =====================
    // MMU instances
    // =====================
    generate
        for (i = 0; i < NUM_CORES; i++) begin : gen_mmus
            // Instruction MMU
            mmu #(
                .ADDR_WIDTH(ADDR_WIDTH),
                .DATA_WIDTH(DATA_WIDTH),
                .PAGE_LEVELS(3)    // Sv39
            ) immu (
                .clk(clk),
                .rst_n(rst_n),
                
                // CPU interface
                .virt_addr(mmu_instr_virt_addr[i]),
                .mem_read(1'b1),   // Always read for instructions
                .mem_write(1'b0),  // Never write
                .mem_size(3'b010),  // Always 4-byte (32-bit) instructions
                .mem_req(mmu_instr_req[i]),
                .phys_addr(core_instr_addr[i]),
                .page_fault(mmu_instr_page_fault[i]),
                .access_fault(mmu_instr_access_fault[i]),
                .mem_ack(mmu_instr_ack[i]),
                
                // TLB interface
                .tlb_flush(mmu_tlb_flush[i]),
                
                // CSR interface
                .satp_reg(satp_reg[i]),
                .mstatus_sum(mstatus_sum[i]),
                .mstatus_mxr(mstatus_mxr[i]),
                .current_mode(current_mode[i]),
                
                // Memory interface for page table walks
                .mem_paddr(ptw_mem_addr[i]),
                .mem_pread(ptw_mem_read[i]),
                .mem_pwrite(ptw_mem_write[i]),
                .mem_pwrite_data(ptw_mem_write_data[i]),
                .mem_pread_data(ptw_mem_read_data[i]),
                .mem_preq(ptw_mem_request[i]),
                .mem_pack(ptw_mem_ack[i])
            );
            
            // Data MMU
            mmu #(
                .ADDR_WIDTH(ADDR_WIDTH),
                .DATA_WIDTH(DATA_WIDTH),
                .PAGE_LEVELS(3)    // Sv39
            ) dmmu (
                .clk(clk),
                .rst_n(rst_n),
                
                // CPU interface
                .virt_addr(mmu_data_virt_addr[i]),
                .mem_read(mmu_data_read[i]),
                .mem_write(mmu_data_write[i]),
                .mem_size(mmu_data_size[i]),
                .mem_req(mmu_data_req[i]),
                .phys_addr(core_data_addr[i]),
                .page_fault(mmu_data_page_fault[i]),
                .access_fault(mmu_data_access_fault[i]),
                .mem_ack(mmu_data_ack[i]),
                
                // TLB interface
                .tlb_flush(mmu_tlb_flush[i]),
                
                // CSR interface
                .satp_reg(satp_reg[i]),
                .mstatus_sum(mstatus_sum[i]),
                .mstatus_mxr(mstatus_mxr[i]),
                .current_mode(current_mode[i]),
                
                // Memory interface for page table walks - shares with instruction MMU
                .mem_paddr(), // Not used, shared with instr MMU
                .mem_pread(), // Not used, shared with instr MMU
                .mem_pwrite(), // Not used, shared with instr MMU
                .mem_pwrite_data(), // Not used, shared with instr MMU
                .mem_pread_data(ptw_mem_read_data[i]),
                .mem_preq(), // Not used, shared with instr MMU
                .mem_pack(ptw_mem_ack[i])
            );
            
            // Connect the MMU outputs to the cache inputs
            assign core_instr_request[i] = mmu_instr_ack[i] & ~mmu_instr_page_fault[i] & ~mmu_instr_access_fault[i];
            assign core_data_request[i] = mmu_data_ack[i] & ~mmu_data_page_fault[i] & ~mmu_data_access_fault[i];
        end
    endgenerate
    
    // =====================
    // L1 Instruction Cache instances
    // =====================
    generate
        for (i = 0; i < NUM_CORES; i++) begin : gen_l1i_caches
            l1_cache #(
                .DATA_WIDTH(DATA_WIDTH),
                .ADDR_WIDTH(ADDR_WIDTH),
                .CACHE_SIZE(L1_CACHE_SIZE),
                .LINE_SIZE(CACHE_LINE_SIZE),
                .ASSOCIATIVITY(4),
                .ID_WIDTH(ID_WIDTH)
            ) l1i_cache (
                .clk(clk),
                .rst_n(rst_n),
                
                // CPU interface
                .cpu_addr(core_instr_addr[i]),
                .cpu_write_data(64'h0), // Instructions are read-only
                .cpu_read(1'b1),        // Always read
                .cpu_write(1'b0),       // Never write
                .cpu_size(3'b010),      // Always 4-byte
                .cpu_request(core_instr_request[i]),
                .cpu_read_data(core_instruction[i][31:0]), // 32-bit instruction
                .cpu_ready(core_instr_ready[i]),
                .cpu_error(core_instr_error[i]),
                
                // L2 cache interface
                .l2_addr(l1i_l2_addr[i]),
                .l2_write_data(l1i_l2_write_data[i]),
                .l2_read(l1i_l2_read[i]),
                .l2_write(l1i_l2_write[i]),
                .l2_id(l1i_l2_id[i]),
                .l2_request(l1i_l2_request[i]),
                .l2_read_data(l1i_l2_read_data[i]),
                .l2_ready(l1i_l2_ready[i]),
                .l2_error(l1i_l2_error[i]),
                
                // Coherence - instruction caches don't participate
                .snoop_request(1'b0),
                .snoop_addr(64'h0),
                .snoop_invalidate(1'b0),
                .snoop_hit(),
                .snoop_data(),
                .snoop_ack(),
                
                // Performance counters 
                .cache_hits(),
                .cache_misses(),
                .cache_evictions(),
                
                // Core ID for identification
                .core_id(core_id[i])
            );
        end
    endgenerate
    
    // =====================
    // L1 Data Cache instances
    // =====================
    generate
        for (i = 0; i < NUM_CORES; i++) begin : gen_l1d_caches
            l1_cache #(
                .DATA_WIDTH(DATA_WIDTH),
                .ADDR_WIDTH(ADDR_WIDTH),
                .CACHE_SIZE(L1_CACHE_SIZE),
                .LINE_SIZE(CACHE_LINE_SIZE),
                .ASSOCIATIVITY(4),
                .ID_WIDTH(ID_WIDTH)
            ) l1d_cache (
                .clk(clk),
                .rst_n(rst_n),
                
                // CPU interface
                .cpu_addr(core_data_addr[i]),
                .cpu_write_data(core_data_write[i]),
                .cpu_read(core_data_read_en[i]),
                .cpu_write(core_data_write_en[i]),
                .cpu_size(core_data_size[i]),
                .cpu_request(core_data_request[i]),
                .cpu_read_data(core_data_read[i]),
                .cpu_ready(core_data_ready[i]),
                .cpu_error(core_data_error[i]),
                
                // L2 cache interface
                .l2_addr(l1d_l2_addr[i]),
                .l2_write_data(l1d_l2_write_data[i]),
                .l2_read(l1d_l2_read[i]),
                .l2_write(l1d_l2_write[i]),
                .l2_id(l1d_l2_id[i]),
                .l2_request(l1d_l2_request[i]),
                .l2_read_data(l1d_l2_read_data[i]),
                .l2_ready(l1d_l2_ready[i]),
                .l2_error(l1d_l2_error[i]),
                
                // Cache coherence
                .snoop_request(l1d_snoop_request[i]),
                .snoop_addr(l1d_snoop_addr[i]),
                .snoop_invalidate(l1d_snoop_invalidate[i]),
                .snoop_hit(l1d_snoop_hit[i]),
                .snoop_data(l1d_snoop_data[i]),
                .snoop_ack(l1d_snoop_ack[i]),
                
                // Performance counters 
                .cache_hits(),
                .cache_misses(),
                .cache_evictions(),
                
                // Core ID for identification
                .core_id(core_id[i])
            );
        end
    endgenerate
    
    // =====================
    // Combine L1 I$ and D$ interfaces for L2
    // =====================
    generate
        for (i = 0; i < NUM_CORES; i++) begin : gen_l1_l2_connections
            // L1-I$ connections (map to even indices)
            assign l1_l2_addr[i*2] = l1i_l2_addr[i];
            assign l1_l2_write_data[i*2] = l1i_l2_write_data[i];
            assign l1_l2_read[i*2] = l1i_l2_read[i];
            assign l1_l2_write[i*2] = l1i_l2_write[i];
            assign l1_l2_id[i*2] = l1i_l2_id[i];
            assign l1_l2_request[i*2] = l1i_l2_request[i];
            assign l1i_l2_read_data[i] = l1_l2_read_data[i*2];
            assign l1i_l2_ready[i] = l1_l2_ready[i*2];
            assign l1i_l2_error[i] = l1_l2_error[i*2];
            
            // L1-D$ connections (map to odd indices)
            assign l1_l2_addr[i*2+1] = l1d_l2_addr[i];
            assign l1_l2_write_data[i*2+1] = l1d_l2_write_data[i];
            assign l1_l2_read[i*2+1] = l1d_l2_read[i];
            assign l1_l2_write[i*2+1] = l1d_l2_write[i];
            assign l1_l2_id[i*2+1] = l1d_l2_id[i];
            assign l1_l2_request[i*2+1] = l1d_l2_request[i];
            assign l1d_l2_read_data[i] = l1_l2_read_data[i*2+1];
            assign l1d_l2_ready[i] = l1_l2_ready[i*2+1];
            assign l1d_l2_error[i] = l1_l2_error[i*2+1];
        end
    endgenerate
    
    // =====================
    // L2 Cache instance
    // =====================
    l2_cache #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .CACHE_SIZE(L2_CACHE_SIZE),
        .LINE_SIZE(CACHE_LINE_SIZE),
        .ASSOCIATIVITY(8),
        .NUM_CORES(NUM_CORES*2),  // Twice as many interfaces (I$ + D$ per core)
        .ID_WIDTH(ID_WIDTH)
    ) l2_cache_inst (
        .clk(clk),
        .rst_n(rst_n),
        
        // L1 interface
        .l1_addr(l1_l2_addr),
        .l1_write_data(l1_l2_write_data),
        .l1_read(l1_l2_read),
        .l1_write(l1_l2_write),
        .l1_id(l1_l2_id),
        .l1_request(l1_l2_request),
        .l1_read_data(l1_l2_read_data),
        .l1_ready(l1_l2_ready),
        .l1_error(l1_l2_error),
        
        // Memory interface
        .mem_addr(l2_mem_addr),
        .mem_write_data(l2_mem_write_data),
        .mem_read(l2_mem_read),
        .mem_write(l2_mem_write),
        .mem_request(l2_mem_request),
        .mem_read_data(l2_mem_read_data),
        .mem_ready(l2_mem_ready),
        .mem_error(l2_mem_error),
        
        // Performance counters
        .cache_hits(),
        .cache_misses(),
        .cache_evictions()
    );
    
    // =====================
    // Memory Controller for cache line access
    // =====================
    // Convert wide cache line access to sequential memory accesses
    typedef enum logic [2:0] {
        IDLE,
        READ_LINE_START,
        READ_LINE_CONTINUE,
        WRITE_LINE_START,
        WRITE_LINE_CONTINUE
    } mem_state_t;
    
    mem_state_t mem_state, mem_next_state;
    logic [$clog2(CACHE_LINE_SIZE/(DATA_WIDTH/8))-1:0] line_offset;
    logic [CACHE_LINE_SIZE*8-1:0] mem_read_buffer;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_state <= IDLE;
            line_offset <= '0;
            mem_read_buffer <= '0;
        end else begin
            mem_state <= mem_next_state;
            
            // Increment offset during multi-word transfers
            if ((mem_state == READ_LINE_CONTINUE && mem_ready) ||
                (mem_state == WRITE_LINE_CONTINUE && mem_ready)) begin
                line_offset <= line_offset + 1'b1;
            end
            // Reset offset at start of transfer
            else if (mem_state == IDLE && 
                    ((l2_mem_read && l2_mem_request) || 
                     (l2_mem_write && l2_mem_request))) begin
                line_offset <= '0;
            end
            
            // Capture read data during line read
            if (mem_state == READ_LINE_CONTINUE && mem_ready) begin
                mem_read_buffer[line_offset * DATA_WIDTH +: DATA_WIDTH] <= mem_read_data;
            end
        end
    end
    
    // Next state logic
    always_comb begin
        mem_next_state = mem_state;
        
        case (mem_state)
            IDLE: begin
                if (l2_mem_read && l2_mem_request) begin
                    mem_next_state = READ_LINE_START;
                end else if (l2_mem_write && l2_mem_request) begin
                    mem_next_state = WRITE_LINE_START;
                end
            end
            
            READ_LINE_START: begin
                if (mem_ready) begin
                    if (line_offset == (CACHE_LINE_SIZE/(DATA_WIDTH/8) - 1)) begin
                        mem_next_state = IDLE;
                    end else begin
                        mem_next_state = READ_LINE_CONTINUE;
                    end
                end
            end
            
            READ_LINE_CONTINUE: begin
                if (mem_ready) begin
                    if (line_offset == (CACHE_LINE_SIZE/(DATA_WIDTH/8) - 1)) begin
                        mem_next_state = IDLE;
                    end
                end
            end
            
            WRITE_LINE_START: begin
                if (mem_ready) begin
                    if (line_offset == (CACHE_LINE_SIZE/(DATA_WIDTH/8) - 1)) begin
                        mem_next_state = IDLE;
                    end else begin
                        mem_next_state = WRITE_LINE_CONTINUE;
                    end
                end
            end
            
            WRITE_LINE_CONTINUE: begin
                if (mem_ready) begin
                    if (line_offset == (CACHE_LINE_SIZE/(DATA_WIDTH/8) - 1)) begin
                        mem_next_state = IDLE;
                    end
                end
            end
            
            default: mem_next_state = IDLE;
        endcase
    end
    
    // Memory controller outputs
    always_comb begin
        // Default values
        mem_addr = '0;
        mem_write_data = '0;
        mem_read = 1'b0;
        mem_write = 1'b0;
        mem_byte_en = '1; // All bytes enabled
        mem_request = 1'b0;
        l2_mem_read_data = mem_read_buffer;
        l2_mem_ready = 1'b0;
        l2_mem_error = 1'b0;
        
        case (mem_state)
            IDLE: begin
                // Ready to accept new requests
                if (l2_mem_request) begin
                    mem_addr = l2_mem_addr;
                    mem_request = 1'b1;
                    mem_read = l2_mem_read;
                    mem_write = l2_mem_write;
                end
            end
            
            READ_LINE_START, READ_LINE_CONTINUE: begin
                // Read memory in consecutive cycles
                mem_addr = l2_mem_addr + (line_offset * (DATA_WIDTH/8));
                mem_read = 1'b1;
                mem_request = 1'b1;
                
                // Signal L2 ready when all words read
                if (mem_state == READ_LINE_CONTINUE && 
                    mem_ready && 
                    line_offset == (CACHE_LINE_SIZE/(DATA_WIDTH/8) - 1)) begin
                    l2_mem_ready = 1'b1;
                end
            end
            
            WRITE_LINE_START, WRITE_LINE_CONTINUE: begin
                // Write memory in consecutive cycles
                mem_addr = l2_mem_addr + (line_offset * (DATA_WIDTH/8));
                mem_write_data = l2_mem_write_data[line_offset * DATA_WIDTH +: DATA_WIDTH];
                mem_write = 1'b1;
                mem_request = 1'b1;
                
                // Signal L2 ready when all words written
                if (mem_state == WRITE_LINE_CONTINUE && 
                    mem_ready && 
                    line_offset == (CACHE_LINE_SIZE/(DATA_WIDTH/8) - 1)) begin
                    l2_mem_ready = 1'b1;
                end
            end
        endcase
    end
    
    // =====================
    // Page Table Walk Memory Access
    // =====================
    // Simple arbiter for PTW memory access
    logic [$clog2(NUM_CORES)-1:0] ptw_select;
    logic [NUM_CORES-1:0] ptw_grant;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ptw_select <= '0;
        end else if (|ptw_mem_request) begin
            // Simple round-robin selection
            if (ptw_select == NUM_CORES-1) begin
                ptw_select <= '0;
            end else begin
                ptw_select <= ptw_select + 1'b1;
            end
        end
    end
    
    // Grant access to one core at a time
    always_comb begin
        ptw_grant = '0;
        
        // Fixed priority for simplicity
        for (int j = 0; j < NUM_CORES; j++) begin
            if (ptw_mem_request[j] && !|ptw_grant) begin
                ptw_grant[j] = 1'b1;
            end
        end
    end
    
    // Route PTW memory accesses to the main memory interface
    // In a real system this would go through caches, but simplified here
    always_comb begin
        // Default: no access to ptw memory
        for (int j = 0; j < NUM_CORES; j++) begin
            ptw_mem_ack[j] = 1'b0;
            ptw_mem_read_data[j] = '0;
        end
        
        // If not busy with cache line transfer, handle PTW request
        if (mem_state == IDLE && !l2_mem_request) begin
            if (|ptw_grant) begin
                for (int j = 0; j < NUM_CORES; j++) begin
                    if (ptw_grant[j]) begin
                        // Connect the granted core to memory
                        mem_addr = ptw_mem_addr[j];
                        mem_write_data = ptw_mem_write_data[j];
                        mem_read = ptw_mem_read[j];
                        mem_write = ptw_mem_write[j];
                        mem_request = 1'b1;
                        
                        // Update the core with response
                        ptw_mem_ack[j] = mem_ready;
                        ptw_mem_read_data[j] = mem_read_data;
                    end
                end
            end
        end
    end
    
    // =====================
    // Inter-core interrupts for SMP
    // =====================
    // Each core gets a timer and software interrupt
    always_comb begin
        for (int j = 0; j < NUM_CORES; j++) begin
            // Simple timer - would be driven by a real timer peripheral
            timer_interrupt[j] = 1'b0;
            
            // Software interrupt - for inter-processor signaling
            software_interrupt[j] = 1'b0;
        end
    end

endmodule 