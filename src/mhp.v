`default_nettype none
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

localparam ADDITION             = 8'h10;
localparam SUBTRACTION          = 8'h20;
localparam MULTIPLICATION       = 8'h30;
localparam SINUS                = 8'h40;
localparam COSINUS              = 8'h50;
localparam FIBONACCI            = 8'h60;

wire  [7:0]      o_wdata2;
wire             o_wvalid2;





reg [15:0]      our_scs;
reg [15:0]      our_dst;
reg [15:0]      our_src;
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
    .i_scs(our_scs),
    .i_dst(our_dst),
    .i_src(our_src),
    .i_size(i_size),
    .i_dir(i_dir),
    .i_type(our_type),
    .i_payload(our_payload),
    .i_payload_size(i_payload_size),
    .done(frame_assembly_done),
    .start(frame_assembly_start)
);


wire [15:0]      o_dst;
wire [15:0]      o_src;
wire [15:0]      o_size;
wire             o_dir;
wire [6:0]       o_type;
wire [335:0]     o_payload;
// wire             o_wvalid;

frame_decoder frame_decoder_i(
    .clk(i_clk),
    .rst(i_rst),
    .i_rdata(i_rdata),
    .i_rvalid(r_req),
    .o_dst(o_dst),
    .o_src(o_src),
    .o_size(o_size),
    .o_dir(o_dir),
    .o_type(o_type),
    .o_payload(o_payload),
    .o_wvalid()
);

//  fsm
reg   [1:0] ping_state       = 0;
localparam  PING_IDLE        = 0;
localparam  PING_READ        = 1;
localparam  PING_WRITE       = 2;
localparam  PING_LINK       = 3;

reg   [3:0] mhp_state       = 0;
localparam  MHP_ADDR_REQ    = 0;
localparam  MHP_IDLE        = 1;
localparam  MHP_READ        = 2;
localparam  MHP_DELAY       = 3;
localparam  MHP_READY       = 4;
localparam  MHP_READY_ACK1  = 5;
localparam  MHP_READY_ACK2  = 6;
localparam  MHP_TASK1  = 7;
localparam  MHP_TASK2  = 8;
localparam  MHP_PING  = 9;
localparam  MHP_ADD_R1  = 10;
localparam  MHP_ADD_R2  = 11;
localparam  MHP_ADD_S  = 12;

//  local regs
reg           done      = 0;
//  read regs
reg           r_req     = 0;
//  write regs
reg   [7:0]   w_data    = 0;
reg           w_valid   = 0;

reg           link;

vio u0 (
    .source (stop),
    .probe  (read_ctr)
);

reg fib_start;
wire fib_done;
reg [15:0] fib_result;


fib u_fib(
	.i_clk(i_clk),
	.i_rst(i_rst),
	.fib_start(fib_start),
	.fib_done(fib_done),
	.arg(o_payload[15:8]),
	.result(fib_result),
);

wire stop;
reg [7:0] read_ctr;

reg [9:0] link_delay;

reg [3:0] op_ctr;

always @(posedge i_clk) begin
    if (i_rst || stop) begin
        done    <= 0;
        w_data  <= 0;
        w_valid <= 0;
        ping_state   <= PING_IDLE;
        mhp_state   <= MHP_ADDR_REQ;
        link    <= 0;
        i_payload_size <= 0;
        read_ctr <= 8'h0;
        link_delay <= 500;
        our_scs <= 16'h0000;
        our_src <= 16'h0000;
        our_dst <= 16'hffff;
        our_type <= 7'h3;
        our_payload <= 336'b0;
        op_ctr <= 0;
        fib_start <= 0;
    end
    else begin
        fib_start <= 0;
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
                    our_scs <= 16'h0000;
                    our_src <= 16'h0000;
                    our_dst <= 16'hffff;
                    our_payload <= 336'b0;
                    our_type <= 7'h3;
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
                    if (i_rready) begin // received frame's payload ready
                        r_req   <= 1;     // r_req set before read state, so we can expect valid data in READ state
                        mhp_state   <= MHP_READ;
                        read_ctr <= read_ctr + 1;
                        op_ctr <= 0;
                    end else begin
                        r_req   <= 0;
                    end
                end

                MHP_READ: begin
                    if (i_rready) // clear fifo
                        r_req   <= 1;
                    else begin
                        r_req   <= 0;
                        mhp_state   <= MHP_READY;
                        our_src <= o_dst;
                        our_dst <= o_src;
                    end
                end

                MHP_READY: begin
                    our_scs <= 16'h0000;
                    our_type <= 7'h12;
                    our_payload[7:0] <= 8'h04;
                    our_payload[15:8] <= 8'h20;
                    our_payload[23:16] <= 8'h60;
                    our_payload[31:24] <= 8'h61;
                    our_payload[39:32] <= 8'h62;
                    // our_payload[47:40] <= 8'h65;
                    i_payload_size <= 37;
                    if (!frame_assembly_done) begin
                        frame_assembly_start  <= 1'b1;
                    end
                    else begin
                        mhp_state   <= MHP_READY_ACK1;
                        frame_assembly_start <= 1'b0;
                        link_delay <= 500;
                    end
                end

                MHP_READY_ACK1: begin
                    if (i_rready) begin // received frame's payload ready
                        r_req   <= 1;     // r_req set before read state, so we can expect valid data in READ state
                        mhp_state   <= MHP_READY_ACK2;
                    end else begin
                        r_req   <= 0;
                    end
                end

                MHP_READY_ACK2: begin
                    if (i_rready) // clear fifo
                        r_req   <= 1;
                    else begin
                        r_req   <= 0;
                        mhp_state   <= MHP_TASK1;
                    end
                end

                MHP_TASK1: begin
                    if (i_rready) begin // received frame's payload ready
                        r_req   <= 1;     // r_req set before read state, so we can expect valid data in READ state
                        mhp_state   <= MHP_TASK2;
                    end else begin
                        r_req   <= 0;
                    end
                end

                MHP_TASK2: begin
                    if (i_rready) // clear fifo
                        r_req   <= 1;
                    else begin
                        r_req   <= 0;
                        mhp_state   <= MHP_PING;
                    end
                end

                MHP_PING: begin
                    our_scs <= 16'h0000;
                    our_type <= 7'h01;
                    our_payload[7:0] <= 8'h00;
                    our_payload[15:8] <= 8'h00;
                    our_payload[23:16] <= 8'h00;
                    our_payload[31:24] <= 8'h00;
                    our_payload[39:32] <= 8'h00;
                    our_payload[47:40] <= 8'h00;
                    i_payload_size <= 37;
                    if (!frame_assembly_done) begin
                        frame_assembly_start  <= 1'b1;
                    end
                    else begin
                        mhp_state   <= MHP_ADD_R1;
                        frame_assembly_start <= 1'b0;
                        link_delay <= 500;
                    end
                end

                MHP_ADD_R1: begin
                    if (i_rready) begin // received frame's payload ready
                        r_req   <= 1;     // r_req set before read state, so we can expect valid data in READ state
                        mhp_state   <= MHP_ADD_R2;
                    end else begin
                        r_req   <= 0;
                    end
                end

                MHP_ADD_R2: begin
                    if (i_rready) // clear fifo
                        r_req   <= 1;
                    else begin
                        r_req   <= 0;
                        op_ctr <= op_ctr + 1;
                        mhp_state   <= MHP_ADD_S;
                    end
                end

                MHP_ADD_S: begin
                    our_scs <= 16'h0000;
                    our_type <= 7'h0E;

                    case (o_payload[7:0])
                      ADDITION: begin
                      our_payload[15:0] <= o_payload[23:8] + o_payload[39:24];
                      end
                      SUBTRACTION: begin
                        our_payload[15:0] <= o_payload[23:8] - o_payload[39:24];
                      end
                      MULTIPLICATION: begin
                        our_payload[15:0] <=  o_payload[23:8] * o_payload[39:24];
                      end
                    //   SIN: begin

                    //   end
                    //   COS: begin

                    //   end
                        // FIBONACCI: begin
                        //     if (!fib_done) begin
                        //         fib_start  <= 1'b1;
                        //     end
                        //     else begin
                        //         fib_start <= 1'b0;
                        //         our_payload[15:0] <= fib_result;
                        //     end
                        // end
                    endcase

                    // if (o_payload[7:0] != FIBONACCI || fib_done) begin
                        our_payload[23:16] <= 8'h00;
                        our_payload[31:24] <= 8'h00;
                        our_payload[39:32] <= 8'h00;
                        our_payload[47:40] <= 8'h00;
                        i_payload_size <= 37;
                        if (!frame_assembly_done) begin
                            frame_assembly_start  <= 1'b1;
                        end
                        else begin
                            if (op_ctr >= 3) mhp_state <= MHP_DELAY;
                            else mhp_state <= MHP_ADD_R1;
                            frame_assembly_start <= 1'b0;
                            link_delay <= 500;
                        end
                    // end
                end

                MHP_DELAY: begin
                    link_delay <= link_delay - 1;
                    if (link_delay == 0) begin
                        link    <= 0;
                        mhp_state   <= MHP_ADDR_REQ;
                    end
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

`default_nettype wire
