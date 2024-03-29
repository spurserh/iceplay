
// Adafruit TFT https://www.adafruit.com/product/1591
// Adafruit breakout https://www.adafruit.com/product/1932

module top (
	input  clk,
	output LED0,
	output LED1,
	output LED2,
	output LED3,
	output LED4,
	output LED5,
	output LED6,
	output LED7,

	output DE,
	output VSYNC,
	output HSYNC,
	output DCLK,


	output B0,
	output B1,
	output B2,
	output B3,
	output B4,
	output B5,
	output B6,
	output B7,


	output R0,
	output R1,
	output R2,
	output R3,
	output R4,
	output R5,
	output R6,
	output R7,


	output G7,
	output G6,
	output G5,
	output G4,
	output G3,
	output G2,
	//  Ran out of IOs
);

	wire [7:0] B = {B7, B6, B5, B4, B3, B2, B1, B0};
	wire [7:0] R = {R7, R6, R5, R4, R3, R2, R1, R0};
	wire [7:2] G = {G7, G6, G5, G4, G3, G2};


	reg[8:0] count = 0;
	

	reg[9:0] x=0;
	reg[9:0] y=0;

	// 12mhz is max
	assign DCLK = clk;

	always @(posedge DCLK) begin
		if(x < (total_hor - 1)) begin
			x <= x + 1;
		end else begin
			x <= 0;

			if(y < (total_ver - 1)) begin
				y <= y + 1;
			end else begin
				y <= 0;

				count <= count + 1;
			end
		end
	end

	localparam active_hor = 480;
	localparam active_ver = 272;

	localparam front_porch_hor = 32;
	localparam back_porch_hor = 40;

	localparam front_porch_ver = 32;
	localparam back_porch_ver = 16;

	localparam hsync_n = 8;
	localparam vsync_n = 8;

	localparam total_ver = front_porch_ver + active_ver + back_porch_ver;
	localparam total_hor = front_porch_hor + active_hor + back_porch_hor;

	wire h_front_porch = x < front_porch_hor;
	wire h_back_porch = x > (total_hor - back_porch_hor);

	wire v_front_porch = y < front_porch_ver;
	wire v_back_porch = y > (total_ver - back_porch_ver);

	wire h_porch = h_back_porch | h_front_porch;
	wire v_porch = v_back_porch | v_front_porch;

	assign DE = ~(h_porch | v_porch);

	assign HSYNC = ~(x >= (total_hor - hsync_n));
	assign VSYNC = ~(y >= (total_ver - vsync_n));

	assign LED7 = 0;
	assign LED6 = VSYNC;
	assign {LED0, LED1, LED2, LED3, LED4, LED5} = 0;

	assign R = 0;
	assign G = 0;

	wire [7:0] BA, BB, BC, BD;

	wire[9:0] x2 = x << 1;
	wire[9:0] y2 = y << 1;
	
	renderpix pix0(x2+0, y2+0, count, BA);
	renderpix pix1(x2+1, y2+0, count, BB);
	renderpix pix2(x2+0, y2+1, count, BC);
	renderpix pix3(x2+1, y2+1, count, BD);

	assign B = ({2'b0, BA} + {2'b0, BB} + {2'b0, BC} + {2'b0, BD}) >> 2;

endmodule

module renderpix (
	input [9:0] x,
	input [9:0] y,
	input [8:0] count,
	output [7:0] val);

	wire[7:0] count_cycle = (count > 255) ? (255 - count) : count;

	wire [19:0] c100 = count_cycle;

	wire [19:0] dxs = x + (~c100) + 1;
	wire [19:0] dys = y + (~c100) + 1;

	wire [19:0] dx = dxs[9] ? (~dxs + 1) : dxs;
	wire [19:0] dy = dys[9] ? (~dys + 1) : dys;

	wire [20:0] dist = (dx * dx) + (dy * dy);

	wire [21:0] thresh = {count_cycle, 11'b0};
	wire [21:0] minus_dist = (dist > thresh) ? 0 : (thresh - dist);

	assign val = minus_dist >> (13 - 5);

endmodule



