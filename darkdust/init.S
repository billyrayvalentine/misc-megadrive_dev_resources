.include "variables.inc"

	| Sega Genesis ROM header
	
	.long	0x00FFE000, 0x200, Interrupt, Interrupt
	.long	Interrupt, Interrupt, Interrupt, Interrupt
	.long	Interrupt, Interrupt, Interrupt, Interrupt
	.long	Interrupt, Interrupt, Interrupt, Interrupt
	.long	Interrupt, Interrupt, Interrupt, Interrupt
	.long	Interrupt, Interrupt, Interrupt, Interrupt
	.long	Interrupt, Interrupt, Interrupt, Interrupt
	.long	HBlankInterrupt, Interrupt, VBlankInterrupt, Interrupt
	.long	Interrupt, Interrupt, Interrupt, Interrupt
	.long	Interrupt, Interrupt, Interrupt, Interrupt
	.long	Interrupt, Interrupt, Interrupt, Interrupt
	.long	Interrupt, Interrupt, Interrupt, Interrupt
	.long	Interrupt, Interrupt, Interrupt, Interrupt
	.long	Interrupt, Interrupt, Interrupt, Interrupt
	.long	Interrupt, Interrupt, Interrupt, Interrupt
	.long	Interrupt, Interrupt, Interrupt, Interrupt
	
	| Sega string and copyright
	.ascii "SEGA MEGA DRIVE (C)MARC 2004.SEP"
	| Domestic name
	.ascii "MARCS TEST CODE                                 "
	| Overseas name
	.ascii "MARCS TEST CODE                                 "
	| GM (game), product code and serial
	.ascii "GM 12345678-01"
	| Checksum will be here
	.byte 0x81, 0xB4
	| Which devices are supported ?
	.ascii "JD              "
	| ROM start address
	.byte 0x00, 0x00, 0x00, 0x00
	| ROM end address will be here
	.byte 0x00, 0x02, 0x00, 0x00
	| Some magic values, I don't know what these mean
	.byte 0x00, 0xFF, 0x00, 0x00
	.byte 0x00, 0xFF, 0xFF, 0xFF
	| We don't have a modem, so we fill this with spaces
	.ascii "               "
	| Unused
	.ascii "                        "
	.ascii "                         "
	| Country
	.ascii "JUE             "

	tst.l	0x00A10008	| Test on an undocumented (?) IO register ?
	bne	1f		| Branch to the next temp. label 1 if not zero
	tst.w	0x00A1000C	| Test port C control register

1:	bne	SkipSetup	| Branch to SkipSetup if not equal

|||| Initialize some registers values

	lea	Table, %a5	| Load address of Table into A5			| A5 = (address of Table)
	movem.w (%a5)+, %d5-%d7	| The content located at the address stored in	| D5 = 0x8000		A5 += 2
	                        | A5 is moved into D5. Then A5 gets incremented | D6 = 0x3FFF		A5 += 2
				| by two (because we've read a word which is two| D7 = 0x0100		A5 += 2
				| bytes long) and the content of the new loca-
				| tion is moved into D6, and again for D7
	movem.l (%a5)+, %a0-%a4 | The next four longwords (four bytes) are read	| A0 = 0x00A00000	A5 += 4
	                        | into A0 - A4, incrementing A5 after each	| A1 = 0x00A11100	A5 += 4
				| operation by four				| A2 = 0x00A11200	A5 += 4
										| A3 = 0x00C00000	A5 += 4
										| A4 = 0x00C00004	A5 += 4
|||| Check version number

| Version from the SEGA Technical Manual:

	move.b	0xA10001, %d0	| Read MegaDrive hardware version		| D0 =(0x00A10001)
	andi.b	#0x0F, %d0	| The version is stored in last four bytes	| D0 = 0x000000xx
	beq	1f		| If they are all zero we've got one the very
				| first MegaDrives which didn't feature the
				| protection
	move.l	#0x53454741, 0xA14000	| Move the string "SEGA" at 0xA14000

1:	clr.l	%d0		| Move 0 into D0				| D0 = 0x00000000
	movea.l	%d0, %a6	| Move address from D0 into A6 (that is, clear	| A6 = 0x00000000
				| A6)
	move	%a6, %usp	| Setup Stack Pointer				| A7 = 0x00000000
	
2:	move.l	%d0, -(%a6)	| Decrement A6 by four and and write 0x00000000	| D0 -> (A6)		A6 -= 4
				| into (A6)
	dbra	%d6, 2b		| If D6 is not zero then decrement D6 and jump
				| back to 1 (clear user RAM: 0xFFE00000 onward)
										| D6 = 0x00000000
										| A6 = 0xFFE00000 ?

	jsr	InitZ80		| Initialize the Z80 / sound
	jsr	InitPSG		| Initialize the PSG
	jsr	InitVDP		| Initialize the VDP
										

	movem.l	(%a6), %d0-%d7/%a0-%a6	| Clear all registers except A7		| D0 = 0x00000000
				| The registers get cleared because we read from| D1 = 0x00000000
				| the area which we've set to all-zero in the	| D2 = 0x00000000
				| "Initialize memory" section			| D3 = 0x00000000
										| D4 = 0x00000000
										| D5 = 0x00000000
										| D6 = 0x00000000
										| D7 = 0x00000000
										| A0 = 0x00000000
										| A1 = 0x00000000
										| A2 = 0x00000000
										| A3 = 0x00000000
										| A4 = 0x00000000
										| A5 = 0x00000000
										| A6 = 0x00000000

	move	#0x2700, %sr	| Move 0x2700 into Status Register, which now
				| has these set: no trace, A7 is Interupt Stack
				| Pointer, no interrupts, clear condition code bits
	

SkipSetup:
	jmp	main		| Initializing done, jump to main method



|==============================================================================	
Table:
	.word	0x8000		| D5 (needed for initializing the VDP)
	.word	0x3FFF		| D6 (needed for initializing the RAM)
	.word	0x0100		| D7 (needed for initializing the VDP)
	.long	0x00A00000	| A0 (version port)
	.long	0x00A11100	| A1 (Z80 BUSREQ)
	.long	0x00A11200	| A2 (Z80 RESET)
	.long	0x00C00000	| A3 (VDP data port)
	.long	0x00C00004	| A4 (VDP control port)
        
	.word	0xaf01, 0xd91f	| The following stuff is for the Z80
	.word	0x1127, 0x0021
	.word	0x2600,	0xf977
	.word	0xedb0, 0xdde1
	.word	0xfde1, 0xed47
	.word	0xed4f, 0xd1e1
	.word	0xf108, 0xd9c1
	.word	0xd1e1, 0xf1f9
	.word	0xf3ed, 0x5636
	.word	0xe9e9, 0x8104
	.word	0x8f01
	
	.word	0x9fbf, 0xdfff	| Stuff for the PSG


|==============================================================================
| Interrupt routines
|==============================================================================
Interrupt:
	rte
	
HBlankInterrupt:
	add.l	#1, (VarHsync)
	rte

VBlankInterrupt:
	add.l	#1, (VarVsync)
	rte


|==============================================================================
| Initialize the Z80 / load sound program ?
| I don't yet understand what this does...
|==============================================================================
InitZ80:
	move.w	%d7, (%a1)	| Write 0x0100 into Z80 BUSREQ ?		| D7 -> (0x00A11100)
	move.w	%d7, (%a2)	| Write 0x0100 into Z80 RESET ?			| D7 -> (0x00A11200)

1:
	btst	%d0, (%a1)	| Check value of the bit 0 at Z80 BUSREQ
	bne	1b		| Jump back to 1:
	
	moveq	#0x25, %d2	| Write 0x25 into D2				| D2 = 0x00000025

2:
	move.b	(%a5)+, (%a0)+	| Move byte at (A5) into (A0) and increment both| A0 += 1		A5 += 1 * 38 ?
	dbra	%d2, 2b		| If D2 is not zero decrement and jump to Filla	| D2 -= 1
	
										| D2 = 0x00000000
										| A0 = 0x00A00026
	
	move.w	%d0, (%a2)	| Write 0x0000 into Z80 RESET ?			| D0 -> (0x00A11200)
	move.w	%d0, (%a1)	| Write 0x0000 into Z80 BUSREQ ?		| D0 -> (0x00A11100)
	move.w	%d7, (%a2)	| Write 0x0100 into Z80 RESET ?			| D7 -> (0x00A11200)
	rts			| Jump back to caller

|==============================================================================
| Initialize the Programmable Sound Generator ?
| I don't yet understand what this does...
|==============================================================================
InitPSG:
	moveq	#0x03, %d1	| Move 0x03 into D1				| D5 = 0x00000003

1:	move.b	(%a5)+, 0x0011(%a3)	| Write content at (A5) into 0x00C00011,|			A5 += 1 * 4
				| which is the PSG (Programmable Sound Generator)
	dbra	%d1, 1b		| If D1 is not 0 then decrement D5 and jump	| D5 -= 1
				| back to 1
	
										| D5 = 0x00000000
	move.w	%d0, (%a2)	| Write 0x0000 into Z80 RESET ?
	rts			| Jump back to caller

|==============================================================================
| Initialize VDP registers
|==============================================================================
InitVDP:
	moveq	#18, %d0	| 24 registers, but we set only 19
	lea	VDPRegs, %a0	| start address of register values
	
1:	move.b	(%a0)+, %d5	| load lower byte (register value)
	move.w	%d5, (%a4)	| write register
	add.w	%d7, %d5	| next register
	dbra	%d0, 1b		| loop
	
	rts			| Jump back to caller

|==============================================================================
| Register values for the VDP
|==============================================================================
VDPRegs:.byte	0x04	| Reg.  0: Enable Hint, HV counter stop
	.byte	0x74	| Reg.  1: Enable display, enable Vint, enable DMA, V28 mode (PAL & NTSC)
	.byte	0x30	| Reg.  2: Plane A is at 0xC000
	.byte	0x40	| Reg.  3: Window is at 0x10000 (disable)
	.byte	0x07	| Reg.  4: Plane B is at 0xE000
	.byte	0x6A	| Reg.  5: Sprite attribute table is at 0xD400
	.byte	0x00	| Reg.  6: always zero
	.byte	0x00	| Reg.  7: Background color: palette 0, color 0
	.byte	0x00	| Reg.  8: always zero
	.byte	0x00	| Reg.  9: always zero
	.byte	0x00	| Reg. 10: Hint timing
	.byte	0x08	| Reg. 11: Enable Eint, full scroll
	.byte	0x81	| Reg. 12: Disable Shadow/Highlight, no interlace, 40 cell mode
	.byte	0x34	| Reg. 13: Hscroll is at 0xD000
	.byte	0x00	| Reg. 14: always zero
	.byte	0x00	| Reg. 15: no autoincrement
	.byte	0x01	| Reg. 16: Scroll 32V and 64H
	.byte	0x00	| Reg. 17: Window in left side from base point, ???
	.byte	0x00	| Reg. 18: Window in upper side from base point, ???
	.byte	0x00	| Reg. 19: DMA counter low
	.byte	0x00	| Reg. 20: DMA counter high
	.byte	0x00	| Reg. 21: DMA source address low
	.byte	0x00	| Reg. 22: DMA source address mid
	.byte	0x00	| Reg. 23: DMA source address high, DMA mode ?
