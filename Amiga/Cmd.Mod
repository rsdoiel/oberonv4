MODULE Cmd;	(** ww 9 Aug 91 **)

	IMPORT Texts, TextFrames, Viewers, Oberon, Display;

	VAR
		STrack-, UTrack-, Bottom-, Top-: INTEGER;
		w: Texts.Writer; Par: Oberon.ParList;

	PROCEDURE Call*(name, par: ARRAY OF CHAR; VAR res: INTEGER);
		VAR t: Texts.Text; i: INTEGER;
	BEGIN i := 0;
		WHILE (i < LEN(par)) & (par[i] # 0X) DO
			IF par[i] # "'" THEN Texts.Write(w, par[i]); INC(i)
			ELSE INC(i);
				IF (i < LEN(par)) & (par[i] = "'") THEN INC(i); Texts.Write(w, "'") ELSE Texts.Write(w, 22X) END
			END
		END;
		t := TextFrames.Text(""); Texts.WriteLn(w); Texts.Append(t, w.buf);
		Par.text := t; Par.pos := 0;
		Oberon.Call(name, Par, FALSE, res)
	END Call;

	PROCEDURE OpenSTrack*;
	BEGIN Oberon.OpenTrack(Oberon.SystemTrack(Oberon.Par.vwr.X), 0)
	END OpenSTrack;

	PROCEDURE OpenUTrack*;
	BEGIN Oberon.OpenTrack(Oberon.UserTrack(Oberon.Par.vwr.X), 0)
	END OpenUTrack;

	PROCEDURE OpenWTrack*;
	BEGIN Oberon.OpenTrack(Oberon.UserTrack(Oberon.Par.vwr.X), Display.Width)
	END OpenWTrack;

	PROCEDURE CloseSTrack*;
	BEGIN Viewers.CloseTrack(Oberon.SystemTrack(Oberon.Par.vwr.X))
	END CloseSTrack;

	PROCEDURE CloseUTrack*;
	BEGIN Viewers.CloseTrack(Oberon.UserTrack(Oberon.Par.vwr.X))
	END CloseUTrack;

	PROCEDURE Pick*;
		VAR v: Viewers.Viewer;
	BEGIN v := Oberon.MarkedViewer();
		Texts.WriteInt(w, v.X, 9); Texts.WriteInt(w, v.Y + v.H, 9); Texts.WriteLn(w); Texts.Append(Oberon.Log, w.buf)
	END Pick;

	PROCEDURE PickFrames*;
		VAR v: Viewers.Viewer; f: Display.Frame;

		PROCEDURE Print;
		BEGIN
			Texts.WriteInt(w, f.X, 5); Texts.WriteInt(w, f.Y, 5);
			Texts.WriteInt(w, f.W, 5); Texts.WriteInt(w, f.H, 5); Texts.WriteLn(w)
		END Print;

	BEGIN
		v := Oberon.MarkedViewer(); f := v; Texts.WriteString(w, "MenuViewer: "); Print;
		f := v.dsc; Texts.WriteString(w, "MenuFrame: "); Print;
		f := v.dsc.next; Texts.WriteString(w, "MainFrame: "); Print;
		Texts.Append(Oberon.Log, w.buf)
	END PickFrames;

	PROCEDURE Mark*(x, y: INTEGER);
	BEGIN Oberon.DrawCursor(Oberon.Pointer, Oberon.Star, x, y)
	END Mark;

BEGIN
	Texts.OpenWriter(w);
	STrack := Oberon.SystemTrack(Display.Left); UTrack := Oberon.UserTrack(Display.Left);
	Bottom := Display.Bottom; Top := Bottom + Display.Height;
	NEW(Par); Par.frame := Viewers.This(STrack, Bottom)
END Cmd.

Cmd.PickFrames
