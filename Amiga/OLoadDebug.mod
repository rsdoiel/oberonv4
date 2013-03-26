

(* This Module for hacker only. Don't touch !!!! *)


(*$ LargeVars:=TRUE *) (* IMPORTANT !!! *)

IMPLEMENTATION MODULE OLoadDebug;

FROM SYSTEM IMPORT ADDRESS,ADR,ASSEMBLE,CAST,REG,SETREG,WORD;

IMPORT
 Arts,ExecD,ExecL,R;

CONST
 (* trapStubOffset=1D6H; DArts *)
 trapStubOffset=172H; (* Arts *)

 (* trapHandlerOffset=10; not optimized *)
 trapHandlerOffset=9; (* optimized *)

TYPE
 Word3=ARRAY [0..2] OF CARDINAL;
 Word3Ptr=POINTER TO Word3;

VAR
 inOberon:BOOLEAN;
 trapStubInit:Word3;

PROCEDURE ToModula;
BEGIN
 inOberon:=FALSE;
END ToModula;

PROCEDURE ToOberon;
BEGIN
 inOberon:=TRUE;
END ToOberon;

VAR
 copyOfA4:ADDRESS;

PROCEDURE TrapHandler;
(*$EntryExitCode:=FALSE*)
BEGIN
 IF inOberon THEN
  SETREG(R.A5,REG(R.A6));
 END;
 SETREG(R.A4,copyOfA4);
 ASSEMBLE(
  JMP $12345678
  END
 );
END TrapHandler;

PROCEDURE NewTrapStub(adr:LONGINT);
VAR
 p:Word3Ptr;
BEGIN
 p:=ADDRESS(ADR(Arts.Requester)+trapStubOffset);
 p^[0]:=4EF9H;
 p^[1]:=CAST(LONGCARD,adr) DIV 10000H;
 p^[2]:=CAST(LONGCARD,adr) MOD 10000H;
 ExecL.CacheClearU;
END NewTrapStub;

PROCEDURE ResetTrapStub;
VAR
 p:Word3Ptr;
BEGIN
 p:=ADDRESS(ADR(Arts.Requester)+trapStubOffset);
 p^:=trapStubInit;
 ExecL.CacheClearU;
END ResetTrapStub;

PROCEDURE SaveTrapStub;
VAR
 p:Word3Ptr;
BEGIN
 p:=ADDRESS(ADR(Arts.Requester)+trapStubOffset);
 trapStubInit:=p^;
 Arts.Assert(
  (trapStubInit[0]=7000H) & (trapStubInit[1]=302CH)
  ,ADR("Please adjust trapStubOffset.")
 );
END SaveTrapStub;

VAR
 thisTask:ExecD.TaskPtr;
 trapHandler:POINTER TO RECORD
  code:ARRAY [1..trapHandlerOffset] OF WORD;
  oldAddr:PROC;
 END;

BEGIN
 copyOfA4:=REG(R.A4);
 inOberon:=FALSE;
 SaveTrapStub;

(* Patch in our own TrapHandler *)
 thisTask:=ExecL.FindTask(NIL);
 trapHandler:=ADR(TrapHandler);

 Arts.Assert(CAST(LONGCARD,trapHandler^.oldAddr)=12345678H,ADR("Please adjust trapHandler."));

 trapHandler^.oldAddr:=thisTask^.trapCode;
 ExecL.CacheClearU;
 thisTask^.trapCode:=TrapHandler;

END OLoadDebug.
