`timescale 1ns/1ns

module crc (
    input wire clk,
    input wire rst,
    input wire [1:0]d,
    input wire sop,
    input wire eop,
    output logic [1:0]d_out,
    output logic sop_out,
    output logic eop_out
);
    parameter N = 32;
    logic [31:0]pol = 32'h04C11DB7;

    logic [1:0]d_r;
    logic sop_r, eop_r;

    logic [31:0]c;
    logic [15:0][1:0]c_r;
    logic fb0, fb1;

    logic [4:0]cnt;
    enum logic [1:0] {
        IDLE,
        EVAL,
        ADD
	} state;

    always_ff @(posedge clk or posedge rst)
        if (rst)
            {sop_r, eop_r} <= '0;
        else
            {sop_r, eop_r} <= {sop, eop};

    always_ff @(posedge clk)
        d_r <= d;

    always_ff @(posedge clk or posedge rst)
        if (rst)
            state <= IDLE;
        else case (state)
            IDLE: state <= sop ? EVAL : IDLE;
            EVAL: state <= eop_r ? ADD : EVAL;
            ADD:  state <= &cnt[3:0] ? IDLE : ADD;
            default: state <= IDLE;
        endcase

    assign fb0 = c[30] ^ d[1];
    assign fb1 = c[31] ^ d[0];
    always_ff @(posedge clk)
        if (state == IDLE && !sop)
            c <= '1;
        else begin
            c[0] <= fb0;
            c[1] <= fb0 ^ fb1;
            for (int i = 2; i < N; i++)
                c[i] <= c[i-2] ^ (fb0 & pol[i]) ^ (fb1 & pol[i-1]);
        end

    //c_r <= ~{<<{c}}; // not supported...
	genvar a, b;
	generate
        for (a = 0; a < 16; a++) begin : BIT_REV
            for (b = 0; b < 2; b++) begin : BIT_REV_1
			    always_ff @(posedge clk)
				    if (eop_r)
					    c_r[a][b] <= ~c[31-2*a-b];
            end
        end
	endgenerate

    always_ff @(posedge clk)
        if (state == IDLE)
            cnt <= '0;
        else if (state == ADD)
            cnt <= cnt + 5'd1;

    always_ff @(posedge clk)
        d_out <= (state == EVAL) ? d_r : c_r[cnt[3:0]];

    always_ff @(posedge clk or posedge rst)
        if (rst)
            {sop_out, eop_out} <= '0;
        else
            {sop_out, eop_out} <= {sop_r, &cnt[3:0]};

endmodule
