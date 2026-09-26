// Data Memory (Read/Write)
//
// This model intentionally behaves like a simple SRAM block with one-cycle
// read latency and one-cycle write capture.  Real SRAM macros typically do not
// provide combinational read data; they present the selected word on the next
// clock edge.  Keeping this timing model makes the CPU interface compatible
// with a later replacement by real SRAM macros.
/*module data_mem (
    input  wire        clk,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [31:0] addr,
    input  wire [31:0] write_data,
    output reg  [31:0] read_data
);
    reg [31:0] mem [0:255];

    // Read latency: one cycle delayed, like a real SRAM macro.
    always @(posedge clk) begin
        if (mem_read)
            read_data <= mem[addr[9:2]];
        else
            read_data <= 32'b0;
    end

    // Write: captured on active clock edge.
    always @(posedge clk) begin
        if (mem_write) begin
            mem[addr[9:2]] <= write_data;
        end
    end
endmodule*/


//secded ECC mem

// data_mem.v — ab 39-bit wide, taake ECC codeword store ho sake
// Read/Write dono sync hain (real SRAM jaisa) — bilkul jaisa tumne banaya tha
/*module data_mem (
    input  wire        clk,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [31:0] addr,
    input  wire [38:0] write_cw,     // <-- ab 39-bit codeword input leta hai
    output reg  [38:0] read_cw       // <-- ab 39-bit codeword output deta hai
);
    reg [38:0] mem [0:255];

    // Read latency: one cycle delayed, jaisa real SRAM macro
    always @(posedge clk) begin
        if (mem_read)
            read_cw <= mem[addr[9:2]];
        else
            read_cw <= 39'b0;
    end

    // Write: captured on active clock edge
    always @(posedge clk) begin
        if (mem_write) begin
            mem[addr[9:2]] <= write_cw;
        end
    end
endmodule*/


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
