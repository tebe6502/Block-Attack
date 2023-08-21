
function doGameOver: Boolean;

var p,q: pointer;
    ptr: PByte absolute $e0;
    i: byte;
    timeOut: Boolean;

const
    yPos = 35;

// bounce: array [0..15] of byte = (0,2,4,6,7,7,5,4,2,0,3,5,7,5,2,0);


 procedure setYes;
 begin
  right_edge:=82;
  left_edge:=95;
  hposm2:=88;

 end;


 procedure setNo;
 begin
  right_edge:=117;
  left_edge:=123;
  hposm2:=0;

 end;


 procedure fill(a: byte);
 var k: byte;
 begin

  for k:=15*6-1 downto 0 do
   if playfield[k] <> 0 then begin

    playfield[k]:=a;

    if k mod 6=0 then begin UpdateTiles; Pause(2) end;
   end;

  UpdateTiles;
 end;



procedure doMoveLogo(y: byte);
var i: byte;

const

 gmov: array [0..3] of word = (0, 168, 168*2, 168*3);

begin

 if timeOut then
  ptr := @timeover
 else
  ptr := @gameover;

 p:=pointer(savmsc + 4);

 asm
	lda y
	and #3
	:2 asl @
	add >CHARSET_RAM_ADDRESS

 	sta JGPFirstCharset
	sta JGPCharset
 end;

 inc(ptr, gmov[y and 3]);

 y:=y shr 2;

 inc(p, y*width);

 fillchar(p, 24, 0);		// dwa pierwsze wiersze wypelniamy #0
 inc(p, width);
 fillchar(p, 24, 0);
 inc(p, width);

 for i:=6 downto 0 do begin
 move(ptr, p, 24);
 inc(ptr, 24);
 inc(p, width);
 end;

end;



// --------------------------------------------------------------------------
// --------------------------------------------------------------------------

begin

 scroll:=0;

 msx_faster:=false;
 msx_play:=false;

 pause;

 msx.stop($10);


// nmien:=$40;

 {$IFDEF DEBUG}
 timeout:= false;		// 'true' -> 'gameTimeTrial'
 {$ELSE}
 timeOut := (second + minute = 0);
 {$ENDIF}

 hposm1:=0;
 hposm2:=0;

 right_edge:=0;
 left_edge:=0;

 fill(45 or $80);					// kasowanie klockow, gorny wiersz, dolny wiersz
 pause(2);

 fill(46 or $80);

 fill(0);						// skasowanie wszystkich klockow z pola gry


 ptr:=pointer(savmsc);

 for i:=63 downto 0 do begin
  fillchar(ptr, 28, 0);

  ptr[30]:=bkg_panel;					// wypelnienie panelu pod duchami
  ptr[31]:=bkg_panel;
  ptr[32]:=bkg_panel;
  ptr[33]:=bkg_panel;
  ptr[34]:=bkg_panel;
  ptr[35]:=bkg_panel;
  ptr[36]:=bkg_panel;

  inc(ptr, 40);
 end;

 fillchar(pointer(SAPR_PLAYER+$300), $900, 0);
 GetResourceHandle(msx.modul, 'sapr_critical');

 msx.init($10);

 pause;

 msx_play:=true;

 vram^:=savmsc + 16 * width;

 vsc:=0;
 vscrol:=1;

 panelUpdate;



 resetCharset(0);					// wylaczenie przelaczania zestawow znakow co wiersz



 if timeOut then begin
   GetResourceHandle(p, 'f_id2');			// time over

   color0:=$04;
   color1:=$0e;
   color2:=$00;

 end else begin
   GetResourceHandle(p, 'f_id1');			// game over

   color0:=$34;
   color1:=$28;
   color2:=$00;

 end;

 unZX5(p, pointer(CHARSET_RAM_ADDRESS));		// dekompresja zestawow


 panelUpdate;						// uzupelniamy znaki zestawu ktore rozpakowalismy

 prior:=8;

 sizem:=255;



 i:=6*4;

 while i < 80 do begin

	pause;

        doMoveLogo(i);		// 8

  inc(i,2);

 end;



 if timeOut then begin

  GetResourceHandle(p, 'f_id2_a');			// time over + (yes / no)
  GetResourceHandle(q, 'f_id2_b');

  unZX5(p, pointer(CHARSET_RAM_ADDRESS));
  unZX5(q, pointer(CHARSET_RAM_ADDRESS+$400));

  resetCharset(4);					// wylaczenie przelaczania zestawow znakow co wiersz

  ptr:=@timeover_yn;

  p:=pointer(savmsc+20*width + 4);

  for i:=7 downto 0 do begin
   move(ptr, p, 24);
   inc(ptr, 24);
   inc(p, width);
  end;

  ptr := @tryagain2

 end else begin

  GetResourceHandle(p, 'f_id1_a');			// game over + (yes / no)
  GetResourceHandle(q, 'f_id1_b');

  unZX5(p, pointer(CHARSET_RAM_ADDRESS));
  unZX5(q, pointer(CHARSET_RAM_ADDRESS+$400));

  resetCharset(4);					// wylaczenie przelaczania zestawow znakow co wiersz

  ptr:=@gameover_yn;

  p:=pointer(savmsc+20*width + 4);

  for i:=7 downto 0 do begin
   move(ptr, p, 24);
   inc(ptr, 24);
   inc(p, width);
  end;

  ptr := @tryagain;

 end;

 p:=pointer(savmsc+30*width + 4);

 for i:=7 downto 0 do begin
 move(ptr, p, 24);
 inc(ptr, 24);
 inc(p, width);
 end;


 fillchar(pointer(PMB_PAGE+$300), 256, $00);		// podswietlenie odpowiedzi napisow dla 'try again'

 fillchar(pointer(PMB_PAGE+$300+169), 14, 255);

 Result:=true;


 setYes;						// ustawienie odpowiedzi na 'YES'


 xsel:=1;

 while true do begin

  if not timeOut then begin
   inc(color0, $11);
   dec(color1, $11);
  end;

  pause;

  joyScan(@joyGame);

  if fireBtn then Break;

  case xsel of
   0: if not Result then begin setYes; xsel:=1; Result:=true end;
   2: if Result then begin setNo; xsel:=1; Result:=false end;
  else
   xsel:=1;
  end;

  while vcount<>70 do;

  while vcount<>78 do colpf0:=(rnd and $f0) or $04;

  colpf0:=$02;

 end;


 right_edge:=0;
 left_edge:=0;
 hposm2:=0;

 sdmctl:=0;

 ClearGTIA;


 msx_play:=false;

 pause;

 msx.stop($10);

end;
