// =====================================================================
// driver.sv
// Only layer allowed to drive the DUT (via the virtual interface).
// Consumes transactions from gen2drv, drives them, forwards a copy to
// drv2mon so the monitor knows what to check for, then signals txn_done.
//
// Never references dut.* directly - the two DUT-internal signals it
// needs (the memory-read strobe for fault sync, and the interrupt-mask
// bit) are handed in as `ref` arguments by tb_top's run() call.
// =====================================================================

`include "transaction.sv"

class driver;
    virtual cpu_if vif;
    mailbox #(transaction) gen2drv;
    mailbox #(transaction) drv2mon;
    event txn_done;

    localparam int CLOCKS_PER_BIT = 100_000_000 / 115200;
    localparam int BIT_PERIOD     = CLOCKS_PER_BIT * 10;

    function new(virtual cpu_if vif, mailbox #(transaction) gen2drv,
                 mailbox #(transaction) drv2mon, event txn_done);
        this.vif      = vif;
        this.gen2drv  = gen2drv;
        this.drv2mon  = drv2mon;
        this.txn_done = txn_done;
    endfunction

    task automatic reset_dut();
        vif.rst     = 1;
        vif.rx_pin  = 1;
        vif.fi_en   = 0;
        vif.fi_mask = 0;
        #15;
        vif.rst = 0;
    endtask

    task automatic drive_uart_byte(byte data);
        int i;
        $display("  [DRV %0t] UART TX byte 0x%0h", $time, data);
        vif.rx_pin = 0;
        #(BIT_PERIOD);
        for (i = 0; i < 8; i++) begin
            vif.rx_pin = data[i];
            #(BIT_PERIOD);
        end
        vif.rx_pin = 1;
        #(BIT_PERIOD);
    endtask

    task automatic drive_fault(ref logic ram_re_probe, input [38:0] mask);
        @(posedge vif.clk iff ram_re_probe == 1'b1);
        vif.fi_en   = 1;
        vif.fi_mask = mask;
        @(posedge vif.clk);
        vif.fi_en   = 0;
        vif.fi_mask = 0;
    endtask

    task automatic run(ref logic ram_re_probe, ref logic mie_bit);
        transaction tr;
        forever begin
            gen2drv.get(tr);
            drv2mon.put(tr);
            case (tr.kind)
                TXN_WAIT:       #(tr.wait_time);
                TXN_UART_BYTE:  drive_uart_byte(tr.uart_data);
                TXN_FAULT_SB:   drive_fault(ram_re_probe, tr.fault_mask);
                TXN_FAULT_DB:   drive_fault(ram_re_probe, tr.fault_mask);
                TXN_MASK_IRQ:   mie_bit = 1'b0;
                TXN_UNMASK_IRQ: mie_bit = 1'b1;
            endcase
            -> txn_done;
        end
    endtask
endclass