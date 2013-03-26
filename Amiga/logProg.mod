MODULE log;

FROM Arguments IMPORT
 GetArg,NumArgs;

FROM Break IMPORT
 TestBreak;

FROM Logger IMPORT
 clear,firstPos,nextPos,read,write,writeStamp;

FROM String IMPORT
 ANSICapString,Compare;

FROM Terminal IMPORT
 FormatNr,FormatS,Write,WriteLn;

PROCEDURE usage();
VAR
 arg:ARRAY [0..99] OF CHAR;
 len:INTEGER;
BEGIN
 GetArg(0,arg,len);
 IF len=0 THEN arg:="log"; END;
 FormatS("usage: %s (dump|clear|status|write|tail text)\n",arg);
END usage;

VAR
 arg:ARRAY [0..99] OF CHAR;
 ch:CHAR;
 end,i,pos,start:LONGCARD;
 len:INTEGER;
BEGIN
 IF NumArgs()=1 THEN
  GetArg(1,arg,len);
  ANSICapString(arg);
  IF Compare(arg,"DUMP")=0 THEN
   IF nextPos()>0 THEN
    FOR pos:=firstPos() TO nextPos()-1 DO Write(read(pos)); TestBreak(); END;
   END;
  ELSIF Compare(arg,"TAIL")=0 THEN
   end:=nextPos();
   IF end>0 THEN
    IF end>2000 THEN
     start:=end-2000;
    ELSE
     start:=0;
    END;
    IF start<firstPos() THEN start:=firstPos(); END;
    FOR pos:=start TO end-1 DO Write(read(pos)); TestBreak(); END;
   END;
  ELSIF Compare(arg,"CLEAR")=0 THEN
   clear();
  ELSIF Compare(arg,"STATUS")=0 THEN
   FormatNr("First=%ld",firstPos());
   FormatNr("  Next=%ld",nextPos());
   FormatNr("  Length=%ld\n",nextPos()-firstPos());
  ELSE
   usage();
  END;
 ELSIF NumArgs()=2 THEN
  GetArg(1,arg,len);
  ANSICapString(arg);
  IF Compare(arg,"WRITE")=0 THEN
   writeStamp;
   GetArg(2,arg,len);
   IF len>0 THEN
    FOR i:=0 TO len-1 DO write(arg[i]); END;
   END;
   write(12C);
  ELSE
   usage();
  END;
 ELSE
  usage()
 END;
END log.

