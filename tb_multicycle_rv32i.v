/*`timescale 1ns / 1ps

module tb_multicycle_rv32i;

    reg clk;
    reg rst;

    // Overall Instrumentation Variables
    integer cycle_count = 0;
    integer instr_count = 0;

    // Per-Instruction Cycle Tracking Variables
    integer per_instr_cycles  = 0;
    integer current_instr_num = 0;
    reg [31:0] current_pc     = 0;
    reg [31:0] current_ir     = 0;

    // Instantiate Top Module
    multicycle_rv32i dut (
        .clk(clk),
        .rst(rst)
    );

    // 100MHz Clock Generation (10ns period)
    always #5 clk = ~clk;

    // Combined Cycle & Per-Instruction Tracking Logic
    always @(posedge clk) begin
        if (!rst) begin
            cycle_count      <= cycle_count + 1;
            per_instr_cycles <= per_instr_cycles + 1;

            // FSM entering FETCH state (3'b000) -> Start of a new instruction
            if (dut.ctrl_inst.state == 3'b000) begin
                instr_count <= instr_count + 1;

                // Display cycle breakdown for the instruction that JUST completed
                if (current_instr_num > 0) begin
                    $display("Instr #%0d | PC: 0x%08h | IR: 0x%08h | Cycles Taken: %0d", 
                             current_instr_num, current_pc, current_ir, per_instr_cycles);
                end

                per_instr_cycles  <= 1; // Cycle 1 of current instruction
                current_instr_num <= current_instr_num + 1;
            end

            // FSM entering DECODE state (3'b001) -> Capture PC and IR for logging
            if (dut.ctrl_inst.state == 3'b001) begin
                current_pc <= dut.old_pc;
                current_ir <= dut.ir;
            end
        end
    end

    initial begin
        clk = 0;
        rst = 1;

        // Preload memory with machine code instructions:
        // 1. ADDI x1, x0, 10  -> x1 = 10
        dut.mem_inst.mem[0] = 32'h00A00093;
        // 2. ADDI x2, x0, 20  -> x2 = 20
        dut.mem_inst.mem[1] = 32'h01400113;
        // 3. ADD  x3, x1, x2  -> x3 = 30
        dut.mem_inst.mem[2] = 32'h002081B3;
        // 4. SW   x3, 32(x0)  -> Mem[32] = 30
        dut.mem_inst.mem[3] = 32'h02302023;
        // 5. LW   x4, 32(x0)  -> x4 = Mem[32] = 30
        dut.mem_inst.mem[4] = 32'h02002203;
        // 6. BEQ  x1, x1, 8   -> Jump +8 bytes (skips instruction 7)
        dut.mem_inst.mem[5] = 32'h00108463;
        // 7. ADDI x5, x0, 99  -> Skipped by branch
        dut.mem_inst.mem[6] = 32'h06300293;
        // 8. SUB  x6, x3, x1  -> x6 = 30 - 10 = 20
        dut.mem_inst.mem[7] = 32'h40118333;

        // Release reset
        #15;
        rst = 0;

        $display("==================================================");
        $display("          PER-INSTRUCTION CYCLE LOG               ");
        $display("==================================================");

        // Run simulation cycles
        #400;

        // Display Register / Memory Results
        $display("==================================================");
        $display("             PROCESSOR EXECUTION RESULTS          ");
        $display("==================================================");
        $display("x1 (Expected: 10)     = %d", dut.rf_inst.registers[1]);
        $display("x2 (Expected: 20)     = %d", dut.rf_inst.registers[2]);
        $display("x3 (Expected: 30)     = %d", dut.rf_inst.registers[3]);
        $display("x4 (Expected: 30)     = %d", dut.rf_inst.registers[4]);
        $display("x5 (Expected: 0)      = %d [Skipped by Branch]", dut.rf_inst.registers[5]);
        $display("x6 (Expected: 20)     = %d", dut.rf_inst.registers[6]);
        $display("Mem[32] (Expected: 30)= %d", dut.mem_inst.mem[8]);
        $display("==================================================");

        // Display Multi-Cycle Performance Metrics
        $display("==================================================");
        $display("          MULTI-CYCLE TIMING METRICS              ");
        $display("==================================================");
        $display("Total Clock Cycles : %0d", cycle_count);
        $display("Total Instructions : %0d", instr_count);
        if (instr_count > 0)
            $display("Average CPI        : %0.2f", $itor(cycle_count) / $itor(instr_count));
        $display("==================================================");

        if (dut.rf_inst.registers[1] == 10 &&
            dut.rf_inst.registers[2] == 20 &&
            dut.rf_inst.registers[3] == 30 &&
            dut.rf_inst.registers[4] == 30 &&
            dut.rf_inst.registers[5] == 0  &&
            dut.rf_inst.registers[6] == 20 &&
            dut.mem_inst.mem[8]      == 30) begin
            $display(">>> SUCCESS: ALL MULTI-CYCLE TESTS PASSED <<<");
        end else begin
            $display(">>> FAILURE: INCORRECT REGISTER/MEMORY VALUES <<<");
        end

        $finish;
    end

endmodule*/



`timescale 1ns / 1ps

module tb_multicycle_rv32i;

    reg clk;
    reg rst;

    // Overall Instrumentation Variables
    integer cycle_count = 0;
    integer instr_count = 0;

    // Per-Instruction Cycle Tracking Variables
    integer per_instr_cycles  = 0;
    integer current_instr_num = 0;
    reg [31:0] current_pc     = 0;
    reg [31:0] current_ir     = 0;

    // Instantiate Top Module
    multicycle_rv32i dut (
        .clk(clk),
        .rst(rst)
    );

    // 100MHz Clock Generation (10ns period)
    always #5 clk = ~clk;

    // Combined Cycle & Per-Instruction Tracking Logic
    always @(posedge clk) begin
        if (!rst) begin
            cycle_count      <= cycle_count + 1;
            per_instr_cycles <= per_instr_cycles + 1;

            // FSM entering FETCH state (3'b000) -> Start of a new instruction
            if (dut.ctrl_inst.state == 3'b000) begin
                instr_count <= instr_count + 1;

                // Display cycle breakdown for the instruction that JUST completed
                if (current_instr_num > 0) begin
                    $display("Instr #%0d | PC: 0x%08h | IR: 0x%08h | Cycles Taken: %0d", 
                             current_instr_num, current_pc, current_ir, per_instr_cycles);
                end

                per_instr_cycles  <= 1; // Cycle 1 of current instruction
                current_instr_num <= current_instr_num + 1;
            end

            // FSM entering DECODE state (3'b001) -> Capture PC and IR for logging
            if (dut.ctrl_inst.state == 3'b001) begin
                current_pc <= dut.old_pc;
                current_ir <= dut.ir;
            end
        end
    end

    initial begin
        clk = 0;
        rst = 1;

        // Preload memory with machine code instructions:
        // 1. ADDI x1, x0, 10  -> x1 = 10
        dut.imem_inst.mem[0] = 32'h00A00093;
        // 2. ADDI x2, x0, 20  -> x2 = 20
        dut.imem_inst.mem[1] = 32'h01400113;
        // 3. ADD  x3, x1, x2  -> x3 = 30
        dut.imem_inst.mem[2] = 32'h002081B3;
        // 4. SW   x3, 32(x0)  -> Mem[32] = 30
        dut.imem_inst.mem[3] = 32'h02302023;
        // 5. LW   x4, 32(x0)  -> x4 = Mem[32] = 30
        dut.imem_inst.mem[4] = 32'h02002203;
        // 6. BEQ  x1, x1, 8   -> Jump +8 bytes (skips instruction 7)
        dut.imem_inst.mem[5] = 32'h00108463;
        // 7. ADDI x5, x0, 99  -> Skipped by branch
        dut.imem_inst.mem[6] = 32'h06300293;
        // 8. SUB  x6, x3, x1  -> x6 = 30 - 10 = 20
        dut.imem_inst.mem[7] = 32'h40118333;

        // Release reset
        #15;
        rst = 0;

        $display("==================================================");
        $display("          PER-INSTRUCTION CYCLE LOG               ");
        $display("==================================================");

        // Run simulation cycles
        #400;

        // Display Register / Memory Results
        $display("==================================================");
        $display("             PROCESSOR EXECUTION RESULTS          ");
        $display("==================================================");
        $display("x1 (Expected: 10)     = %d", dut.rf_inst.registers[1]);
        $display("x2 (Expected: 20)     = %d", dut.rf_inst.registers[2]);
        $display("x3 (Expected: 30)     = %d", dut.rf_inst.registers[3]);
        $display("x4 (Expected: 30)     = %d", dut.rf_inst.registers[4]);
        $display("x5 (Expected: 0)      = %d [Skipped by Branch]", dut.rf_inst.registers[5]);
        $display("x6 (Expected: 20)     = %d", dut.rf_inst.registers[6]);
        $display("Mem[32] (Expected: 30)= %d", dut.dmem_inst.mem[8]);
        $display("==================================================");

        // Display Multi-Cycle Performance Metrics
        $display("==================================================");
        $display("          MULTI-CYCLE TIMING METRICS              ");
        $display("==================================================");
        $display("Total Clock Cycles : %0d", cycle_count);
        $display("Total Instructions : %0d", instr_count);
        if (instr_count > 0)
            $display("Average CPI        : %0.2f", $itor(cycle_count) / $itor(instr_count));
        $display("==================================================");

        if (dut.rf_inst.registers[1] == 10 &&
            dut.rf_inst.registers[2] == 20 &&
            dut.rf_inst.registers[3] == 30 &&
            dut.rf_inst.registers[4] == 30 &&
            dut.rf_inst.registers[5] == 0  &&
            dut.rf_inst.registers[6] == 20 &&
            dut.dmem_inst.mem[8]      == 30) begin
            $display(">>> SUCCESS: ALL MULTI-CYCLE TESTS PASSED <<<");
        end else begin
            $display(">>> FAILURE: INCORRECT REGISTER/MEMORY VALUES <<<");
        end

        $finish;
    end

endmodule