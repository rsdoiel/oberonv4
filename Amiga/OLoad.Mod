(*$LargeVars:=TRUE *)(* Absolute addressing so A4 hasn't any special meaning *)

MODULE OLoad; (** SHML/cn 13-Jul-93 **)
(*
 OLoad is the Amiga Oberon Loader. It implements the loading and
 relocating of modules.

 Additionally it provides runtime support functions for Oberon.
*)

FROM SYSTEM IMPORT ADDRESS,ADR,ASSEMBLE,BITSET,BYTE,CAST,LOADREGS,REG,SAVEREGS,SETREG,SHIFT,TAG,WORD;

FROM OLoadData IMPORT
 Absolute,CodeBase,Count,Entry,Module,Name,Size,TypeDescriptor
 ,descSizeAligned,nameLen
 ,module255
 ,commandsEntryG,commandsEntryP,commandsNameG,commandsNameP,codeG,codeSizeG,codeSizeP
 ,constG,constSizeG,constSizeP,dataG,dataSizeG,dataSizeP,entriesG,entryG
 ,keyG,keyP,importsG,importsP,nameG,nameP,nextG,nextP
 ,nofCommandsG,nofCommandsP,nofEntriesG,nofEntriesP,nofImportsG,nofImportsP
 ,nofPointersG,nofPointersP,pointerG,refG,refP,refCntG,refCntP,refSizeG,refSizeP,tagP
 ,tdExtensionLevelG,tdModuleP,tdNumberOfMethodsG,tdSizeG,tdSizeP,tdTagP
 ,Address,AllocateMod,CompleteTypeDescs,DeallocateMod,EqualName,Fixup,GetName
 ,MakeAbsolute,PutName,SetupPointers;

FROM OLoadDebug IMPORT
 NewTrapStub,ResetTrapStub,ToModula,ToOberon;

IMPORT
 Arguments,Arts,Break,DosD,DosL,ExecD,ExecL,Heap
 ,P:PeekNPoke,SeqIO,str:String,T:Terminal,Terminator;

CONST
 (*
  return values of ThisMod
 *)
 done=0; fileNotFound=1; keyMismatch= 3; invalidObjFile=4;
 commandNotFound=5; tooManyImports=6; notEnoughSpace=7;

 (*
  return values of Free
 *)
 modNotFound=7; refCntNotZero=9;

 (*
  implementation restrictions
 *)
 MaxImports=64;

(*
 bufferSize for source file.
*)
 bufferSize=04000H;

VAR
 modules:ADDRESS;
 noSystem:BOOLEAN;
 oberonModuleList:POINTER TO ADDRESS;
 objFile:SeqIO.SeqKey;
 oberonTerm:Terminator.Reference;
 oberonTrapStub:LONGINT;
 searchPath:ARRAY [0..255] OF CHAR;

(*
 Some procedure for easier reading from object file
*)

PROCEDURE Read():CHAR; BEGIN RETURN SeqIO.SeqInB(objFile); END Read;
(* Read one byte from object file. *)

PROCEDURE ReadShort():INTEGER; BEGIN RETURN SeqIO.SeqInW(objFile); END ReadShort;
(* Read two bytes from object file. *)

PROCEDURE ReadLong():LONGINT; BEGIN RETURN SeqIO.SeqInL(objFile); END ReadLong;
(* Read four bytes from object file. *)

PROCEDURE ReadName(VAR name: ARRAY OF CHAR);
(* Read a modulename of 24 bytes from object files. *)
BEGIN SeqIO.SeqInCount(objFile,ADR(name),nameLen); END ReadName;

PROCEDURE ReadString(VAR name: ARRAY OF CHAR);
(* Read a zero terminated string from object file. *)
VAR i:INTEGER;
BEGIN
 i:=-1; REPEAT INC(i); SeqIO.SeqGetB(objFile,name[i]); UNTIL name[i]=0C;
END ReadString;

PROCEDURE ReadBlock(block: Absolute; size:Size);
(* Read a block of given length from object file. *)
BEGIN SeqIO.SeqInCount(objFile,block,size); END ReadBlock;

PROCEDURE Check(byte:CHAR; VAR res:INTEGER);
(* Check if current byte in objfile=byte; res:=done | invalidObjFile *)
BEGIN
 IF (res=done) & (byte=Read()) THEN res:=done; ELSE res:=invalidObjFile; END
END Check;

(*-------*)

PROCEDURE Matches(VAR s0,s1:ARRAY OF CHAR): BOOLEAN;
(*
 TRUE, if s0, s1 match up to the third period
 TRUE, if s0 is terminated, and the rest of s1 starts with a period
 FALSE otherwise
*)
VAR
 i,no:INTEGER;
 ch:CHAR;
BEGIN
 i:=0; no:=0; ch:=s0[0];
 WHILE (ch#0C) & (ch=s1[i]) DO
  IF ch="." THEN INC(no); IF no=3 THEN RETURN TRUE END END;
  INC(i); ch:=s0[i]
 END;
 RETURN (ch=0C) & (s1[i]=".")
END Matches;

PROCEDURE Find(name:ARRAY OF CHAR; VAR mod:Module; VAR res:INTEGER);
(*
 find name in global module list, mod:=NIL | found module, res:=done | modNotFound
*)
BEGIN
 mod:=modules;
 WHILE (mod#NIL) & NOT(EqualName(mod,name)) DO mod:=nextG(mod); END;
 IF mod=NIL THEN res:=modNotFound; ELSE res:=done; END
END Find;

PROCEDURE Unlink(mod:Module);
(* Remove the module from the singly linked list of modules. *)
VAR
 cur,prev:Module;
BEGIN
 IF modules=mod THEN
  modules:=nextG(mod); nextP(mod,NIL);
  IF oberonModuleList#NIL THEN
   oberonModuleList^:=modules;
  END;
 ELSE
  cur:=modules;
  WHILE (cur#NIL) & (cur#mod) DO prev:=cur; cur:=nextG(cur); END;
  IF cur#NIL THEN nextP(prev,nextG(cur)); nextP(cur,NIL); END
 END;
END Unlink;

PROCEDURE ErrMsg(res: INTEGER; n1,n2: ARRAY OF CHAR);
BEGIN
 CASE res OF
 | done: T.WriteString("done\n");
 | invalidObjFile: T.FormatS("Invalid object file %s\n", n1);
 | keyMismatch:
  T.FormatS("Call error: %s", n1); T.FormatS(" imports %s with bad key\n", n2);
 | fileNotFound: T.FormatS("File not found: %s\n", n1);
 | commandNotFound: T.WriteString(n1); T.FormatS(".%s command not found\n",n2)
 | tooManyImports: T.FormatS("%s has too many imports\n", n1);
 | refCntNotZero: T.FormatS("Reference count not zero: %s\n", n1)
 | notEnoughSpace: T.WriteString("Not enough heap space\n");
 ELSE T.FormatNr("Unrecognized error %d\n",res);
 END;
END ErrMsg;

PROCEDURE ThisMod(name:ARRAY OF CHAR; VAR module:Module; VAR res:INTEGER; VAR imported:ARRAY OF CHAR); FORWARD;

PROCEDURE ThisCommand(mod:Module; commandname:ARRAY OF CHAR; VAR adr:Absolute; VAR res:INTEGER);
(* returns the adr of command commandname in mod, res:=done | commandNotFound *)
VAR
 i:Count;
 name:Name;
 nofCommands:Count;
BEGIN
 (* Search the command in the modules command table *)
 i:=0; nofCommands:=nofCommandsG(mod);
 LOOP
  IF i>=nofCommands THEN EXIT; END;
  commandsNameG(mod,i,name);
  IF str.Compare(name,commandname)=0 THEN EXIT; END;
  INC(i);
 END;
 IF i=nofCommands THEN
  adr:=0; res:=commandNotFound;
  nameG(mod,name);
  IF noSystem THEN ErrMsg(res,name,commandname); END;
 ELSE
  adr:=codeG(mod)+commandsEntryG(mod,i); res:=done;
 END
END ThisCommand;

PROCEDURE FreeModule(mod:Module; all:BOOLEAN);
(*
 Unload mod and if requested all modules imported by this module.
*)
VAR
 i:INTEGER;
 imp:Module;
 refCnt:Count;
BEGIN
(*
 For each imported module, the reference count is decreased. If it is
 zero, then that module is freed to, if all is TRUE. At the end the
 module itself is removed from the module list.
*)
 FOR i:=1 TO nofImportsG(mod) DO
  imp:=importsG(mod,i);
  refCnt:=refCntG(imp);
  DEC(refCnt);
  refCntP(imp,refCnt);
  IF (refCnt=0) & all THEN FreeModule(imp,TRUE) END;
 END;
 Unlink(mod);
END FreeModule;

PROCEDURE Free(name:ARRAY OF CHAR; all:BOOLEAN; VAR res:INTEGER);
(* unload module name and all imports, res:=done | refCntNotZero *)
VAR
 mod:Module;
BEGIN
(*
 Freeing is only done, if the module exists in the module list and
 the reference count of the module is zero.
*)
 Find(name,mod,res);
 IF res=done THEN
  IF refCntG(mod)>0 THEN res:=refCntNotZero;
  ELSE FreeModule(mod,all); res:=done;
  END
 END
END Free;

PROCEDURE CallOberon0(ud{0}:Terminator.UserData);
(*
 Call an Oberon procedure. Performs necessary save of registers.
*)
VAR
 data:ADDRESS;
 proc:PROC;
 dump:POINTER TO ARRAY [0..20] OF BYTE;
BEGIN
 data:=ud;
 proc:=CAST(PROC,data);
 dump:=data;
 ToOberon;
 SAVEREGS(BITSET{0..14});
 SETREG(16B,REG(15B));
 proc();
 LOADREGS(BITSET{0..14});
 ToModula;
END CallOberon0;

PROCEDURE CallOberon2(ud{0}:Terminator.UserData);
(*
 Call an Oberon procedure. Performs necessary save of registers.
*)
VAR
 data:ADDRESS;
 proc:PROC;
 dump:POINTER TO ARRAY [0..20] OF BYTE;
 dummy:INTEGER;
BEGIN
 data:=ud;
 proc:=CAST(PROC,data);
 dump:=data;
 ToOberon;
 SAVEREGS(BITSET{0..14});
 SETREG(16B,REG(15B));
 proc();
 LOADREGS(BITSET{0..14});
 ToModula;
END CallOberon2;

PROCEDURE CallOberon(ud{0}:Terminator.UserData);
(*
 Call an Oberon procedure. Performs necessary save of registers.
*)
VAR
 dummy:INTEGER;
BEGIN
 IF (ADR(dummy) MOD 4)#0 THEN CallOberon0(ud);
 ELSE CallOberon2(ud);
 END;
END CallOberon;

PROCEDURE CallTrapStub;
BEGIN
 CallOberon(oberonTrapStub);
END CallTrapStub;

PROCEDURE Amiga(data{3}:Absolute);
(*
 This procedure is installed into a procedure variable of module Amiga,
 and allows to execute some loader functions from Oberon.
*)
(*$ StackChk:=FALSE *)

 PROCEDURE GetData(index:SHORTCARD):LONGCARD;
 BEGIN
  RETURN P.GetLongB(data,index*4);
 END GetData;

VAR
 adrPtr,importedPtr,modPtr,modulesPtr,namePtr,procPtr,resPtr,sizePtr:Absolute;
 adr:ADDRESS;
 all:BOOLEAN;
 cond:BOOLEAN;
 err:LONGINT;
 i:INTEGER;
 imported:Name;
 mod:Module;
 msg:ADDRESS;
 name:Name;
 proc:Absolute;
 size:Size;
 res:INTEGER;
(*$ LoadA4:=TRUE *)
BEGIN
 ToModula;
 CASE GetData(0) OF

 | 0: (* InstallNew(proc:NewProc); *)
  (* Transfer address of Kernel.New, so it can be used in Fixup *)
  module255[0]:=GetData(1);

 | 1: (* InstallSysNew(proc:NewProc); *)
  (* Transfer address of Kernel.SysNew, so it can be used in Fixup *)
  module255[1]:=GetData(1);

(* 2 no more *)

 | 3: (* Terminate() *)
  (* Terminate Oberon *)
  Arts.Terminate();

 | 4: (* ThisMod(name:ARRAY OF CHAR; VAR module:Module; VAR res:INTEGER; VAR modules:Module; VAR imported:ARRAY OF CHAR); *)
  (* Load a new module *)
  namePtr:=GetData(1);
  modPtr:=GetData(2);
  resPtr:=GetData(3);
  modulesPtr:=GetData(4);
  importedPtr:=GetData(5);
  GetName(namePtr,0,name);
  ThisMod(name,mod,res,imported);
  PutName(importedPtr,0,imported);
  P.PutLongB(modPtr,0,mod);
  P.PutWordB(resPtr,0,res);
  P.PutLongB(modulesPtr,0,modules);

 | 5: (* ThisCommand(mod:Module; cmdname:ARRAY OF CHAR; VAR adr:Absolute; VAR res:INTEGER); *)
  (* Get address of a command *)
  mod:=GetData(1);
  namePtr:=GetData(2);
  procPtr:=GetData(3);
  resPtr:=GetData(4);
  GetName(namePtr,0,name);
  ThisCommand(mod,name,proc,res);
  P.PutLongB(procPtr,0,proc);
  P.PutWordB(resPtr,0,res);

 | 6: (* Free(name:ARRAY OF CHAR; all:BOOLEAN; VAR res:INTEGER; VAR modules:Module); *)
  (* Free a module *)
  namePtr:=GetData(1);
  all:=GetData(2)#0;
  resPtr:=GetData(3);
  modulesPtr:=GetData(4);
  GetName(namePtr,0,name);
  Free(name,all,res);
  P.PutWordB(resPtr,0,res);
  P.PutLongB(modulesPtr,0,modules);

 | 7: (* Allocate(VAR adr:LONGINT; size:LONGINT); *)
  adrPtr:=GetData(1);
  adr:=P.GetLongB(adrPtr,0);
  size:=GetData(2);
  Heap.Allocate(adr,size);
  P.PutLongB(adrPtr,0,adr);

 | 8: (* TermProcedure(proc:PROCEDURE); *)
  proc:=GetData(1);
  oberonTerm:=Terminator.Add(CallOberon,proc,oberonTerm);
  Arts.Assert(oberonTerm#Terminator.newReference,ADR("Terminator problem!"));

(* 9 no more *)

 | 10: (* Assert(cond:BOOLEAN; msg:ARRAY OF CHAR); *)
  cond:=GetData(1)#0;
  msg:=GetData(2);
  Arts.Assert(cond,msg);

(* 11 no more *)

 | 12: (* Deallocate(adr:LONGINT; size:LONGINT); *)
  adr:=GetData(1);
  size:=GetData(2);
  Heap.Deallocate(adr);
 | 13: (* InstallModuleList(modList:LONGINT); *)
  adr:=GetData(1);
  oberonModuleList:=ADDRESS(adr);
 | 14: (* InstallTrapHandler(p: PROCEDURE); *)
  oberonTrapStub:=GetData(1);
  NewTrapStub(ADR(CallTrapStub));
 | 15: (* ResetTrapStub; *)
  ResetTrapStub;
 | 16: (* GetErrorFrame(VAR err: ErrorFrame); *)
  err:=GetData(1);
  P.PutLongB(err,0,Arts.errorFrame.pc);
  P.PutLongB(err,4,Arts.errorFrame.aRegs[15]); (* stack pointer *)
  P.PutLongB(err,8,Arts.errorFrame.aRegs[13]); (* frame pointer *)
  P.PutLongB(err,12,ORD(Arts.errorFrame.error));
  CASE Arts.errorFrame.error OF
  | Arts.trap:
   P.PutLongB(err,16,Arts.errorFrame.trapNr);
  | Arts.exception:
   P.PutLongB(err,16,CAST(LONGINT,Arts.errorFrame.exceptionMask));
  | Arts.system:
   P.PutLongB(err,16,ORD(Arts.errorFrame.sysErr));
  ELSE
   P.PutLongB(err,16,0);
  END;
 | 17:(* GetSearchPath(VAR searchPath:ARRAY OF CHAR); *)
  adr:=GetData(1);
  size:=GetData(2);
  i:=0;
  WHILE (i<size-1) & (searchPath[i]#0C) DO
   P.PutByte(adr,i,SHORTCARD(searchPath[i]));
   INC(i);
  END;
  P.PutByte(adr,i,0);
 | 18: (* SystemHere(); *)
  noSystem:=FALSE;
 END;
 ToOberon;
END Amiga;

(*$ POP StackChk *)

PROCEDURE InitAmiga(mod:Module);
(*
 Install Amiga in procedure variable loaderCall of module Amiga.
*)
VAR
 p:POINTER TO PROCEDURE(LONGINT{3});
BEGIN
 (*
  Knowing the current address of variable loaderCall, we patch it,
  to point to procedure Amiga. As the position of this variable
  can change, we patch also two guard variables, which are tested
  in Module Amiga.
 *)
 p:=ADR(Amiga);
 P.PutLongB(codeG(mod),-4,ADDRESS(002468ACEH)); (* guard1 *)
 P.PutLongB(codeG(mod),-8,ADDRESS(p));          (* loaderCall *)
 P.PutLongB(codeG(mod),-12,ADDRESS(013579BDFH));(* guard2 *)
END InitAmiga;

PROCEDURE LoadModule(VAR mod:Module; VAR res:INTEGER; VAR imported:ARRAY OF CHAR);
(*
 Load module from open object file. The structure of the object file is

  ObjFile=Header Entries Commands Pointers Imports Const Code References.

  Header=0F1H version refPos refLen
   numOfEntries numOfCommands numOfPointers numOfImports
   link dataSize constSize codeSize key modName.

  version=36H.

  refPos,refLen,dataSize,constSize,codeSize,key=LONGCARD.

  numOfEntries,numOfCommands,numOfPointers,numOfImports,link=CARDINAL.

  modName=ARRAY [0..23] OF CHAR.

  name={ BYTE[1..255] } 0H.

  Entries=82H {entry}.

  Commands=83H {name entry}.

  Pointers=84H {offset}. (* global pointers, needed for the garbage collector *)

  Imports=85H {key name}.

  Const=86H {byte}.

  Code=87H {byte}.

  References=88H point "$\0" {variable} {point ["(" name ")"] name {variable}}.

  point=0F8X pcPos.

  variable=mode form adr name.

  pcPos,adr='variable length number'.

*)

VAR
 constSize, dataSize, codeSize, refPos, refSize, descSize, size: LONGINT;
 constAdr:LONGINT;
 dummyS:ARRAY [0..1] OF CHAR;
 dummyI:INTEGER;
 entry:Entry;
 i, j: LONGINT;
 imp: Module;
 import: ARRAY [0..MaxImports-1] OF RECORD name: Name; key: LONGINT END;
 link, nofEntries, nofCommands, nofPtrs, nofImports: INTEGER;
 name:Name;
 proc:PROC;
 tagbuf:ARRAY [0..9] OF LONGINT;
BEGIN
 res:=done;
 Check(CHAR(0F1H),res); Check("6",res); (* Verify it's an object file version "6" *)
 IF res=done THEN
  (*
   Read first part of header
  *)
  refPos:=ReadLong(); refSize:=ReadLong();
  nofEntries:=ReadShort(); nofCommands:=ReadShort();
  nofPtrs:=ReadShort(); nofImports:=ReadShort();

  IF nofImports >= MaxImports THEN res:=tooManyImports END;
  link:=ReadShort(); dataSize:=ReadLong();
  constSize:=ReadLong(); codeSize:=ReadLong();

  (*
   As soon as the size is known, we can allocate the memory for this
   module.
  *)
  mod:=AllocateMod(nofEntries,nofCommands,nofPtrs,nofImports,constSize,dataSize,codeSize,refSize);

  IF mod=NIL THEN
   res:=notEnoughSpace;
   IF noSystem THEN ErrMsg(res,"",""); END;
   RETURN; (* !!!!!!!!!!!!!!!!!!!!!!!! procedure termination !!!!!!!!!!!!!!!!!! *)
  END;
  INC(mod,4); (* Adjust pointer, so that start of block is at offset -4 *)

  tagP(mod,1); (* set mark bit in tag *)

  refCntP(mod,0);
  (*
   How many times, this module is imported. On module load time there
   is of course nobody who already imports this module.
  *)

  nofEntriesP(mod,nofEntries); (* Entries = exported procedures (?) *)
  nofCommandsP(mod,nofCommands);(* Commands = user callable procedures (M.P) *)
  nofPointersP(mod,nofPtrs);   (* Pointers = global pointers (used by Garbage Collector) *)
  nofImportsP(mod,nofImports); (* Imports = imported modules *)

  dataSizeP(mod,dataSize);     (* Data = global variables *)
  constSizeP(mod,constSize);   (* Const = real and strings constants *)
  codeSizeP(mod,codeSize);     (* Code = code *)
  refSizeP(mod,refSize);       (* Ref = information for trap viewer *)

  keyP(mod,ReadLong());        (* Key = time stamp of symbol file generation *)
  ReadName(name);              (* Name = module name *)
  nameP(mod,name);

  SetupPointers(mod);          (* set entry .. ref pointers *)

  Check(CHAR(82H), res);       (* Entries *)
  IF res=done THEN
   ReadBlock(entryG(mod), 4*nofEntriesG(mod));
  END;

  Check(CHAR(83H), res);       (* Commands *)
  IF res=done THEN
   i:=0;
   WHILE i < nofCommandsG(mod) DO
    ReadString(name);
    entry:=ReadLong();
    commandsNameP(mod,i,name);
    commandsEntryP(mod,i,entry);
    INC(i);
   END;
  END;

  Check(CHAR(84H), res);       (* Pointers *)
  IF res=done THEN
   ReadBlock(pointerG(mod), 4*nofPointersG(mod));
  END;

  Check(CHAR(85H), res);       (* Imports *)
  IF res=done THEN
   i:=1;                       (* own module inserted later *)
   WHILE i <= nofImportsG(mod) DO
    import[i].key:=ReadLong();
    ReadString(import[i].name);
    INC(i)
   END;
  END;

  Check(CHAR(86H), res);       (* Constants *)
  IF res=done THEN
   ReadBlock(constG(mod), constSizeG(mod));
  END;

  Check(CHAR(87H), res);       (* Code *)
  IF res=done THEN
   ReadBlock(codeG(mod), codeSizeG(mod));
  END;

  Check(CHAR(88H), res);       (* Ref *)
  IF res=done THEN
   ReadBlock(refG(mod), refSizeG(mod));
   nameG(mod,name);
  END;

  SeqIO.CloseSeq(objFile);

  j:=1;
  IF res=done THEN
   importsP(mod,0,mod);
   WHILE (j <= nofImportsG(mod)) & (res=done) DO
    ThisMod(import[j].name,imp,res,imported);
    IF res=done THEN
     importsP(mod,j,imp);
     refCntP(imp,refCntG(imp)+1);
     IF import[j].key#keyG(imp) THEN
      res:=keyMismatch;
      nameG(mod,name);
      str.Copy(imported,import[j].name);
      IF noSystem THEN ErrMsg(res,name,import[j].name); END;
     END;
     INC(j)
    ELSE
     importsP(mod,j,0);
    END;
   END
  END;
  IF res=done THEN
   Fixup(mod,link);
   CompleteTypeDescs(mod);
   nextP(mod,modules);
   modules:=mod;
   IF oberonModuleList#NIL THEN
    oberonModuleList^:=modules;
   END;
   IF EqualName(mod,"Amiga") THEN
    InitAmiga(mod);
   END;
   ExecL.CacheClearU;
   CallOberon(codeG(mod));
  ELSE
   WHILE j > 1 DO
    DEC(j);
    imp:=importsG(mod,j);
    IF imp#0 THEN
     refCntP(imp,refCntG(imp)-1);
    END;
   END;
   DeallocateMod(mod);
   Unlink(mod);
  END;
 END;
END LoadModule;

PROCEDURE MakeFileName(dir, name: ARRAY OF CHAR; VAR dest: ARRAY OF CHAR);
BEGIN
 dest[0]:=0C;
 IF DosL.AddPart(ADR(dest),ADR(dir),HIGH(dest)+1) THEN END;
 IF DosL.AddPart(ADR(dest),ADR(name),HIGH(dest)+1) THEN END;
END MakeFileName;

 PROCEDURE ThisMod(name: ARRAY OF CHAR; VAR module:Module; VAR res: INTEGER; VAR imported:ARRAY OF CHAR);
 (* returns the module descriptor to name, res:=done | error code *)
 VAR
  fname: ARRAY [0..nameLen+4] OF CHAR;
  path: ARRAY [0..255] OF CHAR;
  i: INTEGER;
 BEGIN
  Find(name,module,res);
  IF res=modNotFound THEN (* module not yet loaded *)
   i:=-1; REPEAT INC(i); fname[i]:=name[i] UNTIL (name[i]=0C) OR (i=nameLen);
   fname[i]:="."; fname[i+1]:="O"; fname[i+2]:="b"; fname[i+3]:="j"; fname[i+4]:=0C;
   IF SeqIO.OpenSeqIn(objFile,fname,bufferSize) THEN
    res:=done;
   ELSE
    MakeFileName(searchPath, fname, path);
    IF SeqIO.OpenSeqIn(objFile,path,bufferSize) THEN res:=done;
    ELSE
     res:=fileNotFound;
     IF noSystem THEN ErrMsg(res,path,""); END;
    END;
   END;
   IF res=done THEN LoadModule(module,res,imported) END
  END;
 END ThisMod;

(*********************************)

VAR
  process: DosD.ProcessPtr;
  oldExceptCode: PROC;
  oldExceptData:LONGINT;

(*$ SaveA4:=TRUE *) (* VERY IMPORTANT, save A4!!! *)
PROCEDURE ExceptionHandler;
VAR
  inDos: BOOLEAN;
  oldD0: LONGINT;
BEGIN
  oldD0:=REG(0);
  ASSEMBLE(
	MOVE.L	A1,A4 (* sonst kein Exec oder process^. ...! *)
  END);
  ExecL.Forbid; (* exclusive access to signals! *)
  WITH process^.task DO
    inDos:=ExecD.sigDos IN (sigWait/sigRecvd);
    (* sigWait / sigReceived  X=sigDos IN, 0 not
     *    0         0         no Dos call pending, should be no problem
     *    X         0         in Dos waiting for answer, return quietly
     *    0         X         in Dos(?) answer just received, curious
     *    X         X         just finished dos call, remove message
     *)
  END;
  ExecL.Permit;
  IF ~inDos THEN
    T.WriteString("CTRL-C terminates\n");
    (* get any pending message *)
    SETREG(0,ExecL.GetMsg(ADR(process^.msgPort)));
    Break.ExitBreak;
  ELSE
    T.WriteString("CTRL-C can't terminate\n");
  END;
  SETREG(0,oldD0) (* reenable exception -> [RKM] *)
END ExceptionHandler;

PROCEDURE InstallException;
BEGIN
  ExecL.Forbid;
  process^.task.exceptCode:=ExceptionHandler;
  process^.task.exceptData:=REG(4+8);
  SETREG(0,ExecL.SetSignal(Break.NoBreak,Break.FullBreak)); (* alle lschen! *)
  SETREG(0,ExecL.SetExcept(Break.CBreak,Break.CBreak));
  ExecL.Permit;
END InstallException;

PROCEDURE RemoveException;
BEGIN
  ExecL.Forbid;
  SETREG(0,ExecL.SetExcept(Break.NoBreak,Break.CBreak));
  process^.task.exceptCode:=oldExceptCode;
  process^.task.exceptData:=oldExceptData;
  ExecL.Permit;
END RemoveException;

(*********************************)

VAR
 command:LONGINT;
 imported:Name;
 len:INTEGER;
 mod:Module;
 oldLock:DosD.FileLockPtr;
 res:INTEGER;
 st:ARRAY [0..255] OF CHAR;
 task:ExecD.TaskPtr;
BEGIN
 oldLock:=DosL.CurrentDir(DosL.Lock(ADR(""),DosD.sharedLock));
 oberonTerm:=Terminator.newReference;
 task:=ExecL.FindTask(NIL);
 process:=ADDRESS(task);
 IF ExecL.SetTaskPri(task,-4)=0 THEN END;
 IF DosL.SetProgramName(ADR("Oberon4Amiga")) THEN END;
 task^.node.name:=ADR("Oberon4Amiga");

 modules:=NIL;
 oberonModuleList:=NIL;
 noSystem:=TRUE;
 InstallException;

 IF Arguments.NumArgs()#1 THEN
  T.WriteString("Usage: OLoad searchAssign\n");
  RETURN;
 ELSE
  Arguments.GetArg(1,searchPath,len);
 END;

 ThisMod("Kernel\o",mod,res,imported);
 IF res=done THEN
  ThisMod("Amiga\o",mod,res,imported);
  IF res=done THEN
   ThisCommand(mod,"Loop\o",command,res);
   IF res=done THEN
    CallOberon(command);
   END;
  END;
 END;

CLOSE
 RemoveException;
 IF oldLock#NIL THEN DosL.UnLock(DosL.CurrentDir(oldLock)); END;
END OLoad.
