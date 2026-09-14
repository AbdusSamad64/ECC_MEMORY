/*module ecc_status_regs (
    input  wire        clk,
    input  wire        re,
    input  wire        we,
    input  wire [31:0]  addr,
    input  wire         sb_sticky,
    input  wire         db_sticky,
    input  wire [31:0]  sb_count,
    input  wire [31:0]  db_count,
    output reg  [31:0]  rdata,
    output wire         clear_pulse    // software write se sticky clear karne ke liye
);
    localparam SB_STICKY_REG = 8'h00;
    localparam DB_STICKY_REG = 8'h04;
    localparam SB_COUNT_REG  = 8'h08;
    localparam DB_COUNT_REG  = 8'h0C;
    localparam CLEAR_REG     = 8'h10;

    assign clear_pulse = we && (addr[7:0] == CLEAR_REG);

    always @(*) begin
        if (re) begin
            case (addr[7:0])
                SB_STICKY_REG: rdata = {31'b0, sb_sticky};
                DB_STICKY_REG: rdata = {31'b0, db_sticky};
                SB_COUNT_REG:  rdata = sb_count;
                DB_COUNT_REG:  rdata = db_count;
                default:       rdata = 32'b0;
            endcase
        end else begin
            rdata = 32'b0;
        end
    end
endmodule*/


module ecc_status_regs (
    input  wire        clk,
    input  wire        re,
    input  wire        we,
    input  wire [31:0] addr,
    input  wire        sb_sticky,
    input  wire        db_sticky,
    input  wire [31:0] sb_count,
    input  wire [31:0] db_count,
    output reg  [31:0] rdata,
    output wire         clear_pulse
);
    localparam SB_STICKY_REG = 8'h00;
    localparam DB_STICKY_REG = 8'h04;
    localparam SB_COUNT_REG  = 8'h08;
    localparam DB_COUNT_REG  = 8'h0C;
    localparam CLEAR_REG     = 8'h10;

    assign clear_pulse = we && (addr[7:0] == CLEAR_REG);

    always @(*) begin
        if (re) begin
            case (addr[7:0])
                SB_STICKY_REG: rdata = {31'b0, sb_sticky};
                DB_STICKY_REG: rdata = {31'b0, db_sticky};
                SB_COUNT_REG:  rdata = sb_count;
                DB_COUNT_REG:  rdata = db_count;
                default:       rdata = 32'b0;
            endcase
        end else begin
            rdata = 32'b0;
        end
    end
endmodule