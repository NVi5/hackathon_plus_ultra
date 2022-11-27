module fib (
	input wire i_clk,
	input wire i_rst,

	input wire fib_start,
	output reg fib_done,

	input wire [7:0] arg,
	output reg [15:0] result
);

	reg [15:0] fib_out;
	reg [15:0] fib_n_less1;

	reg [15:0] fib_cntr;

	reg [1:0] fib_state;

	localparam FIB_IDLE = 0, FIB_CALC = 1;

	always @(posedge i_clk) begin
		 if (i_rst) begin
			  fib_done  <= 1'b0;
			  fib_out <= 16'b1;
			  fib_n_less1 <= 16'b1;
			  fib_state <= FIB_IDLE;
			  fib_cntr <= 1'b1;
			  result <= 0;
		 end
		 else begin
			  case (fib_state)
					FIB_IDLE: begin
						 if (fib_start) begin
                            fib_done  <= 1'b0;
                            fib_out <= 16'b1;
                            fib_n_less1 <= 16'b1;
                            fib_state <= FIB_CALC;
                            fib_cntr <= arg - 2;
                            if (arg == 0) begin
                                fib_done <= 1;
                                result <= 0;
                                fib_state <= FIB_IDLE;
                            end
                            else if (arg == 1) begin
                                fib_done <= 1;
                                result <= 1;
                                fib_state <= FIB_IDLE;
                            end
						 end
					end
					FIB_CALC: begin
						if (fib_cntr > 0) begin
							fib_n_less1 <= fib_out;
							fib_out <= fib_out + fib_n_less1;
							fib_cntr <= fib_cntr - 1;
						end
						else begin
							fib_done <= 1;
							result <= fib_out;
							fib_state <= FIB_IDLE;
						end
					end
			  endcase
		 end
	end

endmodule
