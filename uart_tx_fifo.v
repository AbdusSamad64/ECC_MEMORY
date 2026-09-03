module uart_tx_fifo (
    input  wire        clk,
    input  wire        rst,
    input  wire        load_word,
    input  wire [31:0] word_in,
    input  wire        tx_byte_ready,
    output reg  [7:0]  tx_byte_data,
    output reg         tx_byte_valid,
    output reg         busy,
    output reg         tx_done
);
    reg [31:0] word_buf;
    reg [1:0]  byte_index;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            word_buf      <= 32'b0;
            byte_index    <= 2'b00;
            tx_byte_data  <= 8'b0;
            tx_byte_valid <= 1'b0;
            busy          <= 1'b0;
            tx_done       <= 1'b0;
        end else begin
            tx_byte_valid <= 1'b0;
            tx_done       <= 1'b0;

            if (load_word && !busy) begin
                word_buf   <= word_in;
                byte_index <= 2'b00;
                busy       <= 1'b1;
            end else if (busy && tx_byte_ready && !tx_byte_valid) begin
                case (byte_index)
                    2'd0: tx_byte_data <= word_buf[7:0];
                    2'd1: tx_byte_data <= word_buf[15:8];
                    2'd2: tx_byte_data <= word_buf[23:16];
                    2'd3: tx_byte_data <= word_buf[31:24];
                endcase
                tx_byte_valid <= 1'b1;

                if (byte_index == 2'd3) begin
                    busy    <= 1'b0;
                    tx_done <= 1'b1;
                end else begin
                    byte_index <= byte_index + 2'd1;
                end
            end
        end
    end
endmodule
