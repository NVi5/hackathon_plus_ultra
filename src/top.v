`timescale 1ns/1ns

module top (
  //  SYS
  input   CLK_50,
  //  RGMII
  input   L1_OSC,
  output  L1_TX0,
  output  L1_TX1,
  output  L1_TX_EN,
  input   L1_RX0,
  input   L1_RX1,
  input   L1_CRS_DV,
  //  UART
  output  UART_TX,
  input   UART_RX
);

//  TOP
wire            clk, reset, link;
assign          clk = CLK_50;

reset_release reset_release(
  .i_clk        (clk),
  .o_rst        (reset)
);

//  UART
wire  [7:0]     uart_rx_data;
wire            uart_rx_req;
wire            uart_rx_ready;
wire  [7:0]     uart_tx_data;
wire            uart_tx_valid;
wire            uart_tx_ready;

`ifdef SIMULATION
parameter UART_BAUD = 1250000;
`else
parameter UART_BAUD = 115200;
`endif

uart_wrapper #(
  .BAUD(UART_BAUD)
) uart_wrapper (
  //  sys
  .i_clk        (clk),
  .i_rst        (reset),
  //  uart rx
  .o_data       (uart_rx_data),
  .i_req        (uart_rx_req),
  .o_rx_ready   (uart_rx_ready),
  //  uart tx
  .i_data       (uart_tx_data),
  .i_valid      (uart_tx_valid),
  .o_tx_ready   (uart_tx_ready),
  //  top if
  .i_rx         (UART_RX),
  .o_tx         (UART_TX)
);

//  RGMII ETH MAC PHY + CDC
wire            reset_phy;
wire            clk_phy = L1_OSC;
wire  [7:0]     eth_rx_data;
wire            eth_rx_ready;
wire            eth_rx_req;
wire  [7:0]     eth_tx_data;
wire            eth_tx_ready;
wire            eth_tx_valid;

cdc_pipeline reset_phy_pipe(
  .i_clk        (clk),
  .o_clk        (clk_phy),
  .i_data       (reset),
  .o_data       (reset_phy)
);

mac_wrapper mac_wrapper(
  //  sys
  .i_clk        (clk),
  .i_rst        (reset),
  .i_link       (link),
  //  phy (top if)
  .i_clk_phy    (clk_phy),
  .i_rst_phy    (reset_phy),
  .i_l1_rxd     ({L1_RX1,L1_RX0}),
  .i_l1_rxen    (L1_CRS_DV),
  .o_l1_txd     ({L1_TX1,L1_TX0}),
  .o_l1_txen    (L1_TX_EN),
  //  eth fifo access
  .o_rx_data    (eth_rx_data),
  .o_rx_ready   (eth_rx_ready),
  .i_rx_req     (eth_rx_req),
  .i_tx_data    (eth_tx_data),
  .o_tx_ready   (eth_tx_ready),
  .i_tx_valid   (eth_tx_valid)
);

defparam 
  mac_wrapper.BOARD_MAC = {8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00} // place your assigned MAC address here :)

control main(
  //  sys
  .i_clk        (clk),
  .i_rst        (reset),
  .o_link       (link),
  //  eth fifo access
  .i_eth_rdata  (eth_rx_data),
  .i_eth_rready (eth_rx_ready),
  .o_eth_rreq   (eth_rx_req),
  .o_eth_wdata  (eth_tx_data),
  .i_eth_wready (eth_tx_ready),
  .o_eth_wvalid (eth_tx_valid),
  //  uart rx
  .i_uart_rdata (uart_rx_data),
  .i_uart_rready(uart_rx_ready),
  .o_uart_rreq  (uart_rx_req),
  //  uart tx
  .o_uart_wdata (uart_tx_data),
  .i_uart_wready(uart_tx_ready),
  .o_uart_wvalid(uart_tx_valid)
);

endmodule
