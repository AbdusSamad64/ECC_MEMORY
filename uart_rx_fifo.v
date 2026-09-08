module uart_rx_fifo (
    input  wire        clk,
    input  wire        rst,
    input  wire        byte_valid,
    input  wire [7:0]  byte_data,
    input  wire        read_clear,
    output reg  [31:0] data_out,
    output reg         full
);
    reg [1:0] byte_count;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out    <= 32'b0;
            full        <= 1'b0;
            byte_count  <= 2'b00;
        end else begin
            if (read_clear) begin
                full       <= 1'b0;
                byte_count <= 2'b00;
            end else if (byte_valid && !full) begin
                case (byte_count)
                    2'd0: data_out[7:0]   <= byte_data;
                    2'd1: data_out[15:8]  <= byte_data;
                    2'd2: data_out[23:16] <= byte_data;
                    2'd3: data_out[31:24] <= byte_data;
                endcase

                if (byte_count == 2'd3) begin
                    full <= 1'b1;
                end else begin
                    byte_count <= byte_count + 2'd1;
                end
            end
        end
    end
endmodule

