module mmu #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter TLB_ENTRIES = 16
)(
    input  logic                    clk,
    input  logic                    rst_n,
    
    // Virtual memory interface
    input  logic [ADDR_WIDTH-1:0]   virt_addr,
    input  logic [1:0]              access_type,  // 00: instr, 01: load, 10: store
    input  logic [1:0]              current_privilege,
    input  logic [DATA_WIDTH-1:0]   satp,         // Supervisor address translation and protection
    
    // Physical memory interface
    output logic [ADDR_WIDTH-1:0]   phys_addr,
    output logic                    tlb_hit,
    output logic                    tlb_miss,
    output logic                    page_fault,
    
    // Memory interface for page table walks
    output logic [ADDR_WIDTH-1:0]   pt_walk_addr,
    output logic                    pt_walk_req,
    input  logic [DATA_WIDTH-1:0]   pt_walk_data,
    input  logic                    pt_walk_ack
);

    // TLB entry structure
    typedef struct packed {
        logic [19:0]                vpn;          // Virtual Page Number
        logic [19:0]                ppn;          // Physical Page Number
        logic                       valid;        // Valid bit
        logic                       dirty;        // Dirty bit
        logic [1:0]                 access_type;  // Access type (R/W/X)
        logic [1:0]                 privilege;    // Required privilege level
    } tlb_entry_t;
    
    // TLB array
    tlb_entry_t [TLB_ENTRIES-1:0]   tlb;
    logic [$clog2(TLB_ENTRIES)-1:0] tlb_index;
    
    // Page table walk state machine
    typedef enum logic [2:0] {
        IDLE,
        LEVEL1,
        LEVEL2,
        LEVEL3,
        UPDATE_TLB,
        FAULT
    } pt_walk_state_t;
    
    pt_walk_state_t                 walk_state;
    logic [ADDR_WIDTH-1:0]          walk_addr;
    logic [1:0]                     walk_level;
    
    // Extract fields from virtual address
    logic [9:0]                     vpn0;         // Level 0 VPN
    logic [9:0]                     vpn1;         // Level 1 VPN
    logic [9:0]                     vpn2;         // Level 2 VPN
    logic [11:0]                    page_offset;  // Page offset
    
    assign vpn0 = virt_addr[21:12];
    assign vpn1 = virt_addr[31:22];
    assign vpn2 = virt_addr[41:32];
    assign page_offset = virt_addr[11:0];
    
    // TLB lookup
    always_comb begin
        tlb_hit = 1'b0;
        tlb_miss = 1'b1;
        phys_addr = virt_addr;  // Default to direct mapping
        
        for (int i = 0; i < TLB_ENTRIES; i++) begin
            if (tlb[i].valid && 
                tlb[i].vpn == virt_addr[31:12] && 
                tlb[i].privilege <= current_privilege) begin
                tlb_hit = 1'b1;
                tlb_miss = 1'b0;
                phys_addr = {tlb[i].ppn, virt_addr[11:0]};
                break;
            end
        end
    end
    
    // Page table walk state machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            walk_state <= IDLE;
            walk_addr <= '0;
            walk_level <= '0;
            pt_walk_req <= 1'b0;
            page_fault <= 1'b0;
        end else begin
            case (walk_state)
                IDLE: begin
                    if (tlb_miss && satp[31]) begin  // Check if paging is enabled
                        walk_state <= LEVEL1;
                        walk_addr <= {satp[21:0], 12'h000} + (vpn2 << 2);
                        walk_level <= 2'd2;
                        pt_walk_req <= 1'b1;
                        page_fault <= 1'b0;
                    end
                end
                
                LEVEL1, LEVEL2, LEVEL3: begin
                    if (pt_walk_ack) begin
                        pt_walk_req <= 1'b0;
                        
                        if (!pt_walk_data[0]) begin  // Check valid bit
                            walk_state <= FAULT;
                            page_fault <= 1'b1;
                        end else if (pt_walk_data[1] || walk_level == 0) begin  // Check if leaf
                            walk_state <= UPDATE_TLB;
                            // Update TLB with new entry
                            tlb[tlb_index].vpn <= virt_addr[31:12];
                            tlb[tlb_index].ppn <= pt_walk_data[31:12];
                            tlb[tlb_index].valid <= 1'b1;
                            tlb[tlb_index].dirty <= 1'b0;
                            tlb[tlb_index].access_type <= access_type;
                            tlb[tlb_index].privilege <= current_privilege;
                        end else begin
                            walk_state <= (walk_state == LEVEL1) ? LEVEL2 : LEVEL3;
                            walk_addr <= {pt_walk_data[31:12], 12'h000} + 
                                       ((walk_state == LEVEL1 ? vpn1 : vpn0) << 2);
                            walk_level <= walk_level - 1;
                            pt_walk_req <= 1'b1;
                        end
                    end
                end
                
                UPDATE_TLB: begin
                    walk_state <= IDLE;
                    tlb_index <= tlb_index + 1;
                end
                
                FAULT: begin
                    walk_state <= IDLE;
                end
                
                default: walk_state <= IDLE;
            endcase
        end
    end
    
    // TLB replacement policy (simple round-robin)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tlb_index <= '0;
        end else if (walk_state == UPDATE_TLB) begin
            tlb_index <= tlb_index + 1;
        end
    end
    
endmodule 