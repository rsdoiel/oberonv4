package ch.claudio.oberon;

import java.io.IOException;
import java.io.InputStream;
import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;
import java.util.Comparator;
import java.util.Map;
import java.util.SortedSet;
import java.util.TreeMap;
import java.util.TreeSet;
import java.util.Map.Entry;

import org.apache.commons.io.IOUtils;
import org.apache.commons.lang3.StringEscapeUtils;
import org.apache.commons.lang3.text.translate.CharSequenceTranslator;
import org.apache.commons.lang3.text.translate.NumericEntityEscaper;

/**
 * @author <a href="mailto:private@claudio.ch">Claudio Nieder</a>
 *         <p>
 *         Copyright (C) 2013 Claudio Nieder &lt;private@claudio.ch&gt;, CH-8610
 *         Uster
 *         </p>
 *         <p>
 *         This program is free software: you can redistribute it and/or modify
 *         it under the terms of the GNU Affero General Public License as
 *         published by the Free Software Foundation, version 3 of the License.
 *         </p>
 *         <p>
 *         This program is distributed in the hope that it will be useful, but
 *         WITHOUT ANY WARRANTY; without even the implied warranty of
 *         MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 *         Affero General Public License for more details.
 *         </p>
 *         <p>
 *         You should have received a copy of the GNU Affero General Public
 *         License along with this program. If not, see <http:if
 *         (debug)www.gnu.org/licenses/>.
 *         </p>
 */
public class OberonFilter
{
 /**
  * Copyright notice and startup checks.
  */
 static {
  System.setProperty("file.encoding","UTF-8");
  System.setProperty("sun.jnu.encoding","UTF-8");
  if (!OberonFilter.class.desiredAssertionStatus()) {
   System.err.println("ATTENTION: Assertions disabled for "
     +OberonFilter.class.getName()+".");
   System.exit(1);
  }
 }

 /**
  * set to true to generate a lot of debug statements.
  */
 private static final boolean debug=false;

 /**
  * Describe usage of command.
  */
 private static final String usageString=
   "oberon {-nopos|-plain} <input >output"
     +"\n\nCopyright (C) 2013 Claudio Nieder <private@claudio.ch>, CH-8610 Uster\n"
     +"\nThis program is free software: you can redistribute it and/or modify"
     +"\nit under the terms of the GNU Affero General Public License as published by"
     +"\nthe Free Software Foundation, version 3 of the License.\n"
     +"\nThis program is distributed in the hope that it will be useful,"
     +"\nbut WITHOUT ANY WARRANTY; without even the implied warranty of"
     +"\nMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the"
     +"\nGNU Affero General Public License for more details.\n"
     +"\nYou should have received a copy of the GNU Affero General Public License"
     +"\nalong with this program.  If not, see <http:if (debug)www.gnu.org/licenses/>.\n";

 /**
  * Read a fixed ISO8859-1 STring from input stream.
  * 
  * @param in stream
  * @param len string length
  * @return string
  * @throws IOException on read errors.
  */
 private static String getAscii(final InputStream in,final int len)
   throws IOException
 {
  final byte[] b=new byte[len];
  int off=0;
  while (off<len) {
   final int n=in.read(b,off,len-off);
   off+=n;
  }
  return new String(b,0,len,StandardCharsets.ISO_8859_1);
 }

 /**
  * Read zero terminated ISO8859-1 string from input stream.
  * 
  * @param in stream
  * @return string
  * @throws IOException on read errors.
  */
 private static String getAscii0(final InputStream in) throws IOException
 {
  final StringBuilder sb=new StringBuilder();
  int b=in.read();
  while (b>0) {
   sb.append((char)b);
   b=in.read();
  }
  return sb.toString();
 }

 /**
  * Read a two byte little endian value from input stream.
  * 
  * @param in stream
  * @return 16 bit unsigned value
  * @throws IOException on read errors.
  */
 private static int get2u(final InputStream in) throws IOException
 {
  int value=(in.read()&0xff);
  value|=(in.read()&0xff)<<8;
  return value;
 }

 /**
  * Read a four byte little endian value from input stream.
  * 
  * @param in stream
  * @return 16 bit value
  * @throws IOException on read errors.
  */
 private static int get4(final InputStream in) throws IOException
 {
  int value=get2u(in);
  value|=(get2u(in)<<16);
  return value;
 }

 /**
  * Convert a byte array to a stream of hex digits.
  * 
  * @param bytes to convert
  * @return string of hex digits.
  */
 private static String bytesToHex(final byte[] bytes)
 {
  if (bytes!=null) {
   final StringBuilder sb=new StringBuilder(bytes.length*2);
   for (final byte b:bytes) {
    sb.append(String.format("%02x",Integer.valueOf(b&0xff)));
   }
   return sb.toString();
  }
  return null;
 }

 /**
  * Filter which reads an Oberon Text-file and writes out either an XML
  * representation of its content or a stripped plain text version of the
  * content.
  * <p>
  * Note: There are some assert statements that could be triggered if the input
  * file has no proper tag (0xF001) or the InputStream does not deliver the
  * requested number of byte.
  * </p>
  * 
  * @param textOnly if true just copy the input to the output skipping the
  *         header and transforming CR into NL.
  * @param nopos if true suppresses position information in tag. This may be
  *         useful if output is used to compare two files.
  * @param in Oberon Test file
  * @param out {@link PrintWriter}
  * @throws IOException on read or write errors.
  */
 public static void oberonToXML(final boolean textOnly,final boolean nopos,
   final InputStream in,final PrintWriter out) throws IOException
 {
  class Piece
  {
   int col;

   int font=-1;

   int voff;

   int pos;

   int len=1;

   int element=-1;

   int width=0;

   int height=0;

   byte[] elementData=null;
  }
  final int tag=in.read();
  final int version=in.read();
  assert ((tag==0xF0)&&(version==0x01))||((tag==0x01)&&(version==0xF0));
  final int headLen=get4(in);
  if (textOnly) {
   IOUtils.skip(in,headLen-6);
   int ch=in.read();
   while (ch>=0) {
    if (ch=='\r') {
     out.println();
    } else if ((ch=='\t')||(ch>=' ')) {
     out.print((char)ch);
    }
    ch=in.read();
   }
  } else {
   final Map<Integer,String> elementMap=new TreeMap<>();
   final Map<Integer,String> fontMap=new TreeMap<>();
   int elementCount=0;
   int fontCount=0;
   final SortedSet<Piece> pieceList=new TreeSet<>(new Comparator<Piece>() {
    @Override
    public int compare(final Piece p1,final Piece p2)
    {
     return Integer.compare(p1.pos,p2.pos);
    }
   });
   if (debug) {
    System.out.printf("*File pos=%x%n",Integer.valueOf(6));
   }
   int fontNumber=in.read();
   int filePos=7;
   int pos=headLen;
   while (fontNumber!=0) {
    if (debug) {
     System.out.printf("File pos=%x%n",Integer.valueOf(filePos));
    }
    final Piece piece=new Piece();
    piece.font=fontNumber;
    piece.pos=pos;
    if (fontNumber>fontCount) {
     fontCount=fontNumber;
     final String fontName=getAscii0(in);
     filePos+=fontName.length()+1; // 0 final terminated string
     fontMap.put(Integer.valueOf(fontNumber),fontName);
    }
    if (debug) {
     System.out.printf("File pos=%x%n",Integer.valueOf(filePos));
    }
    piece.col=in.read();
    piece.voff=in.read();
    piece.len=get4(in);
    filePos+=6;
    if (debug) {
     System.out.printf("File pos=%x%n",Integer.valueOf(filePos));
    }
    if (piece.len<=0) { // It's an element
     final int elementDataLength=-piece.len;
     piece.len=1;
     if (debug) {
      System.out.printf("+File pos=%x%n",Integer.valueOf(filePos));
     }
     piece.width=get4(in);
     piece.height=get4(in);
     piece.element=in.read();
     filePos+=9;
     if (debug) {
      System.out.printf("+File pos=%x%n",Integer.valueOf(filePos));
     }
     if (piece.element>elementCount) {
      elementCount=piece.element;
      final String module=getAscii0(in);
      filePos+=module.length()+1; // 0 terminated string
      final String procedure=getAscii0(in);
      filePos+=procedure.length()+1; // 0 terminated string
      if (debug) {
       System.out.printf("-File pos=%x%n",Integer.valueOf(filePos));
      }
      elementMap.put(Integer.valueOf(piece.element),module+"."+procedure);
     }
     final byte[] buf=new byte[elementDataLength];
     assert in.read(buf)==elementDataLength;
     piece.elementData=buf;
     filePos+=elementDataLength;
     if (debug) {
      System.out.printf("-File pos=%x%n",Integer.valueOf(filePos));
     }
    }
    pos+=piece.len;
    pieceList.add(piece);
    if (debug) {
     System.out.printf("*File pos=%x%n",Integer.valueOf(filePos));
    }
    fontNumber=in.read();
    filePos+=1;
   }
   if (debug) {
    System.out.printf("EOH File pos=%x%n",Integer.valueOf(filePos));
   }
   out.println("<text headerLength='"+headLen+"'>");
   for (final Entry<Integer,String> font:fontMap.entrySet()) {
    out.println(" <font id='"+font.getKey().intValue()+"'>"+font.getValue()
      +"</font>");
   }
   for (final Entry<Integer,String> element:elementMap.entrySet()) {
    out.println(" <element id='"+element.getKey().intValue()+"'>"
      +element.getValue()+"</element>");
   }
   final CharSequenceTranslator escaper=
     StringEscapeUtils.ESCAPE_XML.with(NumericEntityEscaper.between(0,8)).with(
       NumericEntityEscaper.between(11,31));
   for (final Piece piece:pieceList) {
    if (filePos<piece.pos) {
     in.skip(piece.pos-filePos);
     filePos=piece.pos;
     if (debug) {
      System.out.printf("File pos=%x%n",Integer.valueOf(filePos));
     }
    }
    final StringBuilder common=new StringBuilder();
    common.append("length='").append(piece.len).append("'");
    if (!nopos) {
     common.append(" pos='").append(piece.pos).append("'");
    }
    common.append(" col='").append(piece.col).append("' voff='")
      .append(piece.voff).append("' font='").append(piece.font).append("'");
    if (piece.elementData!=null) {
     out.println(" <piece element='"+piece.element+"' width='"+piece.width
       +"' height='"+piece.height+"' "+common+">"
       +OberonFilter.bytesToHex(piece.elementData)+"</piece>");
    } else {
     if (debug) {
      System.out.printf("File pos=%x+%x%n",Integer.valueOf(filePos),
        Integer.valueOf(piece.len));
     }
     final String text=
       OberonFilter.getAscii(in,piece.len).replaceAll("\r","\n");
     filePos+=text.length();
     if (debug) {
      System.out.printf("File pos=%x%n",Integer.valueOf(filePos));
     }
     out.println(" <piece "+common+">"+escaper.translate(text)+"</piece>");
    }
   }
   out.println("</text>");
   out.flush();
  }
 }

 /**
  * Filters from STDIN to STDOUT
  * 
  * @param args ignored
  * @throws IOException on read or write errors.
  */
 public static void main(final String[] args) throws IOException
 {
  boolean nopos=false;
  boolean textOnly=false;
  boolean usage=false;
  for (final String arg:args) {
   if (arg.startsWith("-n")) {
    nopos=true;
   } else if (arg.startsWith("-t")) {
    textOnly=true;
   } else {
    usage=true;
   }
  }
  if (usage) {
   System.err.println(usageString);
  } else {
   try (PrintWriter out=new PrintWriter(System.out)) {
    oberonToXML(textOnly,nopos,System.in,out);
   }
  }
 }
}
