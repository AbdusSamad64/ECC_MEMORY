// Instruction Memory (Read-Only)
//
// This intentionally models a single-cycle SRAM-like read latency so the CPU
// interface can later be migrated to real instruction SRAM macros without a
// major change in the control-flow assumptions.
/*module inst_mem (
    input  wire        clk,
    input  wire        mem_read,
    input  wire [31:0] addr,
    output reg  [31:0] read_data
);
    reg [31:0] mem [0:255];

    always @(posedge clk) begin
        if (mem_read)
            read_data <= mem[addr[9:2]];
        else
            read_data <= 32'b0;
    end
endmodule*/



//with sram macro

// Instruction Memory (Read-Only) — Real SRAM macro (ram_256x16A) wrapper
// 32-bit word width banane ke liye do 16-bit macros parallel mein use kiye
module inst_mem (
    input  wire        clk,
    input  wire        mem_read,
    input  wire [31:0] addr,
    output wire [31:0] read_data
);

    // Lower 16 bits
    ram_256x16A mem_lo (
        .CLK (clk),
        .CEN (~mem_read),   // active-low chip enable
        .WEN (1'b1),        // hamesha 1 = read-only, kabhi write nahi
        .OEN (1'b0),        // hamesha 0 = output hamesha enabled
        .A   (addr[9:2]),   // 8-bit word address
        .D   (16'b0),        // write data unused (read-only)
        .Q   (read_data[15:0])
    );

    // Upper 16 bits
    ram_256x16A mem_hi (
        .CLK (clk),
        .CEN (~mem_read),
        .WEN (1'b1),
        .OEN (1'b0),
        .A   (addr[9:2]),
        .D   (16'b0),
        .Q   (read_data[31:16])
    );

endmodule
