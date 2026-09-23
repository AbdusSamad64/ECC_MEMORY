


//with sram amcro


// Data Memory (ECC codeword storage) — Real SRAM macro (ram_256x16A) wrapper
// 39-bit codeword banane ke liye teen 16-bit macros parallel mein use kiye
// (32-bit data + 7-bit SECDED parity; teesri macro mein 9 bits unused)
module data_mem (
    input  wire        clk,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [31:0] addr,
    input  wire [38:0] write_cw,     // 39-bit codeword input
    output wire [38:0] read_cw       // 39-bit codeword output
);

    wire        cen = ~(mem_read | mem_write);  // active-low: enable jab read ya write ho
    wire        wen = ~mem_write;                // active-low: 0 = write, 1 = read
    wire [7:0]  addr_word = addr[9:2];            // 8-bit word address

    wire [15:0] q2_full;   // teesri macro ka poora 16-bit output (7 bits use honge)

    // Macro #1 — codeword bits [15:0]
    ram_256x16A mem_0 (
        .CLK (clk),
        .CEN (cen),
        .WEN (wen),
        .OEN (1'b0),
        .A   (addr_word),
        .D   (write_cw[15:0]),
        .Q   (read_cw[15:0])
    );

    // Macro #2 — codeword bits [31:16]
    ram_256x16A mem_1 (
        .CLK (clk),
        .CEN (cen),
        .WEN (wen),
        .OEN (1'b0),
        .A   (addr_word),
        .D   (write_cw[31:16]),
        .Q   (read_cw[31:16])
    );

    // Macro #3 — codeword bits [38:32] (sirf 7 bits, baaki 9 bits unused/padded)
    ram_256x16A mem_2 (
        .CLK (clk),
        .CEN (cen),
        .WEN (wen),
        .OEN (1'b0),
        .A   (addr_word),
        .D   ({9'b0, write_cw[38:32]}),
        .Q   (q2_full)
    );

    assign read_cw[38:32] = q2_full[6:0];  // sirf lower 7 bits chahiye

endmodule