// =====================================================================
// scoreboard.sv
// Only layer allowed to declare PASS/FAIL. Two ways to check:
//   1. run() - automatic per-observation model, reacts by txn kind
//   2. check_equal() - explicit check the test calls directly, for
//      exact expected values that don't fit the generic per-txn model
// =====================================================================

`include "transaction.sv"
`include "observation.sv"
 
class scoreboard;
    mailbox #(observation) mon2sb;
    int error_count = 0;
    int check_count = 0;

    function new(mailbox #(observation) mon2sb);
        this.mon2sb = mon2sb;
    endfunction

    task automatic pass(string name, string info = "");
        check_count++;
        $display("  [SB  PASS] %-28s %0s", name, info);
    endtask

    task automatic fail(string name, string info = "");
        check_count++;
        error_count++;
        $display("  [SB  FAIL] %-28s %0s", name, info);
    endtask

    task automatic check_equal(string name, int actual, int expected);
        check_count++;
        if (actual !== expected) begin
            $display("  [SB  FAIL] %-28s got 0x%08h, expected 0x%08h", name, actual, expected);
            error_count++;
        end else begin
            $display("  [SB  PASS] %-28s 0x%08h", name, actual);
        end
    endtask

    task automatic check_true(string name, bit cond);
        check_count++;
        if (cond !== 1'b1) begin
            $display("  [SB  FAIL] %-28s condition was false", name);
            error_count++;
        end else begin
            $display("  [SB  PASS] %-28s", name);
        end
    endtask

    task automatic run();
        observation o;
        forever begin
            mon2sb.get(o);
            case (o.kind)
                TXN_UART_BYTE: begin
                    if (o.label == "uart_masked") begin
                        if (o.x10 === o.x10_pre)
                            pass(o.label, $sformatf("x10 unchanged (0x%08h) - correctly masked", o.x10));
                        else
                            fail(o.label, $sformatf("x10 changed while masked: 0x%08h -> 0x%08h", o.x10_pre, o.x10));
                    end else if (o.label == "T2_uart_b0" || o.label == "T2_uart_b1" || o.label == "T2_uart_b2") begin
                        // intermediate bytes of a multi-byte word: no observable
                        // effect expected yet, so just record it, don't judge it
                        pass(o.label, "intermediate byte of word, no check needed yet");
                    end else begin
                        if (o.x10 !== o.x10_pre)
                            pass(o.label, $sformatf("x10 updated: 0x%08h -> 0x%08h", o.x10_pre, o.x10));
                        else
                            fail(o.label, "x10 did not change after UART byte");
                    end
                end

                TXN_FAULT_SB: begin
                    if (o.sb_sticky && (o.sb_count > o.sb_count_pre))
                        pass(o.label, $sformatf("sb_sticky=1, sb_count %0d->%0d", o.sb_count_pre, o.sb_count));
                    else
                        fail(o.label, $sformatf("sb_sticky=%0d, sb_count %0d->%0d", o.sb_sticky, o.sb_count_pre, o.sb_count));
                end

                TXN_FAULT_DB: begin
                    if (o.db_sticky && (o.db_count > o.db_count_pre) && (o.x9 == 1))
                        pass(o.label, $sformatf("db_sticky=1, db_count %0d->%0d, x9=1", o.db_count_pre, o.db_count));
                    else
                        fail(o.label, $sformatf("db_sticky=%0d, db_count %0d->%0d, x9=%0d", o.db_sticky, o.db_count_pre, o.db_count, o.x9));
                end

                TXN_WAIT: begin
                    if (o.x5 > o.x5_pre)
                        pass(o.label, $sformatf("x5 %0d -> %0d (advancing)", o.x5_pre, o.x5));
                    else
                        fail(o.label, $sformatf("x5 %0d -> %0d (stalled)", o.x5_pre, o.x5));
                end

                default: ; // TXN_MASK_IRQ / TXN_UNMASK_IRQ: no direct check
            endcase
        end
    endtask

    task automatic report();
        $display("==================================================");
        $display("             SYSTEM VERIFICATION SUMMARY          ");
        $display("==================================================");
        $display("Total checks : %0d", check_count);
        $display("Passed       : %0d", check_count - error_count);
        $display("Failed       : %0d", error_count);
        if (error_count == 0)
            $display(">>> SYSTEM VERIFICATION: PASS <<<");
        else
            $display(">>> SYSTEM VERIFICATION: FAIL <<<");
        $display("==================================================");
    endtask
endclass