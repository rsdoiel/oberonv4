MODULE AmigaInputEvent;

IMPORT e := AmigaExec, t := AmigaTimer;

CONST
  null           * = 00H; (* A NOP input event                              *)
  rawkey         * = 01H; (* A raw keycode from the keyboard device         *)
  rawmouse       * = 02H; (* The raw mouse report from the game port        *
                           * device                                         *)
  event          * = 03H; (* A private console event                        *)
  pointerpos     * = 04H; (* A Pointer Position report                      *)
  timer          * = 06H; (* A timer event                                  *)
  gadgetdown     * = 07H; (* select button pressed down over a Gadget       *
                           * (address in ie_EventAddress)                   *)
  gadgetup       * = 08H; (* select button released over the same Gadget    *
                           * (address in ie_EventAddress)                   *)
  requester      * = 09H; (* some Requester activity has taken place.  See  *
                           * Codes REQCLEAR and REQSET                      *)
  menulist       * = 0AH; (* this is a Menu Number transmission (Menu       *
                           * number is in ie_Code)                          *)
  closewindow    * = 0BH; (* User has selected the active Window's Close    *
                           * Gadget                                         *)
  sizewindow     * = 0CH; (* this Window has a new size                     *)
  refreshwindow  * = 0DH; (* the Window pointed to by ie_EventAddress needs *
                           * to be refreshed                                *)
  newprefs       * = 0EH; (* new preferences are available                  *)
  diskremoved    * = 0FH; (* the disk has been removed                      *)
  diskinserted   * = 10H; (* the disk has been inserted                     *)
  activewindow   * = 11H; (* the window is about to be been made active     *)
  inactivewindow * = 12H; (* the window is about to be made inactive        *)
  newpointerpos  * = 13H; (* extended-function pointer position report      *
                           * (V36)                                          *)
  menuhelp       * = 14H; (* Help key report during Menu session (V36)      *)
  changewindow   * = 15H; (* the Window has been modified with move, size,  *
                           * zoom, or change (V36)                          *)

  classMax       * = 15H; (* the last class                                 *)


(*  --- InputEvent.subClass --- *)
(*  newpointerpos *)
(*      like pointerpos *)
  compatible   * = 00H;
(*      InputEvent.eventAddress points to struct IEPointerPixel *)
  pixel        * = 01H;
(*      InputEvent.eventAddress points to struct IEPointerTablet *)
  tablet       * = 02H;

CONST

(*  --- InputEvent.ie_Code --- *)
(*  IECLASS_RAWKEY *)
  upPrefix             * = 080H;
  keyCodeFirst         * = 000H;
  keyCodeLast          * = 077H;
  commCodeFirst        * = 078H;
  commCodeLast         * = 07FH;

(*  IECLASS_ANSI *)
  c0First              * = 000H;
  c0Last               * = 01FH;
  asciiFirst           * = 020H;
  asciiLast            * = 07EH;
  asciiDel             * = 07FH;
  c1First              * = 080H;
  c1Last               * = 09FH;
  latin1First          * = 0A0H;
  latin1Last           * = 0FFH;

(*  IECLASS_RAWMOUSE *)
  lButton              * = 068H;  (* also uses IECODE_UP_PREFIX *)
  rButton              * = 069H;
  mButton              * = 06AH;
  noButton             * = 0FFH;

(*  IECLASS_EVENT (V36) *)
  newActive            * = 001H;  (* new active input window *)
  newSize              * = 002H;  (* resize of window *)
  refresh              * = 003H;  (* refresh of window *)

(*  IECLASS_REQUESTER *)
(*      broadcast when the first Requester (not subsequent ones) opens up in *)
(*      the Window *)
  reqSet               * = 001H;
(*      broadcast when the last Requester clears out of the Window *)
  reqClear             * = 000H;



(*  --- InputEvent.qualifier --- *)

  lShift         * = 0;
  rShift         * = 1;
  capsLock       * = 2;
  control        * = 3;
  lAlt           * = 4;
  rAlt           * = 5;
  lCommand       * = 6;
  rCommand       * = 7;
  numericPad     * = 8;
  repeat         * = 9;
  interrupt      * = 10;
  multiBroadCast * = 11;
  midButton      * = 12;
  rightButton    * = 13;
  leftButton     * = 14;
  relativeMouse  * = 15;

TYPE

(*----- InputEvent -------------------------------------------------*)

  InputEventPtr * = POINTER TO InputEvent;
  InputEvent * = RECORD
    nextEvent * : InputEventPtr;   (* the chronologically next event *)
    class * : SHORTINT;            (* the input event class *)
    subClass * : SHORTINT;         (* optional subclass of the class *)
    code * : INTEGER;              (* the input event code *)
    qualifier * : INTEGER;             (* qualifiers in effect for the event*)
    x*: INTEGER;                   (* the pointer position for the event*)
    y*: INTEGER;
    timeStamp * : t.TimeVal;       (* the system tick at the event *)
  END;
  InputEventAdrPtr * = POINTER TO InputEventAdr;
  InputEventAdr * = RECORD
    nextEvent * : InputEventAdrPtr;(* the chronologically next event *)
    class * : SHORTINT;            (* the input event class *)
    subClass * : SHORTINT;         (* optional subclass of the class *)
    code * : INTEGER;              (* the input event code *)
    qualifier * : INTEGER;             (* qualifiers in effect for the event*)
    addr *: LONGINT;                (* the event address *)
    timeStamp * : t.TimeVal;       (* the system tick at the event *)
  END;
  InputEventPrevPtr * = POINTER TO InputEventPrev;
  InputEventPrev * = RECORD
    nextEvent * : InputEventPrevPtr;(* the chronologically next event *)
    class * : SHORTINT;            (* the input event class *)
    subClass * : SHORTINT;         (* optional subclass of the class *)
    code * : INTEGER;              (* the input event code *)
    qualifier * : INTEGER;             (* qualifiers in effect for the event*)
    prev1DownCode * : SHORTINT;    (* previous down keys for dead *)
    prev1DownQual * : SHORTINT;    (*   key translation: the ie_Code *)
    prev2DownCode * : SHORTINT;    (*   & low byte of ie_Qualifier for *)
    prev2DownQual * : SHORTINT;    (*   last & second last down keys *)
    timeStamp * : t.TimeVal;       (* the system tick at the event *)
  END;

END AmigaInputEvent.

