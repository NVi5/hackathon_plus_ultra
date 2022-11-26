`timescale 1ns/1ns

module cdc_pipeline #(
  parameter W = 1
)(
  input           i_clk,
  input           o_clk,

  input   [W-1:0] i_data,
  output  [W-1:0] o_data
);

logic [1:0][W-1:0]  pipe_i;
logic [1:0][W-1:0]  pipe_o;

always_ff@(posedge i_clk)
  pipe_i <= {pipe_i[0], i_data};

always_ff@(posedge o_clk)
  pipe_o <= {pipe_o[0], pipe_i[1]};

assign o_data = pipe_o[1];

endmodule
