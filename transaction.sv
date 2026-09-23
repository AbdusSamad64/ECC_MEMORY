// =====================================================================
// transaction.sv
// One stimulus item: what the generator produces, the driver consumes,
// and (tagged) the monitor/scoreboard use to know what to check.
// =====================================================================

`ifndef TRANSACTION_SV
`define TRANSACTION_SV

typedef enum {TXN_UART_BYTE, TXN_FAULT_SB, TXN_FAULT_DB, TXN_MASK_IRQ,
              TXN_UNMASK_IRQ, TXN_WAIT} txn_kind_e;

class transaction;
    txn_kind_e kind;
    byte       uart_data;    // valid for TXN_UART_BYTE
    bit [38:0] fault_mask;   // valid for TXN_FAULT_SB / TXN_FAULT_DB
    time       wait_time;    // valid for TXN_WAIT
    string     label;        // human-readable id, used in scoreboard messages
endclass


`endif