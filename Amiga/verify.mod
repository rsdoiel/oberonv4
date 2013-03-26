MODULE verify; (* cn 24-Sep-94 *)
(*
 verify takes alist of sym and obj files, and looks, if they
 all have the same keys for each other.
*)

FROM SYSTEM IMPORT ADR;

IMPORT
 Arguments,Arts,Break,SeqIO,s:String,T:Terminal;

CONST
 maxNames=200;
 nameLen=24;
 pathLen=128;

(*
 bufferSize for source file.
*)
 bufferSize=04000H;

TYPE
 CARDINAL=INTEGER;
 LONGCARD=LONGINT;
 Name=ARRAY [0..nameLen-1] OF CHAR;
 Path=ARRAY [0..pathLen-1] OF CHAR;
 File=RECORD
  path:Path;
  key:LONGCARD;
 END;

VAR
 inFile:SeqIO.SeqKey;
 outFile:SeqIO.SeqKey;
 files:ARRAY [1..maxNames] OF File;
 numOfFiles:INTEGER;

(*
 Some procedure for easier reading from input file
*)

PROCEDURE Read():CHAR; BEGIN RETURN SeqIO.SeqInB(inFile); END Read;
(* Read one byte from input file. *)

PROCEDURE ReadShort():INTEGER; BEGIN RETURN SeqIO.SeqInW(inFile); END ReadShort;
(* Read two bytes from input file. *)

PROCEDURE ReadLong():LONGINT; BEGIN RETURN SeqIO.SeqInL(inFile); END ReadLong;
(* Read four bytes from input file. *)

PROCEDURE ReadName(VAR name: ARRAY OF CHAR);
(* Read a modulename of 24 bytes from input files. *)
BEGIN SeqIO.SeqInCount(inFile,ADR(name),nameLen); END ReadName;

PROCEDURE ReadLine(VAR name: ARRAY OF CHAR);
(* Read a filename from input files. *)
VAR
 ch:CHAR;
 i:INTEGER;
BEGIN
 REPEAT SeqIO.SeqGetB(inFile,ch) UNTIL (ch>" ") OR ~SeqIO.SeqOk(inFile);
 WHILE (ch>" ") & SeqIO.SeqOk(inFile) DO
  name[i]:=ch;
  INC(i);
  SeqIO.SeqGetB(inFile,ch);
 END;
 name[i]:=0C;
END ReadLine;

PROCEDURE ReadString(VAR name: ARRAY OF CHAR);
(* Read a zero terminated string from input file. *)
VAR i:INTEGER;
BEGIN
 i:=-1; REPEAT INC(i); SeqIO.SeqGetB(inFile,name[i]); UNTIL name[i]=0C;
END ReadString;

VAR
 dummy:ARRAY [0..999] OF CHAR;

PROCEDURE SkipBlock(size:INTEGER);
(* Skip a block of given length from input file. *)
BEGIN
 Arts.Assert(size<SIZE(dummy),ADR("Illegal size in SkipBlock"));
 SeqIO.SeqInCount(inFile,ADR(dummy),size);
END SkipBlock;

PROCEDURE Check(byte:CHAR):BOOLEAN;
(* Check if current byte in objfile=byte; res:=done | invalidObjFile *)
BEGIN RETURN byte=Read(); END Check;

PROCEDURE WriteLine(path:Path);
VAR
 i:INTEGER;
BEGIN
 i:=0;
 WHILE path[i]#0C DO
  SeqIO.SeqOutB(outFile,path[i]);
  INC(i);
 END;
 SeqIO.SeqOutB(outFile,CHAR(10));
END WriteLine;

(*-------*)

PROCEDURE VerifyObjKey(file:File);
VAR
 hasErrors:BOOLEAN;
 i,j:INTEGER;
 key:LONGINT;
 len:INTEGER;
 name:Name;
 nofCommands:INTEGER;
 nofEntries:INTEGER;
 nofImports:INTEGER;
 nofPointers:INTEGER;
 pos:INTEGER;
BEGIN
 SkipBlock(9);
 nofEntries:=ReadShort();
 nofCommands:=ReadShort();
 nofPointers:=ReadShort();
 nofImports:=ReadShort();
 SkipBlock(42);
 Arts.Assert(Check(CHAR(82H)),ADR("No entries?"));       (* Entries *)
 SkipBlock(4*nofEntries);
 Arts.Assert(Check(CHAR(83H)),ADR("No commands ?"));       (* Commands *)
 FOR i:=1 TO nofCommands DO
  ReadString(name);
  SkipBlock(4);
 END;
 Arts.Assert(Check(CHAR(84H)),ADR("No pointers ?"));       (* Pointers *)
 SkipBlock(4*nofPointers);
 Arts.Assert(Check(CHAR(85H)),ADR("No imports ?"));       (* Imports *)
 FOR i:=1 TO nofImports DO
  key:=ReadLong();
  ReadString(name);
  len:=s.Length(name);
  name[len]:="."; name[len+1]:=0C;
  hasErrors:=FALSE;
  FOR j:=1 TO numOfFiles DO
   pos:=s.Occurs(files[j].path,s.first,name,TRUE);
   IF (pos#s.last)
      & ((pos=0) OR (files[j].path[pos-1]="/") OR (files[j].path[pos-1]=":")) THEN
    IF (key#files[j].key) & (files[j].key#0) THEN
     hasErrors:=TRUE;
     T.WriteString(file.path);
     T.FormatS(" imports %s",files[j].path);
     T.FormatNr("[key=%08lx]",files[j].key);
     T.FormatNr(" with key %08lx.\n",key);
    END;
   END;
  END;
  IF hasErrors THEN
   WriteLine(file.path);
  END;
 END;
END VerifyObjKey;

PROCEDURE VerifySymKey(file:File);
BEGIN
 (* not yet implemented *)
END VerifySymKey;

PROCEDURE GetObjKey():LONGINT;
VAR
 key:LONGINT;
BEGIN
 IF Check("6") THEN (* Verify it's an object file version "6" *)
  SkipBlock(30);
  key:=ReadLong();
 ELSE
  key:=0; HALT;
 END;
 RETURN key;
END GetObjKey;

PROCEDURE GetSymKey():LONGINT;
BEGIN
 (* not yet implemented *)
 RETURN 0;
END GetSymKey;

PROCEDURE AddKey(VAR file:File);
VAR
 ch:CHAR;
BEGIN
 IF ~SeqIO.OpenSeqIn(inFile,file.path,bufferSize) THEN
  T.FormatS("File %s not found.\n",file.path);
 ELSE
  ch:=Read();
  IF ch=CHAR(0F1H) THEN (* object file *)
   file.key:=GetObjKey();
  ELSIF ch=CHAR(0F9H) THEN (* symbol file *)
   file.key:=GetSymKey();
  ELSE
   file.key:=0; HALT;
   T.FormatS(" %s has unknown file format.\n",file.path);
  END;
  IF file.key=0 THEN
   T.FormatS(" %s has no valid key, so no checks are performed.\n",file.path);
  END;
  SeqIO.CloseSeq(inFile);
 END;
END AddKey;

PROCEDURE VerifyKey(VAR file:File);
VAR
 ch:CHAR;
BEGIN
 IF file.key=0 THEN
  T.FormatS(" %s is not verified.\n",file.path);
 ELSE
  IF ~SeqIO.OpenSeqIn(inFile,file.path,bufferSize) THEN
   T.FormatS("File %s not found.\n",file.path);
  ELSE
   ch:=Read();
   IF ch=CHAR(0F1H) THEN (* object file *)
    VerifyObjKey(file);
   ELSIF ch=CHAR(0F9H) THEN (* symbol file *)
    VerifySymKey(file);
   ELSE
    T.FormatS(" %s has unknown file format.\n",file.path);
   END;
   SeqIO.CloseSeq(inFile);
  END;
 END;
END VerifyKey;

PROCEDURE Verify(filePath:ARRAY OF CHAR);
VAR
 i:INTEGER;
 path:Path;
BEGIN
 IF ~SeqIO.OpenSeqIn(inFile,filePath,bufferSize) THEN
  T.FormatS("File %s not found.\n",filePath);
 ELSE
  T.FormatS("Reading names from %s:\n",filePath);
  i:=0;
  WHILE SeqIO.SeqOk(inFile) DO
   ReadLine(path);
   IF s.Length(path)>0 THEN
    IF i<maxNames THEN
     INC(i);
     T.FormatNr("\r%4ld",i); T.Flush;
     files[i].path:=path;
    ELSE
     T.FormatNr(" More than %ld files.\n",maxNames);
     SeqIO.CloseSeq(inFile);
     RETURN; (* <------------------------------- error termination. *)
    END;
   END;
  END;
  SeqIO.CloseSeq(inFile);
  numOfFiles:=i;
  T.WriteString(" files found. Getting keys:\n");
  FOR i:=1 TO numOfFiles DO
   T.FormatNr("\r%4ld",i);
   T.FormatNr("/%4ld",numOfFiles);
   T.Flush;
   AddKey(files[i]);
  END;
  T.WriteString(" keys retrieved. Verifying keys:\n");
  IF SeqIO.OpenSeqOut(outFile,"t:errors",bufferSize) THEN END;
  FOR i:=1 TO numOfFiles DO
   T.FormatNr("\r%4ld",i);
   T.FormatNr("/%4ld",numOfFiles);
   T.Flush;
   VerifyKey(files[i]);
  END;
  T.WriteString(" all verified.\n");
  SeqIO.CloseSeq(outFile);
 END;
END Verify;

VAR
 len:INTEGER;
 path:Path;
BEGIN
 Break.InstallException;
 IF Arguments.NumArgs()#1 THEN
  T.WriteString("Usage: verifyAll <file>\n\n  where file contains a list of sym/obj files to be checked.\n");
 ELSE
  Arguments.GetArg(1,path,len);
  Verify(path);
 END;
END verify.
