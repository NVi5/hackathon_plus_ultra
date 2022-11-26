`timescale 1ns/1ns

module uart_rx #( 
  parameter F = 50000000,
  parameter BAUD = 115200
) (
  //  sys
  input         i_clk,
  input         i_rst,
  output        o_busy,
  //  data if
  output  [7:0] o_data,
  output        o_valid,
  input         i_ready,
  //  top if
  input         i_rx
);

localparam MOD = (F+BAUD/2)/BAUD;
localparam MOD_LOG = $clog2(MOD);

enum logic [1:0] {
  WAIT,
  START,
  DATA,
  STOP
} state;

logic [MOD_LOG-1:0] ctx_q;
logic [7:0] rxb, data;
logic [2:0] i;
logic       ctx_rst, data_count_rst;
logic       rx_clk, valid, busy;
logic       data_count_ov, data_count_ov_d;

always_ff @(posedge i_clk) begin
  if (i_rst) begin
    state <= WAIT;
    busy  <= 0;
  end
  else begin
    busy  <=  (state != WAIT) ? 1 : 0;
    case (state)
      WAIT: state <= i_rx ? WAIT : START;
      START: state <= rx_clk ? DATA : START;
      DATA: state <= data_count_ov_d ? STOP : DATA;
      STOP: state <= rx_clk ? WAIT : STOP;
      default: state <= WAIT;
    endcase
  end
end

assign ctx_rst = (state == WAIT);
assign rx_clk = (ctx_q == MOD/2);
assign data_count_rst = (state != DATA);

uart_counter #(.N(MOD)) crx (
  .i_clk(i_clk),
  .i_rst(ctx_rst),
  .i_ce(1'b1),
  .o_q(ctx_q),
  .o_ov());

uart_counter #(.N(8)) data_count (
  .i_clk(i_clk),
  .i_rst(data_count_rst),
  .i_ce(rx_clk),
  .o_q(i),
  .o_ov(data_count_ov)
);

always_ff @(posedge i_clk) begin
  if (data_count_ov_d && state == DATA)
    data <= rxb;
  if (rx_clk) begin
    data_count_ov_d <= data_count_ov;
    rxb[i] <= i_rx;
  end
end

always_ff @(posedge i_clk) begin
  if (i_rst)
    valid <= 1'b0;
  else if (data_count_ov_d && state == DATA)
    valid <= 1'b1;
  else if (i_ready)
    valid <= 1'b0;
end

assign  o_busy  = busy;
assign  o_data  = data;
assign  o_valid = valid;

endmodule
