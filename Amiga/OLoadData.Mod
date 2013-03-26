IMPLEMENTATION MODULE OLoadData;
(*
 This module allows the access to the data structures Module and
 TypeDescriptor, which are used also in the Oberon System.

 The access is done through procedures. These procedures are
 written in concordance to the aligning rules of the oberon
 compiler.

 Thus this module has to be revised whenever the oberon compiler
 is changed.
*)

FROM SYSTEM IMPORT ADDRESS,CAST;

FROM Arts IMPORT Assert;

FROM PeekNPoke IMPORT
 GetByte,GetWordB,GetLongB,PutByte,PutWordB,PutLongB;

IMPORT
 Heap;

PROCEDURE GetAddr(base:ADDRESS; offset:LONGINT):ADDRESS;
BEGIN
 RETURN CAST(ADDRESS,GetLongB(base,offset));
END GetAddr;

PROCEDURE PutAddr(base:ADDRESS; offset:LONGINT; addr:ADDRESS);
BEGIN
 PutLongB(base,offset,CAST(LONGCARD,addr));
END PutAddr;

PROCEDURE PutName(base:Absolute; offset:LONGINT; name:Name);
VAR
 i:SHORTCARD;
BEGIN
 FOR i:=0 TO nameLen-1 DO
  PutByte(base,LONGINT(i)+offset,SHORTCARD(name[i]));
 END;
END PutName;

PROCEDURE GetName(base:Absolute; offset:LONGINT; VAR name:Name);
VAR
 i:SHORTCARD;
BEGIN
 FOR i:=0 TO nameLen-1 DO
  name[i]:=CHAR(GetByte(base,LONGINT(i)+offset));
 END;
END GetName;

PROCEDURE Address(mod:Module; mno,eno:SHORTCARD):Absolute;
(* address of entry mno,eno *)
VAR
 imported:Module;
BEGIN
 imported:=importsG(mod,mno);
(*$OverflowChk:=FALSE*)
 RETURN codeG(imported)+entriesG(imported,eno);
(*$POP OverflowChk*)
END Address;

PROCEDURE MakeAbsolute(mod:Module; base:Absolute; entry:Entry);
(*
 Replace an long word consisting of module number an entry number
 as bytes at offset 2 and 3 with an absolute 32 bit address stored in
 a big endian fashion at offset 0.
*)
VAR
 adr:LONGINT;
 eno,mno:SHORTCARD;
BEGIN
 mno:=GetByte(base,entry+2); eno:=GetByte(base,entry+3);
 adr:=Address(mod,mno,eno);
 PutLongB(base,entry,CAST(LONGCARD,adr));
END MakeAbsolute;

PROCEDURE Fixup(mod:Module; link:CARDINAL);
(* follow fixup chain and insert absolute addresses *)
VAR
 address:Absolute;
 code:CodeBase;
 nxt:OldCardinal;
 entry,next:CARDINAL;
 modno,entno:SHORTCARD;
BEGIN
 code:=codeG(mod);
 WHILE link#0 DO
  (*
   At each link position, the first 16 bit contain a word offset to the
   next link posision. The second 16 bit contain a module and an entry
   number as 2 bytes packed into one word. link indexes words!
  *)
  nxt:=GetWordB(code,2*OldCardinal(link));
  next:=nxt;
  modno:=GetByte(code,2*OldCardinal(link)+2);
  entno:=GetByte(code,2*OldCardinal(link)+3);
  IF modno=255 THEN (* special, indicate the new and sysNew procedures *)
   address:=module255[entno];
  ELSE
   address:=Address(mod,modno,entno); (* Lookup the relocated address *)
  END;
  (*
   Replace the linkage entry by the absoulte 32 bit address, and go to
   the next link position.
  *)
  PutLongB(code,2*OldCardinal(link),address);
  link:=next
 END
END Fixup;

 (*
  Type descriptor offsets. The type descriptor looks roughly like this:

  Reference=RECORD
   CASE (*relocated*):BOOLEAN OF
   | FALSE: moduleNumber,entryNumber:INTEGER;
   | TRUE: address:ADDRESS;
   END;
  END;

  TypeDescriptor=RECORD
   methods:ARRAY OF Reference;
   (*-4*) tag:LONGINT;  (* offset -4, as pointer points to size element *)
   (* 0*) size:LONGCARD; (* pointer points to this element *)
   (* 4*) extensionLevel:INTEGER;
   (* 6*) numberOfMethods:INTEGER;
   (* 8*) moduleAddress:ADDRESS;
   (*12*) reserved:ADDRESS;
   (*16*) baseTypes:ARRAY [0..7] OF Reference;
   (*48*) name:ARRAY [0..23] OF CHAR; (* 0C terminated *)
   (*72*) pointerOffsets:ARRAY OF LONGINT; (* variable length *)
   backPointer:LONGINT; (* relative pointer back to «size» *)

  But because the type descriptor is used on the Oberon side too, it is
  manipulated using the known offsets used by the Oberon compiler. An
  overlaying of the above declared structure, would make this program
  also dependent from the Modula compiler.

  Note:
   TypeDescriptors need to be aligned on an 8 byte boundary, i.e. tdAdr MOD 8=0.
 *)
CONST
 tagOff=-4; baseTypeOff=40;
 referenceSize=4;

PROCEDURE CompleteTypeDescs(mod:Module);
(* completes type descriptors of a module *)
VAR
 address:LONGINT;
 code:CodeBase;
 dataSize:Size;
 i,j:Count;
 extlev,numberOfMethods:INTEGER;
 mno,eno:SHORTCARD;
 relTypeDesc:Entry;
 typeDesc:TypeDescriptor;
 size:Size;
BEGIN
 code:=codeG(mod);
 dataSize:=dataSizeG(mod);
 FOR i:=0 TO nofEntriesG(mod)-1 DO
  relTypeDesc:=entriesG(mod,i);
  IF relTypeDesc<(-Entry(dataSize)) THEN
   (*
    The entry can only be a type descriptor, if it is located in
    the const area, i.e. the entry offsett is less than the data
    size.
   *)
   typeDesc:=code+relTypeDesc;
   Assert(typeDesc=constG(mod)+constSizeG(mod)+dataSizeG(mod)+relTypeDesc,NIL);

   tdTagP(typeDesc,1); (* set mark bit *)

   (*
    Extend size by a long word, and realligne on a 16 byte boundary.
   *)
   size:=tdSizeG(typeDesc);
   size:=(((size+4)+15) DIV 16)*16;
   tdSizeP(typeDesc,size);

   (*
    Store the module base in the type descriptor
   *)
   tdModuleP(typeDesc,mod);

   (*
    Read the extension level.
   *)
   FOR j:=0 TO tdExtensionLevelG(typeDesc) DO
    (*
     Fill base type table by transforming every entry from the
     mno,eno form to its real address.
    *)

    MakeAbsolute(mod,typeDesc,baseTypeOff+(j*referenceSize));
   END;

   FOR j:=1 TO tdNumberOfMethodsG(typeDesc) DO
    (*
     Fill method table by transforming every entry from the
     mno,eno form to its real address.

     Note: tag is the first item after the method table.
    *)
    MakeAbsolute(mod,typeDesc,tagOff-(j*referenceSize));
   END;
  END;
 END;
END CompleteTypeDescs;

PROCEDURE tdTagP(td:TypeDescriptor; tag:Tag);
BEGIN PutLongB(td,-4,tag); END tdTagP;

PROCEDURE tdSizeG(td:TypeDescriptor):Size;
BEGIN RETURN GetLongB(td,0); END tdSizeG;

PROCEDURE tdSizeP(td:TypeDescriptor; size:Size);
BEGIN PutLongB(td,0,size); END tdSizeP;

PROCEDURE tdExtensionLevelG(td:TypeDescriptor):Count;
BEGIN RETURN GetWordB(td,4); END tdExtensionLevelG;

PROCEDURE tdNumberOfMethodsG(td:TypeDescriptor):Count;
BEGIN RETURN GetWordB(td,6); END tdNumberOfMethodsG;

PROCEDURE tdModuleP(td:TypeDescriptor; mod:Module);
BEGIN PutAddr(td,8,mod); END tdModuleP;


 (*
  Module header offsets. The module descripter looks roughly like this:

  Name=ARRAY [0..NameLen-1] OF CHAR;
  Command=RECORD
   name:Name;
   entry:LONGCARD;
  END;
  Module=POINTER TO ModuleDesc;
  ModuleDesc=RECORD
   (*-4*) tag:LONGINT; (* offset -4, as pointer points to next element *)
   (* 0*) next:Module; (* pointer points to this item *)
   (* 4*) nofEntries:INTEGER;
   (* 6*) nofCommands:INTEGER;
   (* 8*) nofPtrs:INTEGER;
   (*10*) nofImports:INTEGER;
   (*12*) refCnt:INTEGER;
   (*14*) constSize:LONGINT;
   (*18*) dataSize:LONGINT;
   (*22*) codeSize:LONGINT;
   (*26*) refSize:LONGINT;
   (*30*) key:LONGINT;
   (*34*) name:ARRAY [0..23] OF CHAR;
   (*58*) entry:ADDRESS;
   (*62*) command:ADDRESS;
   (*66*) ptr:ADDRESS;
   (*70*) import:ADDRESS;
   (*74*) const:ADDRESS;
   (*78*) data:ADDRESS;
   (*82*) code:ADDRESS;
   (*86*) ref:ADDRESS;
   (*90*) entries:ARRAY OF LONGCARD; (* nofEntries *)
   commands:ARRAY OF Command; (* nofCommands *)
   pointerOffsets:ARRAY OF LONGINT; (* nofPtrs *)
   imports:ARRAY OF Module; (* nofImports+1 *)
   constants:ARRAY OF SHORTCARD; (* constSize *)
   data:ARRAY OF SHORTCARD; (* dataSize *)
   code:ARRAY OF SHORTCARD; (* codeSize *)
   references:ARRAY OF SHORTCARD; (* refSize *)
  END;

  Again we won't alias a Modula-2 declaration to it, but use the offsets
  declared below, which conform to the allocation strategy of the Oberon
  compiler.

  Note:
   The constants, data and code area have to be aligned on an 8 byte boundary,
   to satisfy the alignement condition for type descriptors.
 *)

PROCEDURE tagP(mod:Module; tag:Tag);
BEGIN PutLongB(mod,-4,tag); END tagP;

PROCEDURE nextG(mod:Module):Module;
BEGIN RETURN GetAddr(mod,0); END nextG;

PROCEDURE nextP(mod:Module; next:Module);
BEGIN PutAddr(mod,0,next); END nextP;

PROCEDURE nofEntriesG(mod:Module):Count;
BEGIN RETURN GetWordB(mod,4); END nofEntriesG;

PROCEDURE nofEntriesP(mod:Module; count:Count);
BEGIN PutWordB(mod,4,count); END nofEntriesP;

PROCEDURE nofCommandsG(mod:Module):Count;
BEGIN RETURN GetWordB(mod,6); END nofCommandsG;

PROCEDURE nofCommandsP(mod:Module; count:Count);
BEGIN PutWordB(mod,6,count); END nofCommandsP;

PROCEDURE nofPointersG(mod:Module):Count;
BEGIN RETURN GetWordB(mod,8); END nofPointersG;

PROCEDURE nofPointersP(mod:Module; count:Count);
BEGIN PutWordB(mod,8,count); END nofPointersP;

PROCEDURE nofImportsG(mod:Module):Count;
BEGIN RETURN GetWordB(mod,10); END nofImportsG;

PROCEDURE nofImportsP(mod:Module; count:Count);
BEGIN PutWordB(mod,10,count); END nofImportsP;

PROCEDURE refCntG(mod:Module):Count;
BEGIN RETURN GetWordB(mod,12); END refCntG;

PROCEDURE refCntP(mod:Module; refCnt:Count);
BEGIN PutWordB(mod,12,refCnt); END refCntP;

PROCEDURE constSizeG(mod:Module):Size;
BEGIN RETURN GetLongB(mod,14); END constSizeG;

PROCEDURE constSizeP(mod:Module; size:Size);
BEGIN PutLongB(mod,14,size); END constSizeP;

PROCEDURE dataSizeG(mod:Module):Size;
BEGIN RETURN GetLongB(mod,18); END dataSizeG;

PROCEDURE dataSizeP(mod:Module; size:Size);
BEGIN PutLongB(mod,18,size); END dataSizeP;

PROCEDURE codeSizeG(mod:Module):Size;
BEGIN RETURN GetLongB(mod,22); END codeSizeG;

PROCEDURE codeSizeP(mod:Module; size:Size);
BEGIN PutLongB(mod,22,size); END codeSizeP;

PROCEDURE refSizeG(mod:Module):Size;
BEGIN RETURN GetLongB(mod,26); END refSizeG;

PROCEDURE refSizeP(mod:Module; size:Size);
BEGIN PutLongB(mod,26,size); END refSizeP;

PROCEDURE keyG(mod:Module):Key;
BEGIN RETURN GetLongB(mod,30); END keyG;

PROCEDURE keyP(mod:Module; key:Key);
BEGIN PutLongB(mod,30,key); END keyP;

PROCEDURE nameG(mod:Module; VAR name:Name);
BEGIN
 GetName(mod,34,name);
END nameG;

PROCEDURE nameP(mod:Module; name:Name);
BEGIN
 PutName(mod,34,name);
END nameP;

PROCEDURE entryG(mod:Module):EntryBase;
BEGIN RETURN GetAddr(mod,58); END entryG;

PROCEDURE entryP(mod:Module; entry:EntryBase);
BEGIN PutAddr(mod,58,entry); END entryP;

PROCEDURE commandG(mod:Module):CommandBase;
BEGIN RETURN GetAddr(mod,62); END commandG;

PROCEDURE commandP(mod:Module; command:CommandBase);
BEGIN PutAddr(mod,62,command); END commandP;

PROCEDURE pointerG(mod:Module):PointerBase;
BEGIN RETURN GetAddr(mod,66); END pointerG;

PROCEDURE pointerP(mod:Module; pointer:PointerBase);
BEGIN PutAddr(mod,66,pointer); END pointerP;

PROCEDURE importG(mod:Module):ImportBase;
BEGIN RETURN GetAddr(mod,70); END importG;

PROCEDURE importP(mod:Module; import:ImportBase);
BEGIN PutAddr(mod,70,import); END importP;

PROCEDURE constG(mod:Module):ConstBase;
BEGIN RETURN GetAddr(mod,74); END constG;

PROCEDURE constP(mod:Module; const:ConstBase);
BEGIN PutAddr(mod,74,const); END constP;

PROCEDURE dataG(mod:Module):DataBase;
BEGIN RETURN GetAddr(mod,78); END dataG;

PROCEDURE dataP(mod:Module; data:DataBase);
BEGIN PutAddr(mod,78,data); END dataP;

PROCEDURE codeG(mod:Module):CodeBase;
BEGIN RETURN GetAddr(mod,82); END codeG;

PROCEDURE codeP(mod:Module; code:CodeBase);
BEGIN PutAddr(mod,82,code); END codeP;

PROCEDURE refG(mod:Module):RefBase;
BEGIN RETURN GetAddr(mod,86); END refG;

PROCEDURE refP(mod:Module; ref:RefBase);
BEGIN PutAddr(mod,86,ref); END refP;

PROCEDURE entriesG(mod:Module; index:Index):Entry;
BEGIN RETURN GetAddr(entryG(mod),index*4); END entriesG;

PROCEDURE commandsEntryG(mod:Module; index:Index):Entry;
BEGIN RETURN GetAddr(commandG(mod),index*(nameLen+4)+24); END commandsEntryG;

PROCEDURE commandsEntryP(mod:Module; index:Index; entry:Entry);
BEGIN PutAddr(commandG(mod),index*(nameLen+4)+24,entry); END commandsEntryP;

PROCEDURE commandsNameG(mod:Module; index:Index; VAR name:Name);
BEGIN GetName(commandG(mod),index*(nameLen+4),name); END commandsNameG;

PROCEDURE commandsNameP(mod:Module; index:Index; name:Name);
BEGIN PutName(commandG(mod),index*(nameLen+4),name); END commandsNameP;

PROCEDURE importsG(mod:Module; index:Index):Module;
BEGIN RETURN GetAddr(importG(mod),index*4); END importsG;

PROCEDURE importsP(mod:Module; index:Index; module:Module);
BEGIN PutAddr(importG(mod),index*4,module); END importsP;

PROCEDURE SetupPointers(mod:Module);
VAR
 constAdr:Absolute;
 dataStart:Absolute;
BEGIN
 entryP(mod,mod+descSizeAligned);
 commandP(mod,entryG(mod)+4*nofEntriesG(mod));
 pointerP(mod,commandG(mod)+(nameLen+4)*nofCommandsG(mod));
 importP(mod,pointerG(mod)+4*nofPointersG(mod));

 constAdr:=importG(mod)+4*(nofImportsG(mod)+1);
 constAdr:=((constAdr+7) DIV 8)*8; (* align on 8 byte boundary *)

 constP(mod,constAdr);

 dataStart:=constG(mod)+constSizeG(mod);
 codeP(mod,dataStart+dataSizeG(mod));
 dataP(mod,codeG(mod));       (* use same pointer, but with negative offsets *)

 refP(mod,codeG(mod)+codeSizeG(mod));
END SetupPointers;

PROCEDURE EqualName(mod:Module; name:ARRAY OF CHAR):BOOLEAN;
VAR
 ch:CHAR;
 i:INTEGER;
BEGIN
 i:=0;
 LOOP
  IF i>=nameLen THEN RETURN (i>HIGH(name)) OR (name[i]=0C); END;
  ch:=CHAR(GetByte(mod,34+i));
  IF i>HIGH(name) THEN RETURN ch=0C; END;
  IF ch#name[i] THEN RETURN FALSE; END;
  IF ch=0C THEN RETURN TRUE; END;
  INC(i);
 END;
END EqualName;

PROCEDURE AllocateMod(nofEntries:Count; nofCommands:Count; nofPtrs:Count; nofImports:Count; constSize:Size; dataSize:Size; codeSize:Size; refSize:Size):Module;
VAR
 m:ADDRESS;
 size:Size;
BEGIN
 size:=
  descSizeAligned         (* Size of Module-descriptor *)
  +4*nofEntries           (* The entry table *)
  +(nameLen+4)*nofCommands  (* The command table *)
  +4*nofPtrs              (* The table with the offsets of the gloabl pointer variables *)
  +4*(nofImports+1)       (* References to imported modules *)
  +constSize              (* The constants of this module *)
  +dataSize               (* The global data of this module *)
  +codeSize               (* The code of this module *)
  +refSize;               (* The reference information needed by Oberons trap handler *)
 Heap.Allocate(m,size+7+4);
 (*
  Allocate 4 bytes more for tag field at offset -4, and another 7 bytes
  more, so that we can adjust the const space to an 8 byte boundary.
 *)
 RETURN Module(m);
END AllocateMod;

PROCEDURE DeallocateMod(mod:Module);
VAR
 m:ADDRESS;
BEGIN
 m:=mod;
 Heap.Deallocate(m);
END DeallocateMod;

END OLoadData.
