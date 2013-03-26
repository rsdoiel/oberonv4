IMPLEMENTATION MODULE PeekNPoke;
(*
 The routines of this module allow to read/build a data structure in a  machine
 independent way. Instead of aliasing datatypes to memory areas, the structure
 is read/built by copying individual bytes from/to the correct place.

 In all routines, base is a pointer (anchor) to the memory block you want to
 manipulate and offset an address relativ to this base.

 Word is used to denominate a 2 byte entity, long to denominate a 4 byte entity.
*)

FROM SYSTEM IMPORT ADDRESS;

PROCEDURE PutByte(base:ADDRESS; offset:LONGINT; value:SHORTCARD);
(* Write a single byte *)
VAR
 tmpPtr:POINTER TO SHORTCARD;
BEGIN
 tmpPtr:=ADDRESS(base+offset); tmpPtr^:=value;
END PutByte;

PROCEDURE PutWordB(base:ADDRESS; offset:LONGINT; value:CARDINAL);
(*
 Write a word in big endian fashion, i.e. most significant byte
 at lowest memory address.
*)
BEGIN
 PutByte(base,offset,value DIV 100H); PutByte(base,offset+1,value MOD 100H);
END PutWordB;

PROCEDURE PutWordL(base:ADDRESS; offset:LONGINT; value:CARDINAL);
(*
 Write a word in little endian fashion, i.e. most significant byte
 at highest memory address.
*)
BEGIN
 PutByte(base,offset+1,value DIV 100H); PutByte(base,offset,value MOD 100H);
END PutWordL;

PROCEDURE PutLongB(base:ADDRESS; offset:LONGINT; value:LONGCARD);
(*
 Write a long word in big endian fashion, i.e. most significant byte
 at lowest memory address.
*)
BEGIN
 PutWordB(base,offset,value DIV 10000H); PutWordB(base,offset+2,value MOD 10000H);
END PutLongB;

PROCEDURE PutLongL(base:ADDRESS; offset:LONGINT; value:LONGCARD);
(*
 Write a long word in little endian fashion, i.e. most significant byte
 at highest memory address.
*)
BEGIN
 PutWordL(base,offset+2,value DIV 10000H); PutWordL(base,offset,value MOD 10000H);
END PutLongL;

PROCEDURE GetByte(base:ADDRESS; offset:LONGINT):SHORTCARD;
(* Read a byte *)
VAR
 tmpPtr:POINTER TO SHORTCARD;
BEGIN
 tmpPtr:=ADDRESS(base+offset); RETURN tmpPtr^;
END GetByte;

PROCEDURE GetWordB(base:ADDRESS; offset:LONGINT):CARDINAL;
(*
 Read a word in big endian fashion, i.e. the most significant
 byte from the lowest memory address.
*)
VAR
 tmp1,tmp2:SHORTCARD;
BEGIN
 tmp1:=GetByte(base,offset); tmp2:=GetByte(base,offset+1);
 RETURN CARDINAL(tmp1)*100H+CARDINAL(tmp2);
END GetWordB;

PROCEDURE GetWordL(base:ADDRESS; offset:LONGINT):CARDINAL;
(*
 Read a word in little endian fashion, i.e. the most significant
 byte from the highest memory address.
*)
VAR
 tmp1,tmp2:SHORTCARD;
BEGIN
 tmp1:=GetByte(base,offset); tmp2:=GetByte(base,offset+1);
 RETURN CARDINAL(tmp2)*100H+CARDINAL(tmp1);
END GetWordL;

PROCEDURE GetLongB(base:ADDRESS; offset:LONGINT):LONGCARD;
(*
 Read a long word in big endian fashion, i.e. the most significant
 byte from the lowest memory address.
*)
VAR
 tmp1,tmp2:CARDINAL;
BEGIN
 tmp1:=GetWordB(base,offset); tmp2:=GetWordB(base,offset+2);
 RETURN LONGCARD(tmp1)*10000H+LONGCARD(tmp2);
END GetLongB;

PROCEDURE GetLongL(base:ADDRESS; offset:LONGINT):LONGCARD;
(*
 Read a long word in little endian fashion, i.e. the most significant
 byte from the highest memory address.
*)
VAR
 tmp1,tmp2:CARDINAL;
BEGIN
 tmp1:=GetWordL(base,offset); tmp2:=GetWordL(base,offset+2);
 RETURN LONGCARD(tmp2)*10000H+LONGCARD(tmp1);
END GetLongL;

END PeekNPoke.
