`timescale 1ns/1ns

module mac_tx #(
  parameter logic [0:5][3:0][1:0]MAC = {8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0}
) (
  //  sys
  input           i_clk,
  input           i_rst,
  input   [15:0]  i_etype,
  input [0:5][3:0][1:0] i_dst_mac,
  //  data if
  input           i_valid,
  input   [7:0]   i_data,
  output          o_req, o_busy,
  //  top if
  output  [1:0]   o_txd,
  output          o_txen
);

localparam    _MIN_MTU = 58; // 60 - 2
localparam    _MAX_MTU = 1516; // 1518 - 2

logic         valid_d, d_req, start, busy;
logic         tx_start, tx_start_t, tx_start_t_d;
logic         sop, last, eop, crc, eop_crc, eop_crc_d;
logic [1:0]   txd, txen, d_pre, d_mem, d_crc;
logic [3:0]   eop_cnt;
logic [5:0]   pre_cnt;
logic [15:0]  taddr;

assign  start = (i_valid & !valid_d);

// control
enum logic {
  IDLE,
  SEND
} state;
    
always_ff @(posedge i_clk) begin
  if (i_rst) begin
    valid_d <= '0;
  end else begin
    valid_d <= i_valid;
  end
  if (i_rst)
    state <= IDLE;
  else begin
    busy  <= state == IDLE ? 0 : 1;
    case (state)
      IDLE: state <= start ? SEND : IDLE;
      SEND: state <= eop_crc ? IDLE : SEND;
      default: state <= IDLE;
    endcase
  end
end

// header
typedef struct packed {
  logic [ 15:0] ethertype; // 2 bytes
  logic [5:0][3:0][1:0] src_mac; // 6 bytes
  logic [5:0][3:0][1:0] dst_mac; // 6 bytes
} header_t; // 14 bytes header
  // + minimum of 46 bytes data
  // + 4 bytes CRC

header_t header;
logic [55:0][1:0] hbits; // header bits
logic [3:0] [1:0] pbits; // payload bits
assign  hbits = header;
logic [7:0]   bdata;  //  byte data
logic [10:0]  baddr;
logic [31:0]  bcrc;
logic [3:0]   ci;
wire  [7:0]   p_bits = pbits;
logic         min_reached, max_reached;

always_ff @(posedge i_clk) begin
  if (i_rst) begin
    for (int i=0; i<6; i++) begin
      header.src_mac[i] <= MAC[i];
      header.dst_mac[i] <= '0;
    end
    header.ethertype <= {i_etype[7:0], i_etype[15:8]};
  end else begin
    for (int i=0; i<6; i++)
      header.dst_mac[i] <= i_dst_mac[i];
    header.ethertype <= {i_etype[7:0], i_etype[15:8]};
  end
end

// preamble
always_ff @(posedge i_clk) begin
  //  control
  if (state == IDLE)
    pre_cnt <= '0;
  else if (pre_cnt[5] == 1'b0)
    pre_cnt <= pre_cnt + 1'b1;
  //  set preamble
  d_pre <= pre_cnt[5] ? 2'd3 : 2'd1;
end

// tx i_data
always_ff @(posedge i_clk) begin
  //  taddr counter
  if (state == IDLE)
    taddr <= '0;
  else if (tx_start)
    taddr <= taddr + 1'b1;
  //  tx_start
  if (state == IDLE)
    tx_start <= 1'b0;
  else if (tx_start_t)
    tx_start <= 1'b1;
  //  tx_start_t + t_d
  tx_start_t <= pre_cnt == 6'd29;
  tx_start_t_d <= tx_start_t;
  //  data request
  if (taddr > 51 && taddr % 4 == 0 && i_valid)
    d_req <= 1;
  else
    d_req <= 0;
  //  payload bytes
  if (taddr[1:0] == 3)
    pbits <= i_data;
  //  bits to send header/payload
  d_mem <= taddr < 56 ? hbits[taddr] : pbits[taddr%4];
  //  end of packet
  if (taddr[1:0] == 2'b10) begin
    min_reached <= baddr >= _MIN_MTU ? 1 : 0;
    max_reached <= baddr >= _MAX_MTU ? 1 : 0;
  end
  if ((!valid_d && min_reached) || max_reached) begin
    if (eop_cnt != 0)
      eop_cnt <= eop_cnt - 1;
    case (eop_cnt)
      3: eop <= 1;
      0: crc <= 1;
      default: eop <= 0;
    endcase
  end else begin
    eop_cnt <= 7;
    eop     <= 0;
    crc     <= 0;
  end
end

// packet control
always_ff @(posedge i_clk) begin
  //  start of packet
  sop <= tx_start_t_d;
end

always @(posedge i_clk) begin
  if (state == IDLE) begin
    bdata <= 0;
    baddr <= 0;
  end else begin
    // show byte
    if ((taddr + 1)%4 == 0) begin
      bdata <= taddr < 56 ?
               {hbits[3+taddr-3],
                hbits[2+taddr-3],
                hbits[1+taddr-3],
                hbits[0+taddr-3]}
             : {pbits[3],
                pbits[2],
                pbits[1],
                pbits[0]};
      baddr <= baddr + 1;
    end
  end
  // crc
  if (!txen) begin
    ci    <= 15;
    bcrc  <= 0;
  end else begin
    if (crc) begin
      ci <= ci + 1;
      bcrc[(2*ci) +: 2] <= txd;
    end
  end
end

// crc module
crc add_crc (
  .clk      (i_clk),
  .rst      (i_rst),
  .d        (d_mem),
  .sop      (sop),
  .eop      (eop),
  .d_out    (d_crc),
  .sop_out  (),
  .eop_out  (eop_crc)
);

// sending actual data
logic select_data, select_data_d;

always_ff @(posedge i_clk) begin
  select_data <= pre_cnt[5];
  select_data_d <= select_data;
  txd <= select_data_d ? d_crc : d_pre;
end

always_ff @(posedge i_clk)
  eop_crc_d <= eop_crc;

always_ff @(posedge i_clk or posedge i_rst) begin
  if (i_rst)
    txen <= '0;
  else if (pre_cnt == 5'd2)
    txen <= '1;
  else if (eop_crc_d)
    txen <= '0;
end

assign  o_busy  = busy;
assign  o_req   = d_req;
assign  o_txd   = txd;
assign  o_txen  = txen;

endmodule
