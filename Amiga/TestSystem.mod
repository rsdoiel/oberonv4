(* Test System Configuration by Ralf Degner *)
(* written with AmigaObeon 3.2   29.03.1996 *)

MODULE TestSystem;

IMPORT Exec, a: Arguments;

VAR Str: ARRAY 8 OF CHAR;

BEGIN
  a.GetArg(1, Str);
  IF a.NumArgs()=1 THEN
    CASE Str[0] OF
      "C" : IF NOT(Exec.m68020 IN Exec.SysBase.attnFlags) THEN (* CPU *)
              HALT(5)
            END
    | "F" : IF NOT(Exec.m68881 IN Exec.SysBase.attnFlags) THEN (* FPU *)
              HALT(5)
            END
    | "M" : IF Exec.AvailMem(LONGSET{}) < 1258291 THEN (* Memory *)
              HALT(5)
            END
    | "O" : IF Exec.SysBase.libNode.version < 36 THEN (* OS *)
              HALT(5)
            END
    END;
  ELSE
    HALT(10);
  END;
END TestSystem.
