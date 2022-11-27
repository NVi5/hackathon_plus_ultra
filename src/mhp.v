`timescale 1ns/1ns

module mhp(
    //  sys
    input           i_clk,      i_rst,
    //  ctrl
    output           o_link,
    //   output          o_done,
    //  eth
    input   [7:0]   i_rdata,
    input           i_rready,
    output          o_rreq,
    output  [7:0]   o_wdata,
    input           i_wready,
    output          o_wvalid
);


wire  [7:0]      o_wdata2;
wire             o_wvalid2;


reg [15:0]      our_dst = 16'hffff;
reg [15:0]      our_src = 16'h0000;
wire [15:0]      i_size = 37;
wire             i_dir  = 1;
reg [6:0]           our_type = 7'h3;
reg [335:0]         our_payload = 336'b0;

wire             frame_assembly_done;
reg              frame_assembly_start;

reg [5:0]        i_payload_size;

frame_assembly frame_assembly_i(
    .clk(i_clk),
    .rst(i_rst),
    .o_wdata(o_wdata2),
    .o_wvalid(o_wvalid2),
    .i_dst(our_dst),
    .i_src(our_src),
    .i_size(i_size),
    .i_dir(i_dir),
    .i_type(our_type),
    .i_payload(i_payload),
    .i_payload_size(i_payload_size),
    .done(frame_assembly_done),
    .start(frame_assembly_start)
);

//  fsm
reg   [1:0] ping_state       = 0;
localparam  PING_IDLE        = 0;
localparam  PING_READ        = 1;
localparam  PING_WRITE       = 2;
localparam  PING_LINK       = 3;

reg   [1:0] mhp_state       = 0;
localparam  MHP_ADDR_REQ    = 0;
localparam  MHP_IDLE        = 1;
localparam  MHP_READ        = 2;
localparam  MHP_WRITE       = 3;

//  local regs
reg           done      = 0;
//  read regs
reg           r_req     = 0;
//  write regs
reg   [7:0]   w_data    = 0;
reg           w_valid   = 0;

reg           link;

vio u0 (
    .source (trigger_send),
    .probe  (read_ctr)
);

wire trigger_send;
reg [7:0] read_ctr;

reg [9:0] link_delay;

always @(posedge i_clk) begin
    if (i_rst) begin
        done    <= 0;
        w_data  <= 0;
        w_valid <= 0;
        ping_state   <= PING_IDLE;
        mhp_state   <= MHP_ADDR_REQ;
        link    <= 0;
        i_payload_size <= 0;
        read_ctr <= 8'h0;
        link_delay <= 500;
        our_src <= 16'h0000;
        our_dst <= 16'hffff;
        our_type <= 7'h3;
        our_payload <= 336'b0;
    end
    else begin
        if (link == 1'b0) begin
            case (ping_state)
                PING_IDLE: begin
                    w_data  <= 0;
                    w_valid <= 0;
                    done    <= 0;
                    if (i_rready) begin // received frame's payload ready
                        r_req   <= 1;     // r_req set before read state, so we can expect valid data in READ state
                        ping_state   <= PING_READ;
                    end else begin
                        r_req   <= 0;
                    end
                end

                PING_READ: begin
                    if (i_rready) // clear fifo
                        r_req   <= 1;
                    else begin
                        r_req   <= 0;
                        ping_state   <= PING_WRITE;
                    end
                end

                PING_WRITE: begin    //  write data
                    if (i_wready) begin
                        w_valid <= 1;
                        ping_state   <= PING_LINK;
                        link_delay <= 500;
                    end
                end

                PING_LINK: begin    //  go to link
                    w_valid <= 0;
                    link_delay <= link_delay - 1;
                    if (link_delay == 0) begin
                        link    <= 1;
                        ping_state   <= PING_IDLE;
                    end
                end
            endcase

        end else begin

            case (mhp_state)

                MHP_ADDR_REQ: begin
                    i_payload_size <= 37;
                    if (!frame_assembly_done) begin
                        frame_assembly_start  <= 1'b1;
                    end
                    else begin
                        mhp_state   <= MHP_IDLE;
                        frame_assembly_start <= 1'b0;
                    end
                end

                MHP_IDLE: begin
                    if (i_rready || trigger_send) begin // received frame's payload ready
                        r_req   <= 1;     // r_req set before read state, so we can expect valid data in READ state
                        mhp_state   <= MHP_READ;
                        read_ctr <= read_ctr + 1;
                    end else begin
                        r_req   <= 0;
                    end
                end

                MHP_READ: begin
                    if (i_rready) // clear fifo
                        r_req   <= 1;
                    else begin
                        r_req   <= 0;
                        mhp_state   <= MHP_WRITE;
                        link_delay <= 500;
                    end
                end

                MHP_WRITE: begin    //  write data
                    link_delay <= link_delay - 1;
                    if (link_delay == 0) begin
                        link    <= 0;
                        mhp_state   <= MHP_ADDR_REQ;
                    end

                    // if (i_wready) begin
                    //     w_valid <= 1;
                    //     mhp_state   <= MHP_READ;
                    // end
                end
            endcase
        end
    end
end


assign    o_link   = link;
assign    o_rreq   = r_req;
assign    o_wdata  = link ? o_wdata2  : w_data;
assign    o_wvalid = link ? o_wvalid2 : w_valid;

endmodule
