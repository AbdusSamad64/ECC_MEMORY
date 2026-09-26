set log file ecc_memory_lec.log -replace


read library ../lib/slow.v  ../lib/ram256x16A.v -verilog -both


read design ../rtl/multicycle_rv32i.v \
            ../rtl/alu.v \
            ../rtl/control_unit.v \
            ../rtl/csr_file.v \
            ../rtl/data_mem.v \
            ../rtl/ecc_dmem_wrapper.v \
            ../rtl/ecc_status_regs.v \
            ../rtl/error_status_reg.v \
            ../rtl/imm_gen.v \
            ../rtl/inst_mem.v \
            ../rtl/reg_file.v \
            ../rtl/secded_decoder.v \
            ../rtl/secded_encoder.v \
            ../rtl/soc_interconnect.v \
            ../rtl/uart_rx_fifo.v \
            ../rtl/uart_top.v \
            ../rtl/uart_tx_fifo.v \
            -verilog -golden


read design ../synthesis/outputs/multicycle_rv32i_netlist.v \
            -verilog -revised

set system mode lec

add compared points -all
compare -NONEQ_Print
report verification

