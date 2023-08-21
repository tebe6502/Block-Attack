
// Block Attack Title Screen

/***************************************/
/*  Use MADS http://mads.atari8.info/  */
/*  Mode: DLI (char mode)              */
/***************************************/

	icl "bl09.h"

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

scroll_buffer = $0400

	opt f+h-

program = $d800

; ---	MAIN PROGRAM
	org program

	jmp main
;	jmp stop

ant	dta $70
	dta $44,a(scr),$84,$04,$04,$04,$04,$04,$84,$84,$84,$04,$84,$04,$84,$04,$04

	dta $84+$40,a(scr2)
	dta $84,$04,$84,$84,$04,$84,$04,$84

	dta $46|$50|$80
sadr	dta a(scroll_buffer+40)

	dta $44,a(scr2+10*40)
	dta $04
	dta $41,a(ant)

	org program+$100

scr2	ins "bl09.scr",-480


	org program+$300

pmg	SPRITES

fnt	ins "bl09.fnt",0,4*1024+512

fntS	ins '..\scroll\text.fnt',0,512		; 64 znaki

scr	ins "bl09.scr",0,720


crd	ins "bl09.scr",25*40,40


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

	tay
	sta:rne scroll_buffer,y+


	mwa #NMI $fffa		;new NMI handler

	mva #$c0 nmien		;switch on NMI+DLI again

	lda:req trig0


_lp	lda:cmp:req cloc

	jsr scroll

	lda trig0		; FIRE #0
	beq stop

	lda trig1		; FIRE #1
	beq stop

	lda consol		; START
	and #1
	beq stop

	lda skctl
	and #$04
	bne _lp			;wait to press any key; here you can put any own routine

;	rts

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
	DLINEW DLI.dli2 1 0 0

dli2
	sta regA
	lda >fnt+$400*$01
	sta wsync		;line=72
	sta chbase
	DLINEW dli10 1 0 0

dli10
	sta regA

	sta wsync		;line=80
x8	lda #$5F
	sta wsync		;line=81
	sta hposp0
	sta wsync		;line=82
x9	lda #$8B
	sta wsync		;line=83
	sta hposp1
	DLINEW dli11 1 0 0

dli11
	sta regA

c10	lda #$0C
	sta wsync		;line=88
	sta color3
c11	lda #$26
	sta wsync		;line=89
	sta colpm2
	DLINEW dli12 1 0 0

dli12
	sta regA
	stx regX
	sty regY

	sta wsync		;line=104
	sta wsync		;line=105
x10	lda #$52
c12	ldx #$08
c13	ldy #$18
	sta wsync		;line=106
	sta hposp0
	stx colpm0
	sty colpm1
x11	lda #$7C
c14	ldx #$48
	sta wsync		;line=107
	sta hposp1
	stx colpm1
	DLINEW dli3 1 1 1

dli3
	sta regA
	lda >fnt+$400*$02
	sta wsync		;line=120
	sta chbase
	DLINEW dli13 1 0 0

dli13
	sta regA

c15	lda #$0E
	sta wsync		;line=144
	sta color3
	DLINEW dli14 1 0 0

dli14
	sta regA
	stx regX

	sta wsync		;line=152
	sta wsync		;line=153
	sta wsync		;line=154
	sta wsync		;line=155
	sta wsync		;line=156
	sta wsync		;line=157
	sta wsync		;line=158
x12	lda #$B0
c16	ldx #$1C
	sta wsync		;line=159
	sta hposp2
	stx colpm2
	lda >fnt+$400*$03
c17	ldx #$1C
	sta wsync		;line=160
	sta chbase
	stx colpm3
	sta wsync		;line=161
	sta wsync		;line=162
x13	lda #$7C
	sta wsync		;line=163
	sta hposp0
x14	lda #$58
	sta wsync		;line=164
	sta hposp1
s5	lda #$0C
	sta wsync		;line=165
	sta sizem
	DLINEW dli15 1 1 0

dli15
	sta regA

c18	lda #$1C
	sta wsync		;line=168
	sta color1
	DLINEW dli16 1 0 0

dli16
	sta regA

c19	lda #$0A
	sta wsync		;line=176
	sta color3
	DLINEW dli4 1 0 0

dli4
	sta regA
	lda >fnt+$400*$00
	sta wsync		;line=192
	sta chbase
	sta wsync		;line=193
	sta wsync		;line=194
	sta wsync		;line=195
c20	lda #$1A
	sta wsync		;line=196
	sta color0

	lda #$1a
	sta colpm0
	sta colpm1
	sta colpm2
	sta colpm3

	lda #48+128
	sta hposm0
	lda #48+128+8
	sta hposm1
	lda #48+128+16
	sta hposm2
	lda #48+128+24
	sta hposm3

	lda #$ff
	sta sizem

	lda #14
	sta color2

	DLINEW dli5 1 0 0


// scroll

dli5
	sta regA
	stx regX
	lda >fntS
c21	ldx #$00
	sta wsync		;line=208
	sta chbase
	stx color0

	lda #48
	sta hposp0
	lda #48+32
	sta hposp1
	lda #48+64
	sta hposp2
	lda #48+96
	sta hposp3

	DLINEW dli6 1 1 0


dli6
	sta regA
	stx regX
	lda >fnt+$400*$04
c22	ldx #$08
	sta wsync		;line=216
	sta chbase
	stx color3

	lda #$1a
	sta color0

	lda regA
	ldx regX
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

s2	lda #$03
	sta sizep0
	sta sizep1
	sta sizep2
	sta sizep3

x2	lda #$AC
	sta hposp2

c7	lda #$0C
	sta colpm2
	sta colpm3


s4	lda #$10
	sta sizem
x3	lda #$30
	sta hposp3
x4	lda #$CC
	sta hposm2
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



.local	scroll

	lda hsc
	bne toEnd

	lda #8
	sta hsc

	ldy sadr
	lda txtadr: text
	cmp #$9b
	bne skp

	mwa #text txtadr
	lda text

skp	sta scroll_buffer,y
	sta scroll_buffer+48,y

	iny
	cpy #48
	sne
	ldy #0
	sty sadr

	inw txtadr

toEnd	dec hsc

	lda hsc: #8
	sta hscrol

	rts

text	ins '..\scroll\text.scr',160,12*40	; omijamy 4 pierwsze wiersz

	dta $9b

.endl

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
	.he 00 00 00 00 00 FF FF FF FF FF FF FF FF FF FF FF
	.he FF FF 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
player0
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 FF FF FF FF FF FF FF FF FF
	.he FF FF FF FF FF FF FF FF FF FF FF FF FF FF EF FF
	.he EF F7 DF 57 77 C7 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 FF FF FF FF FF FF FF
	.he FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF 00
	.he 00 00 FF FF FF FF FF FF FF FF FF FF FF FF FF FF
	.he FF FF FF FF FF FF FF FF F7 FF FF FF F7 FF FF EF
	.he EB FF 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 FF FF FF FF FF
	.he FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
	.he FF FF FF FF FF FF 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 FF FF FF FF FF FF FF FF FF FF
	.he FF FF 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
player1
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 FF FF FF FF FF FF FF FF FF FF FF FF
	.he FF FF FF FF FF FF FF FF FF FF FF FE FF FF FE FF
	.he FF FF FF F7 F7 F7 D7 D3 CB CB CB E3 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 E5 D5 F5 F7 FD
	.he FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
	.he FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
	.he FF FF FF FF FF FF FF FF 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 FF FF FF FF
	.he FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
	.he FF FF FF FF FF 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 FF FF FF FF FF FF FF FF FF FF
	.he FF FF 00 00 00 00 00 00 00 00 00 00 00 00 00 00
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
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 FF FF FF FF FF FF FF FF FF
	.he FF FF FF FF FF FF FF FF FF 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 FF FF FF FF FF FF FF FF FF FF
	.he FF FF 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
player3
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he FC FC FC FC FC FC FC FC FC FC FC FC FC FC FC FC
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 FC FC FC FC FC FC FC FC
	.he FC FC FC FC FC FC FC FC 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 FF FF FF FF FF FF FF FF FF FF
	.he FF FF 00 00 00 00 00 00 00 00 00 00 00 00 00 00
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