module frame_decoder (
    input   wire            clk,
    input   wire            rst,

    input   wire [7:0]      i_rdata,
    input   wire            i_rvalid,

    output wire [15:0]      o_dst,
    output wire [15:0]      o_src,
    output wire [15:0]      o_size,
    output wire             o_dir,
    output wire [6:0]       o_type,
    output wire [335:0]     o_payload,
    output wire [15:0]      o_scs,

    input  wire             i_wready,
    output reg              o_wvalid,
);

localparam MHP_FRAME_LEN    = 51;

localparam IDLE             = 2'b00;
localparam FRAME_RECEIVE    = 2'b01;
localparam FRAME_RECEIVED   = 2'b10;

reg [MHP_FRAME_LEN*8-1:0] frame;
reg [1:0] state;

always @(posedge clk) begin
    if (rst) begin
        frame <= {(MHP_FRAME_LEN*8){1'b0}};
        state <= IDLE;
        o_valid <= 1'b0;
    end else begin
        case (state)
            IDLE: begin
                o_valid <= 1'b0;
                if (data_ready) begin
                    frame[7:0] <= i_rdata;
                    state <= FRAME_RECEIVE;
                end
            end
            FRAME_RECEIVE: begin
                if (i_rvalid) begin
                    state <= FRAME_RECEIVE;
                    frame <= (frame << 8) | i_rdata;
                end
                else begin
                    state <= FRAME_RECEIVED;
                end
            end
            FRAME_RECEIVED: begin
                if (i_wready) begin
                    STATE <= IDLE;
                    o_valid <= 1'b1;
                end
            end
        endcase
    end
end

endmodule

module frame_assembly (
    input  wire             clk,
    input  wire             rst,

    output reg  [7:0]       o_wdata,
    output reg              o_wvalid,

    input  wire [15:0]      i_dst,
    input  wire [15:0]      i_src,
    input  wire [15:0]      i_size,
    input  wire             i_dir,
    input  wire [6:0]       i_type,
    input  wire [335:0]     i_payload,
    input  wire [15:0]      i_scs,

    output reg             o_rready,
    input  wire            i_rvalid,
);

localparam MHP_FRAME_LEN    = 51;

localparam IDLE             = 2'b00;
localparam FRAME_SENDING    = 2'b01;
localparam FRAME_SENT       = 2'b10;

reg [MHP_FRAME_LEN*8-1:0] frame;

reg [1:0] state;

always @(posedge clk) begin
    if (rst) begin
        frame <= {(MHP_FRAME_LEN*8){1'b0}};
        state <= IDLE;
        o_valid <= 1'b0;
    end else begin
        case (state)
            IDLE: begin
                i_rready <= 1'b0;
                if (i_rvalid) begin
                    frame <= { i_scs, i_payload, i_type, i_dir, i_size, i_src, i_dst };
                    o_wvalid <= 1'b1;
                    state <= FRAME_SENDING;
                end
            end
            FRAME_SENDING: begin
                if (tutej licznik < MHP_FRAME_LEN) begin
                    state <= FRAME_SENDING;
                    o_wdata <= frame[MHP_FRAME_LEN*8-1 : MHP_FRAME_LEN*8-1-8];
                    frame <= frame << 8;
                end
                else begin
                    o_wvalid <= 1'b0;
                    state <= FRAME_SENT;
                end
            end
            FRAME_SENT: begin
                STATE <= IDLE;
                o_wready <= 1'b1;
            end
        endcase
    end
end

endmodule
