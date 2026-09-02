module control_unit (
    input  wire       clk,
    input  wire       rst,
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    input  wire       zero,
    
    // Interrupts & CSR
    input  wire       trap_pending,  
    output reg        trap_entry,    
    output reg        trap_exit,     
    output reg        csr_write,     

    output reg        ir_write,
    output reg        pc_write,
    output reg        reg_write,
    output reg        mem_write,
    output reg        i_or_d,
    output reg        mem_read,
    output reg        mem_to_reg,
    output reg  [1:0] alu_src_a, 
    output reg  [1:0] alu_src_b, 
    output reg        pc_source, 
    output reg  [3:0] alu_ctrl
);

    // FSM States
    localparam FETCH     = 3'b000;
    localparam DECODE    = 3'b001;
    localparam EXECUTE   = 3'b010;
    localparam MEMORY    = 3'b011;
    localparam WRITEBACK = 3'b100;
    localparam BRANCH    = 3'b101;
    localparam TRAP      = 3'b110; 

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
                    7'b0000011, 7'b0100011,
                    7'b0110111:             next_state = EXECUTE; // FIX 1: LUI Opcode Added
                    7'b1100011:             next_state = BRANCH;
                    7'b1110011:             next_state = EXECUTE; 
                    default:                next_state = (trap_pending) ? TRAP : FETCH;
                endcase
            end
            
            EXECUTE: begin
                if (opcode == 7'b0000011 || opcode == 7'b0100011) 
                    next_state = MEMORY; 
                else if (opcode == 7'b1110011) 
                    next_state = (trap_pending) ? TRAP : FETCH; 
                else 
                    next_state = WRITEBACK; 
            end
            
            MEMORY:    
                next_state = (opcode == 7'b0000011) ? WRITEBACK : ((trap_pending) ? TRAP : FETCH);
                
            WRITEBACK: next_state = (trap_pending) ? TRAP : FETCH;
            BRANCH:    next_state = (trap_pending) ? TRAP : FETCH;
            TRAP:      next_state = FETCH; 
            default:   next_state = FETCH;
        endcase
    end

    // Control Output Logic
    always @(*) begin
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
        
        trap_entry = 0;
        trap_exit  = 0;
        csr_write  = 0;

        case (state)
            FETCH: begin
                i_or_d    = 1'b0; 
                mem_read  = 1'b1;
                ir_write  = 1'b1;
                alu_src_a = 2'b00; 
                alu_src_b = 2'b01; 
                alu_ctrl  = 4'b0000; 
                pc_write  = 1'b1;   
                pc_source = 1'b0;  
            end

            DECODE: begin
                alu_src_a = 2'b10; 
                alu_src_b = 2'b10; 
                alu_ctrl  = 4'b0000; 
            end

            EXECUTE: begin
                alu_src_a = 2'b01; // Reg A (Default)
                case (opcode)
                    7'b0110111: begin // FIX 2: LUI Logic
                        alu_src_a = 2'b11;   // Force '0' into ALU A
                        alu_src_b = 2'b10;   // Imm into ALU B
                        alu_ctrl  = 4'b0000; // ADD (Result = Imm)
                    end
                    7'b0110011: begin // R-Type
                        alu_src_b = 2'b00; // Reg B
                        case (funct3)
                            3'b000: alu_ctrl = (funct7[5]) ? 4'b0001 : 4'b0000; 
                            3'b111: alu_ctrl = 4'b0010; 
                            3'b110: alu_ctrl = 4'b0011; 
                            3'b010: alu_ctrl = 4'b1000; 
                            default: alu_ctrl = 4'b0000;
                        endcase
                    end
                    7'b0010011: begin // I-Type
                        alu_src_b = 2'b10; // Imm
                        case (funct3)
                            3'b000: alu_ctrl = 4'b0000; 
                            3'b111: alu_ctrl = 4'b0010; 
                            3'b110: alu_ctrl = 4'b0011; 
                            3'b101: alu_ctrl = (funct7[5]) ? 4'b0111 : 4'b0110; // FIX 3: SRAI : SRLI added
                            default: alu_ctrl = 4'b0000;
                        endcase
                    end
                    7'b0000011, 7'b0100011: begin // Load / Store Address
                        alu_src_b = 2'b10; 
                        alu_ctrl  = 4'b0000; 
                    end
                    7'b1110011: begin // SYSTEM Instructions
                        if (funct3 == 3'b000) begin 
                            trap_exit = 1'b1;
                            pc_write  = 1'b1;
                        end 
                        else if (funct3 == 3'b001) begin 
                            csr_write = 1'b1;
                        end
                    end
                endcase
            end

            MEMORY: begin
                i_or_d = 1'b1; 
                if (opcode == 7'b0000011) mem_read  = 1'b1; 
                if (opcode == 7'b0100011) mem_write = 1'b1; 
            end

            WRITEBACK: begin
                reg_write  = 1'b1;
                mem_to_reg = (opcode == 7'b0000011);
            end

            BRANCH: begin
                alu_src_a = 2'b01; 
                alu_src_b = 2'b00; 
                alu_ctrl  = 4'b0001; 
                pc_source = 1'b1;   
                
                if (funct3 == 3'b000 && zero == 1)       
                    pc_write = 1'b1; // BEQ 
                else if (funct3 == 3'b001 && zero == 0)  
                    pc_write = 1'b1; // BNE
            end
            
            TRAP: begin
                trap_entry = 1'b1; 
                pc_write   = 1'b1; 
            end
        endcase
    end
endmodule