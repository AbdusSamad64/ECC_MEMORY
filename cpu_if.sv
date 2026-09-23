`timescale 1ns / 1ps
// =====================================================================
// cpu_if.sv
// Single point of contact between the testbench and the DUT.
// Every layer that needs to touch DUT top-level ports goes through this.
// =====================================================================
interface cpu_if (input logic clk);
    logic        rst;
    logic        rx_pin;
    logic        tx_pin;
    logic        fi_en;
    logic [38:0] fi_mask;
endinterface