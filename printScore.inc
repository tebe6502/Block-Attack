
procedure printScore;

var p: PByte absolute $e0;
    i, a, b, l: byte;
    t: TString;


 procedure printDigits;
 begin

 if l > 0  then begin
  a:=(ord(t[l])- 47) shl 3 + 96;
  dec(l);
 end else
  a:=8 + 96;

 if l>0 then  begin
  b:=(ord(t[l]) - 47) shl 3;
  dec(l);
 end else
  b:=8;

 for i:=7 downto 0 do begin
  p[0]:=digitH[a+i] or digitH[b+i];

  dec(p);
 end;

 end;


 procedure printDigits_lo;
 begin

 if l > 0  then begin
  a:=(ord(t[l])- 47) shl 3 + 96;
  dec(l);
 end else
  a:=8 + 96;

 for i:=7 downto 0 do begin
  p[0]:=(p[0] and $f0) or digitH[a+i];

  dec(p);
 end;

 end;


begin

 score_:=score;

 str(score, t);

 l:=length(t);

 p:=pointer(PMB_PAGE+$600+66+7);
 printDigits;

 p:=pointer(PMB_PAGE+$500+66+7);
 printDigits;

 p:=pointer(PMB_PAGE+$400+66+7);
 printDigits_lo;

end;
