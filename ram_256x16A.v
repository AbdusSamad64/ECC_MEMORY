module ram_256x16A (
    input  wire        CLK,
    input  wire        CEN,   // active-low chip enable
    input  wire        WEN,   // active-low write enable
    input  wire        OEN,   // active-low output enable
    input  wire [7:0]  A,
    input  wire [15:0] D,
    output wire [15:0] Q
);

    reg [15:0] mem [0:255];
    reg [15:0] q_int;

    always @(posedge CLK) begin
        if (!CEN) begin
            if (!WEN)
                mem[A] <= D;
            else
                q_int  <= mem[A];
        end
    end

    assign Q = OEN ? 16'bz : q_int;

endmodule