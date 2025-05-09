module free_list #(
    parameter NUM_PHYSICAL_REGS = 64,
    parameter TAG_WIDTH = 6  // Changed to match physical register width
)(
    input  logic                     clk,
    input  logic                     rst_n,
    
    // Read interface
    input  logic                     read,
    output logic [TAG_WIDTH-1:0]     read_tag,
    output logic                     read_valid,
    
    // Return interface
    input  logic [TAG_WIDTH-1:0]     return_tag,
    input  logic                     return_valid,
    
    // Status
    output logic                     empty,
    output logic                     full
);

    // Free list storage
    logic [TAG_WIDTH-1:0] free_list_storage [NUM_PHYSICAL_REGS-1:0];
    logic [TAG_WIDTH:0]   count;
    logic [TAG_WIDTH-1:0] head_ptr;
    logic [TAG_WIDTH-1:0] tail_ptr;
    
    // Status signals
    assign empty = (count == '0);
    assign full  = (count == TAG_WIDTH'(NUM_PHYSICAL_REGS));
    
    // Read valid signal
    assign read_valid = !empty;
    
    // Read tag output
    assign read_tag = free_list_storage[head_ptr];
    
    // Free list management
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Initialize free list with all physical registers except architectural registers
            for (int i = 0; i < NUM_PHYSICAL_REGS - 32; i++) begin
                free_list_storage[i] <= TAG_WIDTH'(i + 32);
            end
            head_ptr <= '0;
            tail_ptr <= TAG_WIDTH'(NUM_PHYSICAL_REGS - 32);
            count    <= TAG_WIDTH'(NUM_PHYSICAL_REGS - 32);
        end else begin
            // Read from free list
            if (read && read_valid) begin
                head_ptr <= head_ptr + TAG_WIDTH'(1);
                count    <= count - TAG_WIDTH'(1);
            end
            
            // Return to free list
            if (return_valid) begin
                free_list_storage[tail_ptr] <= return_tag;
                tail_ptr <= tail_ptr + TAG_WIDTH'(1);
                count    <= count + TAG_WIDTH'(1);
            end
        end
    end

endmodule 
