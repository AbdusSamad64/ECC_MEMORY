// =====================================================================
// generator.sv
// Builds the transaction stream for a scenario and pushes it into the
// gen2drv mailbox. Test (tb_top) calls these add_* methods to define
// what each scenario does; generator itself knows nothing about the DUT.
// =====================================================================

`include "transaction.sv"

class generator;
    mailbox #(transaction) gen2drv;

    function new(mailbox #(transaction) gen2drv);
        this.gen2drv = gen2drv;
    endfunction

    task automatic add_wait(time t, string label = "wait");
        transaction tr = new();
        tr.kind      = TXN_WAIT;
        tr.wait_time = t;
        tr.label     = label;
        gen2drv.put(tr);
    endtask

    task automatic add_uart_byte(byte data, string label = "uart_byte");
        transaction tr = new();
        tr.kind      = TXN_UART_BYTE;
        tr.uart_data = data;
        tr.label     = label;
        gen2drv.put(tr);
    endtask

    task automatic add_fault_sb(string label = "fault_sb");
        transaction tr = new();
        tr.kind       = TXN_FAULT_SB;
        tr.fault_mask = 39'h0000000001;   // single bit flip
        tr.label      = label;
        gen2drv.put(tr);
    endtask

    task automatic add_fault_db(string label = "fault_db");
        transaction tr = new();
        tr.kind       = TXN_FAULT_DB;
        tr.fault_mask = 39'h0000000003;   // double bit flip
        tr.label      = label;
        gen2drv.put(tr);
    endtask

    task automatic add_mask_irq(string label = "mask_irq");
        transaction tr = new();
        tr.kind  = TXN_MASK_IRQ;
        tr.label = label;
        gen2drv.put(tr);
    endtask

    task automatic add_unmask_irq(string label = "unmask_irq");
        transaction tr = new();
        tr.kind  = TXN_UNMASK_IRQ;
        tr.label = label;
        gen2drv.put(tr);
    endtask
endclass