module uart_top #(
    parameter CLK_FREQ  = 100_000_000, // 100 MHz clock
    parameter BAUD_RATE = 115200
)(
    input  wire        clk,
    input  wire        rst,
    
    // Bus Interface (Connected to soc_interconnect)
    input  wire        re,
    input  wire        we,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    
    // Interrupt Signal (To CPU)
    output wire        rx_interrupt,
    
    // Physical UART Pins
    input  wire        rx_pin,
    output reg         tx_pin
);

    // Register Offsets
    localparam DATA_REG   = 8'h00; // 0x4000_0000
    localparam STATUS_REG = 8'h04; // 0x4000_0004

    // Baud Rate Calculation
    localparam CLOCKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    
    // Internal Signals
    reg  [7:0] rx_data_out;
    wire       rx_ready;
    wire [31:0] rx_word_data;
    wire        rx_fifo_full;
    wire        rx_read_clear;
    wire [7:0]  tx_fifo_byte_data;
    wire        tx_fifo_byte_valid;
    wire        tx_fifo_busy;
    wire        tx_byte_ready;
    wire        tx_word_load;
    wire        tx_busy;

    // ========================================================
    // STATE MACHINE DEFINITIONS (Moved up to fix declaration error)
    // ========================================================
    localparam TX_IDLE  = 2'b00;
    localparam TX_START = 2'b01;
    localparam TX_DATA  = 2'b10;
    localparam TX_STOP  = 2'b11;
    reg [1:0]  tx_state;

    localparam RX_IDLE  = 2'b00;
    localparam RX_START = 2'b01;
    localparam RX_DATA  = 2'b10;
    localparam RX_STOP  = 2'b11;
    reg [1:0]  rx_state;

    // Interrupt Mapping & Status
    assign rx_interrupt  = rx_fifo_full;
    assign tx_byte_ready = (tx_state == TX_IDLE);
    assign tx_busy       = tx_fifo_busy | (tx_state != TX_IDLE);
    assign rx_read_clear = re && (addr[7:0] == DATA_REG) && rx_fifo_full;
    assign tx_word_load  = we && (addr[7:0] == DATA_REG) && !tx_fifo_busy;

    // ========================================================
    // 1. MEMORY-MAPPED I/O LOGIC
    // ========================================================
    
    // READ LOGIC (Combinational/Asynchronous)
    always @(*) begin
        if (re) begin
            case (addr[7:0])
                DATA_REG:   rdata = rx_word_data;
                STATUS_REG: rdata = {30'b0, rx_fifo_full, tx_busy}; 
                default:    rdata = 32'b0;
            endcase
        end else begin
            rdata = 32'b0;
        end
    end

    // ========================================================
    // 2. UART TRANSMITTER (TX FSM)
    // ========================================================
    reg [31:0] tx_clk_cnt;
    reg [2:0]  tx_bit_cnt;
    reg [7:0]  tx_shift_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_state   <= TX_IDLE;
            tx_pin     <= 1'b1; // Idle state is HIGH
            tx_clk_cnt <= 0;
            tx_bit_cnt <= 0;
        end else begin
            case (tx_state)
                TX_IDLE: begin
                    tx_pin <= 1'b1;
                    if (tx_fifo_byte_valid) begin
                        tx_shift_reg <= tx_fifo_byte_data;
                        tx_state     <= TX_START;
                        tx_clk_cnt   <= 0;
                    end
                end
                TX_START: begin
                    tx_pin <= 1'b0; // Start bit is LOW
                    if (tx_clk_cnt < CLOCKS_PER_BIT - 1) begin
                        tx_clk_cnt <= tx_clk_cnt + 1;
                    end else begin
                        tx_clk_cnt <= 0;
                        tx_state   <= TX_DATA;
                    end
                end
                TX_DATA: begin
                    tx_pin <= tx_shift_reg[0]; // Send LSB first
                    if (tx_clk_cnt < CLOCKS_PER_BIT - 1) begin
                        tx_clk_cnt <= tx_clk_cnt + 1;
                    end else begin
                        tx_clk_cnt   <= 0;
                        tx_shift_reg <= tx_shift_reg >> 1;
                        if (tx_bit_cnt < 7) begin
                            tx_bit_cnt <= tx_bit_cnt + 1;
                        end else begin
                            tx_bit_cnt <= 0;
                            tx_state   <= TX_STOP;
                        end
                    end
                end
                TX_STOP: begin
                    tx_pin <= 1'b1; // Stop bit is HIGH
                    if (tx_clk_cnt < CLOCKS_PER_BIT - 1) begin
                        tx_clk_cnt <= tx_clk_cnt + 1;
                    end else begin
                        tx_clk_cnt <= 0;
                        tx_state   <= TX_IDLE;
                    end
                end
            endcase
        end
    end

    // ========================================================
    // 3. UART RECEIVER (RX FSM)
    // ========================================================
    reg [31:0] rx_clk_cnt;
    reg [2:0]  rx_bit_cnt;
    reg        rx_ready_internal;

    assign rx_ready = rx_ready_internal;

    uart_rx_fifo rx_fifo_inst (
        .clk(clk),
        .rst(rst),
        .byte_valid(rx_ready),
        .byte_data(rx_data_out),
        .read_clear(rx_read_clear),
        .data_out(rx_word_data),
        .full(rx_fifo_full)
    );

    uart_tx_fifo tx_fifo_inst (
        .clk(clk),
        .rst(rst),
        .load_word(tx_word_load),
        .word_in(wdata),
        .tx_byte_ready(tx_byte_ready),
        .tx_byte_data(tx_fifo_byte_data),
        .tx_byte_valid(tx_fifo_byte_valid),
        .busy(tx_fifo_busy),
        .tx_done()
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_state          <= RX_IDLE;
            rx_clk_cnt        <= 0;
            rx_bit_cnt        <= 0;
            rx_ready_internal <= 0;
            rx_data_out       <= 8'b0;
        end else begin
            rx_ready_internal <= 0; // Default pulse is low
            
            case (rx_state)
                RX_IDLE: begin
                    if (rx_pin == 1'b0) begin // Start bit detected (LOW)
                        rx_state   <= RX_START;
                        rx_clk_cnt <= 0;
                    end
                end
                RX_START: begin
                    // Wait for half a bit period to sample in the middle
                    if (rx_clk_cnt < (CLOCKS_PER_BIT / 2) - 1) begin
                        rx_clk_cnt <= rx_clk_cnt + 1;
                    end else begin
                        if (rx_pin == 1'b0) begin // Confirm it's still low
                            rx_clk_cnt <= 0;
                            rx_state   <= RX_DATA;
                        end else begin
                            rx_state <= RX_IDLE; // False alarm
                        end
                    end
                end
                RX_DATA: begin
                    if (rx_clk_cnt < CLOCKS_PER_BIT - 1) begin
                        rx_clk_cnt <= rx_clk_cnt + 1;
                    end else begin
                        rx_clk_cnt  <= 0;
                        rx_data_out <= {rx_pin, rx_data_out[7:1]}; // Shift in MSB, data moves right (LSB first)
                        if (rx_bit_cnt < 7) begin
                            rx_bit_cnt <= rx_bit_cnt + 1;
                        end else begin
                            rx_bit_cnt <= 0;
                            rx_state   <= RX_STOP;
                        end
                    end
                end
                RX_STOP: begin
                    if (rx_clk_cnt < CLOCKS_PER_BIT - 1) begin
                        rx_clk_cnt <= rx_clk_cnt + 1;
                    end else begin
                        rx_clk_cnt <= 0;
                        rx_state   <= RX_IDLE;
                        rx_ready_internal <= 1'b1; // Trigger one-clock-cycle ready pulse!
                    end
                end
            endcase
        end
    end
endmodule