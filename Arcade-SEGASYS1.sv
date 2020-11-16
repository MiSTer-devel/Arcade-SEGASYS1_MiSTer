//=========================================================
//  Arcade: SEGA SYSTEM 1  for MiSTer
//
//                        Copyright (c) 2019,20 MiSTer-X
//=========================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [45:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	output [11:0] VIDEO_ARX,
	output [11:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler

	// Use framebuffer from DDRAM (USE_FB=1 in qsf)
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of 16 bytes.
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,    // 1 - signed audio samples, 0 - unsigned

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT
);

assign VGA_F1    = 0;
assign VGA_SCALER= 0;
assign USER_OUT  = '1;
assign LED_USER  = ioctl_download;
assign LED_DISK  = 0;
assign LED_POWER = 0;

wire screen_H = status[6]|~SYSMODE[1]|direct_video;
wire [1:0] ar = status[15:14];

assign VIDEO_ARX = (!ar) ? (screen_H ? 8'd4 : 8'd3) : (ar - 1'd1);
assign VIDEO_ARY = (!ar) ? (screen_H ? 8'd3 : 8'd4) : 12'd0;

`include "build_id.v" 
localparam CONF_STR = {
	"A.SEGASYS1;;",
	"-;",
	"H0OEF,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"H0O6,Orientation,Vert,Horz;", 
	"O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"-;",
	"DIP;",
	"-;",
	"OOS,Analog Video H-Pos,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31;",
	"OTV,Analog Video V-Pos,0,1,2,3,4,5,6,7;",
	"-;",
	"R0,Reset;",
	"J1,Trig1,Trig2,Trig3,Trig4,Trig5,Start 1P,Start 2P,Coin;",
	"jn,A,B,X,,,Start,Select,R;",
	"V,v",`BUILD_DATE
};

wire [4:0] HOFFS = status[28:24];
wire [2:0] VOFFS = status[31:29];


////////////////////   CLOCKS   ///////////////////

wire clk_48M;
wire clk_hdmi = clk_48M;
wire clk_sys  = clk_48M;

pll pll
(
	.rst(0),
	.refclk(CLK_50M),
	.outclk_0(clk_48M)
);

///////////////////////////////////////////////////

wire [31:0] status;
wire  [1:0] buttons;
wire        forced_scandoubler;
wire			direct_video;

wire        ioctl_download;
wire        ioctl_wr;
wire  [7:0]	ioctl_index;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

wire [15:0] joy1, joy2;
wire [15:0] joy = joy1 | joy2;
wire  [8:0] spinner_0, spinner_1;

wire [21:0]	gamma_bus;

hps_io #(.STRLEN($size(CONF_STR)>>3)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.conf_str(CONF_STR),

	.buttons(buttons),

	.status(status),
	.status_menumask(direct_video),

	.forced_scandoubler(forced_scandoubler),
	.gamma_bus(gamma_bus),
	.direct_video(direct_video),

	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_index(ioctl_index),

	.joystick_0(joy1),
	.joystick_1(joy2),
	.spinner_0(spinner_0),
	.spinner_1(spinner_1)
);

reg [7:0] SYSMODE;	// [0]=SYS1/SYS2,[1]=H/V,[2]=H256/H240,[3]=water match control,[4]=CW/CCW,[5]=spinner
reg [7:0] DSW[8];
always @(posedge clk_sys) begin
	if (ioctl_wr) begin
		if ((ioctl_index==1  ) && (ioctl_addr==0))   SYSMODE <= ioctl_dout;
		if ((ioctl_index==254) && !ioctl_addr[24:3]) DSW[ioctl_addr[2:0]] <= ioctl_dout;
	end
end

wire m_lup    = joy[3];
wire m_ldown  = joy[2];
wire m_lleft  = joy[1];
wire m_lright = joy[0];
wire m_rup    = joy[7];
wire m_rdown  = joy[6];
wire m_rleft  = joy[5];
wire m_rright = joy[4];
wire m_trig   = joy[8];

wire m_up     = joy[3];
wire m_down   = joy[2];
wire m_left   = joy[1];
wire m_right  = joy[0];
wire m_trig_1 = joy[4];
wire m_trig_2 = joy[5];
wire m_trig_3 = joy[6];

wire m_start1 = joy[9];
wire m_start2 = joy[10];
wire m_coin   = joy[11];

///////////////////////////////////////////////////

wire hblank, vblank;
wire ce_vid;
wire hs, vs;
wire [2:0] r,g;
wire [1:0] b;

reg ce_pix;
always @(posedge clk_hdmi) begin
	reg old_clk;
	old_clk <= ce_vid;
	ce_pix  <= old_clk & ~ce_vid;
end

arcade_video #(288,8) arcade_video
(
	.*,

	.clk_video(clk_hdmi),

	.RGB_in({r,g,b}),
	.HBlank(hblank),
	.VBlank(vblank),
	.HSync(~hs),
	.VSync(~vs),

	.fx(status[5:3])
);

assign {FB_PAL_CLK, FB_FORCE_BLANK, FB_PAL_ADDR, FB_PAL_DOUT, FB_PAL_WR} = '0;
 
wire no_rotate = screen_H;
wire rotate_ccw = ~SYSMODE[4];
screen_rotate screen_rotate (.*);

wire			PCLK_EN;
wire  [8:0] HPOS,VPOS;
wire  [7:0] POUT;
HVGEN hvgen
(
	.HPOS(HPOS),
	.VPOS(VPOS),
	.CLK(clk_sys),
	.PCLK_EN(PCLK_EN),
	.iRGB(POUT),
	.oRGB({b,g,r}),
	.HBLK(hblank),
	.VBLK(vblank),
	.HSYN(hs),
	.VSYN(vs),
	.H240(SYSMODE[2]),
	.HOFFS(HOFFS),
	.VOFFS(VOFFS)
);

assign ce_vid = PCLK_EN;

wire [15:0] AOUT;
assign AUDIO_L = AOUT;
assign AUDIO_R = AUDIO_L;
assign AUDIO_S = 0; // unsigned PCM


///////////////////////////////////////////////////

wire iRST = RESET | status[0] | buttons[1];

reg [7:0] INP0, INP1, INP2;
always @(posedge clk_sys) begin
	if (SYSMODE[5]) begin
		INP0 = ~spin;
		INP1 = ~spin;
		INP2 = ~{m_trig_1, m_trig_1, m_start2, m_start1, 3'b000, m_coin};
	end
	else if (SYSMODE[3]) begin
		INP0 = ~{m_lleft, m_lright, m_lup, m_ldown, m_rleft, m_rright, m_rup, m_rdown};
		INP1 = ~{m_lleft, m_lright, m_lup, m_ldown, m_rleft, m_rright, m_rup, m_rdown};
		INP2 = ~{m_trig, m_trig, m_start2, m_start1, 3'b000, m_coin};
	end
	else begin
		INP0 = ~{m_left, m_right, m_up, m_down,1'd0, m_trig_2, m_trig_1, m_trig_3};
		INP1 = ~{m_left, m_right, m_up, m_down,1'd0, m_trig_2, m_trig_1, m_trig_3};
		INP2 = ~{2'b00, m_start2, m_start1, 3'b000, m_coin}; 
	end
end

wire [7:0] spin;
spinner #(15,25,5) spinner
(
	.clk(clk_sys),
	.reset(iRST),
	.minus(m_left),
	.plus(m_right),
	.fast(m_trig_2),
	.strobe(vs),
	.spin1_in(spinner_0),
	.spin2_in(spinner_1),
	.spin_out(spin)
);

SEGASYSTEM1 GameCore
( 
	.clk48M(clk_sys),
	.reset(iRST),

	.INP0(INP0),
	.INP1(INP1),
	.INP2(INP2),
	.DSW0(DSW[0]),
	.DSW1(DSW[1]),

	.PH(HPOS),
	.PV(VPOS),
	.PCLK_EN(PCLK_EN),
	.POUT(POUT),
	.SOUT(AOUT),

	.ROMCL(clk_sys),
	.ROMAD(ioctl_addr),
	.ROMDT(ioctl_dout),
	.ROMEN(ioctl_wr & (ioctl_index==0))
);

endmodule
