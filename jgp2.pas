unit jgp2;

interface

procedure JGPInit(DListAddress: word; VRamAddress: word; lines: byte; blanks: byte);

type
	TJGPBlock = object

		x, y: byte;

		procedure Put(a: byte);
	end;


implementation

uses atari;


const
    DL_BLANK8 = %01110000;	// 8 blank lines
    DL_DLI = %10000000;		// Order to run DLI
    DL_LMS = %01000000;		// Order to set new memory address
    DL_VSCROLL = %00100000;	// Turn on vertical scroll on this line
    DL_HSCROLL = %00010000;	// Turn on horizontal scroll on this line
    DL_MODE = $04;
    DL_JVB = %01000001;		// Jump to begining


var	dList: PByteArray;


procedure TJGPBlock.Put(a: byte);
begin

end;


procedure JGPDLI; interrupt; assembler;
asm
	pha

	lda #0
.def	:JGPCharset = *-1

	inc dliCnt	; cycle latency

	sta chbase

	eor #4
.def	:JGPEor = *-1
	sta JGPCharset

	lda #0
.def	:dliCnt = *-1
	add cntRow

	bpl skp

	lda #6
	sta colpf1
	lda #4
	sta colpf2

skp
	pla
end;


procedure DLPoke(b: byte);
begin
    dList[0] := b;
    Inc(dList);
end;

procedure DLPokeW(w: word);
begin
    dList[0] := Lo(w);
    dList[1] := Hi(w);
    Inc(dList, 2);
end;


procedure BuildDisplayList(DListAddress: word; VRamAddress: word; lines: byte; blanks: byte);
begin

    dList := pointer(DListAddress);
    while blanks > 0 do begin
	DLPoke(DL_BLANK8 + DL_DLI);
        dec(blanks);
    end;

    lines:=lines - 1;

    DLPoke(DL_LMS + DL_MODE + DL_DLI + DL_VSCROLL);
    DLPokeW(VRamAddress);

    while (lines > 0) do begin
	DLPoke(DL_MODE + DL_DLI + DL_VSCROLL);

        dec(lines);
    end;
    DLPoke(DL_MODE);

    DLPoke(DL_JVB);
    DLPokeW(DListAddress);
end;

procedure JGPInit(DListAddress: word; VRamAddress: word; lines: byte; blanks: byte);
begin
    BuildDisplayList(DListAddress, VRamAddress, lines, blanks);
    SDLSTL := DListAddress;
    savmsc := VRamAddress;
    SetIntVec(iDLI, @JGPDli);
    nmien := $c0;
end;

end.
