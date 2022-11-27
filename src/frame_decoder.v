module frame_decoder (
    input   wire            clk,
    input   wire            rst,

    input   wire [7:0]      i_rdata,
    input   wire            i_rvalid,

    output reg  [15:0]      o_dst,
    output reg  [15:0]      o_src,
    output wire [15:0]      o_size,
    output wire             o_dir,
    output reg [6:0]       o_type,
    output reg [335:0]     o_payload,

    output reg              o_wvalid
);

localparam MHP_FRAME_LEN    = 51;

localparam IDLE             = 2'b00;
localparam FRAME_RECEIVE    = 2'b01;
localparam FRAME_RECEIVED   = 2'b10;

// reg [MHP_FRAME_LEN*8-1:0] frame;
reg [1:0] state;
reg [7:0] ctr;

always @(posedge clk) begin
    if (rst) begin
        // frame <= {(MHP_FRAME_LEN*8){1'b0}};
        state <= IDLE;
        o_wvalid <= 1'b0;
        ctr <= 0;
        o_payload <= 336'h0;
    end else begin
        case (state)
            IDLE: begin
                ctr <= 0;
                o_wvalid <= 1'b0;
                if (i_rvalid) begin
                    state <= FRAME_RECEIVE;
                end
            end
            FRAME_RECEIVE: begin
                if (i_rvalid) begin
                    ctr <= ctr + 1;
                    state <= FRAME_RECEIVE;
                    // frame <= (frame << 8) | i_rdata;
                    if (ctr == 0) o_dst[7:0] <= i_rdata;
                    if (ctr == 1) o_dst[15:8] <= i_rdata;
                    if (ctr == 2) o_src[7:0] <= i_rdata;
                    if (ctr == 3) o_src[15:8] <= i_rdata;
                    if (ctr == 6) o_type[6:0] <= i_rdata;
                    if (ctr >= 7) o_payload[8*(ctr-7) +:8] <= i_rdata;
                end
                else begin
                    state <= FRAME_RECEIVED;
                end
            end
            FRAME_RECEIVED: begin
                state <= IDLE;
                o_wvalid <= 1'b1;
            end
        endcase
    end
end

endmodule
