transcript on

if {[file exists hackathon]} {
	vdel -lib hackathon -all
}

if {[file exists tb]} {
	vdel -lib tb -all
}

# hackathon library compilation

vlib hackathon
vmap hackathon hackathon
vlog -sv -work hackathon \
+define+SIMULATION \
+incdir+../../../src \
../../../src/top.v \
../../../src/eth_fifo.v \
../../../src/uart_fifo.v \
../../../src/cdc_pipeline.sv \
../../../src/crc.sv \
../../../src/mac_rx.sv \
../../../src/mac_tx.sv \
../../../src/mac_wrapper.sv \
../../../src/reset_release.sv \
../../../src/uart_counter.sv \
../../../src/uart_rx.sv \
../../../src/uart_tx.sv \
../../../src/uart_wrapper.sv \
../../../src/control.v \
../../../src/debug_port.v \
../../../src/mhp.v \
../../../src/task_manager.v \

# tb library compilation

vlib tb
vmap tb tb
vlog -sv -work tb +incdir+../../../src/tb \
../../../src/tb/tb_top.sv
