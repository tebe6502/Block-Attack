unit sysreq;

interface


implementation

uses crt, misc, atari;

var yes: Boolean;


initialization

 yes:=false;

 if not DetectAntic then begin writeln('ANTIC PAL is required'); yes:=true end;
 if DetectCPU > 127 then begin writeln(' 6502 CPU is required'); yes:=true end;
 if not DetectStereo then begin writeln('Second POKEY not detected'); yes:=true end;
 if trig3 <> 0 then begin writeln('Disable external cart'); yes:=true end;

 if yes then begin

   writeln;

   writeln('Press any key');

   repeat until keypressed;

   halt;

 end;


end.
