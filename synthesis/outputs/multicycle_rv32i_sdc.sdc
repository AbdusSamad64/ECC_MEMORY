# ####################################################################

#  Created by Genus(TM) Synthesis Solution 26.10-p002_1 on Thu Sep 17 12:05:02 PKT 2026

# ####################################################################

set sdc_version 2.0

set_units -capacitance 1000fF
set_units -time 1000ps

# Set the current design
current_design multicycle_rv32i

create_clock -name "clk" -period 10.0 -waveform {0.0 5.0} [get_ports clk]
set_clock_transition 0.1 [get_clocks clk]
set_clock_gating_check -setup 0.0 
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports fi_en]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[38]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[37]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[36]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[35]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[34]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[33]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[32]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[31]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[30]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[29]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[28]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[27]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[26]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[25]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[24]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[23]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[22]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[21]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[20]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[19]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[18]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[17]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[16]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[15]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[14]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[13]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[12]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[11]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[10]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[9]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[8]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[7]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[6]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[5]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[4]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[3]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[2]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[1]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {fi_mask[0]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports rst]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports rx_pin]
set_output_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports tx_pin]
set_wire_load_mode "enclosed"
set_clock_uncertainty -setup 0.01 [get_ports clk]
set_clock_uncertainty -hold 0.01 [get_ports clk]
