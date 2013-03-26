IMPLEMENTATION MODULE Terminator;

FROM SYSTEM IMPORT ADDRESS;

IMPORT Heap;

TYPE
 ProcNodePtr=POINTER TO ProcNode;
 ProcNode=RECORD
  tp:TermProc;
  ud:UserData;
  next:ProcNodePtr;
 END;
 ReferenceInfo=RECORD
  next:Reference;
  procedures:ProcNodePtr;
 END;
 Reference=POINTER TO ReferenceInfo;

VAR
 cleanupList:Reference;

PROCEDURE Add(tp:TermProc; ud:UserData; ref:Reference):Reference;
VAR
 node:ProcNodePtr;
BEGIN
 Heap.Allocate(node,SIZE(ProcNode));
 IF node=NIL THEN
  RETURN newReference;
 ELSE
  node^.tp:=tp;
  node^.ud:=ud;
  IF ref=newReference THEN
   Heap.Allocate(ref,SIZE(ReferenceInfo));
   IF ref=NIL THEN
    Heap.Deallocate(node);
    RETURN newReference;
   ELSE
    ref^.next:=cleanupList;
    ref^.procedures:=NIL;
    cleanupList:=ref;
   END;
  END;
  node^.next:=ref^.procedures;
  ref^.procedures:=node;
 END;
 RETURN ref;
END Add;

PROCEDURE Remove(VAR ref:Reference);
VAR
 pre:Reference;
 node,next:ProcNodePtr;
BEGIN
 IF ref#NIL THEN
  IF ref=cleanupList THEN
   cleanupList:=ref^.next;
  ELSE
   pre:=cleanupList;
   WHILE (pre#NIL) & (pre^.next#ref) DO pre:=pre^.next; END;
   IF pre#NIL THEN
    pre^.next:=ref^.next;
   END;
  END;
  node:=ref^.procedures;
  Heap.Deallocate(ref);
  ref:=newReference;
  WHILE node#NIL DO
   next:=node^.next;
   Heap.Deallocate(node);
   node:=next;
  END;
 END;
END Remove;

PROCEDURE Use(VAR ref:Reference);
VAR
 pre:Reference;
 node,next:ProcNodePtr;
BEGIN
 IF ref#NIL THEN
  IF ref=cleanupList THEN
   cleanupList:=ref^.next;
  ELSE
   pre:=cleanupList;
   WHILE (pre#NIL) & (pre^.next#ref) DO pre:=pre^.next; END;
   IF pre#NIL THEN
    pre^.next:=ref^.next;
   END;
  END;
  node:=ref^.procedures;
  Heap.Deallocate(ref);
  ref:=newReference;
  WHILE node#NIL DO
   node^.tp(node^.ud);
   next:=node^.next;
   Heap.Deallocate(node);
   node:=next;
  END;
 END;
END Use;

VAR
 ref:Reference;
BEGIN
 cleanupList:=NIL;
CLOSE
 WHILE cleanupList#NIL DO ref:=cleanupList; Use(ref); END;
END Terminator.

