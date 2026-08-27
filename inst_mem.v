// Instruction Memory (Read-Only)
module inst_mem (
    input  wire        clk,
    input  wire        mem_read,
    input  wire [31:0] addr,
    output reg  [31:0] read_data
);
    reg [31:0] mem [0:255];

    always @(*) begin
        if (mem_read)
            read_data = mem[addr[9:2]];
        else
            read_data = 32'b0;
    end
endmodule