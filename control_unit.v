module control_unit (
    input  wire       clk,
    input  wire       rst,
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    input  wire       zero,
    output reg        ir_write,
    output reg        pc_write,
    output reg        reg_write,
    output reg        mem_write,
    output reg        i_or_d,
    output reg        mem_read,
    output reg        mem_to_reg,
    output reg  [1:0] alu_src_a, // 00: PC, 01: Reg A, 10: OldPC
    output reg  [1:0] alu_src_b, // 00: Reg B, 01: 4, 10: Imm
    output reg        pc_source, // 0: ALU Result (PC+4), 1: ALUOut (Target)
    output reg  [3:0] alu_ctrl
);

    // FSM States
    localparam FETCH     = 3'b000;
    localparam DECODE    = 3'b001;
    localparam EXECUTE   = 3'b010;
    localparam MEMORY    = 3'b011;
    localparam WRITEBACK = 3'b100;
    localparam BRANCH    = 3'b101;

    reg [2:0] state, next_state;

    // FSM State Register
    always @(posedge clk or posedge rst) begin
        if (rst) state <= FETCH;
        else     state <= next_state;
    end

    // Next State Logic
    always @(*) begin
        case (state)
            FETCH:   next_state = DECODE;
            DECODE: begin
                case (opcode)
                    7'b0110011, 7'b0010011, 
                    7'b0000011, 7'b0100011: next_state = EXECUTE;
                    7'b1100011:             next_state = BRANCH;
                    default:                next_state = FETCH;
                endcase
            end
            EXECUTE:   next_state = (opcode == 7'b0000011 || opcode == 7'b0100011) ? MEMORY : WRITEBACK;
            MEMORY:    next_state = (opcode == 7'b0000011) ? WRITEBACK : FETCH;
            WRITEBACK: next_state = FETCH;
            BRANCH:    next_state = FETCH;
            default:   next_state = FETCH;
        endcase
    end

    // Control Output Logic
    always @(*) begin
        // Defaults (Prevents Latch)
        ir_write   = 0; 
        pc_write   = 0; 
        reg_write  = 0;
        mem_write  = 0; 
        mem_read   = 0; 
        mem_to_reg = 0;
        i_or_d     = 0;
        alu_src_a  = 2'b00; 
        alu_src_b  = 2'b00;
        pc_source  = 1'b0;  
        alu_ctrl   = 4'b0000;

        case (state)
            FETCH: begin
                i_or_d    = 1'b0; // Address = PC
                mem_read  = 1'b1;
                ir_write  = 1'b1;
                alu_src_a = 2'b00; // Select PC
                alu_src_b = 2'b01; // Select 4
                alu_ctrl  = 4'b0000; // ADD (PC + 4)
                pc_write  = 1'b1;   // Update PC = PC + 4
                pc_source = 1'b0;  // Direct ALU Result
            end

            DECODE: begin
                // Pre-compute Branch Target using OldPC (OldPC + Imm)
                alu_src_a = 2'b10; // Select OldPC
                alu_src_b = 2'b10; // Select Imm
                alu_ctrl  = 4'b0000; // ADD
            end

            EXECUTE: begin
                alu_src_a = 2'b01; // Reg A
                case (opcode)
                    7'b0110011: begin // R-Type
                        alu_src_b = 2'b00; // Reg B
                        case (funct3)
                            3'b000: alu_ctrl = (funct7[5]) ? 4'b0001 : 4'b0000; // SUB : ADD
                            3'b111: alu_ctrl = 4'b0010; // AND
                            3'b110: alu_ctrl = 4'b0011; // OR
                            3'b010: alu_ctrl = 4'b1000; // SLT
                            default: alu_ctrl = 4'b0000;
                        endcase
                    end
                    7'b0010011: begin // I-Type
                        alu_src_b = 2'b10; // Imm
                        case (funct3)
                            3'b000: alu_ctrl = 4'b0000; // ADDI
                            3'b111: alu_ctrl = 4'b0010; // ANDI
                            3'b110: alu_ctrl = 4'b0011; // ORI
                            default: alu_ctrl = 4'b0000;
                        endcase
                    end
                    7'b0000011, 7'b0100011: begin // Load / Store Address
                        alu_src_b = 2'b10; // Imm
                        alu_ctrl  = 4'b0000; // ADD
                    end
                endcase
            end

            MEMORY: begin
                i_or_d = 1'b1; // Address = ALUOut (Calculated address 32)
                if (opcode == 7'b0000011) mem_read  = 1'b1; // LW
                if (opcode == 7'b0100011) mem_write = 1'b1; // SW
            end

            WRITEBACK: begin
                reg_write  = 1'b1;
                mem_to_reg = (opcode == 7'b0000011);
            end

            BRANCH: begin
                alu_src_a = 2'b01; // Reg A
                alu_src_b = 2'b00; // Reg B
                alu_ctrl  = 4'b0001; // SUB for comparison
                pc_source = 1'b1;   // Select ALUOut (Computed in DECODE)
                if (zero) pc_write = 1'b1; // Branch Taken
            end
        endcase
    end
endmodule