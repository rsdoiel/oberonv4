Table of Contents
=================

Oberon Public Domain Software
-----------------------------

The following software is available in source code from our department. All modules are written in Oberon-2 and usually run on all implementations of the ETH Oberon System. If a module is specific to the PowerMac Oberon implementation this is explicitly mentioned. The source modules are encoded with the AsciiCoder tool available under Oberon. Follow the link from a module name to the encoded source and copy the whole file to your Oberon System. Middle-click at the heading line (AsciiCoder.DecodeFiles) to decode the source. Then compile it.

### Packages

+ [Coco/R](Coco.Cod) generates a scanner and a recursive descent parser from an attributed grammar.
+ [Dialogs](DFiles) A graphical user interface for Oberon V4 [MK](mailto:knasmueller@ssw.uni-linz.ac.at
+ [Kepler](Kepler.Cod) > An object oriented graphics editor
+ [FileManager](FileManager.Cod) A graphically oriented file manager
+ [FTP](FTP.Cod) A graphically oriented ftp client (requires [FileManager](FileManager.Cod)
+ [ODBC](ODBC.Cod) A package for accessing ODBC databases from Oberon programs ([CS](mailto:steindl@ssw.uni-linz.ac.at).
+ [NewNews](NetNews.Cod) A comfortable NetNews reader ([PH](mailto:k3085e0@c210.edvz.uni-linz.ac.at)
+ [HeapInspector](HeapInspector.Cod) A tool to inspect the heap and other run-time data structures ([MR](mailto:k3073e6@c210.edvz.uni-linz.ac.at)

### Tools

+ [Backup](Backup.Cod) incremental backup of Macintosh directories ([HM](mailto:moessenboeck@ssw.uni-linz.ac.at)
+ [Batch](Batch.Cod) introduces basic batch facilities ([mah](mailto:hof@ssw.uni-linz.ac.at)
+ [Beautifier](Beautifier.Cod) formats your Oberon-2 code ([Description](http://sport1.uibk.ac.at/tanis/beautifier.html)) ([MK](mailto:knasmueller@ssw.uni-linz.ac.at)
+ [Class](Class.Cod) extracts Oberon-2 class interfaces from a source module ([HM](mailto:moessenboeck@ssw.uni-linz.ac.at)
+ [Count](Count.Cod) counts lines, statements and characters in an Oberon-2 module ([HM](mailto:moessenboeck@ssw.uni-linz.ac.at)
+ [Find](Find.Cod) compares files; lists all lines containing a certain pattern; lists clients and imports of a module; searches files for attributes in InfoElems (PowerMac Oberon only) ([HM](mailto:moessenboeck@ssw.uni-linz.ac.at).
+ [Folds](Folds.Cod) allows compilation of folded texts; sets and searches for error markers in the compiled text ([HM](mailto:moessenboeck@ssw.uni-linz.ac.at).
+ [Lines](Lines.Cod) extracts lines containing a specified pattern from a text ([HM](mailto:moessenboeck@ssw.uni-linz.ac.at).
+ [Make](Make.Cod) topologically sorts a set of Oberon source file names according to their import relationship ([HM](mailto:moessenboeck@ssw.uni-linz.ac.at).
+ [Packager](Packager.Cod) packages several object files into one compound object file that is loaded as one (thereby saving time; PowerMac Oberon only) ([CS](mailto:steindl@ssw.uni-linz.ac.at).
+ [Profiler](Profiler.Cod) instruments source programs by inserting counters and timers ([MK](mailto:knasmueller@ssw.uni-linz.ac.at)
+ [RandomNumbers](RandomNumbers.Cod) calculates a random number ([MK](mailto:knasmueller@ssw.uni-linz.ac.at).
+ [Screen](Screen.Cod) switches between a one-track and a two-track screen ([HM](mailto:moessenboeck@ssw.uni-linz.ac.at).
+ [Statistics](Statistics.Cod) implements some statistical distributions ([CS](mailto:steindl@ssw.uni-linz.ac.at).
+ [StringSearch](StringSearch.Cod) implements some popular string search algorithms ([CS](mailto:steindl@ssw.uni-linz.ac.at).
+ [ToDo](ToDo.Cod) helps to schedule activities and meet deadlines ([HM](mailto:moessenboeck@ssw.uni-linz.ac.at).
+ [Trace](Trace.Cod) provides a list of trace switches that can be set/reset with commands ([HM](mailto:moessenboeck@ssw.uni-linz.ac.at).
 +[VCS](VCS.Cod) is a version control system for text files ([HM](mailto:moessenboeck@ssw.uni-linz.ac.at).
+ [Xref](Xref.Cod) generates a cross reference list for Oberon-2 programs ([HM](mailto:moessenboeck@ssw.uni-linz.ac.at).

### Utility Modules

+ [MoreMathL](MoreMathL.Cod) implements some additional mathematical functions (hyperbolic, trigonometric and inverse functions) ([CS](mailto:steindl@ssw.uni-linz.ac.at).
+ [Strings](Strings.Cod) provides string operations which are not supported by the Oberon-2 language ([HM](mailto:moessenboeck@ssw.uni-linz.ac.at).
+ [Timer](Timer.Cod) provides time measurements of programs ([HM](mailto:moessenboeck@ssw.uni-linz.ac.at).
+ [XIn](XIn.Cod) offers some (now and then) used functions to read in parameters ([CS](mailto:steindl@ssw.uni-linz.ac.at).

### Text Elements

For a documentation of the text elements click [Elem.Guide](Elem.Guide.Cod)h[here](Elem.Guide.Cod). Note that some elements need our extended version of Popup elements from below (not the one from the original Oberon system).

+ [Auto menu elements](AutoMenuElems.Cod)search (when the text is loaded) for AutoMenuElems throughout the text and add these to its menu (needs Handler elements) ([mah](mailto:hof@ssw.uni-linz.ac.at).
+ [Ballon elements](BalloonElems.Cod) offer balloon help (i.e., popup explanations) in texts ([HM](mailto:moessenboeck@ssw.uni-linz.ac.at).
+ [Clock elements](ClockElems.Cod) display the current time (original author: R. Griesemer, ETH Zurich).
+ [Directory elements](DirElems.Cod) allow a user to conveniently switch between working directories ([HM](mailto:moessenboeck@ssw.uni-linz.ac.at).
+ [Fold elements](FoldElems.Cod) can be used to partially and hierarchically fold texts ([HM](mailto:moessenboeck@ssw.uni-linz.ac.at).
+ [Font elements](FontElems.Cod) allow a user to conveniently set the font family, font size and font style of a piece of text ([HM](mailto:moessenboeck@ssw.uni-linz.ac.at).
+ [Handler elements](HandlerElems.Cod) install a custom handler in the viewer's contents frame ([HM](mailto:moessenboeck@ssw.uni-linz.ac.at).
+ [Index elements](IndexElems.Cod) mark a text position which may be used as the target of hypertext links (LinkElems) or as bookmarks. Additionally index elements can automatically create an index of the corresponding text ([mah](mailto:hof@ssw.uni-linz.ac.at).
+ [Info elements](InfoElems.Cod) contain additional information about the text (author, date of creation,...) in which the element is inserted ([CS](mailto:steindl@ssw.uni-linz.ac.at).
+ [Kepler links](KeplerLinks.Cod) allow setting a link from a text to a Kepler graphic and vice versa ([HM](mailto:moessenboeck@ssw.uni-linz.ac.at).
 "ftp://oberon.ssw.uni-linz.ac.at/pub/Oberon/LinzTools/LinkElems.Cod">Link elements</A> represent a hypertext link to a mark element (MarkElems) (<A HREF = "mailto:moessenboeck@ssw.uni-linz.ac.at">HM</A>).</LI>
+ [Mac Picture elements](MacPicElems.Cod) insert PICT graphics from the clipboard into your text (PowerMac Oberon only) ([HM](mailto:moessenboeck@ssw.uni-linz.ac.at).
+ [Mark elements](MarkElems.Cod) see link elements ([HM](mailto:moessenboeck@ssw.uni-linz.ac.at).
+ [Open elements](OpenElems.Cod) perform a generic open command on the selected item. Depending on the suffix of the item different commands are called. The name (e.g. * or *.Mod) of an OpenElem is taken as a pattern to collect all matching files in the current directory ([CS](mailto:steindl@ssw.uni-linz.ac.at).
+ [Popup elements](PopupElems.Cod) respond to a middle mouse click by showing a text of lines (a popup menu). Extended version (original author: M. Franz, ETH Zurich) ([HM](mailto:moessenboeck@ssw.uni-linz.ac.at).
+ [SectionLinkElems](SectionLinkElems.Cod) represents a hyptertext link to a section of a report ([MK](mailto:knasmueller@ssw.uni-linz.ac.at)
+ [Tree elements](TreeElems.Cod) extension of the Popup elemements which - located in a menu - analyzes the Oberon module in the corresponding window and shows - in its popup - a tree-like representation of the module's structure. By selecting a shown name, the source code is scrolled to the name's definition position. ([mah](mailto:hof@ssw.uni-linz.ac.at).
+ [Version elements](VersionElems.Cod) allow a user to maintain multiple versions of a module in the same file. Similar to conditional compilation, but language independent ([HM](mailto:moessenboeck@ssw.uni-linz.ac.at).

### Miscellaneous Examples

+[CrazyFiller](CrazyFiller.Cod) draws a Mandelbrot set into the filler viewer ([CS](mailto:steindl@ssw.uni-linz.ac.at).
+[TravelingSalesman](TravelingSalesman.Cod) a solution for this problem ([MK]("mailto:knasmueller@ssw.uni-linz.ac.at).
+ [Calendar](Calendar.Cod) a calendar showing a year with its weeks ([mah](mailto:hof@ssw.uni-linz.ac.at).

### Documentation

+[Prog.Guide.Text](Prog.Guide.Cod) is an Oberon hypertext document that shows examples of many frequent programming tasks under Oberon.
+ [Elem.Guide.Text](Elem.Guide.Cod) is an Oberon document that explains how to use text elements.
+ [Balloon.Text](Balloon.Cod) is the global dictionary used by BalloonElems. It contains short descriptions of most types and procedures of the Oberon system. Might be worth studying also without BalloonElems.
+ [Reference Card](Reference.ps). This postscript document is a reference card with the most frequently used commands of the Oberon system.

