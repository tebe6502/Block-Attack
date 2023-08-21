
// Title Screen
// assets\title\title_select_2.asm


procedure setGameSpeed;
var a: byte;
    t: string[3];

 procedure d1;
 begin
  a := (ord(t[1]) - 48) shl 4;
  move(pmDigit[a], pointer(PMB_PAGE + $600 + 136), 16);
 end;

begin

 a := gmSpeed[ord(gameMode)];

 t := ByteToStr(max_speed - a);

 if length(t) = 2 then begin

  a := (ord(t[2]) - 48) shl 4;
  move(pmDigit[a], pointer(PMB_PAGE + $700 + 136), 16);

  d1;

  poke($d800+7, $9f);
  poke($d800+6, $99);

 end else begin

  d1;

  poke($d800+7, 0);
  poke($d800+6, $99+3);

 end;

end;


procedure setGameMode(a: byte);
begin

 gameMode := TGameMode(a);

 case a of

  0: begin
       poke($f000+12*40+6, $11);
       poke($f000+13*40+6, $2b);

       poke($d900+0*40+6, $42);
       poke($d900+1*40+6, $50);

     end;

  1: begin

       poke($f000+12*40+6, $42);
       poke($f000+13*40+6, $50);

       poke($d900+0*40+6, $11);
       poke($d900+1*40+6, $2b);

     end;

  end;

 setGameSpeed;

end;


procedure doTitle;
var ptr: pointer;
    s, y: byte;


 procedure joyMenu(a: byte); StdCall;
 begin

 	case a of
	 joy_right: if s > 1 then begin dec(s); gmSpeed[y]:=s; setGameSpeed end; 	{left}
	  joy_left: if s < 99 then begin inc(s); gmSpeed[y]:=s; setGameSpeed end;	{right}
	  joy_down: if y = 0 then begin inc(y); s:=gmSpeed[y]; setGameSpeed end;	{down}
	    joy_up: if y = 1 then begin dec(y); s:=gmSpeed[y]; setGameSpeed end;	{up}
	end;

 end;


begin

// while trig0 = 0 do;

 sdmctl:=0;
 pause;			// wymagane aby rozpakowal pod ROM ? ciekawe

 GetResourceHandle(ptr, 't_tit');
 unZX5(ptr, pointer(pmb_page));

 fillchar(pointer(SAPR_PLAYER+$300), $900, 0);
 GetResourceHandle(msx.modul, 'sapr_modul');

 msx.player:=pointer(sapr_player);

 msx.init($0);

 asm
	lda <MAIN.PlaySAP
	ldy >MAIN.PlaySAP

	jsr pmb_page
 end;

// while trig0 = 0 do;


 sdmctl:=0;
 pause;

 msx.stop($0);


 GetResourceHandle(ptr, 't_tit2');
 unZX5(ptr, pointer(pmb_page));

 asm
 	lda <MAIN.PlaySAP
	ldy >MAIN.PlaySAP

	jsr pmb_page
 end;


// --------------------------------------------------

 while trig0 = 0 do;

 y:=ord(gameMode);
 s:=gmSpeed[y];

 setGameMode(ord(gameMode));
 setGameSpeed;

 while true do begin

  pause;

  JoyScan(@joyMenu);

  if ord(gameMode) <> y then setGameMode(y);

  if fireBtn then Break;

 end;

 asm
	jsr pmb_page+3
 end;


 sdmctl:=0;
 pause;

 msx.stop($0);

end;