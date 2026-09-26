set_db init_lib_search_path ../lib/
set_db init_hdl_search_path ../rtl/



read_libs {slow.lib ram_256x16A_slow_syn.lib}

read_hdl {alu.v control_unit.v csr_file.v data_mem.v ecc_dmem_wrapper.v \
          ecc_status_regs.v error_status_reg.v imm_gen.v inst_mem.v \
          multicycle_rv32i.v reg_file.v secded_decoder.v secded_encoder.v \
          soc_interconnect.v uart_rx_fifo.v uart_top.v uart_tx_fifo.v}



elaborate

set_db delete_unloaded_insts false
set_db optimize_constant_0_flops false
set_db optimize_constant_1_flops false
set_db optimize_constant_feedback_seqs false
set_db auto_ungroup none



read_sdc ../constraints/constraints_top.sdc

set_db syn_generic_effort medium
set_db syn_map_effort medium
set_db syn_opt_effort medium

syn_generic
syn_map
syn_opt

report_timing > reports/report_timing.rpt
report_power  > reports/report_power.rpt
report_area   > reports/report_area.rpt
report_qor    > reports/report_qor.rpt

write_hdl > outputs/multicycle_rv32i_netlist.v
write_sdc > outputs/multicycle_rv32i_sdc.sdc
write_sdf -timescale ns -nonegchecks -recrem split -edges check_edge -setuphold split > outputs/delays.sdf
