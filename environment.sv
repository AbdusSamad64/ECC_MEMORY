// =====================================================================
// environment.sv
// Instantiates generator/driver/monitor/scoreboard and wires them
// together with mailboxes + an event. Nothing else in the TB should
// construct these classes directly - always go through environment.
// =====================================================================

`include "transaction.sv"
`include "generator.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"

class environment;
    virtual cpu_if vif;

    mailbox #(transaction) gen2drv;
    mailbox #(transaction) drv2mon;
    mailbox #(observation) mon2sb;
    event txn_done;

    generator  gen;
    driver     drv;
    monitor    mon;
    scoreboard sb;

    function new(virtual cpu_if vif);
        this.vif = vif;
        gen2drv  = new();
        drv2mon  = new();
        mon2sb   = new();

        gen = new(gen2drv);
        drv = new(vif, gen2drv, drv2mon, txn_done);
        mon = new(mon2sb, drv2mon, txn_done);
        sb  = new(mon2sb);
    endfunction
endclass