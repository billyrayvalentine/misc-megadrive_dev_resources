.include "variables.inc"
.global	main

|==============================================================================
| MAIN
|==============================================================================
main:
	move.l	#0x00C00000, %a4	| Throughout all my code I'll use A4
	move.l	#0x00C00004, %a5	| for the VDP data port and A5 for the
					| VDP control port
	
	bsr	LoadPalettes
	bsr	LoadPatterns
	bsr	FillPlaneA
	bsr	FillPlaneB
	
	clr.l	%d6			| Set D6 to 0
	move.w	#0x2000, %sr		| Enable the interrupts
	move.l	#0x50000003, (%a5)	| Point the VDP data port to the hori-
					| zontal scroll table
	move.w	#0x8F00, (%a5)		| Disable autoincrement
	
Loop:	bsr	ReadJoypad		| Read joypad values into D7
	
	btst	#2, %d7			| Test whether for left button
	beq	1f			| If it's pressed branch to 1
	
	btst	#3, %d7			| Test whether for right
	bne	3f			| If it's not pressed branch to 3
	
	addq.w	#1, %d6			| Increase D6 by one (if right button
					| is pressed)
	bra	2f			| Branch to 2

1:	subq.w	#1, %d6			| Decrease D6 by one (if left button
					| is pressed)
2:	move.w	%d6, (%a4)		| Write D6 into horizontal scroll table

3:	bsr	WaitVsync		| Wait for vertical retrace
	bra	Loop			| Loop
	

|==============================================================================
| LoadPalettes
|==============================================================================
LoadPalettes:
	move.l	#0xC0000000, (%a5)	| Point data port to CRAM
	move.w	#0x8F02, (%a5)		| Set autoincrement (register 15) to 2
	
	moveq	#31, %d0		| We'll load 32 colors (2 palettes)
	lea	Palettes, %a0		| Load address of Palettes into A0
	
1:	move.w	(%a0)+, (%a4)		| Move word from palette into VDP data
					| port and increment A0 by 2
	dbra	%d0, 1b			| If D0 is not zero decrement and jump
					| back to 1
	
	rts				| Return to caller

|==============================================================================
| LoadPatterns
|==============================================================================
LoadPatterns:
	move.l	#0x40000000, (%a5)	| Point data port to start of VRAM
	move.w	#0x8F02, (%a5)		| Set autoincrement (register 15) to 2
	
	moveq	#31, %d0		| We'll load 4 patterns, each 8 longs
					| wide
	lea	Patterns, %a0		| Load address of Patterns into A0

1:	move.l	(%a0)+, (%a4)		| Move long word from patterns into VDP
					| port and increment A0 by 4
	dbra	%d0, 1b			| If D0 is not zero decrement and jump
					| back to 1
	
	rts				| Return to caller

|==============================================================================
| FillPlaneA
|==============================================================================
FillPlaneA:
	move.l	#0x40000003, (%a5)	| Point data port to 0xC000 in VRAM,
					| which is the start address of plane A
	move.w	#0x8F02, (%a5)		| Set autoincrement (register 15) to 2
	
	move.w	#0x2002, %d0		| We'll use palette #1 and pattern #2,
					| don't flip the pattern and set it to
					| low priority.
	moveq	#27, %d1		| The screen is 28 cells high
	
1:	moveq	#63, %d2		| One line is 64 cells wide

2:	move.w	%d0, (%a4)		| Move our pattern data into the plane
	dbra	%d2, 2b			| Loop back to 2
	
	dbra	%d1, 1b			| Loop back to 1
	
	move.l	#0x40000003, %d0
	moveq	#13, %d1		| We want to draw in line 13...
	mulu.w	#64, %d1		| ... and a line is 64 cells wide...
	addi.w	#20, %d1		| ... and we want to draw in column 20
	rol.l	#1, %d1			| Equivalent to multiply by 2
	swap	%d1			| Swap words in D1
	or.l	%d1, %d0		| Add it to D0
	
	move.l	%d0, (%a5)		| Point the VDP to line 13, column 20
					| in plane A
	move.w	#0003, (%a4)		| Display pattern #3 with palette #0
	
	rts				| Return to caller
	
|==============================================================================
| FillPlaneB
|==============================================================================
FillPlaneB:
	move.l	#0x60000003, (%a5)	| Point data port to 0xE000 in VRAM,
					| which is the start address of plane A
	move.w	#0x8F02, (%a5)		| Set autoincrement (register 15) to 2
	
	move.w	#0x0001, %d0		| We'll use palette #0 and pattern #1,
					| don't flip the pattern and set it to
					| low priority.
	moveq	#27, %d1		| The screen is 28 cells high
	
1:	moveq	#63, %d2		| One line is 40 cells wide

2:	move.w	%d0, (%a4)		| Move our pattern data into the plane
	dbra	%d2, 2b			| Loop back to 2
	
	dbra	%d1, 1b			| Loop back to 1
	
	rts				| Return to caller

|==============================================================================
| Read joypad 1
|
| Returns the joypad values in the last byte of D7 with the following layout:
| SACBRLDU (Start A C B Right Left Down Up)
|==============================================================================
ReadJoypad:
	move.l	#0x00A10003, %a0	| Joypad 1 is at 0x00A10003
	
	move.b	#0x40, (%a0)		| Set TH to high
	nop				| Wait for the bus to synchronize
	move.b	(%a0), %d7		| Read status into D0
	
	andi.b	#0x3F, %d7		| D7.b = 00CBRLDU

	move.b	#0x00, (%a0)		| Set TH to low
	nop				| Wait for the bus to synchronize
	move.b	(%a0), %d0		| Read status into D0
					| D0.b = ?0SA00DU
	
	rol	#2, %d0			| D0.b = SA00DU??
	andi.b	#0xC0, %d0		| D0.b = SA000000
	or.b	%d0, %d7		| D7.b = SACBRLDU
	
	rts				| Return to caller

|==============================================================================
| WaitVsync
|==============================================================================
WaitVsync:
	move.l	(VarVsync), %d0	| Read value from VarVsync into D0

1:	move.l	(VarVsync), %d1	| Read value from VarVsync into D1
	cmp.l	%d0, %d1	| Compare D0 and D1
	beq	1b		| If result is 0 the value has not been changed
				| so jump back to 1
	
	rts			| Return to caller
	

|==============================================================================
| Data
|==============================================================================
Palettes:
	.word	0x0000	| Color 0 is always transparent
	.word	0x00EE	| Yellow
	.word	0x0E00	| Blue
	.word	0x000E	| Red
	.word	0x000E	| Red
	.word	0x000E	| Red
	.word	0x000E	| Red
	.word	0x000E	| Red
	.word	0x000E	| Red
	.word	0x000E	| Red
	.word	0x000E	| Red
	.word	0x000E	| Red
	.word	0x000E	| Red
	.word	0x000E	| Red
	.word	0x000E	| Red
	.word	0x000E	| Red

	.word	0x0000	| Color 0 is always transparent
	.word	0x0000	| Black
	.word	0x0EEE	| White
	.word	0x000E	| Red
	.word	0x000E	| Red
	.word	0x000E	| Red
	.word	0x000E	| Red
	.word	0x000E	| Red
	.word	0x000E	| Red
	.word	0x000E	| Red
	.word	0x000E	| Red
	.word	0x000E	| Red
	.word	0x000E	| Red
	.word	0x000E	| Red
	.word	0x000E	| Red
	.word	0x000E	| Red

Patterns:
	.long	0xFFFFFFFF
	.long	0xFFFFFFFF
	.long	0xFFFFFFFF
	.long	0xFFFFFFFF
	.long	0xFFFFFFFF
	.long	0xFFFFFFFF
	.long	0xFFFFFFFF
	.long	0xFFFFFFFF

	.long	0x22111111
	.long	0x12211111
	.long	0x11221111
	.long	0x11122111
	.long	0x11112211
	.long	0x11111221
	.long	0x11111122
	.long	0x21111112
	
	.long	0x00000000
	.long	0x00000000
	.long	0x00000000
	.long	0x00011000
	.long	0x00011000
	.long	0x00000000
	.long	0x00000000
	.long	0x00000000

	.long	0x22222222
	.long	0x21111112
	.long	0x21222212
	.long	0x21200212
	.long	0x21200212
	.long	0x21222212
	.long	0x21111112
	.long	0x22222222
