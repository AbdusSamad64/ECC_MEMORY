module secded_decoder #(
    parameter DATA_WIDTH   = 32,
    parameter PARITY_WIDTH = 6,
    parameter CODE_WIDTH   = DATA_WIDTH + PARITY_WIDTH,
    parameter TOTAL_WIDTH  = CODE_WIDTH + 1
)(
    input  [TOTAL_WIDTH-1:0] codeword_in,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg single_err,
    output reg double_err,
    output reg no_err
);

    reg [CODE_WIDTH:1] ham;
    reg [CODE_WIDTH:1] ham_corr;

    reg overall_calc;
    reg overall_check;

    reg [PARITY_WIDTH-1:0] syndrome;

    integer d_idx;
    integer p;
    integer r;

    reg s;

    function is_pow2;
        input pos;
        begin
            is_pow2 = (pos != 0) && ((pos & (pos-1)) == 0);
        end
    endfunction

    always @(*) begin

        // Get Hamming field
        ham = codeword_in[CODE_WIDTH:1];

        // Calculate syndrome
        for (r = 0; r < PARITY_WIDTH; r = r + 1) begin

            s = 1'b0;

            for (p = 1; p <= CODE_WIDTH; p = p + 1) begin
                if (((p >> r) & 1) == 1)
                    s = s ^ ham[p];
            end

            syndrome[r] = s;

        end

        // Overall parity check
        overall_calc = ^ham;
        overall_check = overall_calc ^ codeword_in[0];

        // Default: no correction
        ham_corr = ham;

        // No error
        if ((syndrome == {PARITY_WIDTH{1'b0}}) &&
            (overall_check == 1'b0)) begin

            single_err = 1'b0;
            double_err = 1'b0;
            no_err     = 1'b1;

        end

        // Single-bit error inside Hamming field
        else if ((syndrome != {PARITY_WIDTH{1'b0}}) &&
                 (overall_check == 1'b1)) begin

            ham_corr[syndrome] = ~ham[syndrome];

            single_err = 1'b1;
            double_err = 1'b0;
            no_err     = 1'b0;

        end

        // Error in overall parity bit
        else if ((syndrome == {PARITY_WIDTH{1'b0}}) &&
                 (overall_check == 1'b1)) begin

            single_err = 1'b1;
            double_err = 1'b0;
            no_err     = 1'b0;

        end

        // Double-bit error
        else begin

            single_err = 1'b0;
            double_err = 1'b1;
            no_err     = 1'b0;

        end

        // Extract data bits
        d_idx = 0;

        for (p = 1; p <= CODE_WIDTH; p = p + 1) begin

            if (!is_pow2(p)) begin
                data_out[d_idx] = ham_corr[p];
                d_idx = d_idx + 1;
            end

        end

    end

endmodule