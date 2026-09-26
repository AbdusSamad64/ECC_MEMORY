set log file sram_v.log -replace
read library ../memory/ram_256x16A_slow_syn.lib -liberty -both
write library ram_256x16A.v -verilog -replace
exit
