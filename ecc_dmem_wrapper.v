// ecc_dmem_wrapper.v
// Top module ke liye interface bilkul PURANI data_mem jaisi hai (32-bit in/out)
// Andar SECDED encode-on-write, decode-on-read (sync SRAM ke sath) hota hai
/*module ecc_dmem_wrapper (
    input  wire        clk,
    input  wire        rst, 
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [31:0] addr,
    input  wire [31:0] write_data,
    output wire [31:0] read_data,

    // Optional ECC status (monitoring ke liye, chhor bhi sakte ho unconnected)
    output wire         single_err_o,
    output wire         double_err_o,
    output wire         no_err_o,
    output wire        double_err_irq   // <-- NAYA
);

    wire [38:0] enc_codeword;
    wire [38:0] raw_codeword_from_mem;

    // --- WRITE PATH: encode combinationally, phir sync-store ---
    secded_encoder #(
        .DATA_WIDTH(32), .PARITY_WIDTH(6)
    ) u_enc (
        .data_in  (write_data),
        .codeword (enc_codeword)
    );

    // --- Asal SRAM-jaisi sync memory (tumhari data_mem, 39-bit wide) ---
    data_mem u_dmem (
        .clk       (clk),
        .mem_read  (mem_read),
        .mem_write (mem_write),
        .addr      (addr),
        .write_cw  (enc_codeword),
        .read_cw   (raw_codeword_from_mem)
    );

    // --- READ PATH: sync-read se aaya codeword ab decode karo ---
    secded_decoder #(
        .DATA_WIDTH(32), .PARITY_WIDTH(6)
    ) u_dec (
        .codeword_in (raw_codeword_from_mem),
        .data_out    (read_data),
        .single_err  (single_err_o),
        .double_err  (double_err_o),
        .no_err      (no_err_o)
    );

endmodule*/


// ecc_dmem_wrapper.v — updated with status tracking
/*module ecc_dmem_wrapper (
    input  wire        clk,
    input  wire        rst,             // <-- NAYA
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [31:0] addr,
    input  wire [31:0] write_data,
    output wire [31:0] read_data,

    output wire        double_err_irq   // <-- NAYA: CPU ko interrupt bhejne ke liye
);

    wire [38:0] enc_codeword;
    wire [38:0] raw_codeword_from_mem;
    wire single_err, double_err;

    secded_encoder #(.DATA_WIDTH(32), .PARITY_WIDTH(6)) u_enc (
        .data_in  (write_data),
        .codeword (enc_codeword)
    );

    data_mem u_dmem (
        .clk       (clk),
        .mem_read  (mem_read),
        .mem_write (mem_write),
        .addr      (addr),
        .write_cw  (enc_codeword),
        .read_cw   (raw_codeword_from_mem)
    );

    secded_decoder #(.DATA_WIDTH(32), .PARITY_WIDTH(6)) u_dec (
        .codeword_in (raw_codeword_from_mem),
        .data_out    (read_data),
        .single_err  (single_err),
        .double_err  (double_err),
        .no_err      ()
    );

    // --- Status tracking (sticky flags + counters) ---
    wire sb_sticky, db_sticky;
    wire [31:0] sb_count, db_count;

    error_status_reg #(.CNT_WIDTH(32)) u_err_status (
        .clk               (clk),
        .rst_n             (~rst),
        .single_err_in     (single_err),
        .double_err_in     (double_err),
        .clear             (1'b0),   // abhi hardcode, neeche software-clear add karenge
        .single_err_sticky (sb_sticky),
        .double_err_sticky (db_sticky),
        .single_err_count  (sb_count),
        .double_err_count  (db_count)
    );

    // Double-bit error ko seedha interrupt bana do (jaisa UART karta tha)
    assign double_err_irq = db_sticky;

endmodule*/




//finalize

module ecc_dmem_wrapper (
    input  wire        clk,
    input  wire        rst,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [31:0] addr,
    input  wire [31:0] write_data,
    output wire [31:0] read_data,

    output wire        double_err_irq,

    // NAYE OUTPUTS — status regs ke liye
    output wire         sb_sticky_o,
    output wire         db_sticky_o,
    output wire [31:0]  sb_count_o,
    output wire [31:0]  db_count_o,
	 
	 // --- NAYA: Fault Injection (test-only) ---
    input  wire         fi_en,
    input  wire [38:0]  fi_mask
);

    wire [38:0] enc_codeword;
    wire [38:0] raw_codeword_from_mem;
	 wire [38:0] faulty_codeword;      // <-- NAYA
    wire single_err, double_err;

    secded_encoder #(.DATA_WIDTH(32), .PARITY_WIDTH(6)) u_enc (
        .data_in  (write_data),
        .codeword (enc_codeword)
    );

    data_mem u_dmem (
        .clk       (clk),
        .mem_read  (mem_read),
        .mem_write (mem_write),
        .addr      (addr),
        .write_cw  (enc_codeword),
        .read_cw   (raw_codeword_from_mem)
    );

	 // --- NAYA: fault injection, sirf READ path par, memory ke baad ---
    assign faulty_codeword = fi_en ? (raw_codeword_from_mem ^ fi_mask) : raw_codeword_from_mem;
	 
    secded_decoder #(.DATA_WIDTH(32), .PARITY_WIDTH(6)) u_dec (
        .codeword_in (faulty_codeword),
        .data_out    (read_data),
        .single_err  (single_err),
        .double_err  (double_err),
        .no_err      ()
    );

    wire sb_sticky, db_sticky;
    wire [31:0] sb_count, db_count;

    error_status_reg #(.CNT_WIDTH(32)) u_err_status (
        .clk               (clk),
        .rst_n             (~rst),
        .single_err_in     (single_err),
        .double_err_in     (double_err),
        .clear             (1'b0),
        .single_err_sticky (sb_sticky),
        .double_err_sticky (db_sticky),
        .single_err_count  (sb_count),
        .double_err_count  (db_count)
    );

    assign double_err_irq = db_sticky;

    // NAYE ASSIGNS — bahar expose karo
    assign sb_sticky_o = sb_sticky;
    assign db_sticky_o = db_sticky;
    assign sb_count_o  = sb_count;
    assign db_count_o  = db_count;

endmodule