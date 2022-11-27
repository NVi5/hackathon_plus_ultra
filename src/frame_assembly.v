// module frame_assembly (
//     input  wire             clk,
//     input  wire             rst,

//     output reg  [7:0]       o_wdata,
//     output reg              o_wvalid,

//     input  wire [15:0]      i_dst,
//     input  wire [15:0]      i_src,
//     input  wire [15:0]      i_size,
//     input  wire             i_dir,
//     input  wire [6:0]       i_type,
//     input  wire [335:0]     i_payload,

//     output reg              done,
//     input  wire             start
// );

// reg [15:0] scs;

// localparam MHP_FRAME_LEN    = 51;

// localparam IDLE             = 2'b00;
// localparam FRAME_SENDING    = 2'b01;
// localparam FRAME_SENT       = 2'b10;

// reg [MHP_FRAME_LEN*8-1:0] frame;

// reg [1:0] state;
// reg [5:0] ctr;
// reg [1:0] shift;

// always @(posedge clk) begin
//     if (rst) begin
//         frame <= {(MHP_FRAME_LEN*8){1'b0}};
//         state <= IDLE;
//         done <= 1'b0;
//         ctr <= 0;
//         shift <= 0;
//         scs <= 0;
//     end else begin
//         case (state)
//             IDLE: begin
//                 ctr <= MHP_FRAME_LEN-1;
//                 done <= 1'b0;
//                 shift <= 0;
//                 if (start) begin
//                     frame <= { scs, i_payload, i_type, i_dir, i_size, i_src, i_dst };
//                     o_wvalid <= 1'b1;
//                     state <= FRAME_SENDING;
//                 end
//             end
//             FRAME_SENDING: begin
//                 if (ctr == 3) begin
//                     frame[MHP_FRAME_LEN*8-1 : MHP_FRAME_LEN*8-1-15] <= scs;
//                 end

//                 if (ctr > 0) begin
//                     shift <= shift + 1;
//                     scs <= scs + o_wdata << shift;
//                     state <= FRAME_SENDING;
//                     o_wdata <= frame[MHP_FRAME_LEN*8-1 : MHP_FRAME_LEN*8-1-7];
//                     frame <= frame << 8;
//                     ctr <= ctr - 1;
//                 end
//                 else begin
//                     o_wvalid <= 1'b0;
//                     state <= FRAME_SENT;
//                     done <= 1'b1;
//                 end
//             end
//             FRAME_SENT: begin
//                 state <= IDLE;
//                 done <= 1'b0;
//             end
//         endcase
//     end
// end

// endmodule

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

    input  wire [5:0]       i_payload_size,

    output reg              done,
    input  wire             start
);

reg [15:0] scs;

localparam MHP_FRAME_LEN    = 51;

localparam IDLE             = 2'b00;
localparam FRAME_SENDING    = 2'b01;
localparam FRAME_SENT       = 2'b10;

reg [MHP_FRAME_LEN*8-1:0] frame;

reg [1:0] state;
reg [5:0] ctr;
reg [1:0] shift;

always @(posedge clk) begin
    if (rst) begin
        frame <= {(MHP_FRAME_LEN*8){1'b0}};
        state <= IDLE;
        done <= 1'b0;
        ctr <= 0;
        shift <= 0;
        scs <= 0;
    end else begin
        case (state)
            IDLE: begin
                ctr <= MHP_FRAME_LEN-1-(42-i_payload_size);
                done <= 1'b0;
                shift <= shift + 1;
                     scs <= 0;
                if (start) begin
                    frame <= {scs, i_payload, i_dir, i_type, i_size[7:0], i_size[15:8], i_src, i_dst} >> 8;
                    o_wvalid <= 1'b1;
                    state <= FRAME_SENDING;
                    o_wdata <= i_dst[7:0];
                    scs <= scs + (i_dst[7:0] << shift);
                end
            end
            FRAME_SENDING: begin
                if (ctr < 3 && ctr > 0) begin
                    o_wdata <= 0;
                    // o_wdata <= scs[15:8];
                    // scs <= scs << 8;
                    ctr <= ctr - 1;
                end
                else if (ctr > 0) begin
                    shift <= shift + 1;
                    scs <= scs + (frame[7:0] << shift);
                    state <= FRAME_SENDING;
                    o_wdata <= frame[7:0];
                    frame <= frame >> 8;
                    ctr <= ctr - 1;
                end
                else begin
                    o_wvalid <= 1'b0;
                    state <= FRAME_SENT;
                end
                if (ctr == 1) done <= 1'b1;
                else done <= 1'b0;
            end
            FRAME_SENT: begin
                shift <= 0;
                scs <= 0;
                state <= IDLE;
                done <= 1'b0;
            end
        endcase
    end
end

endmodule
