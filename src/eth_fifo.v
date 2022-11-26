`timescale 1ns/1ns

module eth_fifo (
  //  sys
  input         i_rst,
  //  input data
  input         i_clk_din,
  input   [7:0] i_data,
  input         i_write,
  //  output data
  input         i_clk_dout,
  output  [7:0] o_data,
  input         i_read,
  //  control signals
  output        o_empty,  o_full
);

dcfifo dcfifo8bx2048 (
  .aclr     (i_rst),
  .wrclk    (i_clk_din),
  .data     (i_data),
  .wrreq    (i_write),
  .rdclk    (i_clk_dout),
  .q        (o_data),
  .rdreq    (i_read),
  .rdempty  (o_empty),
  .wrfull   (o_full),
  .eccstatus(),
  .wrempty  (),
  .wrusedw  (),
  .rdfull   (),
  .rdusedw  ()
);
defparam
  dcfifo8bx2048.intended_device_family = "Cyclone V",
  dcfifo8bx2048.lpm_numwords = 2048,
  dcfifo8bx2048.lpm_showahead = "OFF",
  dcfifo8bx2048.lpm_type = "dcfifo",
  dcfifo8bx2048.lpm_width = 8,
  dcfifo8bx2048.lpm_widthu = 11,
  dcfifo8bx2048.overflow_checking = "ON",
  dcfifo8bx2048.rdsync_delaypipe = 4,
  dcfifo8bx2048.read_aclr_synch = "ON",
  dcfifo8bx2048.underflow_checking = "ON",
  dcfifo8bx2048.use_eab = "ON",
  dcfifo8bx2048.write_aclr_synch = "ON",
  dcfifo8bx2048.wrsync_delaypipe = 4;

endmodule
