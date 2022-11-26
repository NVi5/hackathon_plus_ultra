`timescale 1ns/1ns

module mac_rx #(
  parameter int LEN = 46,
  parameter logic [0:5][3:0][1:0]MAC = {8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0}
) (
  //  sys
  input           i_clk,
  input           i_rst,
  input   [15:0]  i_etype,
  //  top if
  input   [1:0]   i_rxd,
  input           i_rxen,
  //  output
  output  [7:0]   o_data,
  output          o_valid, o_busy
);

logic         data_ready, valid, busy;
logic [1:0]   rxd_d;
logic [1:0]   rxen_d;
logic [4:0]   cnt;
logic [7:0]   data;
logic [11:0]  cnt_data;
logic [47:0]  dst_mac;
logic [3:0][1:0]  data_in;
logic [0:5][3:0][1:0] dst_mac_in;
wire  [0:1][3:0][1:0] etype = i_etype;

// control
enum logic [3:0] {
  IDLE,
  PREAMB,
  MAC_DST,
  MAC_SRC,
  ETHER_TYPE,
  DATA,
  ERROR
} state, state_d;

always_ff @(posedge i_clk or posedge i_rst)
  if (i_rst) begin
    state   <= IDLE;
    state_d <= IDLE;
    rxen_d  <= 0;
  end else begin
    busy   <= state == IDLE ? 0 : 1;
    rxen_d <= {rxen_d[0], i_rxen};
    state_d <= state;
    case(state)
      IDLE: 
        state <= (rxd_d == 2'd1 && rxen_d[0]) ? PREAMB : IDLE;
      PREAMB:
        case ({rxen_d[0], rxd_d})
          3'b101: state <= PREAMB;
          3'b111: state <= MAC_DST;
          default: state <= ERROR;
        endcase
      MAC_DST: 
        state <= (cnt == 5'd23) ? MAC_SRC : MAC_DST;
      MAC_SRC: 
        state <= (cnt == 5'd23) ? ETHER_TYPE : MAC_SRC;
      ETHER_TYPE:
        if (dst_mac == MAC) begin
          if (etype[cnt[2]][cnt[1:0]] == rxd_d) 
            state <= (cnt == 5'd7) ? DATA : ETHER_TYPE;
          else
            state <= ERROR;
        end else
          state <= ERROR;
      DATA: 
        state <= (|rxen_d) ? DATA : IDLE;
      ERROR:
        state <= (|rxen_d) ? ERROR : IDLE;
    endcase
  end

// src mac acquisition
always_ff @(posedge i_clk) begin
  if (state== MAC_DST)
    dst_mac_in[cnt[4:2]][cnt[1:0]] <= rxd_d;
  if (state_d == MAC_DST)
    dst_mac <= dst_mac_in;
end

assign data_ready = cnt[1:0] == '0;

// data receive
always_ff @(posedge i_clk) begin
  // data counters
  if (state == PREAMB || state == IDLE)
    cnt <= '0;
  else if(cnt == 5'd23 && (state == MAC_DST || state == MAC_SRC))
    cnt <= '0;
  else if(cnt == 5'd7 && state == ETHER_TYPE)
    cnt <= '0;
  else if (cnt == 3'd3 && state == DATA)
    cnt <= '0;
  else
    cnt <= cnt + 1'd1;
  if (state == IDLE)
    cnt_data <= '0;
  else if (state == DATA && cnt[1:0] == 2'd3)
    cnt_data <= cnt_data + 1'd1;
  // data acquisition
  rxd_d <= i_rxd;
  if (state != IDLE)
    data_in[cnt[1:0]] <= rxd_d;
  if (data_ready)
    data <= data_in;
  if (state_d == DATA)
    valid <= data_ready;
end

assign  o_data  = data;
assign  o_valid = valid;
assign  o_busy  = busy;

endmodule
