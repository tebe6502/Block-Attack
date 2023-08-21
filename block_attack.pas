// ---------------------------------------------------------------
// mp.exe block_attack.pas -ipath:[mad_pascal_path]\lib\ -code:980
// ---------------------------------------------------------------
//                          Block Attack
// ---------------------------------------------------------------
// 2019..2022	Tebe/Madteam
//
// 2021-08-25	grafika Odyn1ec
//
// 2021-09-25	nowy ekran tytulowy, ekran wyboru
// 2021-09-03	IRQ zmiana kolorow panelu, rezygnacja z '$define romoff'
// 2021-09-05	rezygnacja z WSYNC (JGP2.PAS -> JPGDLi), cykle opozniajace 'inc DliCnt'
// 2021-12-11	dodane SEI / CLI w procedurze NMI
// 2022-07-17	DEBUG, dla szybszego testowania GAME OVER
// 2022-08-06	creditsy, game over, time over
// 2022-08-08	usuniecie rozkazow SEI/CLI z przerwania NMI, Atari800Win wykladal sie na 'cli \ rti'
// 2022-08-09	dodany modu³ SYSREQ, wymagany 'ANTIC PAL', 'CPU 6502'
// 2022-08-22	poprawione wywolanie IRQ, 'INC IRQEN' zastapione przez 'lda #$00\ sta irqen\ lda #4\ sta irqen'
// 2022-08-23	muzyka na drugim POKEY-u, SAP-R LZSS
// 2022-09-02	obsluga klawiatury A-LEFT, D-RIGHT, W-UP, S-DOWN, Q-FIRE, ESC-QUIT
// 2022-09-17	dodanie obslugi FIRE2 (JOYSCAN) jako alternatywa dla klawisza SHIFT
// 2022-11-06	muzyka LiSU, poprawiony SAPLZSS (restart modulu)
// 2023-06-28	muzyka LiSU na ekran tytu³owy, muzyka VinsCool podczas gry
// 2023-07-06	dodane animacje na panelu (reakcja na zdobycie punktow, combo i przesuniecie klockow)

uses crt, sysutils, jgp2, atari, joystick, graph, zx5, sysreq, saplzss;

{$r block_attack.rc}

{$define basicoff}

//{$DEFINE DEBUG}

type

 TGameMode = (gmEndless, gmTimeTrial);

 TJoyKey = procedure (a: byte);

const

PM_COLOR		= $0600;

PMB_PAGE		= $D800;

DISPLAY_LIST_ADDRESS	= PMB_PAGE;

CHARSET_RAM_ADDRESS	= PMB_PAGE + $0800;	// $dc00, $e000, $e400, $e800, $ec00

VIDEO_RAM_ADDRESS_A	= $C000;		// ..$C9FF (64*width) !!! WIDTH = 40

VIDEO_RAM_ADDRESS_B	= $B000;		// ..$B9FF (64*width) !!! WIDTH = 40

SAPR_PLAYER		= $a400;		// ..$02FF player, $0300..$0BFF buffers [$C00]

bkg_color	= $02;

bkg_panel	= 122 xor $80;

width 		= 40;

max_speed	= 100;


match1 : array [0..18] of byte = (0,	// SFX - match1

	$ff-$b0, $a8,
	$fe-$b0, $a8,
	$fd-$b0, $a8,
	$fc-$b0, $a6,
	$fb-$b0, $a4,
	$f9-$b0, $a3,
	$f8-$b0, $a2,
	$00, $a0,
	$00, $00 );

match2 : array [0..18] of byte = (0,	// SFX - match2

	$f7-$c0, $a8,
	$f6-$c0, $a8,
	$f5-$c0, $a8,
	$f4-$c0, $a6,
	$f3-$c0, $a4,
	$f2-$c0, $a3,
	$f1-$c0, $a2,
	$00, $a0,
	$00, $00 );

match3 : array [0..18] of byte = (0,	// SFX - match3

	$ef-$d0, $a8,
	$ee-$d0, $a8,
	$ed-$d0, $a8,
	$ec-$d0, $a6,
	$eb-$d0, $a4,
	$e9-$d0, $a3,
	$e8-$d0, $a2,
	$e0, $a0,
	$00, $00 );


sfmove : array [0..18] of byte = (0,	// SFX - move

	$00, $a3,
	$00, $a0,
	$00, $a3,
	$00, $a0,
	$00, $a3,
	$00, $a0,
	$00, $a0,
	$00, $a0,
	$00, $00);


sfswap : array [0..18] of byte = (0,	// SFX - swap
	$00, $04,
	$00, $02,
	$00, $01,
	$00, $00,
	$00, $02,
	$00, $04,
	$00, $00,
	$00, $00,
	$00, $00);


vpanel : array [0..14] of byte = (0, bkg_panel, bkg_panel, bkg_panel, bkg_panel, bkg_panel, bkg_panel, bkg_panel, bkg_panel, 0,0,0,0,0,0);

pmDigit	: array [0..159] of byte = (
	$38,$38,$4C,$4C,$54,$54,$64,$64,	// 0
	$44,$44,$44,$44,$38,$38,$00,$00,
	$10,$10,$30,$30,$10,$10,$10,$10,	// 1
	$10,$10,$10,$10,$7C,$7C,$00,$00,
	$38,$38,$04,$04,$38,$38,$40,$40,	// 2
	$40,$40,$40,$40,$7C,$7C,$00,$00,
	$7C,$7C,$08,$08,$18,$18,$04,$04,	// 3
	$04,$04,$44,$44,$38,$38,$00,$00,
	$40,$40,$50,$50,$7C,$7C,$10,$10,	// 4
	$10,$10,$10,$10,$10,$10,$00,$00,
	$7C,$7C,$40,$40,$78,$78,$04,$04,	// 5
	$04,$04,$44,$44,$38,$38,$00,$00,
	$38,$38,$40,$40,$78,$78,$44,$44,	// 6
	$44,$44,$44,$44,$38,$38,$00,$00,
	$7C,$7C,$04,$04,$08,$08,$10,$10,	// 7
	$10,$10,$10,$10,$10,$10,$00,$00,
	$38,$38,$44,$44,$38,$38,$44,$44,	// 8
	$44,$44,$44,$44,$38,$38,$00,$00,
	$3C,$3C,$44,$44,$44,$44,$3C,$3C,	// 9
	$04,$04,$04,$04,$04,$04,$00,$00
	);

digitH	: array [0..191] of byte = (
	$00,$00,$00,$00,$00,$00,$00,$00,	//space
	$60,$A0,$A0,$A0,$A0,$C0,$00,$00,	//0
	$C0,$40,$40,$40,$40,$40,$00,$00,	//1
	$C0,$20,$60,$80,$80,$E0,$00,$00,	//2
	$E0,$20,$60,$20,$20,$C0,$00,$00,	//3
	$80,$A0,$A0,$E0,$20,$20,$00,$00,	//4
	$E0,$80,$E0,$20,$20,$C0,$00,$00,	//5
	$C0,$80,$E0,$A0,$A0,$C0,$00,$00,	//6
	$E0,$20,$20,$20,$20,$20,$00,$00,	//7
	$E0,$A0,$E0,$A0,$A0,$E0,$00,$00,	//8
	$E0,$A0,$A0,$E0,$20,$20,$00,$00,	//9
	$00,$40,$40,$00,$40,$40,$00,$00,	//:
//	);

//digitL	: array [0..95] of byte = (
	$0,$0,$0,$0,$0,$0,$0,$0,		//space
	$6,$A,$A,$A,$A,$C,$0,$0,		//0
	$C,$4,$4,$4,$4,$4,$0,$0,		//1
	$C,$2,$6,$8,$8,$E,$0,$0,		//2
	$E,$2,$6,$2,$2,$C,$0,$0,		//3
	$8,$A,$A,$E,$2,$2,$0,$0,		//4
	$E,$8,$E,$2,$2,$C,$0,$0,		//5
	$C,$8,$E,$A,$A,$C,$0,$0,		//6
	$E,$2,$2,$2,$2,$2,$0,$0,		//7
	$E,$A,$E,$A,$A,$E,$0,$0,		//8
	$E,$A,$A,$E,$2,$2,$0,$0,		//9
	$0,$4,$4,$0,$4,$4,$0,$00		//:
	);


gameover_yn: array [0..191] of byte = (
    $00, $01, $00, $01, $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $00, $01, $00, $01, $00, $01,
    $00, $01, $00, $01, $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $00, $01, $00, $01, $00, $01,
    $0e, $0f, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $1a, $1b, $1c, $1d, $1e, $1f, $00, $01, $00, $01, $00, $01,
    $0e, $0f, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $1a, $1b, $1c, $1d, $1e, $1f, $00, $01, $00, $01, $00, $01,
    $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $2a, $2b, $2c, $2d, $2e, $2f, $30, $31, $32, $33, $00, $01, $00, $01,
    $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $2a, $2b, $2c, $2d, $2e, $2f, $30, $31, $32, $33, $00, $01, $00, $01,
    $00, $01, $00, $01, $34, $35, $36, $37, $38, $39, $3a, $3b, $3c, $3d, $3e, $3f, $40, $41, $42, $43, $44, $45, $00, $01,
    $00, $01, $00, $01, $34, $35, $36, $37, $38, $39, $3a, $3b, $3c, $3d, $3e, $3f, $40, $41, $42, $43, $44, $45, $00, $01
    );


gameover: array [0..671] of byte = (
    $00, $00, $01, $02, $03, $00, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $00, $00, $00, $00, $00, $00, $00,
    $0f, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $1a, $1b, $1c, $1d, $1e, $1f, $00, $00, $00, $00, $00, $00, $00,
    $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $2a, $2b, $2c, $2d, $2e, $2f, $30, $00, $00, $00, $00, $00, $00, $00,
    $00, $31, $32, $33, $34, $35, $36, $37, $38, $39, $3a, $3b, $3c, $3d, $3e, $3f, $40, $41, $42, $43, $00, $00, $00, $00,
    $00, $00, $00, $00, $0f, $10, $44, $45, $46, $47, $48, $49, $4a, $4b, $4c, $4d, $4e, $4f, $50, $51, $00, $00, $00, $00,
    $00, $00, $00, $00, $52, $53, $54, $55, $56, $57, $58, $59, $5a, $5b, $5c, $5d, $5e, $5f, $60, $61, $62, $00, $00, $00,
    $00, $00, $00, $00, $00, $63, $64, $65, $66, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,

    $00, $00, $00, $00, $00, $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $00, $00, $00, $00, $00, $00, $00,
    $00, $0c, $0d, $0e, $0f, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $1a, $1b, $00, $00, $00, $00, $00, $00, $00,
    $1c, $1d, $1e, $1f, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $2a, $2b, $2c, $00, $00, $00, $00, $00, $00, $00,
    $2d, $2e, $2f, $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $3a, $3b, $3c, $3d, $0a, $3e, $3f, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $0c, $40, $41, $42, $43, $44, $45, $46, $47, $48, $49, $4a, $4b, $4c, $4d, $00, $00, $00, $00,
    $00, $00, $00, $00, $4e, $4f, $50, $51, $52, $53, $54, $55, $56, $57, $58, $59, $5a, $5b, $5c, $5d, $5e, $00, $00, $00,
    $00, $00, $00, $00, $00, $5f, $60, $61, $62, $63, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,

    $00, $00, $00, $00, $00, $00, $01, $02, $00, $03, $04, $05, $06, $07, $08, $09, $0a, $00, $00, $00, $00, $00, $00, $00,
    $00, $0b, $0c, $0d, $0e, $0f, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $1a, $00, $00, $00, $00, $00, $00, $00,
    $1b, $1c, $1d, $1e, $1f, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $2a, $2b, $00, $00, $00, $00, $00, $00, $00,
    $2c, $2d, $2e, $2f, $30, $31, $32, $07, $33, $34, $35, $36, $37, $38, $39, $3a, $3b, $09, $3c, $3d, $00, $00, $00, $00,
    $00, $00, $3e, $3f, $00, $0b, $40, $41, $42, $43, $44, $45, $46, $47, $48, $49, $4a, $4b, $4c, $4d, $00, $00, $00, $00,
    $00, $00, $00, $00, $4e, $4f, $50, $51, $52, $53, $54, $55, $56, $57, $58, $59, $5a, $5b, $5c, $5d, $5e, $00, $00, $00,
    $00, $00, $00, $00, $00, $5f, $60, $61, $62, $63, $64, $00, $65, $66, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,

    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $00, $02, $03, $04, $00, $00, $00, $00, $00, $00, $00,
    $00, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f, $10, $11, $12, $13, $14, $00, $00, $00, $00, $00, $00, $00,
    $15, $16, $17, $18, $19, $1a, $1b, $1c, $1d, $1e, $1f, $20, $21, $22, $23, $24, $25, $00, $00, $00, $00, $00, $00, $00,
    $26, $27, $28, $29, $2a, $2b, $2c, $00, $2d, $2e, $2f, $30, $31, $32, $33, $34, $35, $03, $04, $00, $00, $00, $00, $00,
    $00, $36, $37, $38, $39, $05, $3a, $3b, $3c, $3d, $3e, $3f, $40, $41, $42, $43, $44, $45, $46, $47, $00, $00, $00, $00,
    $00, $00, $00, $00, $15, $16, $48, $49, $4a, $4b, $4c, $4d, $4e, $4f, $50, $51, $52, $53, $54, $55, $56, $00, $00, $00,
    $00, $00, $00, $00, $57, $58, $59, $5a, $5b, $5c, $5d, $5e, $5f, $60, $61, $62, $63, $36, $64, $65, $00, $00, $00, $00
    );


timeover_yn: array [0..191] of byte = (
    $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01,
    $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01,
    $82, $83, $84, $85, $86, $07, $88, $09, $8a, $8b, $8c, $8d, $8e, $8f, $90, $91, $92, $93, $94, $15, $00, $01, $00, $01,
    $82, $83, $84, $85, $86, $87, $88, $89, $8a, $8b, $8c, $8d, $8e, $8f, $90, $91, $92, $93, $94, $95, $00, $01, $00, $01,
    $96, $97, $98, $99, $9a, $9b, $9c, $9d, $9e, $9f, $a0, $a1, $a2, $a3, $a4, $a5, $a6, $a7, $a8, $a9, $00, $01, $00, $01,
    $16, $97, $98, $99, $9a, $9b, $9c, $9d, $9e, $9f, $a0, $a1, $a2, $a3, $a4, $a5, $a6, $a7, $a8, $a9, $00, $01, $00, $01,
    $2a, $ab, $ac, $ad, $ae, $af, $b0, $b1, $b2, $b3, $b4, $b5, $b6, $b7, $b8, $b9, $ba, $bb, $bc, $bd, $00, $01, $00, $01,
    $2a, $2b, $2c, $2d, $2e, $2f, $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $3a, $3b, $3c, $3d, $00, $01, $00, $01
    );


timeover: array [0..671] of byte = (
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $81, $82, $83, $84, $85, $86, $87, $88, $89, $8a, $8b, $8c, $8d, $8e, $8f, $90, $91, $92, $93, $94, $00, $00, $00, $00,
    $95, $96, $97, $98, $99, $9a, $9b, $9c, $9d, $9e, $9f, $a0, $a1, $a2, $a3, $a4, $a5, $9f, $a6, $a7, $00, $00, $00, $00,
    $00, $a8, $a9, $aa, $ab, $ac, $ad, $a1, $ae, $af, $9f, $b0, $b1, $b2, $b3, $b4, $b5, $b6, $b7, $b8, $00, $00, $00, $00,
    $00, $b9, $ba, $bb, $bc, $bd, $be, $bf, $c0, $c1, $c2, $c3, $c4, $c5, $c6, $c7, $c8, $c9, $ca, $cb, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,

    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $81, $82, $83, $84, $85, $86, $87, $88, $89, $8a, $8b, $8c, $8d, $8e, $8f, $90, $91, $8f, $84, $92, $00, $00, $00, $00,
    $93, $94, $95, $96, $97, $98, $99, $9a, $9b, $9c, $9d, $9e, $9f, $a0, $a1, $a2, $a3, $a4, $a5, $a6, $00, $00, $00, $00,
    $00, $a7, $a8, $a9, $aa, $ab, $ac, $ad, $ae, $af, $a4, $b0, $b1, $b2, $b3, $b4, $b5, $b6, $b7, $b8, $00, $00, $00, $00,
    $00, $b9, $ba, $bb, $bc, $bd, $be, $bf, $c0, $c1, $c2, $c3, $c4, $c5, $c6, $c7, $c8, $c9, $ca, $cb, $00, $00, $00, $00,
    $00, $cc, $cd, $ce, $cd, $cf, $80, $d0, $ce, $80, $d0, $ce, $d1, $cc, $d1, $d2, $d3, $ce, $cc, $d1, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,

    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $81, $82, $83, $84, $85, $80, $86, $80, $81, $85, $87, $88, $89, $85, $8a, $8b, $84, $8a, $84, $80, $00, $00, $00, $00,
    $8c, $8d, $8e, $8f, $90, $91, $92, $93, $94, $95, $96, $97, $98, $99, $9a, $9b, $9c, $9d, $9e, $9f, $00, $00, $00, $00,
    $a0, $a1, $a2, $a3, $a4, $a5, $a6, $a7, $a8, $a9, $aa, $ab, $ac, $ad, $ae, $af, $b0, $b1, $b2, $b3, $00, $00, $00, $00,
    $00, $b4, $b5, $b6, $b7, $b8, $b9, $ba, $bb, $bc, $bd, $be, $bf, $c0, $c1, $c2, $c3, $c4, $c5, $c6, $00, $00, $00, $00,
    $00, $c7, $c8, $c9, $ca, $cb, $cc, $cd, $c9, $ce, $cf, $d0, $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d1, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,

    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $80, $81, $82, $80, $80, $80, $82, $80, $80, $80, $80, $82, $83, $80, $80, $80, $80, $80, $80, $80, $00, $00, $00, $00,
    $84, $85, $86, $87, $88, $89, $8a, $8b, $8c, $8d, $8e, $8f, $90, $91, $92, $93, $94, $95, $96, $97, $00, $00, $00, $00,
    $98, $99, $9a, $9b, $9c, $9d, $9e, $9f, $a0, $a1, $a2, $a3, $a4, $a5, $a6, $a7, $a8, $a9, $aa, $ab, $00, $00, $00, $00,
    $00, $ac, $ad, $ae, $af, $b0, $b1, $a4, $b2, $b3, $a2, $b4, $b5, $b6, $b7, $b8, $b9, $ba, $bb, $bc, $00, $00, $00, $00,
    $80, $bd, $be, $bf, $c0, $c1, $c2, $c3, $c4, $c5, $c6, $c7, $c8, $c9, $ca, $cb, $cc, $cd, $ce, $cf, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    );


// game over
tryagain: array [0..191] of byte = (
    $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01,
    $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01,
    $46, $c7, $c8, $c9, $ca, $cb, $cc, $cd, $ce, $cf, $d0, $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $00, $01, $00, $01,
    $46, $c7, $c8, $c9, $ca, $cb, $4c, $cd, $ce, $cf, $d0, $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $00, $01, $00, $01,
    $00, $01, $00, $01, $5a, $5b, $5c, $5d, $5e, $5f, $00, $01, $60, $61, $62, $63, $64, $65, $00, $01, $00, $01, $00, $01,
    $00, $01, $00, $01, $5a, $5b, $5c, $5d, $5e, $5f, $00, $01, $60, $61, $62, $63, $64, $65, $00, $01, $00, $01, $00, $01,
    $00, $01, $00, $01, $66, $67, $68, $69, $6a, $6b, $00, $01, $6c, $6d, $6e, $6f, $70, $71, $00, $01, $00, $01, $00, $01,
    $00, $01, $00, $01, $66, $67, $68, $69, $6a, $6b, $00, $01, $6c, $6d, $6e, $6f, $70, $71, $00, $01, $00, $01, $00, $01
    );


// time over
tryagain2: array [0..191] of byte = (
    $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01,
    $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01,
    $3e, $bf, $c0, $c1, $c2, $c3, $c4, $c5, $c6, $c7, $c8, $c9, $ca, $cb, $cc, $cd, $ce, $cf, $d0, $d1, $00, $01, $00, $01,
    $3e, $bf, $c0, $c1, $c2, $c3, $44, $c5, $c6, $c7, $c8, $c9, $ca, $cb, $cc, $cd, $ce, $cf, $d0, $d1, $00, $01, $00, $01,
    $00, $01, $00, $01, $52, $53, $54, $55, $56, $57, $00, $01, $58, $59, $5a, $5b, $5c, $5d, $00, $01, $00, $01, $00, $01,
    $00, $01, $00, $01, $52, $53, $54, $55, $56, $57, $00, $01, $58, $59, $5a, $5b, $5c, $5d, $00, $01, $00, $01, $00, $01,
    $00, $01, $00, $01, $5e, $5f, $60, $61, $62, $63, $00, $01, $64, $65, $66, $67, $68, $69, $00, $01, $00, $01, $00, $01,
    $00, $01, $00, $01, $5e, $5f, $60, $61, $62, $63, $00, $01, $64, $65, $66, $67, $68, $69, $00, $01, $00, $01, $00, $01
    );


monster0	: array [0..143] of byte =
	(
	$0E,$D7,$8F,$4F,$0B,$2F,$26,$00,$10,$0A,$00,$15,$14,$0D,$2C,$2C,$1C,$54,$20,$44,$00,$00,$40,$FE,
	$0E,$D7,$8F,$4B,$0B,$2B,$26,$00,$10,$0A,$00,$15,$14,$0C,$2C,$2D,$1C,$54,$20,$44,$00,$00,$40,$FE,
	$0E,$D7,$89,$49,$09,$2B,$26,$00,$11,$0B,$01,$11,$14,$0C,$2C,$2C,$1D,$54,$20,$44,$00,$00,$40,$FE,

	$4E,$57,$6F,$4F,$6B,$4F,$66,$E0,$51,$5A,$F0,$53,$03,$51,$55,$F4,$76,$65,$40,$04,$00,$00,$00,$81,
	$4E,$57,$6F,$4B,$6B,$4B,$66,$E0,$51,$5A,$F0,$53,$03,$01,$05,$54,$56,$F5,$70,$64,$40,$00,$00,$81,
	$4E,$57,$69,$49,$49,$6B,$E6,$50,$59,$F2,$50,$13,$03,$41,$05,$04,$56,$55,$F0,$74,$60,$40,$00,$81
	);

monster1	: array [0..143] of byte =
	(
	$E0,$32,$18,$0A,$08,$42,$2A,$23,$05,$08,$80,$17,$2B,$17,$0F,$20,$07,$0B,$13,$07,$00,$00,$00,$E8,
	$E0,$32,$18,$0A,$08,$82,$8A,$43,$45,$08,$80,$17,$28,$11,$27,$01,$27,$01,$20,$01,$0B,$00,$00,$E8,
	$E0,$32,$18,$0A,$08,$82,$8A,$83,$45,$08,$80,$17,$28,$11,$4F,$01,$5F,$0F,$41,$00,$1B,$00,$00,$E8,

	$3E,$7E,$86,$03,$03,$13,$8B,$8B,$82,$C4,$7A,$76,$A7,$E3,$F5,$73,$60,$E0,$C0,$80,$00,$00,$00,$00,
	$3E,$7E,$86,$03,$03,$23,$A3,$93,$92,$C4,$7A,$76,$A7,$63,$B5,$23,$B0,$20,$20,$C0,$80,$00,$00,$00,
	$3E,$7E,$86,$03,$03,$23,$A3,$A3,$92,$C4,$7A,$76,$A7,$63,$D5,$13,$D0,$90,$10,$E0,$80,$00,$00,$00
	);

monster2	: array [0..143] of byte =
	(
	$0F,$47,$23,$51,$59,$04,$22,$14,$01,$2A,$19,$2A,$1A,$08,$02,$05,$02,$01,$00,$00,$00,$00,$00,$4C,
	$0F,$47,$2B,$51,$59,$04,$22,$14,$01,$2A,$18,$2A,$1A,$08,$02,$05,$02,$01,$00,$00,$00,$00,$00,$4C,
	$0F,$47,$2B,$51,$59,$04,$22,$14,$01,$2A,$18,$2A,$1A,$08,$02,$05,$02,$01,$00,$00,$00,$00,$00,$4C,

	$46,$54,$48,$51,$E3,$A4,$A8,$E5,$70,$FA,$19,$0B,$49,$EA,$0C,$1C,$78,$70,$E0,$00,$00,$00,$00,$00,
	$46,$54,$4A,$51,$E3,$A4,$A8,$E5,$10,$0A,$09,$0B,$69,$EA,$6C,$24,$31,$5E,$EC,$43,$00,$00,$00,$00,
	$46,$54,$4A,$51,$E3,$A4,$A8,$E5,$10,$0A,$09,$0B,$69,$EA,$6C,$34,$10,$58,$EF,$44,$02,$00,$00,$00
	);


var
	playfield: array [0..127] of byte absolute $0680;

	missile: array [0..255] of byte absolute PMB_PAGE+$300;

	gmSpeed: array [0..1] of byte = (max_speed - 20, max_speed shr 2);

	hiscore: cardinal = 500;

	gameMode: TGameMode = gmEndless;

	rnd: byte absolute $d20a;

	vsc, cntRow, scroll, cntFound, xSel, ySel, found,
	joyDelay, joy, yOld, yShift, tick, match, frame_cnt,
	minute, left_edge, right_edge, SpeedInc, second, second_,
	level, speed, speed_cnt, combo_cnt, monster0_frm, monster1_frm, monster2_frm:  byte;

	ScrollFreeze: word;

	score, score_, hiscore_: cardinal;

	vram: ^word;

	old_vbl, old_dli, old_irq: pointer;

	jump: array [0..5] of Boolean;

	FoundThree, ScrollUp, Combo, ShiftKey, monster_score,
	stop, fireDelay, fireBtn, msx_play, match_play, move_play, swap_play, msx_faster: Boolean;

	msx: TLZSSPlay;

	SwapTiles: record
			stage,
			index,
			tile0,
			tile1: byte;
			p: PByte;
		   end;


{$i printTime.inc}
{$i printSpeed.inc}
{$i printScore.inc}
{$i printHiScore.inc}

{$i monsters.inc}

procedure panelUpdate;
var p: PByte register;
    j: byte;

const
	ch0 = (bkg_panel and $7f) + 2;
	ch1 = (bkg_panel and $7f) + 3;
begin


 p:=pointer(vram^ + 29);

 for j:=3 downto 0 do begin

   p[0] := ch1 xor $80;
   p[width] := bkg_panel+1;
   p[width*2] := bkg_panel+1;
   p[width*3] := bkg_panel+1;	inc(p, width*4);
   p[0] := ch0 xor $80;
   p[width] := bkg_panel;
   p[width*2] := bkg_panel;
   p[width*3] := bkg_panel;	inc(p, width*4);

 end;


 poke(CHARSET_RAM_ADDRESS + ch0*8 + vsc, $00);
 poke(CHARSET_RAM_ADDRESS + $400 + ch0*8 + vsc, $00);

 poke(CHARSET_RAM_ADDRESS + ch1*8 + vsc, $ff);
 poke(CHARSET_RAM_ADDRESS + $400 + ch1*8 + vsc, $ff);

 if vsc = 0 then begin

   poke(CHARSET_RAM_ADDRESS + ch0*8+1, $ff);
   poke(CHARSET_RAM_ADDRESS + ch0*8+2, $ff);
   poke(CHARSET_RAM_ADDRESS + ch0*8+3, $ff);
   poke(CHARSET_RAM_ADDRESS + ch0*8+4, $ff);
   poke(CHARSET_RAM_ADDRESS + ch0*8+5, $ff);
   poke(CHARSET_RAM_ADDRESS + ch0*8+6, $ff);
   poke(CHARSET_RAM_ADDRESS + ch0*8+7, $ff);

   poke(CHARSET_RAM_ADDRESS + $400 + ch0*8+1, $ff);
   poke(CHARSET_RAM_ADDRESS + $400 + ch0*8+2, $ff);
   poke(CHARSET_RAM_ADDRESS + $400 + ch0*8+3, $ff);
   poke(CHARSET_RAM_ADDRESS + $400 + ch0*8+4, $ff);
   poke(CHARSET_RAM_ADDRESS + $400 + ch0*8+5, $ff);
   poke(CHARSET_RAM_ADDRESS + $400 + ch0*8+6, $ff);
   poke(CHARSET_RAM_ADDRESS + $400 + ch0*8+7, $ff);

   poke(CHARSET_RAM_ADDRESS + ch1*8+1, $00);
   poke(CHARSET_RAM_ADDRESS + ch1*8+2, $00);
   poke(CHARSET_RAM_ADDRESS + ch1*8+3, $00);
   poke(CHARSET_RAM_ADDRESS + ch1*8+4, $00);
   poke(CHARSET_RAM_ADDRESS + ch1*8+5, $00);
   poke(CHARSET_RAM_ADDRESS + ch1*8+6, $00);
   poke(CHARSET_RAM_ADDRESS + ch1*8+7, $00);

   poke(CHARSET_RAM_ADDRESS + $400 + ch1*8+1, $00);
   poke(CHARSET_RAM_ADDRESS + $400 + ch1*8+2, $00);
   poke(CHARSET_RAM_ADDRESS + $400 + ch1*8+3, $00);
   poke(CHARSET_RAM_ADDRESS + $400 + ch1*8+4, $00);
   poke(CHARSET_RAM_ADDRESS + $400 + ch1*8+5, $00);
   poke(CHARSET_RAM_ADDRESS + $400 + ch1*8+6, $00);
   poke(CHARSET_RAM_ADDRESS + $400 + ch1*8+7, $00);

 end;

end;


procedure timeUpdate;
begin

 if (stop = false) and (scroll = 0) then

 if gameMode = gmTimeTrial then begin

  dec(second);
  if second = $ff then begin
   second := 59;
   dec(minute)
  end;

 end else begin

  inc(second);
  if second > 59 then begin
   second:=0;
   inc(minute);
  end;

 end;

end;


procedure IRQ; interrupt; assembler;
asm
	sta rA

	lda pmc: pm_color

	sta color3

	inc pmc


	lda #0			; reuse IRQ
	sta irqen
	lda #4
	sta irqen


	lda rA: #0
end;


procedure PlaySAP; assembler; keep;
asm
	lda MSX
	ldy MSX+1
	jsr SAPLZSS.TLZSSPLAY.Decode

	lda MSX
	ldy MSX+1
	jmp SAPLZSS.TLZSSPLAY.Play
end;


procedure NMI; interrupt; assembler;
asm
	bit nmist
	bpl vbl

	jmp (vdslst)

vbl	sta stimer		; restart IRQ

	sta rA
	stx rX
	sty rY

	sta nmist

; ---

	lda #0
	sta IRQ.pmc

; ---

; -----------------------
; play msx
; ----------------------

@	lda msx_play
	beq @+

	lda MSX
	ldy MSX+1
	jsr SAPLZSS.TLZSSPLAY.Decode

	lda MSX
	ldy MSX+1
	jsr SAPLZSS.TLZSSPLAY.Play

; -----------------------
; sfx match
; ----------------------

@	ldy match_play
	beq @+

	lda sfx_match_audf: $1000,y
	sta audf1
	iny
	lda sfx_match_audc: $1000,y
	sta audc1
	iny
	sty match_play

	cpy #18+1
	bne @+

	lda #0
	sta match_play

; -----------------------
; sfx move
; ----------------------

@	ldy move_play
	beq @+

	lda adr.sfmove,y
	sta audf2
	iny
	lda adr.sfmove,y
	sta audc2
	iny
	sty move_play

	cpy #18+1
	bne @+

	lda #0
	sta move_play

; -----------------------
; sfx swap
; ----------------------

@	ldy swap_play
	beq @+

	lda adr.sfswap,y
	sta audf3
	iny
	lda adr.sfswap,y
	sta audc3
	iny
	sty swap_play

	cpy #18+1
	bne @+

	lda #0
	sta swap_play

; ----------------------

@	inc rtclok+2

	mva sdmctl dmactl

	mwa SDLSTL dlptr

	:5 mva 708+# $d016+#

	lda >CHARSET_RAM_ADDRESS
.def	:JGPFirstCharset = *-1
	sta JGPCharset

;	lda #$48
;	sta color1
;	lda #$8c
;	sta color2

	lda #128-29
	sta dliCnt		; unit JPG2 ; procedure JGPDLI

	lda rtclok+2
	and #8

	sta atract

	:3 lsr @
	pha
	add left_edge
	sta hposm0

	pla
	eor #$ff
	adc right_edge
	sta hposm3

	lda ScrollFreeze
	ora ScrollFreeze+1
	bne @+

	:2 inc speed_cnt
@
	dec tic
	bpl toExit

	mva #49 tic

	jsr timeUpdate

toExit

	lda rA: #0
	ldx rX: #0
	ldy rY: #0

	rti

tic	dta 49

end;


function TilesFallDown: Boolean;
var k: byte;
begin

 Result:=false;

 for k:=15*6-1 downto 0 do
  if playfield[k] <> 0 then
   if playfield[k+6] = 0 then begin
    playfield[k+6] := playfield[k];
    playfield[k] := 0;

    Result:=true;

    if move_play = false then move_play := true;

   end;

end;


function onInvers(a: byte): byte; inline;
begin

 if (a=0) or (a=5) {or (a=17)} then	// blok z wykrzyknikiem w inwersie
  Result := $80 + 2			// przesuniecie +2 ze wzgledu na pierwszy 2 bajtowy Tiles reprezentujacy puste pole
 else
  Result := 2;

end;


function TileCode(a: byte): byte;
var inv: byte;
begin

 if a <> 0 then begin

  dec(a);

  inv := onInvers(a);

  a:=a shl 2 + inv;

 end;

 Result:=a;

end;


procedure DrawVerticalJumpTiles(x, c: byte);
var i, a, inv, k: byte;
    p: PByte absolute $e0;
begin

  p:=pointer(vram^ + x shl 2 + 4);

  if cntRow <> 0 then dec(p, width);

  k:=x;

  for i:=14 downto 0 do begin

   a := playfield[k];

   if a >= 1 then
   if a < 7 then begin

    dec(a);

    inv := onInvers(a);

    if c and 15 >= 8 then inc(a, 6);

    a:=a shl 2+inv;

    p[0]:=a;
    p[width]:=a;

    inc(a);

    p[1]:=a;
    p[width+1]:=a;

    inc(a);

    p[2]:=a;
    p[width+2]:=a;

    inc(a);

    p[3]:=a;
    p[width+3]:=a;

   end;

   inc(p, width*2);

   inc(k, 6);

  end;

end;


procedure DrawHorizontalTiles(p: PByte; k: byte); register;
var i, a, inv: byte;
begin

  for i:=5 downto 0 do begin

   a := playfield[k];

//   if a = 128+6 then a:=0;


   if a = 0 then begin		// Tile 0, puste pole

    p[0]:=0;
    p[1]:=0;
    p[2]:=0;
    p[3]:=0;

    p[width]:=0;
    p[width+1]:=0;
    p[width+2]:=0;
    p[width+3]:=0;

   end else begin

    dec(a);

    if a>=128 then a:=a and $7f + 12;

    inv := onInvers(a);

    a:=a shl 2 + inv;


    if a = 70 then begin	// tile ATARI trafiony

    p[0]:=a;
    p[width]:=a or $80;

    inc(a);

    p[1]:=a;
    p[width+1]:=a or $80;

    inc(a);

    p[2]:=a;
    p[width+2]:=a or $80;

    inc(a);

    p[3]:=a;
    p[width+3]:=a or $80;

    end else begin		// pozosta³e tilesy

    p[0]:=a;
    p[width]:=a;

    inc(a);

    p[1]:=a;
    p[width+1]:=a;

    inc(a);

    p[2]:=a;
    p[width+2]:=a;

    inc(a);

    p[3]:=a;
    p[width+3]:=a;

    end;

   end;

   inc(p, 4);			// +4

   inc(k);

  end;

end;


procedure sfx_match;
begin
   case match of
	0:
        asm
		lda <adr.match1
		sta NMI.sfx_match_audf
		sta NMI.sfx_match_audc

		lda >adr.match1
		sta NMI.sfx_match_audf+1
		sta NMI.sfx_match_audc+1
	end;

	1:
        asm
		lda <adr.match2
		sta NMI.sfx_match_audf
		sta NMI.sfx_match_audc

		lda >adr.match2
		sta NMI.sfx_match_audf+1
		sta NMI.sfx_match_audc+1
	end;

     else

        asm
		lda <adr.match3
		sta NMI.sfx_match_audf
		sta NMI.sfx_match_audc

		lda >adr.match3
		sta NMI.sfx_match_audf+1
		sta NMI.sfx_match_audc+1
	end;

   end;

   inc(match);

   match_play:=true;

end;


procedure UpdateTiles;
var p: PByte absolute $e0;
    j, k: byte;
begin

 tick:=0;

 p:=pointer(vram^ + 4);

 if cntRow <> 0 then dec(p, width);

 k:=0;

 for j:=15 downto 0 do begin

   DrawHorizontalTiles(p, k);

   inc(k, 6);
   inc(p, width*2);

 end;

end;


function FindThreeInRow: Boolean;
var i: byte;
    ok: Boolean;
    p: PByte absolute $e0;
    q: PByte absolute $e2;


procedure Horizontal(n: byte);
var a: byte;
begin

 a:=p[0] and $7f;

 if a < 7 then
  if a >= 1 then
   if a = p[1] and $7f then
    if p[1] and $7f = p[2] and $7f then begin

     p[0]:=a or 128;
     p[1]:=p[0];
     p[2]:=p[0];

     ok := true;

    end;

end;


procedure Vertical;
var a: byte;
begin

 a:=p[0] and $7f;

 if a < 7 then
  if a >= 1 then
   if a = p[6] and $7f then
    if p[6] and $7f = p[12] and $7f then begin

     p[0]:=a or 128;
     p[6]:=p[0];
     p[12]:=p[0];

     ok := true;

    end;

end;


begin

 ok := false;

 q:=playfield;

 for i:=14 downto 0 do begin

  p:=q;
		Horizontal(0);	// 0..2
  inc(p);	Horizontal(1);	// 1..3
  inc(p);	Horizontal(2);	// 2..4
  inc(p);	Horizontal(3);	// 3..5

  inc(q, 6);
 end;


 q:=playfield;

 for i:=12 downto 0 do begin

  p:=q;

  Vertical; inc(p);
  Vertical; inc(p);
  Vertical; inc(p);
  Vertical; inc(p);
  Vertical; inc(p);
  Vertical;

  inc(q, 6);
 end;


 if ok then UpdateTiles;

 Result := ok;

end;


function doScore: Boolean;
var k: byte;
begin

 Result:=false;

 if match_play then exit;

 inc(cntFound);

 if cntFound > 15 then begin

 for k:=0 to 15*6-1 do
  if playfield[k] >= 128 then begin

    playfield[k] := 0;

    cntFound:=13;

    inc(found);

    inc(score, 5);

    sfx_match;

    monster_score := true;

    printScore;

    exit;

   end;

 match:=0;

 FoundThree := false;
 cntFound := 0;

 Result:=true;

 end;


 if score > hiscore then begin

  hiscore:=score;

  printHiScore;

 end;

end;


procedure printAllScores;
begin

  printScore;

  if score > hiscore then begin
    hiscore:=score;
    printHiScore;
  end;

end;


procedure ComboScore;
var tmp: byte;
begin
  tmp:=Found shr 2+1;

  if ScrollFreeze < $FF00 then inc(ScrollFreeze, tmp*64);

  tmp:=tmp*5;
  inc(score, tmp);

  printAllScores;
end;


procedure NewRowWithRandomSet;
var i, a, a_, k: byte;
    p: PByte absolute $e0;
    tmp: array [0..5] of byte;
begin

 a_:=255;

 for i:=5 downto 0 do begin

  a:=random(6);

  if i<5 then
   while (a = a_) or (a = tmp[i+1]) do a:=random(6);

  a_:=a;

  tmp[i]:=a;

  inc(a, 19);

  k := playfield[14*6+i];

  if k=a then
   if a < 5+19 then
    inc(a)
   else
    dec(a);

  playfield[15*6+i] := a;

 end;


 if playfield[13*6] > 18 then begin
  dec(playfield[13*6+0], 18);
  dec(playfield[13*6+1], 18);
  dec(playfield[13*6+2], 18);
  dec(playfield[13*6+3], 18);
  dec(playfield[13*6+4], 18);
  dec(playfield[13*6+5], 18);
 end;


 p:=pointer(vram^ + 13*width*2 + 4);

 k:=13*6;
 DrawHorizontalTiles(p, k);

 inc(p, width*2);
 inc(k, 6);

 DrawHorizontalTiles(p, k);

// opty ?

 inc(p, 24);

 p[0] := 0;
 p[1] := bkg_panel;
 p[2] := bkg_panel;
 p[3] := bkg_panel;
 p[4] := bkg_panel;
 p[5] := bkg_panel;
 p[6] := bkg_panel;
 p[7] := bkg_panel;
 p[8] := bkg_panel;

 p[9] := 0;
 p[10] := 0;
 p[11] := 0;
 p[12] := 0;
 p[13] := 0;
 p[14] := 0;
 p[15] := 0;

 inc(p, width);

 p[0] := 0;
 p[1] := bkg_panel;
 p[2] := bkg_panel;
 p[3] := bkg_panel;
 p[4] := bkg_panel;
 p[5] := bkg_panel;
 p[6] := bkg_panel;
 p[7] := bkg_panel;
 p[8] := bkg_panel;

 p[9] := 0;
 p[10] := 0;
 p[11] := 0;
 p[12] := 0;
 p[13] := 0;
 p[14] := 0;
 p[15] := 0;

end;


procedure MoveUpPlayfield; assembler;
asm
	ldy #0
@:	lda adr.playfield+6,y
	sta adr.playfield,y
	iny
	cpy #15*6
	bne @-
end;


procedure SwitchCharset; assembler;
asm
	lda JGPFirstCharset
	eor #4
	sta JGPFirstCharset
	sta JGPCharset
end;


procedure SelectBox;
var a: byte;
begin

	fillchar(missile[yOld], 17, 0);

	a := ysel shl 4 + 24;

	if scroll = 0 then dec(a, yShift);

	yOld:=a;

	missile[a]:=$99;
	missile[a+1]:=$ff;
	missile[a+2]:=$ff;
	missile[a+3]:=$66;

	missile[a+4]:=$42;
	missile[a+5]:=$42;
	missile[a+6]:=$42;
	missile[a+7]:=$42;
	missile[a+8]:=$42;
	missile[a+9]:=$42;
	missile[a+10]:=$42;
	missile[a+11]:=$42;
	missile[a+12]:=$42;

	missile[a+13]:=$66;
	missile[a+14]:=$ff;
	missile[a+15]:=$ff;
	missile[a+16]:=$99;

	a:=xsel shl 4 + 48+16;

//	hposm0:=a;
	left_edge:=a;

	hposm1:=a+15;
	hposm2:=a+16;
//	hposm3:=a+31;

	right_edge:=a+32;

end;


procedure onScroll;
begin

	panelUpdate;

	ScrollUp:=false;

	vsc:=(vsc+1) and 7;

	vscrol := vsc;

	if vsc = 0 then begin

		inc(vram^, width);

		SwitchCharset;

		cntRow := cntRow xor 1;

		if cntRow = 0 then begin


			if vram^ > word(savmsc + 16 * width) then begin

			 savmsc:=savmsc xor (VIDEO_RAM_ADDRESS_A xor VIDEO_RAM_ADDRESS_B);

			 move(pointer(vram^), pointer(savmsc+2*width), 32 * width);

			 vram^:=savmsc + width * 2;

			end;


			//poke($d01a, $0f);

			if scroll > 0 then dec(scroll);

			MoveUpPlayfield;

			NewRowWithRandomSet;

			//poke($d01a, $0);

			ShiftKey:=false;

		end;

	end;

	if scroll = 0 then begin

	 inc(yShift);

	 if yShift>15 then begin
	  if ySel >= 1 then dec(ySel);
	  yShift:=0;
	 end;

	end else
	 yShift:=vsc;

	SelectBox;

end;


procedure SwapTilesOn;
var i, a, b, y: byte;
begin
	i:=ySel+1;

	if yShift > 7 then dec(i);

	y:=i shl 1;

	i:=(i shl 2) + (i shl 1) + xSel;	// i*6+xSel

	a := playfield[i];
	b := playfield[i+1];

	if a < 7 then
	 if b < 7 then
	  if a or b <> 0 then begin
	   SwapTiles.index:=i;
	   SwapTiles.stage:=4;

	   SwapTiles.tile0 := TileCode(a);
	   SwapTiles.tile1 := TileCode(b);

	   SwapTiles.p := pointer(vram^ + y * width  + xSel shl 2 + 4);

	  end;

end;


procedure ClearTile(p: PByte);
begin
	p[0]:=0;
	p[1]:=0;
	p[2]:=0;
	p[3]:=0;

	p[width]:=0;
	p[width+1]:=0;
	p[width+2]:=0;
	p[width+3]:=0;
end;


procedure DrawTile(p: PByte; c: byte); register;
begin

if c >= 1 then begin
	p[0]:=c;
	p[width]:=c;

	inc(c);

	p[1]:=c;
	p[width+1]:=c;

	inc(c);

	p[2]:=c;
	p[width+2]:=c;

	inc(c);

	p[3]:=c;
	p[width+3]:=c;
end;

end;


procedure onSwap;
var p: PByte absolute $e0;
    a,b: byte;
begin

 p := SwapTiles.p;

 if cntRow <> 0 then dec(p , width);

 ClearTile(p);

 inc(p,4);
 ClearTile(p);

 case SwapTiles.stage of
  4: begin
	dec(p);
	DrawTile(p, SwapTiles.Tile1);
	dec(p,2);
	DrawTile(p, SwapTiles.Tile0);

	swap_play:=true;
     end;

  3: begin
	dec(p,2);
	DrawTile(p, SwapTiles.Tile1);
	//dec(p,2);
	DrawTile(p, SwapTiles.Tile0);
     end;

  2: begin
	dec(p,2);
	DrawTile(p, SwapTiles.Tile0);
   end;

  1: begin
	DrawTile(p, SwapTiles.Tile0);
	dec(p, 4);
	DrawTile(p, SwapTiles.Tile1);

	a:=playfield[SwapTiles.index];
	b:=playfield[SwapTiles.index+1];

	playfield[SwapTiles.index]   := b;
	playfield[SwapTiles.index+1] := a;

	UpdateTiles;

	while TilesFallDown do begin pause; UpdateTiles; end;

     end;

 end;

 dec(SwapTiles.stage);

end;


procedure WarningJumps;
var i: byte;
    faster: Boolean;
begin

 for i:=0 to 5 do begin			// testuje kolumny 0..5

  if playfield[2*6+i] <> 0 then

   jump[i]:=true			// kolumna I skacze

  else begin

   if jump[i] then begin
    jump[i]:=false;			// wylacz kolumne I ze skakania

    DrawVerticalJumpTiles(i, 0);
   end;

  end;

 end;


 faster := false;

 for i:=0 to 5 do
  if jump[i] then begin
   faster:=true;
   DrawVerticalJumpTiles(i, tick);
  end;


 if msx_faster <> faster then begin

 if faster then
  GetResourceHandle(msx.modul, 'sapr_critical')
 else
  GetResourceHandle(msx.modul, 'sapr_yoshi');

  msx.init($10);

 end;


 msx_faster := faster;

end;


procedure ClearGTIA;
var p: PByte register;
    i: byte;
begin

 p:=@hposp0;

 for i:=0 to $1e do
  p[i] := ord(i = $1a) * 2;

end;


procedure doInitPMG;
var ptr: pointer;
begin

  ClearGTIA;
//  fillchar(pointer(PMB_PAGE+$300), 256*5, 0);

  GetResourceHandle(ptr, 't_pm0');

  unZX5(ptr, pointer(pmb_page+$300));		// PANEL

  pmbase:=hi(pmb_page);

  gractl:=3;
  prior:=1;// + $10;

  colpm0:=$0f;
  colpm1:=$0f;
  colpm2:=$0f;
  colpm3:=$0f;

  hposp0:=160+4;
  hposp1:=168+4;
  hposp2:=176+4;
  hposp3:=184+4;

end;


procedure resetCharset(a: byte);
begin

 pause;

 asm
	lda a
	sta JGPEor

	lda >CHARSET_RAM_ADDRESS
	sta JGPFirstCharset
	sta JGPCharset
 end;

end;


procedure doInitGame;
var i: byte;
    p, ptr: pointer;
begin

 doInitPMG;

 randomize;

 savmsc:=VIDEO_RAM_ADDRESS_A;

 vram^:=VIDEO_RAM_ADDRESS_A;

 p:=pointer(VIDEO_RAM_ADDRESS_A);
 fillchar(p,  4096, 0);

 inc(p, 28);

 for i:=0 to 30 do begin
  move(vpanel, p , 15);

  inc(p, width);
 end;

 p:=pointer(VIDEO_RAM_ADDRESS_B);
 fillchar(p, 4096, 0);

 inc(p, 28);

 for i:=0 to 30 do begin
  move(vpanel, p , 15);

  inc(p, width);
 end;


 GetResourceHandle(ptr, 'f_id0');
 unZX5(ptr, pointer(CHARSET_RAM_ADDRESS));


 fillchar(playfield, sizeof(playfield), 0);

 color0:=$24;
 color1:=$18;
 color2:=$7c;
 color3:=$46;

 color4:=bkg_color;

 xsel:=2;
 ysel:=6;

 SelectBox;

 scroll:=7+1;		// initial scroll for all blocks

 sizem:=0;

 vsc:=0;
 cntRow:=0;
 tick:=0;

 Found:=0;
 score:=0;
 score_:=0;
// hiscore:=0;
 hiscore_:=0;
 speed_cnt:=0;
 SpeedInc:=0;
 ScrollFreeze:=0;

 second:=0;

 stop:=false;

 if gameMode = gmTimeTrial then begin
 minute:=2;

//  minute:=0;
//  second:=10;

  speed:=gmSpeed[ord(gmTimeTrial)];
 end else begin
  minute:=0;
  speed:=gmSpeed[ord(gmEndless)];
 end;

 second_:=255;

 level:=1;

 timeUpdate;
 panelUpdate;

 printSpeed;
 printScore;
 printHiScore;

 sdmctl:=ord(TDMACtl(normal + missiles + players + oneline + enable));

 resetCharset(4);

 fillchar(pointer(SAPR_PLAYER+$300), $900, 0);
 GetResourceHandle(msx.modul, 'sapr_yoshi');

 msx.player:=pointer(sapr_player);

 msx.init($10);
 msx.decode;		// first use
 msx.play;		// first use

 msx_play:=true;
 msx_faster:=false;

end;


function onShiftDown: Boolean; assembler;
asm
	ldy #0

	lda skctl
	and #%1000
	sne
	iny

	sty Result
end;


Procedure JoyScan(prc: TJoyKey);
var a, onKey: byte;


procedure get_key; assembler;
asm
	lda $d20f
	and #4
	bne @exit

	lda $d209

	cmp onKey_: #0
	bne skp

	ldy delay: #6
	dey
	sty delay
	bne @exit
skp
	sta onKey
	sta onKey_

	mva #6 delay
end;


BEGIN
	fireBtn:=not Boolean(trig0);

	get_key;

	a:=porta and $0f;//joy_1;

	ShiftKey := onShiftDown;

	if Fire2 > 30 then ShiftKey:=true;


	if a = joy then begin

	  if joyDelay >= 1 then begin dec(joyDelay) ; exit end;

	  joy:=$ff;

	end else begin
	  joyDelay:=6;
	  joy:=a;
	end;


	if onKey <> 0 then begin

	 fireBtn:=false;

	 case onKey of
	  28: begin stop:=true; inc(minute) end;	// ESC		zwiekszamy MINUTE aby nie pojawil sie komunikat TIMEOUT gdy przerywamy gre time=00:00

	  47: fireBtn:=true;	// Q

	  58: a:=joy_right;	// D
	  63: a:=joy_left;	// A
	  46: a:=joy_up;	// W
	  62: a:=joy_down;	// S
	 end;

	 onKey:=0;
	end;


	prc(a);

END;


procedure joyGame(a: byte); StdCall;
begin

	if scroll>0 then exit;

	case a of
	  joy_left: if xsel >= 1 then dec(xsel);		{left}
	 joy_right: if xsel < 4 then inc(xsel);			{right}
	  joy_down: if ysel < byte(13 - cntRow) then inc(ysel);	{down}
	    joy_up: if ysel >= 1 then dec(ysel);		{up}
	end;

end;


{$i doGameOver2.inc}

{$i block_title2.inc}


begin

// GetIntVec(iVBL, old_vbl);
// GetIntVec(iDLI, old_dli);

// GetIntVec(iTIM4, old_irq);

 color4:=bkg_color;

 pause;

  asm
  sei
  lda #0
  sta nmien
  sta irqen
  sta irqen+$10
  sta irqen+$20
  sta irqen+$30

  mva #$fe portb

  mwa #NMI nmivec
  mwa #IRQ irqvec

  lda #0
  sta pm_color
  sta pm_color+1
  sta pm_color+2
  sta pm_color+3
  sta pm_color+4
  sta pm_color+5
  sta pm_color+6
  sta pm_color+7

  lda #$78
  sta pm_color+8
  sta pm_color+9
  sta pm_color+10
  sta pm_color+11
  sta pm_color+12

  lda #$56
  sta pm_color+13
  sta pm_color+14
  sta pm_color+15
  sta pm_color+16

  lda #$48
  sta pm_color+17
  sta pm_color+18
  sta pm_color+19
  sta pm_color+20

  lda #$36
  sta pm_color+21
  sta pm_color+22
  sta pm_color+23
  sta pm_color+24

  lda #$24
  sta pm_color+25
  sta pm_color+26
  sta pm_color+27
  sta pm_color+28

  lda #$16
  sta pm_color+29
  sta pm_color+30
  sta pm_color+31
  sta pm_color+32

  lda #$e6
  sta pm_color+33
  sta pm_color+34
  sta pm_color+35
  sta pm_color+36

;  lda #bkg_color
  sta pm_color+37
  sta pm_color+38

  mva #$40 nmien

 end;


 repeat

 doTitle;

 JGPInit(DISPLAY_LIST_ADDRESS, VIDEO_RAM_ADDRESS_A, 28, 1);

 vram:=pointer(DISPLAY_LIST_ADDRESS + 2);

 asm
	sei
	lda #0
	sta nmien

	;sta AUDCTL+$10

	sta SKCTL			; jedna linia nizej dzieki WSYNC i SKCTL=0
	;sta SKCTL+$10

 	lda #1				; 0=POKEY 64KHz, 1=15KHz
	sta AUDCTL
	lda #7				; ~64KHz clock 16 = ~4Khz timer, ~15KHz clock 4 = ~4KHz
	sta AUDF4			; in timer 1

	lda #$f0			; test - no polycounters + volume only
	sta AUDC4
	lda #4
	sta IRQEN			; enable timer 1

	sta wsync

	lda #3
	sta SKCTL			; test - reset pokey and polycounters
	;sta SKCTL+$10

	sta STIMER			; start timers

	cli
 end;

 nmien := $c0;

 doInitGame;

 repeat

 	if second <> second_ then begin
	 printTime;

	 second_:=second;

	 if score <> score_ then printAllScores;

	end;


	if (match <> 0) or (monster0_frm and 3 <> 1) then begin
	  //monster_score:=false;
	  monsters(monster0, 24, monster0_frm);
	end;


	if (combo_cnt <> 0 ) or (monster1_frm and 3 <> 1) then monsters(monster1, 120, monster1_frm);


	if swap_play or (monster2_frm and 3 <> 1) then monsters(monster2, 216, monster2_frm);


	pause;

	JoyScan(@joyGame);		// na poczatku ramki inaczej odczyt z PADDLE bedzie zaklocony


	if fireDelay and fireBtn then begin
	 SwapTilesOn;

	 fireDelay := false;
	end;


	if SwapTiles.stage = 0 then
	 if FoundThree = false then
	  if (scroll >= 1) or ScrollUp then onScroll;

	SelectBox;

	if SwapTiles.stage = 0 then
	  if FoundThree then begin

	   if doScore then
  	    while TilesFallDown do;

	   UpdateTiles;

	  end else
	   FoundThree := FindThreeInRow;


//	if FoundThree = false then
	if SwapTiles.stage <> 0 then
	 onSwap
	else
	if not fireBtn then
	 if not fireDelay then fireDelay := true;


	if SwapTiles.stage = 0 then WarningJumps;


	if stop = false then begin
	 stop := (playfield[0] or playfield[1] or playfield[2] or playfield[3] or playfield[4] or playfield[5] <> 0);

	 if gameMode = gmTimeTrial then stop := stop or (second + minute = 0);
	end;

	{$IFDEF DEBUG}
	if scroll = 0 then begin
	{$ELSE}
	if stop {and (cntRow = 0)} and (second_ = second) then begin		// game over
	{$ENDIF}

	  while cntRow <> 0 do begin pause; onScroll end;

	  if doGameOver then doInitGame else Break;

	end;


	if (speed_cnt >= speed) or ShiftKey then begin
	 speed_cnt := 0;
	 ScrollUp := true;
	end;

	if ScrollFreeze <> 0 then dec(ScrollFreeze);


	if (Found > 0) and (FoundThree=false) then begin

	  inc(SpeedInc, Found);

	  if Combo and (combo_cnt < 128) then begin
	   ComboScore;
	   combo_cnt:=0;
	  end else
	  if Found > 3 then begin
 	   ComboScore;
	   Combo:=true;
	  end;

	  if SpeedInc > 12 then begin
	    if speed > 0 then dec(speed);
 	    printSpeed;
	    SpeedInc:=0;
	  end;

	  Found:=0;
	end;

	if Combo then begin
	 inc(combo_cnt);
	 if combo_cnt > 128 then begin Combo:=false; combo_cnt:=0 end;
	end;

	inc(tick);

	inc(frame_cnt);

 until false;

// SetIntVec(iVBL, old_vbl);
// SetIntVec(iDLI, old_dli);

// SetIntVec(iTIM4, old_irq);

 until false;

end.

// 31136
