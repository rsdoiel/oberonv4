IMPLEMENTATION MODULE LoggerLib;

(*$
 LargeVars:=FALSE StackParms:=FALSE Volatile:=FALSE
 StackChk:=FALSE RangeChk:=FALSE OverflowChk:=FALSE
 NilChk:=FALSE CaseChk:=FALSE
*)

FROM SYSTEM IMPORT
 ADR,ADDRESS,ASSEMBLE,CAST;

FROM Arts IMPORT
 dosCmdLen;

FROM DosD IMPORT
 DateFormat,DateTime,DateTimePtr,DateTimeFlagSet;

FROM DosL IMPORT
 DateStamp,DateToStr;

FROM ExecD IMPORT
 Library,MemReqs,MemReqSet;

FROM ExecL IMPORT
 AllocAbs,AllocMem,Remove,FreeMem;

FROM String IMPORT
 Length;

IMPORT R;

CONST
 revision=4; (* Ihre Revision *)

(*
 This library is shall never be closed, once it is open.
*)
PROCEDURE LibOpen(myLib{R.A6}:LoggerBasePtr):ADDRESS;
(*$ EntryExitCode:=FALSE *)
BEGIN
  ASSEMBLE(
   MOVE.W #1,Library.openCnt(A6)
   MOVE.L A6,D0
   RTS
  END);
END LibOpen;

PROCEDURE LibClose(myLib{R.A6}:LoggerBasePtr): ADDRESS;
(*$ EntryExitCode:=FALSE *)
BEGIN
  ASSEMBLE(
   MOVEQ #0,D0
   RTS
  END);
END LibClose;

PROCEDURE LibExpunge(myLib{R.A6}:LoggerBasePtr): ADDRESS;
(*$ EntryExitCode:=FALSE *)
BEGIN
  ASSEMBLE(
   MOVEQ #0,D0
   RTS
  END);
END LibExpunge;

PROCEDURE LibExtFunc(myLib{R.A6}:LoggerBasePtr): ADDRESS;
(*$ EntryExitCode:=FALSE *)
BEGIN
 ASSEMBLE(
  MOVEQ #0,D0 (* Immer NIL *)
  RTS
 END);
END LibExtFunc;

CONST
 blockSize=100H;
 blockCount=100H;
 bufLength=blockCount*blockSize;
 bufEnd=07F80000H;

TYPE
 BlockData=ARRAY [0..blockSize-1] OF CHAR;
 Buffer=RECORD
  first:LONGCARD;
  next:LONGCARD;
  datasum:ARRAY [0..blockCount-1] OF LONGCARD;
  chksum:LONGCARD; (* sum over first, next and all block checksums. *)
  data:ARRAY [0..blockCount-1] OF BlockData;
 END;
 BufferPtr=POINTER TO Buffer;

PROCEDURE sumBlock(VAR data:BlockData):LONGCARD;
VAR
 i:[0..blockCount-1];
 sum:LONGCARD;
BEGIN
 sum:=0;
 FOR i:=0 TO blockSize-1 DO
  INC(sum,LONGCARD(data[i]));
 END;
 RETURN sum;
END sumBlock;

PROCEDURE sumBuffer(VAR buf:Buffer):LONGCARD;
VAR
 i:[0..blockCount-1];
 sum:LONGCARD;
BEGIN
 sum:=buf.first+buf.next;
 FOR i:=0 TO blockCount-1 DO
  INC(sum,buf.datasum[i]);
 END;
 RETURN sum;
END sumBuffer;

PROCEDURE sumAll(VAR buf:Buffer);
VAR
 sum:LONGCARD;
 i:[0..blockCount-1];
BEGIN
 FOR i:=0 TO blockCount-1 DO
  sum:=sumBlock(buf.data[i]);
  buf.datasum[i]:=sum;
 END;
 sum:=sumBuffer(buf);
 buf.chksum:=sum;
END sumAll;

PROCEDURE sumVerify(VAR buf:Buffer):BOOLEAN;
VAR
 sum:LONGCARD;
 i:[0..blockCount-1];
BEGIN
 FOR i:=0 TO blockCount-1 DO
  sum:=sumBlock(buf.data[i]);
  IF buf.datasum[i]#sum THEN RETURN FALSE; END;
 END;
 sum:=sumBuffer(buf);
 RETURN buf.chksum=sum;
END sumVerify;

PROCEDURE setup(VAR buf:BufferPtr; VAR first,next:LONGCARD);
BEGIN
 buf:=CAST(BufferPtr,bufEnd-SIZE(Buffer));
 first:=buf^.first;
 next:=buf^.next;
END setup;

PROCEDURE update(first,next:LONGCARD);
VAR
 buf:BufferPtr;
BEGIN
 buf:=CAST(BufferPtr,bufEnd-SIZE(Buffer));
 buf^.first:=first;
 buf^.next:=next;
END update;

PROCEDURE init;
(*$ LoadA4:=TRUE *)
VAR
 buf:BufferPtr;
 first,next:LONGCARD;
BEGIN
 setup(buf,first,next);
 IF ~sumVerify(buf^) THEN
  update(0,0);
  sumAll(buf^);
 END;
END init;

PROCEDURE clear;
(*$ LoadA4:=TRUE *)
VAR
 buf:BufferPtr;
 first,next:LONGCARD;
BEGIN
 setup(buf,first,next);
 update(0,0);
 buf^.chksum:=sumBuffer(buf^);
END clear;

PROCEDURE firstPos():LONGCARD;
(*$ LoadA4:=TRUE *)
VAR
 buf:BufferPtr;
 first,next:LONGCARD;
BEGIN
 setup(buf,first,next);
 RETURN first;
END firstPos;

PROCEDURE nextPos():LONGCARD;
(*$ LoadA4:=TRUE *)
VAR
 buf:BufferPtr;
 first,next:LONGCARD;
BEGIN
 setup(buf,first,next);
 RETURN next;
END nextPos;

PROCEDURE write(ch{R.D2}:CHAR);
(*$ LoadA4:=TRUE *)
VAR
 blk,first,next,pos:LONGCARD;
 buf:BufferPtr;
BEGIN
 setup(buf,first,next);
 IF sumBuffer(buf^)#buf^.chksum THEN
  init;
  blk:=0; pos:=0; first:=0; next:=0;
 ELSE
  pos:=next MOD bufLength;
  blk:=pos MOD blockCount;
  IF sumBlock(buf^.data[blk])#buf^.datasum[blk] THEN
   init;
   blk:=0; pos:=0; first:=0; next:=0;
  END;
 END;
 buf^.data[blk][pos DIV blockCount]:=ch;
 buf^.datasum[blk]:=sumBlock(buf^.data[blk]);
 INC(next);
 IF next-first>bufLength THEN
  INC(first);
 END;
 update(first,next);
 buf^.chksum:=sumBuffer(buf^);
END write;

PROCEDURE writeStamp;
(*$ LoadA4:=TRUE *)
VAR
 day,date,time:ARRAY [0..30] OF CHAR;
 dt:DateTimePtr;
 i:INTEGER;
BEGIN
 dt:=AllocMem(SIZE(DateTime),MemReqSet{public});
 DateStamp(ADR(dt^.date));
 dt^.format:=formatDOS;
 dt^.flags:=DateTimeFlagSet{};
 dt^.strDay:=ADR(day);
 dt^.strDate:=ADR(date);
 dt^.strTime:=ADR(time);
 IF DateToStr(dt)#0 THEN
  FOR i:=0 TO Length(day)-1 DO write(day[i]); END;
  write(" ");
  FOR i:=0 TO Length(date)-1 DO write(date[i]); END;
  write(" ");
  FOR i:=0 TO Length(time)-1 DO write(time[i]); END;
  write(" ");
 END;
 FreeMem(dt,SIZE(DateTime));
END writeStamp;

PROCEDURE read(pos{R.D2}:LONGCARD):CHAR;
(*$ LoadA4:=TRUE *)
VAR
 blk,first,next:LONGCARD;
 buf:BufferPtr;
 ch:CHAR;
BEGIN
 setup(buf,first,next);
 IF sumBuffer(buf^)#buf^.chksum THEN
  init;
  ch:=0C;
 ELSIF (first<=pos) & (pos<next) THEN
  pos:=pos MOD bufLength;
  blk:=pos MOD blockCount;
  IF sumBlock(buf^.data[blk])#buf^.datasum[blk] THEN
   init;
   ch:=0C;
  ELSE
   ch:=buf^.data[blk][pos DIV blockCount];
  END;
 ELSE
  ch:=0C;
 END;
 RETURN ch;
END read;

BEGIN
 IF dosCmdLen#0 THEN
  IF AllocAbs(SIZE(Buffer),bufEnd-SIZE(Buffer))=NIL THEN
   dosCmdLen:=0;
  ELSE
   init;
  END;
 END;
END LoggerLib.mod
