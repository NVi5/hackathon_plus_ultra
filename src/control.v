`timescale 1ns/1ns

module control(
  //  sys
  input           i_clk, i_rst,
  output          o_link,
  //  eth
  input   [7:0]   i_eth_rdata,
  input           i_eth_rready,
  output          o_eth_rreq,
  output  [7:0]   o_eth_wdata,
  input           i_eth_wready,
  output          o_eth_wvalid,
  //  uart rx
  input   [7:0]   i_uart_rdata,
  input           i_uart_rready,
  output          o_uart_rreq,
  //  uart tx
  output  [7:0]   o_uart_wdata,
  input           i_uart_wready,
  output          o_uart_wvalid
);

task_manager task_manager(
  //  sys
  .i_clk    (i_clk),
  .i_rst    (i_rst),
  .o_link   (o_link),
  //  eth
  .i_rdata  (i_eth_rdata),
  .i_rready (i_eth_rready),
  .o_rreq   (o_eth_rreq),
  .o_wdata  (o_eth_wdata),
  .i_wready (i_eth_wready),
  .o_wvalid (o_eth_wvalid)
);

debug_port debug_port(
  //  sys
  .i_clk    (i_clk),
  .i_rst    (i_rst),
  //  uart rx
  .i_rdata  (i_uart_rdata),
  .i_rready (i_uart_rready),
  .o_rreq   (o_uart_rreq),
  //  uart tx
  .i_wready (1),
  .o_wdata  (o_uart_wdata),
  .o_wvalid (o_uart_wvalid)
);

endmodule
