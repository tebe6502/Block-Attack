/***************************************/
/*  Use MADS http://mads.atari8.info/  */
/*  Mode: DLI (char mode)              */
/***************************************/

	icl "title_select_2.h"

cloc	= $14

	org $f0

fcnt	.ds 2
fadr	.ds 2
fhlp	.ds 2
regA	.ds 1
regX	.ds 1
regY	.ds 1

WIDTH	= 40
HEIGHT	= 30

program = $d800


	opt f+h-

; ---	MAIN PROGRAM

	org program

	jmp main
	jmp stop

pm23	dta 0,0

ant	dta $70
	dta $44,a(scr),$84,$04,$04,$04,$04,$84,$04,$84,$84,$84,$84,$04,$84,$04,$04

	dta $84+$40,a(scr2)
	dta $84,$04,$84,$84,$04,$84,$04,$04,$04,$84,$84
	dta $41,a(ant)

	org program+$100

scr2	ins "title_select_2.scr",-480

	org program+$300

pmg	SPRITES

fnt	ins "title_select_2.fnt"

scr	ins "title_select_2.scr",0,720


main	sta nmi.prc
	sty nmi.prc+1

	lda $fffa
	sta lnmi+1

	lda $fffa+1
	sta hnmi+1

	lda portb
	sta prtb+1

; ---	init PMG

	ift USESPRITES
	mva >pmg pmbase		;missiles and players data address
	mva #$03 pmcntl		;enable players and missiles
	eif

	lda:cmp:req $14		;wait 1 frame

	sei			;stop IRQ interrupts
	mva #$00 nmien		;stop NMI interrupts
	sta dmactl
;	mva #$fe portb		;switch off ROM to get 16k more ram

	mwa #NMI $fffa		;new NMI handler

	mva #$c0 nmien		;switch on NMI+DLI again


	lda:req trig0

	rts

/*
_lp	lda trig0		; FIRE #0
	beq stop

	lda trig1		; FIRE #1
	beq stop

	lda consol		; START
	and #1
	beq stop

	lda skctl
	and #$04
	bne _lp			;wait to press any key; here you can put any own routine
*/

stop	lda:cmp:req cloc

	mva #$00 pmcntl		;PMG disabled

	ldx #$1e
	sta:rpl hposp0,x-

lnmi	lda #0
	sta $fffa

hnmi	lda #0
	sta $fffa+1

prtb	lda #0
	sta portb

	mva #$40 nmien		;only NMI interrupts, DLI disabled
;	cli			;IRQ enabled

_rts	rts			;return to ... DOS


; ---	DLI PROGRAM

.local	DLI

	?old_dli = *

	ift !CHANGES

dli1	lda trig0		; FIRE #0
	beq stop

	lda trig1		; FIRE #1
	beq stop

	lda consol		; START
	and #1
	beq stop

	lda skctl
	and #$04
	beq stop

	lda vcount
	cmp #$02
	bne dli1

	:3 sta wsync

	DLINEW dli9

	eif

dli_start

dli9
	sta regA

	sta wsync		;line=24
	sta wsync		;line=25
c9	lda #$EA
	sta wsync		;line=26
	sta colpm1
	sta wsync		;line=27
	sta wsync		;line=28
x7	lda #$60
	sta wsync		;line=29
	sta hposp1
	DLINEW dli10 1 0 0

dli10
	sta regA
	stx regX
	sty regY

	sta wsync		;line=64
	sta wsync		;line=65
	sta wsync		;line=66
	sta wsync		;line=67
	sta wsync		;line=68
	sta wsync		;line=69
	sta wsync		;line=70
s5	lda #$00
x8	ldx #$46
c10	ldy #$0E
	sta wsync		;line=71
	sta sizep1
	stx hposp1
	sty colpm1
	lda >fnt+$400*$01
s6	ldx #$00
x9	ldy #$47
	sta wsync		;line=72
	sta chbase
	stx sizep0
	sty hposp0
c11	lda #$34
	sta colpm0
	DLINEW dli11 1 1 1

dli11
	sta regA
	stx regX
	sty regY

	sta wsync		;line=80
	sta wsync		;line=81
	sta wsync		;line=82
s7	lda #$03
x10	ldx #$8B
c12	ldy #$EA
	sta wsync		;line=83
	sta sizep1
	stx hposp1
	sty colpm1
	DLINEW dli12 1 1 1

dli12
	sta regA
	stx regX

c13	lda #$0C
	sta wsync		;line=88
	sta color3
c14	lda #$26
	sta wsync		;line=89
	sta colpm2
s8	lda #$03
x11	ldx #$5F
	sta wsync		;line=90
	sta sizep0
	stx hposp0
	sta wsync		;line=91
	sta wsync		;line=92
c15	lda #$2A
	sta wsync		;line=93
	sta colpm0
	DLINEW DLI.dli2 1 1 0

dli2
	sta regA
	lda >fnt+$400*$02
	sta wsync		;line=96
	sta chbase
	DLINEW dli13 1 0 0

dli13
	sta regA
	stx regX
	sty regY

	sta wsync		;line=104
	sta wsync		;line=105
x12	lda #$52
c16	ldx #$08
c17	ldy #$18
	sta wsync		;line=106
	sta hposp0
	stx colpm0
	sty colpm1
x13	lda #$7C
c18	ldx #$48
	sta wsync		;line=107
	sta hposp1
	stx colpm1
	DLINEW dli14 1 1 1

dli14
	sta regA
	stx regX
	sty regY

	sta wsync		;line=120
	sta wsync		;line=121
s9	lda #$00

x14	ldx #$00	;9F

c19	ldy #$00
	sta wsync		;line=122
	sta sizep3
	stx hposp3
	sty colpm3
	sta wsync		;line=123
s10	lda #$00

x15	ldx #0		;$99

c20	ldy #$00
	sta wsync		;line=124
	sta sizep2
	stx hposp2
	sty colpm2
	DLINEW dli15 1 1 1

dli15
	sta regA

c21	lda #$0E
	sta wsync		;line=144
	sta color3
	DLINEW dli16 1 0 0

dli16
	sta regA
	stx regX
	sty regY

	sta wsync		;line=152
	sta wsync		;line=153
	sta wsync		;line=154
	sta wsync		;line=155
	sta wsync		;line=156
	sta wsync		;line=157
	sta wsync		;line=158
s11	lda #$03
x16	ldx #$B0
c22	ldy #$1C
	sta wsync		;line=159
	sta sizep2
	stx hposp2
	sty colpm2
s12	lda #$03
x17	ldx #$30
c23	ldy #$1C
	sta wsync		;line=160
	sta sizep3
	stx hposp3
	sty colpm3
	sta wsync		;line=161
	sta wsync		;line=162
x18	lda #$7C
	sta wsync		;line=163
	sta hposp0
x19	lda #$58
	sta wsync		;line=164
	sta hposp1
s13	lda #$0C
	sta wsync		;line=165
	sta sizem
	DLINEW dli17 1 1 1

dli17
	sta regA

c24	lda #$1C
	sta wsync		;line=168
	sta color1
	DLINEW dli3 1 0 0

dli3
	sta regA
	stx regX
	lda >fnt+$400*$03
c25	ldx #$0A
	sta wsync		;line=176
	sta chbase
	stx color3
	DLINEW dli4 1 1 0

dli4
	sta regA
	lda >fnt+$400*$02
	sta wsync		;line=192
	sta chbase
	sta wsync		;line=193
	sta wsync		;line=194
	sta wsync		;line=195
c26	lda #$1A
	sta wsync		;line=196
	sta color0
	DLINEW dli5 1 0 0

dli5
	sta regA
	stx regX
	lda >fnt+$400*$03
c27	ldx #$08
	sta wsync		;line=224
	sta chbase
	stx color3
	DLINEW dli6 1 1 0

dli6
	sta regA
	lda >fnt+$400*$02
	sta wsync		;line=232
	sta chbase

	lda regA
	rti

.endl

; ---

CHANGES = 1
FADECHR	= 0

SCHR	= 127

; ---

.proc	NMI

	bit nmist
	bpl VBL

	jmp DLI.dli_start
dliv	equ *-2

VBL
	sta regA
	stx regX
	sty regY

	sta nmist		;reset NMI flag

	mwa #ant dlptr		;ANTIC address program

	mva #@dmactl(standard|dma|lineX1|players|missiles) dmactl	;set new screen width

	inc cloc		;little timer

; Initial values

	lda pm23+1
	sta dli.x14+1

	lda pm23
	sta dli.x15+1

	lda >fnt+$400*$00
	sta chbase
c0	lda #$0E
	sta colbak
	lda #$02
	sta chrctl
	lda #$04
	sta gtictl
c1	lda #$28
	sta color0
c2	lda #$1A
	sta color1
c3	lda #$34
	sta color2
c4	lda #$0A
	sta color3
x0	lda #$61
	sta hposp1
c5	lda #$DA
	sta colpm1
x1	lda #$8B
	sta hposp0
c6	lda #$2A
	sta colpm0
x2	lda #$AC
	sta hposp2

s3	lda #$03
	sta sizep0
	sta sizep1
	sta sizep2
	sta sizep3


s4	lda #$10
	sta sizem
x3	lda #$30
	sta hposp3
x4	lda #$CC
	sta hposm2

c8	lda #$0C
	sta colpm3
	sta colpm2

x5	lda #$B0
	sta hposm1
x6	lda #$00
	sta hposm0
	sta hposm3

	mwa #DLI.dli_start dliv	;set the first address of DLI interrupt

;this area is for yours routines

	jsr prc: _rts

quit
	lda regA
	ldx regX
	ldy regY
	rti

.endp

; ---
;	run main
; ---

	opt l-

.MACRO	SPRITES
missiles
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30
	.he 30 30 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 0C 0C 0C
	.he 0C 0C 0C 0C 0C 0C 0C 0C 0C 0C 0C 0C 0C 0C 0C 0C
	.he 0C 0C 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
player0
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 FF FF FF FF FF FF FF FF FF
	.he FF FF FF FF FF FF FF FF FF FF FF FF FF FF EF FF
	.he EF F7 DF 57 77 C7 00 00 00 00 00 00 00 00 00 00
	.he 80 80 80 80 80 80 80 80 80 80 80 80 80 80 80 80
	.he 80 80 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 3F 3F 3F 3F 3F
	.he 3F 3F 3F 3F BF BF BF 3F FF FF FF FF FF FF FF FF
	.he FF FF FF FF FF FF 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
player1
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 FF FF FF FF FF FF FF FF FF FF FF FF
	.he FF FF FF FF FF FF FF FF FF FF FF FE FF FF FE FF
	.he FF FF FF F7 F7 F7 D7 D3 CB CB CB E3 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 FF
	.he 80 80 80 80 80 80 80 00 00 00 00 E5 D5 F5 F7 FD
	.he FF FF FF FF FF FF FF 80 BF BF 9F 9F A0 A0 80 00
	.he 80 80 84 20 20 20 20 20 20 20 20 20 20 20 20 20
	.he 20 20 20 20 20 20 20 20 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 FF 00 FF FF FF FF FF FF FF FF
	.he FF FF FF FF FF 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
player2
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 FF
	.he FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
	.he FF 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 38 38 4C 4C 54 54 64 64
	.he 44 44 44 44 38 38 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 BF 3F FF FF FF FF FF FF FF
	.he FF FF FF FF FF FF FF FF FF 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
player3
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he FC FC FC FC FC FC FC F0 F0 F0 F0 F0 F0 F0 F0 F0
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 10 10 30 30 10 10 10 10
	.he 10 10 10 10 7C 7C 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 F0 F0 F0 F0 F0 F0 F0 F0
	.he F0 F0 F0 F0 F0 F0 F0 F0 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
.ENDM

USESPRITES = 1

.MACRO	DLINEW
	mva <:1 NMI.dliv
	ift [>?old_dli]<>[>:1]
	mva >:1 NMI.dliv+1
	eif

	ift :2
	lda regA
	eif

	ift :3
	ldx regX
	eif

	ift :4
	ldy regY
	eif

	rti

	.def ?old_dli = *
.ENDM

.print *