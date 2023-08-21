
procedure printTime;

var p: PByte absolute $e0;
    i, a, b, l: byte;
    t: TString;


 procedure printDigits;
 begin

 if l > 0  then begin
  a:=(ord(t[l])- 47) shl 3 + 96;
  dec(l);
 end else
  a:=96;

 if l>0 then  begin
  b:=(ord(t[l]) - 47) shl 3;
  dec(l);
 end else
  b:=0;

 for i:=7 downto 0 do begin
  p[0]:=digitH[a+i] or digitH[b+i];

  dec(p);
 end;

 end;


 procedure printDigits_hi(_add: byte; _and: byte);
 begin

 if l > 0  then begin
  a:=(ord(t[l])- 47) shl 3 + _add;
  dec(l);
 end else
  a:=_add;

 for i:=7 downto 0 do begin
  p[0]:=(p[0] and _and) or digitH[a+i];

  dec(p);
 end;

 end;

{
 procedure printDigits_lo;
 begin

 if l > 0  then begin
  a:=(ord(t[l])- 47) shl 3;
  dec(l);
 end else
  a:=0;

 for i:=7 downto 0 do begin
  p[0]:=(p[0] and $f0) or digitL[a+i];

  dec(p);
 end;

 end;
}

 procedure toString(a: byte);
 begin

  if a < 10 then begin
   t[0]:=chr(2);
   t[1]:='0';
   t[2]:=chr(48 + a);
  end else
   t:=BytetoStr(a);

  l:=2;

 end;


begin

 toString(second);

 p:=pointer(PMB_PAGE+$700+162+7);
 printDigits_hi(0, $0f);

 p:=pointer(PMB_PAGE+$600+162+7);
 printDigits_hi(96, $f0);

 toString(minute);

 p:=pointer(PMB_PAGE+$500+162+7);
 printDigits;

end;
