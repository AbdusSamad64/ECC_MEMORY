// =====================================================================
// observation.sv
// What the monitor reports to the scoreboard after a transaction's
// effect has settled: a snapshot of DUT state, plus the pre-transaction
// snapshot so the scoreboard can check deltas (not just absolute values).
// =====================================================================

`ifndef OBSERVATION_SV
`define OBSERVATION_SV

`include "transaction.sv"

class observation;
    string     label;
    txn_kind_e kind;
    time       t;

    int  x5, x8, x9, x10;
    bit  sb_sticky, db_sticky;
    int  sb_count, db_count;

    // pre-transaction snapshot
    int  x5_pre, x10_pre, sb_count_pre, db_count_pre;
endclass

`endif