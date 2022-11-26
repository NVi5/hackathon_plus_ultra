module uart_wrapper #(
  parameter F = 50000000,
  parameter BAUD = 115200
)(
  //  sys
  input          i_clk,
  input          i_rst,
  //  tx
  input    [7:0] i_data,
  input          i_valid,
  output         o_tx_ready,
  //  rx
  output   [7:0] o_data,
  input          i_req,
  output         o_rx_ready,
  //  top if
  input          i_rx,
  output         o_tx
);

// tx part
wire        tx_fifo_empty;
wire        tx_fifo_full;
wire [7:0]  tx_data_int;
wire        tx_ready_int;
wire        tx_valid_int = ~tx_fifo_empty;

uart_fifo tx_fifo (
  //  sys
  .i_clk    (i_clk),
  .i_rst    (i_rst),
  //  input data
  .i_data   (i_data),
  .i_write  (i_valid),
  //  output data
  .o_data   (tx_data_int),  
  .i_read   (tx_ready_int),
  //  control signals
  .o_full   (tx_fifo_full),
  .o_empty  (tx_fifo_empty)
);
  
uart_tx #( 
  .F    (F),
  .BAUD (BAUD)
) uart_tx (
  //  sys
  .i_clk    (i_clk),
  .i_rst    (i_rst),
  //  data if
  .i_data   (tx_data_int),
  .i_valid  (tx_valid_int),
  .o_ready  (tx_ready_int),
  //  top if
  .o_tx     (o_tx)
);

// rx part
wire        rx_busy, rx_fifo_empty, rx_fifo_full;
wire [7:0]  rx_data_int;
wire        rx_valid_int;
wire        rx_ready_int = ~rx_fifo_full;

uart_rx #( 
  .F    (F),
  .BAUD (BAUD)
) uart_rx (
  //  sys
  .i_clk    (i_clk),
  .i_rst    (i_rst),
  .o_busy   (rx_busy),
  //  data if
  .o_data   (rx_data_int),
  .o_valid  (rx_valid_int),
  .i_ready  (rx_ready_int),
  //  top if
  .i_rx     (i_rx)
);

uart_fifo rx_fifo (
  //  sys
  .i_clk    (i_clk), 
  .i_rst    (i_rst),
  //  input data
  .i_data   (rx_data_int),
  .i_write  (rx_valid_int),
  //  output data
  .o_data   (o_data),
  .i_read   (i_req),
  //  control signals
  .o_empty  (rx_fifo_empty),
  .o_full   (rx_fifo_full)
);

assign      o_tx_ready  = tx_fifo_empty && ~i_valid;
assign      o_rx_ready  = ~rx_fifo_empty && ~rx_busy;

endmodule
