
procedure monsters(ptr: PByte; ofs: byte; var frm: byte);

var i: byte;

    src: PByte absolute $e0;
    pm1: PByte absolute $e2;
    pm2: PByte absolute $e4;

begin

 asm
  lda frame_cnt
  and #7
  jne @exit
 end;

 src:=ptr;

 case frm and 3 of
  
   1, 3: inc(src, 24);

      2: inc(src, 48);

 end;

 pm1 := pointer(pmb_page+$300+$200 + ofs);
 pm2 := pointer(pmb_page+$300+$300 + ofs);


 for i:=23 downto 0 do pm1[i] := src[i];

 inc(src, 72);

 for i:=23 downto 0 do pm2[i] := src[i];

 inc(frm);

end;

