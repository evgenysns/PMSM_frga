module	cordic #(
    parameter IW=18,	// The number of bits in our inputs
    parameter OW=18,	// The number of output bits to produce
    parameter NSTAGES=18,
    parameter XTRA= 3,// Extra bits for internal precision
    parameter WW=21,	// Our working bit-width
    parameter PW=18	// Bits in our phase variables
)(
    input	wire				i_clk, 
    input	wire				i_reset, 
    input	wire				i_stb,
    input	wire	signed	[(IW-1):0]	i_xval, 
    input	wire	signed	[(IW-1):0]	i_yval,
    input	wire		[(PW-1):0]	i_phase,
    output	wire				o_busy,
    output	reg				o_done,
    output	reg	signed	[(OW-1):0]	o_xval,
    output	reg	signed	[(OW-1):0]	o_yval

);
	
	// First step: expand our input to our working width.
	// This is going to involve extending our input by one
	// (or more) bits in addition to adding any xtra bits on
	// bits on the right.  The one bit extra on the left is to
	// allow for any accumulation due to the cordic gain
	// within the algorithm.
	// 
	wire	signed [(WW-1):0]	e_xval, e_yval;
	assign	e_xval = { {i_xval[(IW-1)]}, i_xval, {(WW-IW-1){1'b0}} };
	assign	e_yval = { {i_yval[(IW-1)]}, i_yval, {(WW-IW-1){1'b0}} };

	// Declare variables for all of the separate stages
	reg	signed	[(WW-1):0]	xv, prex, yv, prey;
	reg		[(PW-1):0]	ph, preph;

	// First step, get rid of all but the last 45 degrees
	//	The resulting phase needs to be between -45 and 45
	//		degrees but in units of normalized phase
	always @(posedge i_clk)
		// Walk through all possible quick phase shifts necessary
		// to constrain the input to within +/- 45 degrees.
		case(i_phase[(PW-1):(PW-3)])
		3'b000: begin	// 0 .. 45, No change
			prex  <=  e_xval;
			prey  <=  e_yval;
			preph <= i_phase;
			end
		3'b001: begin	// 45 .. 90
			prex  <= -e_yval;
			prey  <=  e_xval;
			preph <= i_phase - 18'h10000;
			end
		3'b010: begin	// 90 .. 135
			prex  <= -e_yval;
			prey  <=  e_xval;
			preph <= i_phase - 18'h10000;
			end
		3'b011: begin	// 135 .. 180
			prex  <= -e_xval;
			prey  <= -e_yval;
			preph <= i_phase - 18'h20000;
			end
		3'b100: begin	// 180 .. 225
			prex  <= -e_xval;
			prey  <= -e_yval;
			preph <= i_phase - 18'h20000;
			end
		3'b101: begin	// 225 .. 270
			prex  <=  e_yval;
			prey  <= -e_xval;
			preph <= i_phase - 18'h30000;
			end
		3'b110: begin	// 270 .. 315
			prex  <=  e_yval;
			prey  <= -e_xval;
			preph <= i_phase - 18'h30000;
			end
		3'b111: begin	// 315 .. 360, No change
			prex  <=  e_xval;
			prey  <=  e_yval;
			preph <= i_phase;
			end
		endcase

	//
	// In many ways, the key to this whole algorithm lies in the angles
	// necessary to do this.  These angles are also our basic reason for
	// building this CORDIC in C++: Verilog just can't parameterize this
	// much.  Further, these angle's risk becoming unsupportable magic
	// numbers, hence we define these and set them in C++, based upon
	// the needs of our problem, specifically the number of stages and
	// the number of bits required in our phase accumulator
	//
	reg	[17:0]	cordic_angle [0:31];
	reg	[17:0]	cangle;

	initial	cordic_angle[ 0] = 18'h0_4b90; //  26.565051 deg
	initial	cordic_angle[ 1] = 18'h0_27ec; //  14.036243 deg
	initial	cordic_angle[ 2] = 18'h0_1444; //   7.125016 deg
	initial	cordic_angle[ 3] = 18'h0_0a2c; //   3.576334 deg
	initial	cordic_angle[ 4] = 18'h0_0517; //   1.789911 deg
	initial	cordic_angle[ 5] = 18'h0_028b; //   0.895174 deg
	initial	cordic_angle[ 6] = 18'h0_0145; //   0.447614 deg
	initial	cordic_angle[ 7] = 18'h0_00a2; //   0.223811 deg
	initial	cordic_angle[ 8] = 18'h0_0051; //   0.111906 deg
	initial	cordic_angle[ 9] = 18'h0_0028; //   0.055953 deg
	initial	cordic_angle[10] = 18'h0_0014; //   0.027976 deg
	initial	cordic_angle[11] = 18'h0_000a; //   0.013988 deg
	initial	cordic_angle[12] = 18'h0_0005; //   0.006994 deg
	initial	cordic_angle[13] = 18'h0_0002; //   0.003497 deg
	initial	cordic_angle[14] = 18'h0_0001; //   0.001749 deg
	initial	cordic_angle[15] = 18'h0_0000; //   0.000874 deg
	initial	cordic_angle[16] = 18'h0_0000; //   0.000437 deg
	initial	cordic_angle[17] = 18'h0_0000; //   0.000219 deg
	initial	cordic_angle[18] = 18'h0_0000; //   0.000109 deg
	initial	cordic_angle[19] = 18'h0_0000; //   0.000055 deg
	initial	cordic_angle[20] = 18'h0_0000; //   0.000027 deg
	initial	cordic_angle[21] = 18'h0_0000; //   0.000014 deg
	initial	cordic_angle[22] = 18'h0_0000; //   0.000007 deg
	initial	cordic_angle[23] = 18'h0_0000; //   0.000003 deg
	initial	cordic_angle[24] = 18'h0_0000; //   0.000002 deg
	initial	cordic_angle[25] = 18'h0_0000; //   0.000001 deg
	initial	cordic_angle[26] = 18'h0_0000; //   0.000000 deg
	initial	cordic_angle[27] = 18'h0_0000; //   0.000000 deg
	initial	cordic_angle[28] = 18'h0_0000; //   0.000000 deg
	initial	cordic_angle[29] = 18'h0_0000; //   0.000000 deg
	initial	cordic_angle[30] = 18'h0_0000; //   0.000000 deg
	initial	cordic_angle[31] = 18'h0_0000; //   0.000000 deg
	// Std-Dev    : 0.00 (Units)
	// Phase Quantization: 0.000057 (Radians)
	// Gain is 1.164435
	// You can annihilate this gain by multiplying by 32'hdbd95b16
	// and right shifting by 32 bits.


	reg		idle, pre_valid;
	reg	[4:0]	state;

	initial	idle = 1'b1;
	always @(posedge i_clk)
	if (i_reset)
		idle <= 1'b1;
	else if (i_stb)
		idle <= 1'b0;
	else if (state == 17)
		idle <= 1'b1;

	initial	pre_valid = 1'b0;
	always @(posedge i_clk)
	if (i_reset)
		pre_valid <= 1'b0;
	else
		pre_valid <= (i_stb)&&(idle);

	always @(posedge i_clk)
		cangle <= cordic_angle[state];

	initial	state = 0;
	always @(posedge i_clk)
	if (i_reset)
		state <= 0;
	else if (idle)
		state <= 0;
	else if (state == 17)
		state <= 0;
	else
		state <= state + 1;

	// Here's where we are going to put the actual CORDIC
	// we've been studying and discussing.  Everything up to
	// this point has simply been necessary preliminaries.
	always @(posedge i_clk)
	if (pre_valid)
	begin
		xv <= prex;
		yv <= prey;
		ph <= preph;
	end else if (ph[PW-1])
	begin
		xv <= xv + (yv >>> state);
		yv <= yv - (xv >>> state);
		ph <= ph + (cangle);
	end else begin
		xv <= xv - (yv >>> state);
		yv <= yv + (xv >>> state);
		ph <= ph - (cangle);
	end

	// Round our result towards even
	wire	[(WW-1):0]	final_xv, final_yv;

	assign	final_xv = xv + $signed({{(OW){1'b0}},
				xv[(WW-OW)],
				{(WW-OW-1){!xv[WW-OW]}}});
	assign	final_yv = yv + $signed({{(OW){1'b0}},
				yv[(WW-OW)],
				{(WW-OW-1){!yv[WW-OW]}}});

	initial	o_done = 1'b0;
		always @(posedge i_clk)
	if (i_reset)
		o_done <= 1'b0;
	else
		o_done <= (state >= 17);

	always @(posedge i_clk)
	if (state >= 17)
	begin
		o_xval <= final_xv[WW-1:WW-OW];
		o_yval <= final_yv[WW-1:WW-OW];
	end

	assign	o_busy = !idle;

	// Make Verilator happy with pre_.val
	// verilator lint_off UNUSED
	wire	[(2*WW-2*OW-1):0] unused_val;
	assign	unused_val = { final_xv[WW-OW-1:0], final_yv[WW-OW-1:0] };
	// verilator lint_on UNUSED
endmodule
