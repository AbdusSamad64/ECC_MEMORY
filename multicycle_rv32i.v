module multicycle_rv32i (
    input wire clk,
    input wire rst
);
    // Registers
    reg [31:0] pc, old_pc;
    reg [31:0] ir, mdr, a_reg, b_reg, alu_out;

    // Wires
    wire [31:0] inst_data, data_mem_out;
    wire [31:0] read_data1, read_data2;
    wire [31:0] imm_ext;
    wire [31:0] alu_operand_a, alu_operand_b;
    wire [31:0] alu_result;
    wire [31:0] write_back_data;
    wire        zero;

    // Control Signals
    wire ir_write, pc_write, reg_write, i_or_d, mem_write, mem_read, mem_to_reg, pc_source;
    wire [1:0] alu_src_a, alu_src_b;
    wire [3:0] alu_ctrl;

    // 1. Program Counter & OldPC Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc     <= 32'b0;
            old_pc <= 32'b0;
        end else begin
            if (ir_write) old_pc <= pc;
            if (pc_write) pc     <= (pc_source) ? alu_out : alu_result;
        end
    end

    // 2. Multi-Cycle Pipeline Registers
    always @(posedge clk) begin
        if (ir_write) ir <= inst_data;
        mdr     <= data_mem_out;
        a_reg   <= read_data1;
        b_reg   <= read_data2;
        alu_out <= alu_result;
    end

    // 3. MUX Selections
    assign alu_operand_a = (alu_src_a == 2'b00) ? pc     :
                           (alu_src_a == 2'b01) ? a_reg  :
                           (alu_src_a == 2'b10) ? old_pc : 32'b0;

    assign alu_operand_b = (alu_src_b == 2'b00) ? b_reg   :
                           (alu_src_b == 2'b01) ? 32'd4   :
                           (alu_src_b == 2'b10) ? imm_ext : 32'b0;

    assign write_back_data = (mem_to_reg) ? mdr : alu_out;

    // 4. Submodule Instantiations
    inst_mem imem_inst (
        .clk(clk),
        .mem_read(mem_read),
        .addr(pc),              // Instruction Fetch reads directly from PC
        .read_data(inst_data)
    );

    data_mem dmem_inst (
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .addr(alu_out),         // Data Access uses calculated ALU address
        .write_data(b_reg),
        .read_data(data_mem_out)
    );

    reg_file rf_inst (
        .clk(clk),
        .reg_write(reg_write),
        .rs1(ir[19:15]),
        .rs2(ir[24:20]),
        .rd(ir[11:7]),
        .write_data(write_back_data),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    imm_gen imm_inst (
        .instr(ir),
        .imm_ext(imm_ext)
    );

    alu alu_inst (
        .a(alu_operand_a),
        .b(alu_operand_b),
        .alu_control(alu_ctrl),
        .alu_result(alu_result),
        .zero(zero)
    );

    control_unit ctrl_inst (
        .clk(clk),
        .rst(rst),
        .opcode(ir[6:0]),
        .funct3(ir[14:12]),
        .funct7(ir[31:25]),
        .zero(zero),
        .ir_write(ir_write),
        .pc_write(pc_write),
        .reg_write(reg_write),
        .mem_write(mem_write),
        .i_or_d(i_or_d),
        .mem_read(mem_read),
        .mem_to_reg(mem_to_reg),
        .alu_src_a(alu_src_a),
        .alu_src_b(alu_src_b),
        .pc_source(pc_source),
        .alu_ctrl(alu_ctrl)
    );

endmodule