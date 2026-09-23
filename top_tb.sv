`timescale 1ns / 1ps
// =====================================================================
// tb_top.sv  (the "test")
// Instantiates DUT + environment. This is the ONLY file allowed to use
// hierarchical DUT references. It mirrors the DUT signals the driver/
// monitor need into shadow variables (always @(*)), then hands those
// shadow variables in by `ref` when starting drv.run()/mon.run() -
// classes never touch dut.* directly.
//
// Also defines each test scenario as a sequence of generator calls.
// =====================================================================
//import cpu_tb_pkg::*;


`include "environment.sv"

module tb_top;
 
    logic clk = 0;
    always #5 clk = ~clk;
 
    cpu_if vif (.clk(clk));
 
    multicycle_rv32i dut (
        .clk     (clk),
        .rst     (vif.rst),
        .rx_pin  (vif.rx_pin),
        .tx_pin  (vif.tx_pin),
        .fi_en   (vif.fi_en),
        .fi_mask (vif.fi_mask)
    );
 
    environment env;
 
    // -------------------------------------------------------------
    // Program load (memory-macro-aware split: 32-bit imem word across
    // two 16-bit macros, 39-bit dmem codeword across three)
    // -------------------------------------------------------------
    task automatic wr_imem(input int idx, input [31:0] data);
        dut.imem_inst.mem_lo.mem[idx] = data[15:0];
        dut.imem_inst.mem_hi.mem[idx] = data[31:16];
    endtask
 
    task automatic wr_dmem(input int idx, input [38:0] cw);
        dut.dmem_inst.u_dmem.mem_0.mem[idx] = cw[15:0];
        dut.dmem_inst.u_dmem.mem_1.mem[idx] = cw[31:16];
        dut.dmem_inst.u_dmem.mem_2.mem[idx] = {9'b0, cw[38:32]};
    endtask
 
    task automatic load_common_program();
        wr_dmem(64, 39'h0);
 
        wr_imem(0,  32'h08000093);
        wr_imem(1,  32'h30509073);
        wr_imem(2,  32'h000010B7);
        wr_imem(3,  32'h000011B7);
        wr_imem(4,  32'h0011D193);
        wr_imem(5,  32'h0030E0B3);
        wr_imem(6,  32'h30409073);
        wr_imem(7,  32'h00800093);
        wr_imem(8,  32'h30009073);
 
        wr_imem(9,  32'h00000293);
        wr_imem(10, 32'h00100413);
        wr_imem(11, 32'h10000913);
        wr_imem(12, 32'h008282B3);
        wr_imem(13, 32'h00092883);
        wr_imem(14, 32'hfe000ce3);
 
        wr_imem(32, 32'h344015F3);
        wr_imem(33, 32'h00C5D693);
        wr_imem(34, 32'h0016F693);
        wr_imem(35, 32'h00069A63);
        wr_imem(36, 32'h40000137);
        wr_imem(37, 32'h00012503);
        wr_imem(38, 32'h00a00433);
        //wr_imem(39, 32'h00000863);
        wr_imem(39, 32'h00000A63);

        
        wr_imem(40, 32'h00100493);
        wr_imem(41, 32'h50000737);
        wr_imem(42, 32'h00872783);
        wr_imem(43, 32'h00C72803);
        wr_imem(44, 32'h30200073);
    endtask
 
    // -------------------------------------------------------------
    // Shadow variables: continuously mirror DUT state so driver/monitor
    // classes can be handed plain `ref int` / `ref logic`, never a
    // hierarchical DUT path.
    // -------------------------------------------------------------
    int   sh_x5, sh_x8, sh_x9, sh_x10;
    logic sh_sb_sticky, sh_db_sticky;
    int   sh_sb_count, sh_db_count;
    logic sh_ram_re;
    logic sh_mie_bit;
 
    always @(*) sh_x5        = dut.rf_inst.registers[5];
    always @(*) sh_x8        = dut.rf_inst.registers[8];
    always @(*) sh_x9        = dut.rf_inst.registers[9];
    always @(*) sh_x10       = dut.rf_inst.registers[10];
    always @(*) sh_sb_sticky = dut.sb_sticky;
    always @(*) sh_db_sticky = dut.db_sticky;
    always @(*) sh_sb_count  = dut.sb_count;
    always @(*) sh_db_count  = dut.db_count;
    always @(*) sh_ram_re    = dut.ram_re;
 
    // mie_bit goes the other direction: shadow -> DUT (mask/unmask txns
    // write it). NOTE: adjust this hierarchical path to your actual CSR
    // module/instance/signal name.
    initial sh_mie_bit = 1'b1;
    always @(sh_mie_bit) dut.csr_inst.mstatus[3] = sh_mie_bit;
 
    function automatic int rf(input int idx);
        return dut.rf_inst.registers[idx];
    endfunction
 
    // -------------------------------------------------------------
    // INSTRUCTION TRACE - prints every retired instruction, but with
    // spam suppression: full detail for the first N instructions and
    // whenever PC leaves the normal background-loop range (0x30-0x38),
    // i.e. whenever the ISR actually runs. Otherwise stays quiet.
    // -------------------------------------------------------------
    integer trace_instr_num   = 0;
    integer trace_cycles      = 0;
    reg [31:0] trace_pc       = 0;
    reg [31:0] trace_ir       = 0;
    reg [31:0] trace_last_pc  = 32'hFFFF_FFFF;
    integer trace_print_budget = 0;
 
    always @(posedge clk) begin
        if (!vif.rst) begin
            trace_cycles <= trace_cycles + 1;
 
            if (dut.ctrl_inst.state == 3'b000) begin
                if (trace_instr_num > 0 && trace_pc != trace_last_pc) begin
                    // outside the normal loop window -> ISR or boot: always print
                    if (trace_pc < 32'h30 || trace_pc > 32'h38)
                        trace_print_budget <= 10;
 
                    if (trace_instr_num < 30 || trace_print_budget > 0) begin
                        $display("Instr #%0d | PC: 0x%08h | IR: 0x%08h | Cycles: %0d | time=%0t",
                                 trace_instr_num, trace_pc, trace_ir, trace_cycles, $time);
                        if (trace_pc >= 32'h30 && trace_pc <= 32'h38 && trace_instr_num >= 30)
                            trace_print_budget <= trace_print_budget - 1;
                    end else if (trace_instr_num == 30) begin
                        $display("... [background loop running, trace suppressed] ...");
                    end
                    trace_last_pc <= trace_pc;
                end
                trace_cycles    <= 1;
                trace_instr_num <= trace_instr_num + 1;
            end
 
            if (dut.ctrl_inst.state == 3'b001) begin
                trace_pc <= dut.old_pc;
                trace_ir <= dut.ir;
            end
        end
    end
 
    // -------------------------------------------------------------
    // Scenarios: each just feeds the generator; driver/monitor/
    // scoreboard run loops (started below) do the rest.
    // -------------------------------------------------------------
    task automatic build_scenario_normal();
        // no add_wait here either - main initial block's own #21000
        // already provides the settle time; x5 is just observed via rf().
    endtask
 
    task automatic build_scenario_uart_irq();
        // This UART design assembles a full 32-bit word (4 bytes) before
        // asserting the interrupt-pending bit - a single byte never
        // triggers it. Send the same 4-byte pattern the known-good
        // directed TB used (LSB first): 0x93 0x00 0x00 0x08 -> 0x08000093.
        // NOTE: no add_wait() here - the settle delay is applied in the
        // main initial block instead, so the driver isn't left busy
        // draining a long wait transaction while later scenarios queue up.
        env.gen.add_uart_byte(8'h93, "T2_uart_b0");
        env.gen.add_uart_byte(8'h00, "T2_uart_b1");
        env.gen.add_uart_byte(8'h00, "T2_uart_b2");
        env.gen.add_uart_byte(8'h08, "T2_uart_b3");
    endtask
 
    task automatic build_scenario_ecc_single();
        env.gen.add_fault_sb("T3_ecc_single");
    endtask
 
    task automatic build_scenario_ecc_double();
        env.gen.add_fault_db("T4_ecc_double");
    endtask
 
    task automatic build_scenario_masked_irq();
        // Send the SAME full 4-byte word while masked, so this actually
        // tests masking (a single byte would never trigger this UART
        // anyway, making the test meaningless). x10 must stay unchanged
        // since mie is forced off for the whole sequence.
        env.gen.add_mask_irq("T5_mask");
        env.gen.add_uart_byte(8'h93, "uart_masked");
        env.gen.add_uart_byte(8'h00, "uart_masked");
        env.gen.add_uart_byte(8'h00, "uart_masked");
        env.gen.add_uart_byte(8'h08, "uart_masked");
        env.gen.add_unmask_irq("T5_unmask");
    endtask
 
    initial begin
        env = new(vif);
 
        env.drv.reset_dut();
        load_common_program();
        #15;
 
        fork
            env.drv.run(sh_ram_re, sh_mie_bit);
            env.mon.run(sh_x5, sh_x8, sh_x9, sh_x10,
                        sh_sb_sticky, sh_db_sticky, sh_sb_count, sh_db_count);
            env.sb.run();
        join_none
 
        build_scenario_normal();
        #21000;
        env.sb.check_true("T1 x5 advancing (no interrupt)", (rf(5) > 0));
 
        build_scenario_uart_irq();
        #2_000_000;
        env.sb.check_equal("T2 x10 == UART word", rf(10), 32'h08000093);
        env.sb.check_equal("T2 x8  == UART word", rf(8),  32'h08000093);
 
        build_scenario_ecc_single();
        #3000;
        env.sb.check_true("T3 single-err sticky set", sh_sb_sticky);
 
        build_scenario_ecc_double();
        #3000;
        env.sb.check_true("T4 double-err sticky set", sh_db_sticky);
        env.sb.check_equal("T4 x9 ECC-handler flag", rf(9), 32'h00000001);
 
        build_scenario_masked_irq();
        #500_000;  // 4 bytes (~347,200ns) + margin, no ISR expected while masked
        env.sb.check_equal("T5 x10 unchanged while masked", rf(10), 32'h08000093);
 
        #100;
        env.sb.report();
        $finish;
    end
 
endmodule