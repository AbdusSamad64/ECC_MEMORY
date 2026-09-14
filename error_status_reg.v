module error_status_reg #(
    parameter CNT_WIDTH = 32
)(
    input clk,
    input rst_n,
    input single_err_in,
    input double_err_in,
    input clear,

    output reg single_err_sticky,
    output reg double_err_sticky,
    output reg [CNT_WIDTH-1:0] single_err_count,
    output reg [CNT_WIDTH-1:0] double_err_count
);

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            single_err_sticky <= 1'b0;
            double_err_sticky <= 1'b0;

            single_err_count <= {CNT_WIDTH{1'b0}};
            double_err_count <= {CNT_WIDTH{1'b0}};

        end

        else begin

            if (clear) begin
                single_err_sticky <= 1'b0;
                double_err_sticky <= 1'b0;
            end

            if (single_err_in) begin
                single_err_sticky <= 1'b1;
                single_err_count <= single_err_count + 1'b1;
            end

            if (double_err_in) begin
                double_err_sticky <= 1'b1;
                double_err_count <= double_err_count + 1'b1;
            end

        end

    end

endmodule