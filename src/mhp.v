`timescale 1ns/1ns

module mhp(
  //  sys
  input           i_clk,      i_rst,
  //  ctrl
  input           i_send,
  output          o_done,
  //  eth
  input   [7:0]   i_rdata,
  input           i_rready,
  output          o_rreq,
  output  [7:0]   o_wdata,
  input           i_wready,
  output          o_wvalid 
);

//  fsm
reg   [1:0] state       = 0;
localparam  IDLE        = 0;
localparam  READ        = 1;
localparam  WRITE       = 2;
//  local regs
reg           done      = 0;
//  read regs
reg           r_req     = 0;
//  write regs
reg   [7:0]   w_data    = 0;
reg           w_valid   = 0;

always @(posedge i_clk) begin
  if (i_rst) begin
    done    <= 0;
    w_data  <= 0;
    w_valid <= 0;
    state   <= IDLE;
  end
  else begin
    case (state)
      IDLE: begin
        w_data  <= 0;
        w_valid <= 0;
        done    <= 0;
        if (i_rready) begin // received frame's payload ready
          r_req   <= 1;     // r_req set before read state, so we can expect valid data in READ state
          state   <= READ;
        end else
          r_req   <= 0;
      end
      READ: begin
        if (i_rready) // clear fifo
          r_req   <= 1;
        else begin
          r_req   <= 0;
          done    <= 1;
          state   <= WRITE;
        end
      end
      WRITE: begin    //  write data
        if (i_wready) begin
          w_valid <= 1;
          state   <=  IDLE;
        end
      end
    endcase
  end
end

assign    o_done   = done;
assign    o_rreq   = r_req;
assign    o_wdata  = w_data;
assign    o_wvalid = w_valid;

endmodule
