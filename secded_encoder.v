module secded_encoder #(
    parameter DATA_WIDTH   = 32,
    parameter PARITY_WIDTH = 6,
    parameter CODE_WIDTH   = DATA_WIDTH + PARITY_WIDTH,
    parameter TOTAL_WIDTH  = CODE_WIDTH + 1
)(
    input  [DATA_WIDTH-1:0] data_in,
    output reg [TOTAL_WIDTH-1:0] codeword
);

    reg [CODE_WIDTH:1] ham;

    integer d_idx;
    integer p;
    integer r;
    integer pk;
    reg par;

    function is_pow2;
        input pos;
        begin
            is_pow2 = (pos != 0) && ((pos & (pos-1)) == 0);
        end
    endfunction

    always @(*) begin

        // 1) Scatter data bits
        d_idx = 0;

        for (p = 1; p <= CODE_WIDTH; p = p + 1) begin
            if (!is_pow2(p)) begin
                ham[p] = data_in[d_idx];
                d_idx = d_idx + 1;
            end
            else begin
                ham[p] = 1'b0;
            end
        end

        // 2) Compute Hamming parity bits
        for (r = 0; r < PARITY_WIDTH; r = r + 1) begin

            pk = (1 << r);
            par = 1'b0;

            for (p = 1; p <= CODE_WIDTH; p = p + 1) begin
                if ((((p >> r) & 1) == 1) && (p != pk))
                    par = par ^ ham[p];
            end

            ham[pk] = par;
        end

        // 3) Overall parity
        codeword[0] = ^ham[CODE_WIDTH:1];
        codeword[CODE_WIDTH:1] = ham[CODE_WIDTH:1];

    end

endmodule