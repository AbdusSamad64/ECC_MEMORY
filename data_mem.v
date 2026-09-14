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
module data_mem (
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
endmodule