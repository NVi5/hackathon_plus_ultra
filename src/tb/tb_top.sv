`timescale 1ns/1ns

module tb_top;

logic         uart_tx, uart_rx;
logic         rx_en;
logic  [1:0]  rx_d;
logic         clk_50 = 0;
logic         clk_phy = 1;

top dut_top(
  //  SYS
  .CLK_50(clk_50),
  //  RGMII
  .L1_OSC(clk_phy),
  .L1_TX0(),
  .L1_TX1(),
  .L1_TX_EN(),
  .L1_RX0(rx_d[1]),
  .L1_RX1(rx_d[0]),
  .L1_CRS_DV(rx_en),
  //  UART
  .UART_TX(uart_tx),
  .UART_RX(uart_rx)
);

initial
  forever
    #10 clk_50 = ~clk_50;

initial begin
  #5
  forever
    #10 clk_phy = ~clk_phy;
end

initial begin
  rx_d  = 0;
  rx_en = 0;
  uart_rx = 1;
  uart_tx = 1;
end

always @(posedge clk_50) begin
  force dut_top.mac_wrapper.mac_rx_data = 0;
  force dut_top.mac_wrapper.mac_rx_valid = dut_top.main.debug_port.state == 3 ? 1 : 0;
end

endmodule
