`timescale 1ns/1ns

module uart_counter #(
  parameter N = 25,
  parameter W = $clog2(N)
)(
  input           i_clk,
  input           i_rst,
  input           i_ce,
  output  [W-1:0] o_q,
  output          o_ov
);

logic         ov = 0;
logic [W-1:0] q;

  always_ff @(posedge i_clk)
    if (i_rst)
      q <= '0;
    else if (i_ce)
      if (ov)
        q <= '0;
      else
        q <= q + 1'b1;

  always_ff @(posedge i_clk)
    if (i_rst)
      ov <= '0;
    else if (i_ce)
      if (ov)
        ov <= 1'b0;
      else
        ov <= (q == N - 2);

assign  o_q   = q;
assign  o_ov  = ov;

endmodule
