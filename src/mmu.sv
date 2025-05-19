module mmu #(
    parameter ADDR_WIDTH = 64,
    parameter DATA_WIDTH = 64,
    parameter PAGE_LEVELS = 3,       // Sv39 for RV64
    parameter PAGE_SIZE = 4096,      // 4KB pages
    parameter PTE_SIZE = 8,          // 64-bit PTEs for RV64
    parameter SATP_MODE = 4'h8       // Sv39
)(
    input  logic                          clk,
    input  logic                          rst_n,
    
    // CPU interface
    input  logic [ADDR_WIDTH-1:0]         virt_addr,
    input  logic                          mem_read,
    input  logic                          mem_write,
    input  logic [2:0]                    mem_size,    // 000:byte, 001:half, 010:word, 011:double
    input  logic                          mem_req,
    output logic [ADDR_WIDTH-1:0]         phys_addr,
    output logic                          page_fault,
    output logic                          access_fault,
    output logic                          mem_ack,
    
    // TLB interface
    output logic                          tlb_flush,
    
    // CSR interface
    input  logic [ADDR_WIDTH-1:0]         satp_reg,      // Supervisor address translation and protection register
    input  logic                          mstatus_sum,    // Supervisor user memory access
    input  logic                          mstatus_mxr,    // Make executable readable
    input  logic [1:0]                    current_mode,   // 00:U, 01:S, 11:M
    
    // Memory interface for page table walks
    output logic [ADDR_WIDTH-1:0]         mem_paddr,
    output logic                          mem_pread,
    output logic                          mem_pwrite,
    output logic [DATA_WIDTH-1:0]         mem_pwrite_data,
    input  logic [DATA_WIDTH-1:0]         mem_pread_data,
    output logic                          mem_preq,
    input  logic                          mem_pack
);
    // TLB parameters
    localparam TLB_ENTRIES = 32;
    localparam VPN_BITS = 27;     // 9 bits x 3 levels for Sv39
    localparam PPN_BITS = 44;     // 44 bits physical address
    
    // SATP register fields
    logic [3:0]             satp_mode;
    logic [43:0]            satp_ppn;
    
    // Page table entry fields
    typedef struct packed {
        logic v;       // Valid
        logic r;       // Read permission
        logic w;       // Write permission 
        logic x;       // Execute permission
        logic u;       // User mode access
        logic g;       // Global mapping
        logic a;       // Accessed
        logic d;       // Dirty
        logic [1:0] rsw;    // Reserved for software
        logic [43:0] ppn;   // Physical page number
        logic [9:0] reserved;
    } pte_t;
    
    // TLB entry
    typedef struct packed {
        logic valid;
        logic [VPN_BITS-1:0] vpn;
        logic [PPN_BITS-1:0] ppn;
        logic u;        // User page
        logic g;        // Global page
        logic r, w, x;  // Access permissions
        logic a, d;     // Accessed and dirty bits
    } tlb_entry_t;
    
    // TLB
    tlb_entry_t tlb [0:TLB_ENTRIES-1];
    logic [$clog2(TLB_ENTRIES)-1:0] tlb_replace_index;
    
    // FSM states
    typedef enum logic [2:0] {
        IDLE,
        TLB_LOOKUP,
        PAGE_WALK_L1,
        PAGE_WALK_L2,
        PAGE_WALK_L3,
        UPDATE_TLB,
        COMPLETE_ACCESS
    } state_t;
    
    state_t state, next_state;
    
    // Internal registers
    logic [ADDR_WIDTH-1:0] vaddr_reg;
    logic mem_read_reg, mem_write_reg;
    logic [2:0] mem_size_reg;
    pte_t current_pte;
    logic [ADDR_WIDTH-1:0] pte_addr;
    logic [ADDR_WIDTH-1:0] pt_base;
    logic [1:0] page_level;
    logic tlb_hit;
    logic [$clog2(TLB_ENTRIES)-1:0] tlb_hit_index;
    
    // VPN extraction for Sv39
    logic [8:0] vpn [0:2];  // VPN[0] is the least significant
    
    // SATP decode
    assign satp_mode = satp_reg[63:60];
    assign satp_ppn = satp_reg[43:0];
    
    // VPN extraction
    assign vpn[0] = virt_addr[20:12];
    assign vpn[1] = virt_addr[29:21];
    assign vpn[2] = virt_addr[38:30];
    
    // Page offset
    logic [11:0] page_offset;
    assign page_offset = virt_addr[11:0];
    
    // Page table base address
    assign pt_base = {satp_ppn, 12'b0};
    
    // Main state machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            vaddr_reg <= '0;
            mem_read_reg <= 1'b0;
            mem_write_reg <= 1'b0;
            mem_size_reg <= 3'b0;
            page_level <= 2'b0;
            tlb_replace_index <= '0;
            
            // Initialize TLB
            for (int i = 0; i < TLB_ENTRIES; i++) begin
                tlb[i].valid <= 1'b0;
            end
        end else begin
            state <= next_state;
            
            // Register virtual address and request type on new request
            if (state == IDLE && mem_req) begin
                vaddr_reg <= virt_addr;
                mem_read_reg <= mem_read;
                mem_write_reg <= mem_write;
                mem_size_reg <= mem_size;
            end
            
            // Update page level during page walk
            if (state == PAGE_WALK_L1 && mem_pack) begin
                page_level <= 2'd1;
            end else if (state == PAGE_WALK_L2 && mem_pack) begin
                page_level <= 2'd2;
            end
            
            // Update current PTE during page walk
            if ((state == PAGE_WALK_L1 || state == PAGE_WALK_L2 || state == PAGE_WALK_L3) && mem_pack) begin
                current_pte <= mem_pread_data;
            end
            
            // Update TLB replacement counter
            if (state == UPDATE_TLB) begin
                tlb_replace_index <= tlb_replace_index + 1'b1;
                
                // Update TLB entry
                tlb[tlb_replace_index].valid <= 1'b1;
                tlb[tlb_replace_index].vpn <= {vpn[2], vpn[1], vpn[0]};
                tlb[tlb_replace_index].ppn <= current_pte.ppn;
                tlb[tlb_replace_index].u <= current_pte.u;
                tlb[tlb_replace_index].g <= current_pte.g;
                tlb[tlb_replace_index].r <= current_pte.r;
                tlb[tlb_replace_index].w <= current_pte.w;
                tlb[tlb_replace_index].x <= current_pte.x;
                tlb[tlb_replace_index].a <= current_pte.a;
                tlb[tlb_replace_index].d <= current_pte.d;
            end
            
            // Handle TLB flush
            if (tlb_flush) begin
                for (int i = 0; i < TLB_ENTRIES; i++) begin
                    tlb[i].valid <= 1'b0;
                end
            end
        end
    end
    
    // TLB lookup logic
    always_comb begin
        tlb_hit = 1'b0;
        tlb_hit_index = '0;
        
        for (int i = 0; i < TLB_ENTRIES; i++) begin
            if (tlb[i].valid && tlb[i].vpn == {vpn[2], vpn[1], vpn[0]}) begin
                tlb_hit = 1'b1;
                tlb_hit_index = i[$clog2(TLB_ENTRIES)-1:0];
            end
        end
    end
    
    // Next state logic
    always_comb begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (mem_req) begin
                    if (satp_mode == 4'h0 || current_mode == 2'b11) begin
                        // No translation in machine mode or when satp.MODE=Bare
                        next_state = COMPLETE_ACCESS;
                    end else begin
                        next_state = TLB_LOOKUP;
                    end
                end
            end
            
            TLB_LOOKUP: begin
                if (tlb_hit) begin
                    next_state = COMPLETE_ACCESS;
                end else begin
                    next_state = PAGE_WALK_L1;
                end
            end
            
            PAGE_WALK_L1: begin
                if (mem_pack) begin
                    if (!current_pte.v || (!current_pte.r && current_pte.w)) begin
                        // Invalid PTE
                        next_state = IDLE;
                    end else if (current_pte.r || current_pte.x) begin
                        // Leaf PTE
                        next_state = UPDATE_TLB;
                    end else begin
                        // Non-leaf PTE, continue page walk
                        next_state = PAGE_WALK_L2;
                    end
                end
            end
            
            PAGE_WALK_L2: begin
                if (mem_pack) begin
                    if (!current_pte.v || (!current_pte.r && current_pte.w)) begin
                        // Invalid PTE
                        next_state = IDLE;
                    end else if (current_pte.r || current_pte.x) begin
                        // Leaf PTE
                        next_state = UPDATE_TLB;
                    end else begin
                        // Non-leaf PTE, continue page walk
                        next_state = PAGE_WALK_L3;
                    end
                end
            end
            
            PAGE_WALK_L3: begin
                if (mem_pack) begin
                    if (!current_pte.v || (!current_pte.r && current_pte.w)) begin
                        // Invalid PTE
                        next_state = IDLE;
                    end else if (current_pte.r || current_pte.x) begin
                        // Leaf PTE
                        next_state = UPDATE_TLB;
                    end else begin
                        // Invalid last-level PTE
                        next_state = IDLE;
                    end
                end
            end
            
            UPDATE_TLB: begin
                next_state = COMPLETE_ACCESS;
            end
            
            COMPLETE_ACCESS: begin
                next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // Address translation and permission check
    always_comb begin
        // Default values
        phys_addr = virt_addr;  // Default to identity mapping
        page_fault = 1'b0;
        access_fault = 1'b0;
        mem_ack = 1'b0;
        mem_paddr = '0;
        mem_pread = 1'b0;
        mem_pwrite = 1'b0;
        mem_pwrite_data = '0;
        mem_preq = 1'b0;
        tlb_flush = 1'b0;
        
        case (state)
            IDLE: begin
                mem_ack = 1'b0;
                
                // Handle TLB flush on SATP write (implicit based on CSR write)
                if (satp_reg != '0) begin
                    tlb_flush = 1'b0;  // Would be driven by CSR logic
                end
            end
            
            TLB_LOOKUP: begin
                if (tlb_hit) begin
                    // TLB hit path
                    logic [PPN_BITS-1:0] ppn;
                    logic permission_ok;
                    
                    ppn = tlb[tlb_hit_index].ppn;
                    
                    // Construct physical address
                    phys_addr = {ppn, page_offset};
                    
                    // Permission check
                    permission_ok = 1'b0;
                    
                    // User mode access allowed?
                    if (current_mode == 2'b00 && !tlb[tlb_hit_index].u) begin
                        permission_ok = 1'b0;  // User cannot access supervisor pages
                    end 
                    // Supervisor mode access to user page
                    else if (current_mode == 2'b01 && tlb[tlb_hit_index].u && !mstatus_sum) begin
                        permission_ok = 1'b0;  // Supervisor cannot access user pages without SUM
                    end else begin
                        // Read permission
                        if (mem_read_reg && (tlb[tlb_hit_index].r || (tlb[tlb_hit_index].x && mstatus_mxr))) begin
                            permission_ok = 1'b1;
                        end
                        // Write permission
                        else if (mem_write_reg && tlb[tlb_hit_index].w) begin
                            permission_ok = 1'b1;
                        end
                    end
                    
                    if (!permission_ok) begin
                        page_fault = 1'b1;
                    end
                end
            end
            
            PAGE_WALK_L1: begin
                // First level page table walk
                mem_paddr = pt_base + ({vpn[2], 3'b0} << 3);  // PTE is 8 bytes
                mem_pread = 1'b1;
                mem_preq = 1'b1;
            end
            
            PAGE_WALK_L2: begin
                // Second level page table walk
                mem_paddr = {current_pte.ppn, 12'b0} + ({vpn[1], 3'b0} << 3);
                mem_pread = 1'b1;
                mem_preq = 1'b1;
            end
            
            PAGE_WALK_L3: begin
                // Third level page table walk
                mem_paddr = {current_pte.ppn, 12'b0} + ({vpn[0], 3'b0} << 3);
                mem_pread = 1'b1;
                mem_preq = 1'b1;
            end
            
            UPDATE_TLB: begin
                // Check permissions based on current_pte
                logic permission_ok;
                
                permission_ok = 1'b0;
                
                // User mode access allowed?
                if (current_mode == 2'b00 && !current_pte.u) begin
                    permission_ok = 1'b0;  // User cannot access supervisor pages
                end 
                // Supervisor mode access to user page
                else if (current_mode == 2'b01 && current_pte.u && !mstatus_sum) begin
                    permission_ok = 1'b0;  // Supervisor cannot access user pages without SUM
                end else begin
                    // Read permission
                    if (mem_read_reg && (current_pte.r || (current_pte.x && mstatus_mxr))) begin
                        permission_ok = 1'b1;
                    end
                    // Write permission
                    else if (mem_write_reg && current_pte.w) begin
                        permission_ok = 1'b1;
                    end
                end
                
                if (!permission_ok) begin
                    page_fault = 1'b1;
                end
                
                // Set A and D bits - would normally do an atomic update to memory
                if (permission_ok) begin
                    // Modify PTE to set A bit and D bit (if write)
                    pte_t updated_pte;
                    updated_pte = current_pte;
                    updated_pte.a = 1'b1;
                    
                    if (mem_write_reg) begin
                        updated_pte.d = 1'b1;
                    end
                    
                    // In a real implementation, we would update the PTE in memory atomically
                    // This is simplified for this model
                    current_pte = updated_pte;
                end
            end
            
            COMPLETE_ACCESS: begin
                mem_ack = 1'b1;
                
                if (satp_mode == 4'h0 || current_mode == 2'b11) begin
                    // No translation in machine mode or when satp.MODE=Bare
                    phys_addr = vaddr_reg;
                end else if (tlb_hit) begin
                    // Use address from TLB
                    phys_addr = {tlb[tlb_hit_index].ppn, page_offset};
                end else begin
                    // Use address from page table walk
                    case (page_level)
                        2'd0: phys_addr = {current_pte.ppn, vaddr_reg[11:0]};
                        2'd1: begin
                            // Megapage: top-level PTE maps 1GB, use vpn[0] and vpn[1] as part of offset
                            phys_addr = {current_pte.ppn[43:18], vpn[1], vpn[0], page_offset};
                        end
                        2'd2: begin
                            // Superpage: mid-level PTE maps 2MB, use vpn[0] as part of offset
                            phys_addr = {current_pte.ppn[43:9], vpn[0], page_offset};
                        end
                        default: phys_addr = {current_pte.ppn, page_offset};
                    endcase
                end
            end
            
            default: begin
                // Default case
                mem_ack = 1'b0;
            end
        endcase
    end

endmodule 
