/********************************************************************
        FPGA Implimentation of SEGA System 1,2 (Top Module)

											Copyright (c) 2017,19 MiSTer-X
*********************************************************************/
module SEGASYSTEM1
(
	input				clk48M,
	input				reset,

	input   [7:0]	INP0,
	input   [7:0]	INP1,
	input   [7:0]	INP2,

	input   [7:0]	DSW0,
	input   [7:0]	DSW1,
	
	input   [8:0]  PH,         // PIXEL H
	input   [8:0]  PV,         // PIXEL V
	output        PCLK_EN,
	output  [7:0]	POUT, 	   // PIXEL OUT

	output  [15:0] SOUT,			// Sound Out (PCM)

	input				ROMCL,		// Downloaded ROM image
	input   [24:0]	ROMAD,
	input	  [7:0]	ROMDT,
	input				ROMEN,

	input 			PAUSE_N,
	input  [15:0]	HSAD,
	output [7:0]	HSDO,
	input  [7:0]	HSDI,
	input				HSWE

	);

// CPU
wire [15:0] CPUAD;
wire  [7:0] CPUDO,VIDDO,SNDNO,VIDMD;
wire			CPUWR,VIDCS,VBLK;
wire			SNDRQ;


// HISCORE MUX
wire [7:0]	HSDO_MAIN;
wire [7:0]	HSDO_VIDEO;
wire			HSWE_MAIN;
wire			HSWE_VIDEO;

assign HSWE_MAIN = (HSAD[15:12] == 4'b1100);
assign HSWE_VIDEO = ~HSWE_MAIN;
assign HSDO = HSWE_MAIN ? HSDO_MAIN : HSDO_VIDEO;

SEGASYS1_MAIN Main (
	.RESET(reset),
	.INP0(INP0),.INP1(INP1),.INP2(INP2),
	.DSW0(DSW0),.DSW1(DSW1),
	.CLK48M(clk48M),
	.CPUAD(CPUAD),.CPUDO(CPUDO),.CPUWR(CPUWR),
	.VBLK(VBLK),.VIDCS(VIDCS),.VIDDO(VIDDO),
	.SNDRQ(SNDRQ),.SNDNO(SNDNO),
	.VIDMD(VIDMD),
	
	.ROMCL(ROMCL),.ROMAD(ROMAD),.ROMDT(ROMDT),.ROMEN(ROMEN),
	
	.PAUSE_N(PAUSE_N),
	.HSAD(HSAD),.HSDO(HSDO_MAIN),.HSDI(HSDI),.HSWE(HSWE_MAIN & HSWE)
	
);

// Video
wire [7:0] OPIX;
SEGASYS1_VIDEO Video (
	.RESET(reset),.VCLKx8(clk48M),
	.PH(PH),.PV(PV),.VFLP(VIDMD[7]),
	.VBLK(VBLK),.PCLK_EN(PCLK_EN),.RGB8(OPIX),.PALDSW(1'b0),

	.cpu_ad(CPUAD),.cpu_wr(CPUWR),.cpu_dw(CPUDO),
	.cpu_rd(VIDCS),.cpu_dr(VIDDO),

	.ROMCL(ROMCL),.ROMAD(ROMAD),.ROMDT(ROMDT),.ROMEN(ROMEN),
	
	.PAUSE_N(PAUSE_N),
	.HSAD(HSAD),.HSDO(HSDO_VIDEO),.HSDI(HSDI),.HSWE(HSWE_VIDEO & HSWE)
);
assign POUT = VIDMD[4] ? 8'd0 : OPIX;

// Sound
SEGASYS1_SOUND Sound(
	clk48M, reset, SNDNO, SNDRQ, SOUT,
	ROMCL, ROMAD, ROMDT, ROMEN
);

endmodule

