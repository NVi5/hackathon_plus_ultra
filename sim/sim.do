vsim tb.tb_top -t ps \
-L ../../modelsim/verilog_libs/altera_mf_ver \
-L hackathon \
-L tb

add log sim:/tb_top/dut_top/mac_wrapper/mac_rx/MAC

do waves.do
run 200us