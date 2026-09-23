// =====================================================================
// monitor.sv
// Passive layer. Waits for the driver's txn_done, lets effects settle,
// then snapshots DUT state (handed in as `ref` by tb_top) into an
// observation and sends it to the scoreboard. Never drives anything.
// =====================================================================

`include "transaction.sv"
`include "observation.sv"

class monitor;
    mailbox #(observation) mon2sb;
    mailbox #(transaction) drv2mon;
    event txn_done;

    function new(mailbox #(observation) mon2sb, mailbox #(transaction) drv2mon,
                 event txn_done);
        this.mon2sb   = mon2sb;
        this.drv2mon  = drv2mon;
        this.txn_done = txn_done;
    endfunction

    task automatic run(ref int x5, ref int x8, ref int x9, ref int x10,
                        ref logic sb_sticky, ref logic db_sticky,
                        ref int sb_count, ref int db_count);
        transaction tr;
        observation obs;
        int x5_pre, x10_pre, sb_count_pre, db_count_pre;
        forever begin
            drv2mon.get(tr);
            x5_pre       = x5;
            x10_pre      = x10;
            sb_count_pre = sb_count;
            db_count_pre = db_count;

            @(txn_done);
          #500; // settle window for effects (correction, trap, etc.) to land

            obs              = new();
            obs.label        = tr.label;
            obs.kind         = tr.kind;
            obs.t            = $time;
            obs.x5           = x5;
            obs.x8           = x8;
            obs.x9           = x9;
            obs.x10          = x10;
            obs.sb_sticky    = sb_sticky;
            obs.db_sticky    = db_sticky;
            obs.sb_count     = sb_count;
            obs.db_count     = db_count;
            obs.x5_pre       = x5_pre;
            obs.x10_pre      = x10_pre;
            obs.sb_count_pre = sb_count_pre;
            obs.db_count_pre = db_count_pre;

            mon2sb.put(obs);
        end
    endtask
endclass