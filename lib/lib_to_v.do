set log file lib_v.log -replace
read library ../lib/slow.lib -liberty -both
write library slow.v -verilog -replace
exit
