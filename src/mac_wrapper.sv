`timescale 1ns/1ns

module mac_wrapper(
  // sys
  input         i_clk,
  input         i_rst,
  input         i_link,
  // phy (top if)
  input         i_clk_phy,
  input         i_rst_phy,
  input  [1:0]  i_l1_rxd,
  input         i_l1_rxen,
  output [1:0]  o_l1_txd,
  output        o_l1_txen,
  // eth fifo access
  output [7:0]  o_rx_data,
  output        o_rx_ready,
  input         i_rx_req,
  input  [7:0]  i_tx_data,
  output        o_tx_ready,
  input         i_tx_valid
);

parameter ETHERTYPE_MHP  = {16'h88b5};
parameter ETHERTYPE_PING = {16'hc0de};

parameter JUDGE_MAC = {8'h68, 8'h05, 8'hca, 8'h2a, 8'h4e, 8'h23};
parameter BOARD_MAC = {8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};
wire  [15:0]  ethertype = i_link ? ETHERTYPE_MHP : ETHERTYPE_PING;

// rx
logic [7:0]   mac_rx_data;
logic         mac_rx_valid, mac_rx_busy;
logic         rx_fifo_rdempty, rx_fifo_full;

mac_rx #(
  .MAC        (BOARD_MAC)
) mac_rx (
  //  sys
  .i_clk      (i_clk_phy),
  .i_rst      (i_rst_phy),
  .i_etype    (ethertype),
  //  data if
  .o_data     (mac_rx_data),
  .o_valid    (mac_rx_valid),
  .o_busy     (mac_rx_busy),
  //  top if
  .i_rxd      (i_l1_rxd),
  .i_rxen     (i_l1_rxen)
);

eth_fifo rx_fifo (
  //  sys
  .i_rst      (i_rst),
  //  input data
  .i_clk_din  (i_clk_phy),
  .i_data     (mac_rx_data),
  .i_write    (mac_rx_valid),
  //  output data
  .i_clk_dout (i_clk),
  .o_data     (o_rx_data),
  .i_read     (i_rx_req),
  // control signals
  .o_empty    (rx_fifo_rdempty),
  .o_full     (rx_fifo_full)
);

// tx
logic [7:0] mac_tx_data;
logic       mac_tx_req;
logic       mac_tx_busy;
logic       tx_fifo_rdempty;

eth_fifo tx_fifo (
  //  sys
  .i_rst      (i_rst),
  //  input data
  .i_clk_din  (i_clk),
  .i_data     (i_tx_data),
  .i_write    (i_tx_valid),
  //  output data
  .i_clk_dout (i_clk_phy),
  .o_data     (mac_tx_data),
  .i_read     (mac_tx_req),
  // control signals
  .o_empty    (tx_fifo_rdempty),
  .o_full     ()
);

mac_tx #(
  .MAC       (BOARD_MAC)
) mac_tx (
  //  sys
  .i_clk     (i_clk_phy),
  .i_rst     (i_rst_phy),
  .i_etype   (ethertype),
  .i_dst_mac (JUDGE_MAC),
  //  data if
  .i_valid   (~tx_fifo_rdempty),
  .o_req     (mac_tx_req),
  .i_data    (mac_tx_data),
  .o_busy    (mac_tx_busy),
  //  top if
  .o_txd     (o_l1_txd),
  .o_txen    (o_l1_txen)
);

assign  o_rx_ready  = ~rx_fifo_rdempty && ~mac_rx_busy;
assign  o_tx_ready  = tx_fifo_rdempty && ~mac_tx_busy;

endmodule
