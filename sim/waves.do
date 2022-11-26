add wave -divider TOP
add wave -group -expand TOP /tb_top/dut_top/*

add wave -divider MAC_PHY
add wave -group MAC -group WRAPPER /tb_top/dut_top/mac_wrapper/*
add wave -group MAC -group MAC_RX  /tb_top/dut_top/mac_wrapper/mac_rx/*
add wave -group MAC -group MAC_TX  /tb_top/dut_top/mac_wrapper/mac_tx/*

add wave -divider UART_PHY
add wave -group UART -group WRAPPER /tb_top/dut_top/uart_wrapper/*
add wave -group UART -group UART_RX /tb_top/dut_top/uart_wrapper/uart_rx/*
add wave -group UART -group UART_TX /tb_top/dut_top/uart_wrapper/uart_tx/*

add wave -divider CONTROLLER
add wave -group CONTROL       /tb_top/dut_top/main/*
add wave -group TASK_MGR      /tb_top/dut_top/main/task_manager/*
add wave -group MHP_PROTOCOL  /tb_top/dut_top/main/task_manager/protocol/*
add wave -group DEBUG_PORT    /tb_top/dut_top/main/debug_port/*

add wave -divider TB
add wave -group TB_TOP  /tb_top/*