// 122 znak kazdego zestawu wypelniamy wartoscia $ff

uses crt;

var f: file;

    tb: array [0..4095] of byte;

const
 ch0 = 122;

 ch2 = ch0 + 2;
 ch3 = ch0 + 3;


procedure fill(a: byte);
var i: byte;
begin

 for i:=0 to 7 do
  tb[a*1024 + ch0*8+i] := $ff;

 for i:=0 to 7 do
  tb[a*1024 + ch2*8+i] := $ff;

 tb[a*1024 + ch2*8] := $00;

 for i:=0 to 7 do
  tb[a*1024 + ch3*8+i] := $00;

 tb[a*1024 + ch3*8] := $ff;

end;



begin

 assign(f, 'game_over_anim.fnt'); reset(f, 1);
 blockread(f, tb, 4*1024);
 close(f);

 fill(0);
 fill(1);
 fill(2);
 fill(3);

 assign(f, 'game_over_anim.dat'); rewrite(f, 1);
 blockwrite(f, tb, 4*1024);
 close(f);

 writeln('Done.');

end.