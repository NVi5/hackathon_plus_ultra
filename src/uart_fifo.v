`timescale 1ns/1ns

module uart_fifo (
  //  sys
  input         i_clk,  i_rst,
  //  input data
  input   [7:0] i_data,
  input         i_write,
  //  output data
  output  [7:0] o_data,
  input         i_read,
  //  control signals
  output        o_empty,  o_full
);

scfifo scfifo8bx256(
  .sclr   (i_rst),
  .clock  (i_clk),
  .data   (i_data),
  .wrreq  (i_write),
  .q      (o_data),
  .rdreq  (i_read),
  .empty  (o_empty),
  .full   (o_full),
  .aclr   (),
  .usedw  (),
  .eccstatus(),
  .almost_full(),
  .almost_empty()
);
defparam
  scfifo8bx256.add_ram_output_register  = "ON",
  scfifo8bx256.enable_ecc  = "FALSE",
  scfifo8bx256.intended_device_family  = "Cyclone V",
  scfifo8bx256.lpm_numwords  = 256,
  scfifo8bx256.lpm_showahead  = "ON",
  scfifo8bx256.lpm_type  = "scfifo",
  scfifo8bx256.lpm_width  = 8,
  scfifo8bx256.lpm_widthu  = 8,
  scfifo8bx256.overflow_checking  = "ON",
  scfifo8bx256.underflow_checking  = "ON",
  scfifo8bx256.use_eab  = "ON";

endmodule
