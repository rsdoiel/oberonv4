Conversion of Oberon Fonts into X Fonts
--------------------------------

Oberon raster fonts can be converted to a format handled
more efficiently by an X server. The conversion happens in
a sequence of steps and is inherently server dependent.
If you are not familiar with SunOS and/or X-Windows, ask your
system administrator for some support.

1. Convert Oberon fonts into the target independent
bitmap distribution format (bdf) by executing the Oberon command
	FontToBDF.Convert {path} ~
This command accepts an arbitrary number of path names separated by
blanks or <carriage return> and terminated by "~".
The converted files are stored with extension ".bdf" in the current directory.
Use System.Directory to generate a list of font path names, e.g.
	System.Directory /usr/local/Oberon/*.Scn.Fnt

The next steps are to be executed within a Unix shell.

2. Copy the produced *bdf files into a temporary directory on the machine that
runs the X server process. Of course, this and step 3 are only necessary, 
if server and client are runing on different machines.
If the server is a dedicated X-Terminal, ask your system administrator
how to install additional fonts or refer to the X-Terminal specific
documentation.

3. Login on the server machine.

4. Convert the *.bdf files into the native X server format.

	4.1 if using xnews (e.g. for Sun's OpenWindows)
		% convertfont -d myfontdir -f 20 Oberon*.bdf
		% bldfamily -d myfontdir -f 20
		Note that myfontdir must be an absolute path name.

	4.2 on other X servers there are two widely used formats (pcf, snf).
		Use a font converter (e.g. bdftopcf, bdftosnf, dxfc ...)
		to convert the *bdf files into the target format.
		Then create a file that contains the font directory
		(e.g. mkfontdir, dxmkfontdir, ...)
	
		% foreach f (Oberon*bdf)
		%   bdftopcf $f > myfontdir/"`basename $f bdf`pcf"
		% end
		% cd myfontdir
		% mkfontdir

		Note that the commands bdftopcf and mkfontdir are server dependent.
		Each X server, however, is expected to provide equivalent commands.

5. Extend the X fontpath by the new directory.
	% xset +fp myfontdir
	This command can also be entered in the startup script (.xinitrc) of the X server.
	Note that myfontdir must be an absolute path name. On some machines
	it must also be terminated by "/".

6. Remove the *bdf files

7. Restart oberon.
