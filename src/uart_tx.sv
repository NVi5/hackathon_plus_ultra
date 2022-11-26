`timescale 1ns/1ns

module uart_tx #( 
  parameter F = 50000000,
  parameter BAUD = 115200
)(
  //  sys
  input       i_clk,
  input       i_rst,
  //  data if
  input [7:0] i_data,
  input       i_valid,
  output      o_ready,
  //  top if
  output      o_tx
);

enum logic [1:0] {
  WAIT,
  START,
  DATA,
  STOP
} state;

logic [7:0]txb;
logic [2:0]i;
logic ready, handshake;
logic tx, tx_clk;
logic ctx_rst, data_count_rst;
logic data_count_ov, data_count_ov_d;

assign handshake = i_valid & ready;
logic tx_clk_2;

always_ff @(posedge i_clk)
  if (i_rst)
    state <= WAIT;
  else
    case (state)
      WAIT: state <= handshake ? START : WAIT;
      START: state <= tx_clk ? DATA : START;
      DATA: state <= data_count_ov_d ? STOP : DATA;
      STOP: state <= tx_clk ? WAIT : STOP;
      default: state <= WAIT;
    endcase

always_ff @(posedge i_clk)
  if (handshake)
    txb <= i_data;

always_ff @(posedge i_clk)
  ready <= (state == WAIT) & !handshake;

always_ff @(posedge i_clk)
  case (state)
    START: tx <= 1'b0;
    DATA: tx <= data_count_ov_d ? 1'b1 : txb[i];
    default: tx <= 1'b1;
  endcase

assign ctx_rst = (state == WAIT);
uart_counter #(.N((F+BAUD/2)/BAUD)) ctx (
  .i_clk(i_clk),
  .i_rst(ctx_rst),
  .i_ce(1'b1),
  .o_q(),
  .o_ov(tx_clk)
);

assign data_count_rst = (state != DATA);
uart_counter #(.N(8)) data_count (
  .i_clk(i_clk),
  .i_rst(data_count_rst),
  .i_ce(tx_clk),
  .o_q(i),
  .o_ov(data_count_ov)
);

always_ff @(posedge i_clk)
  if (tx_clk)
    data_count_ov_d <= data_count_ov;
      
assign  o_ready = ready;
assign  o_tx    = tx;

endmodule
