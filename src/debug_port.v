`timescale 1ns/1ns

module debug_port(
  //  sys
  input           i_clk,      i_rst,
  //  uart rx
  input   [7:0]   i_rdata,
  input           i_rready,
  output          o_rreq,
  //  uart tx
  input           i_wready,
  output  [7:0]   o_wdata,
  output          o_wvalid
);

localparam  _START_BYTE = 8'h68;
localparam  _WATCHDOG   = 8'h65;
`ifdef SIMULATION
localparam  _TIME_30s   = 32'h00000fff;
`else
localparam  _TIME_30s   = 32'h59682eff;
`endif

reg   [1:0] state       = 0;
localparam  IDLE        = 0;
localparam  START       = 1;
localparam  CODE        = 2;
localparam  DONE        = 3;

//  ctrl
reg   [31:0]  watchdog  = 0;
//  comm
reg   [7:0]   wdata     = 0;
reg           wvalid    = 0;

always @(posedge i_clk) begin
  if (i_rst) begin
    state     <= 0;
    watchdog  <= _TIME_30s;
  end
  else begin
    if (state != IDLE)
      watchdog <= _TIME_30s;
    else if (watchdog != 0)
      watchdog <= watchdog - 1;
    case (state)
      IDLE: begin
        wdata  <= 0;
        wvalid <= 0;
        if (watchdog == 0) begin
          state <=  START;
        end
      end
      START: begin
        wvalid <= 1;
        wdata  <= _START_BYTE;
        state  <= CODE;
      end
      CODE: begin
        wvalid <= 1;
        wdata  <= _WATCHDOG;
        state  <= DONE;
      end
      DONE: begin
        wvalid  <= 0;
        state <= IDLE;
      end
    endcase
  end
end

assign      o_wdata   = wdata;
assign      o_wvalid  = wvalid;

endmodule
