
procedure printHiScore;

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

 for i:=7 downto 0 do
  p[i]:=digitH[a+i] or digitH[b+i];

 end;



 procedure printDigits_hi;
 begin

 if l > 0  then begin
  a:=(ord(t[l])- 47) shl 3;
  dec(l);
 end else
  a:=8;

 for i:=7 downto 0 do
  p[i]:=(p[i] and $0f) or digitH[i + a];

 end;


begin

 hiscore_:=hiscore;

 str(hiscore, t);

 l:=length(t);

 p:=pointer(PMB_PAGE+$700+98);
 printDigits_hi;

 p:=pointer(PMB_PAGE+$600+98);
 printDigits;

 p:=pointer(PMB_PAGE+$500+98);
 printDigits;

end;
