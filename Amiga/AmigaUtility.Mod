MODULE AmigaUtility;

CONST
 user*=80000000H; done*=0;

TYPE
 TagItem*=RECORD
  tag*,data*:LONGINT;
 END;
 TagItemPtr*=LONGINT;

BEGIN
 (* Currently no procedures exported, so no need to open library. *)
END AmigaUtility.



