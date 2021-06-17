// Copyright (c) 2019 MiSTer-X

module HVGEN
(
	output  [8:0]		HPOS,
	output  [8:0]		VPOS,
	input         		CLK,
	input         		PCLK_EN,
	input	 [14:0]		iRGB,

	output reg [14:0]	oRGB,
	output    			HBLK,
	output reg			VBLK = 1,
	output reg			HSYN = 1,
	output reg			VSYN = 1,

	input					H240,

	input   [8:0]		HOFFS,
	input	  [8:0]		VOFFS
);

reg [8:0] hcnt = 0;
reg [8:0] vcnt = 0;

assign HPOS = hcnt-9'd16;
assign VPOS = vcnt;

wire [8:0] HS_B = 9'd288+(HOFFS*2'd2);
wire [8:0] HS_E =  9'd32+(HS_B);
wire [8:0] HS_N = 9'd447+(HS_E-9'd320);

wire [8:0] VS_B = 9'd226+(VOFFS*3'd4);
wire [8:0] VS_E =   9'd4+(VS_B);
wire [8:0] VS_N = 9'd481+(VS_E-9'd230);

reg hblk240;
reg hblk256;

assign HBLK = H240 ? hblk240 : hblk256;

always @(posedge CLK) begin
	if (PCLK_EN) begin
		hcnt <= hcnt + 1'd1;
		case (hcnt)
		 30: hblk256 <= 0;
		 38: hblk240 <= 0;
		278: hblk240 <= 1;
		286: hblk256 <= 1;
		511: begin
			case (vcnt)
				223: begin VBLK <= 1; vcnt <= vcnt+9'd1; end
				511: begin VBLK <= 0; vcnt <= 0; end
				default: vcnt <= vcnt+9'd1;
			endcase
			end
		endcase

		if (hcnt==HS_B) begin HSYN <= 0; end
		if (hcnt==HS_E) begin HSYN <= 1; hcnt <= HS_N; end

		if (vcnt==VS_B) begin VSYN <= 0; end
		if (vcnt==VS_E) begin VSYN <= 1; vcnt <= VS_N; end

		oRGB <= iRGB;
	end
end

endmodule
