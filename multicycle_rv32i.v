/*module multicycle_rv32i (
    input  wire clk,
    input  wire rst,
    
    // --- Physical FPGA Pins ---
    input  wire rx_pin,  // UART Receiver Pin (Bahar se aayega)
    output wire tx_pin   // UART Transmitter Pin (Bahar jayega)
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

    // --- Interrupts & CSR Wires ---
    wire        ext_irq; // NAYA: Ab ye internal wire hai jo UART se CSR tak jayegi
    wire        trap_pending, trap_entry, trap_exit, csr_write;
    wire [31:0] mtvec_out, mepc_out, csr_read_data;

    // --- SoC Interconnect Wires ---
    wire        ram_re, ram_we;
    wire [31:0] ram_addr, ram_wdata, ram_rdata;
    
    wire        uart_re, uart_we;
    wire [31:0] uart_addr, uart_wdata, uart_rdata;

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
            
            if (pc_write) begin
                if (trap_entry)
                    pc <= mtvec_out;      
                else if (trap_exit)
                    pc <= mepc_out;       
                else
                    pc <= (pc_source) ? alu_out : alu_result; 
            end
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

    wire is_system_instr = (ir[6:0] == 7'b1110011);
    assign write_back_data = (is_system_instr) ? csr_read_data : 
                             (mem_to_reg)      ? mdr : alu_out;

    // 4. Submodule Instantiations

    // SoC Interconnect 
    soc_interconnect bus_inst (
        .cpu_addr(alu_out),
        .cpu_wdata(b_reg),
        .cpu_mem_read(mem_read),
        .cpu_mem_write(mem_write),
        .cpu_rdata(data_mem_out), 

        .ram_re(ram_re),
        .ram_we(ram_we),
        .ram_addr(ram_addr),
        .ram_wdata(ram_wdata),
        .ram_rdata(ram_rdata),

        .uart_re(uart_re),
        .uart_we(uart_we),
        .uart_addr(uart_addr),
        .uart_wdata(uart_wdata),
        .uart_rdata(uart_rdata)
    );

    // Data Memory (SRAM)
    data_mem dmem_inst (
        .clk(clk),
        .mem_read(ram_re),       
        .mem_write(ram_we),      
        .addr(ram_addr),         
        .write_data(ram_wdata),
        .read_data(ram_rdata)
    );

    // UART Module
    uart_top #(
        .CLK_FREQ(100_000_000), 
        .BAUD_RATE(115200)
    ) uart_inst (
        .clk(clk),
        .rst(rst),
        .re(uart_re),
        .we(uart_we),
        .addr(uart_addr),
        .wdata(uart_wdata),
        .rdata(uart_rdata),
        .rx_interrupt(ext_irq), // UART generate karega interrupt
        .rx_pin(rx_pin),        // FPGA pin
        .tx_pin(tx_pin)         // FPGA pin
    );

    // CSR File for Interrupts
    csr_file csr_inst (
        .clk(clk),
        .rst(rst),
        .csr_write(csr_write),
        .csr_addr(ir[31:20]),
        .write_data(a_reg),
        .read_data(csr_read_data),
        .ext_irq(ext_irq),      // UART ka interrupt yahan receive hoga
        .trap_entry(trap_entry),
        .trap_exit(trap_exit),
        .current_pc(old_pc),
        .mtvec_out(mtvec_out),
        .mepc_out(mepc_out),
        .trap_pending(trap_pending)
    );

    inst_mem imem_inst (
        .clk(clk),
        .mem_read(mem_read),
        .addr(pc),
        .read_data(inst_data)
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
        .trap_pending(trap_pending),
        .trap_entry(trap_entry),
        .trap_exit(trap_exit),
        .csr_write(csr_write),
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

endmodule*/


//adding sram laetncy

module multicycle_rv32i (
    input  wire clk,
    input  wire rst,
    
    // --- Physical FPGA Pins ---
    input  wire rx_pin,  // UART Receiver Pin (Bahar se aayega)
    output wire tx_pin   // UART Transmitter Pin (Bahar jayega)
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

    // --- Interrupts & CSR Wires ---
    wire        ext_irq; // NAYA: Ab ye internal wire hai jo UART se CSR tak jayegi
    wire        trap_pending, trap_entry, trap_exit, csr_write;
    wire [31:0] mtvec_out, mepc_out, csr_read_data;

    // --- SoC Interconnect Wires ---
    wire        ram_re, ram_we;
    wire [31:0] ram_addr, ram_wdata, ram_rdata;
    
    wire        uart_re, uart_we;
    wire [31:0] uart_addr, uart_wdata, uart_rdata;

    // Control Signals
    wire ir_write, pc_write, reg_write, i_or_d, mem_write, mem_read, mem_to_reg, pc_source;
	 wire old_pc_write;   // <-- YEH LINE
    wire [1:0] alu_src_a, alu_src_b;
    wire [3:0] alu_ctrl;

    // 1. Program Counter & OldPC Logic
    /*always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc     <= 32'b0;
            old_pc <= 32'b0;
        end else begin
            if (ir_write) old_pc <= pc;
            
            if (pc_write) begin
                if (trap_entry)
                    pc <= mtvec_out;      
                else if (trap_exit)
                    pc <= mepc_out;       
                else
                    pc <= (pc_source) ? alu_out : alu_result; 
            end
        end
    end*/
	     // 1. Program Counter & OldPC Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc     <= 32'b0;
            old_pc <= 32'b0;
        end else begin
            if (old_pc_write) old_pc <= pc;   // <-- ir_write ki jagah old_pc_write use karo
            
            if (pc_write) begin
                if (trap_entry)
                    pc <= mtvec_out;      
                else if (trap_exit)
                    pc <= mepc_out;       
                else
                    pc <= (pc_source) ? alu_out : alu_result; 
            end
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

    wire is_system_instr = (ir[6:0] == 7'b1110011);
    assign write_back_data = (is_system_instr) ? csr_read_data : 
                             (mem_to_reg)      ? mdr : alu_out;

    // 4. Submodule Instantiations

    // SoC Interconnect 
    soc_interconnect bus_inst (
        .cpu_addr(alu_out),
        .cpu_wdata(b_reg),
        .cpu_mem_read(mem_read),
        .cpu_mem_write(mem_write),
        .cpu_rdata(data_mem_out), 

        .ram_re(ram_re),
        .ram_we(ram_we),
        .ram_addr(ram_addr),
        .ram_wdata(ram_wdata),
        .ram_rdata(ram_rdata),

        .uart_re(uart_re),
        .uart_we(uart_we),
        .uart_addr(uart_addr),
        .uart_wdata(uart_wdata),
        .uart_rdata(uart_rdata)
    );

    // Data Memory (SRAM)
    data_mem dmem_inst (
        .clk(clk),
        .mem_read(ram_re),       
        .mem_write(ram_we),      
        .addr(ram_addr),         
        .write_data(ram_wdata),
        .read_data(ram_rdata)
    );

    // UART Module
    uart_top #(
        .CLK_FREQ(100_000_000), 
        .BAUD_RATE(115200)
    ) uart_inst (
        .clk(clk),
        .rst(rst),
        .re(uart_re),
        .we(uart_we),
        .addr(uart_addr),
        .wdata(uart_wdata),
        .rdata(uart_rdata),
        .rx_interrupt(ext_irq), // UART generate karega interrupt
        .rx_pin(rx_pin),        // FPGA pin
        .tx_pin(tx_pin)         // FPGA pin
    );

    // CSR File for Interrupts
    csr_file csr_inst (
        .clk(clk),
        .rst(rst),
        .csr_write(csr_write),
        .csr_addr(ir[31:20]),
        .write_data(a_reg),
        .read_data(csr_read_data),
        .ext_irq(ext_irq),      // UART ka interrupt yahan receive hoga
        .trap_entry(trap_entry),
        .trap_exit(trap_exit),
        .current_pc(old_pc),
        .mtvec_out(mtvec_out),
        .mepc_out(mepc_out),
        .trap_pending(trap_pending)
    );

    inst_mem imem_inst (
        .clk(clk),
        .mem_read(mem_read),
        .addr(pc),
        .read_data(inst_data)
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
        .trap_pending(trap_pending),
        .trap_entry(trap_entry),
        .trap_exit(trap_exit),
        .csr_write(csr_write),
        .ir_write(ir_write),
		  .old_pc_write(old_pc_write),   // <-- NAYA CONNECTION
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



