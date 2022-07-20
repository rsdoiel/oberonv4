/*------------------------------------------------------
 * Oberon Boot File Loader RC, JS 27.4.93/2.12.93, HP-UX 9.0 Version
 *
 * Oberon Boot File Loader for Linux
 * derived from HP and Windows Boot Loader
 * MAD, 23.05.94
 * PR,  01.02.95  support for sockets added
 * PR,  05.02.95  support for V24 added
 * PR,  23.12.95  migration to shared ELF libraries
 * RLI, 22.08.96  added some math primitives
 * RLI, 27.01.97  included pixmap
 * RLI, 13.10.97  changed name of Fontmap - File
 * RLI, 03.11.99  adaptions for glibc2.1
 *
 * Compilieren: gcc -o oberon linuxboot.c -ldl
 *-----------------------------------------------------------*/

#define _LINUX_SOURCE
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <sys/stat.h>
#include <setjmp.h>
#include <math.h>		/* RLI */
#include "oberon.xpm"

typedef void (*Proc)();
typedef int LONGINT;
FILE *fd;
char *OBERON, *SHLPATH;
char path[4096];
char *dirs[255];
char fullname[512];
int nofdir;
char defaultpath[] = ".:/usr/local/Oberon:/usr/local/Oberon/.Fonts";
char defaultshlpath[] = "/lib /usr/lib /usr/lib/X11 /usr/lib/X386";
char mod[64] = "Oberon", cmd[64] =  "Loop";
char dispname[64] = "";
char bootname[64] = "LinuxOberon.Boot";
char geometry[64] = "";
char fontname[64] = "Font.Map";	            /* Default map file */
int debugOn = 0;
int heapSize, heapAdr;
int Argc, coption;
char **Argv;


int dl_open(char *lib, int mode)
/* mode is ignored since glibc2.1 returns error otherwise */
{
  void *handle;

  if ((handle = dlopen(lib, RTLD_NOW)) == NULL) {
    printf("Error! Could not open Library %s in mode %d\n%s\n", lib, mode, dlerror()); exit(-1);
  }

  return (int)handle;
}

int dl_close(int handle)	/* not necessary */
{
  dlclose((void *)handle);
}

int dl_sym(int handle, char *symbol, int *adr)
{
  int res;
  
  if (strcmp("dlopen", symbol) == 0) *adr = (int)dl_open;
  else if (strcmp("dlclose", symbol) == 0) *adr = (int)dl_close;
/*  else if (strcmp("setjmp", symbol) == 0) *adr = (int)_setjmp;  */
  else if (strcmp("mknod", symbol) == 0) *adr = (int)mknod;
  else if (strcmp("stat", symbol) == 0) *adr = (int)stat;
  else if (strcmp("lstat", symbol) == 0) *adr = (int)lstat;
  else if (strcmp("fstat", symbol) == 0) *adr = (int)fstat;
  
  else if (strcmp("heapAdr", symbol) == 0) *adr = heapAdr;
  else if (strcmp("heapSize", symbol) == 0) *adr = heapSize;
/*	else if (strcmp("bootnameadr", symbol) == 0) *adr = (int)bootname;
 */	else if (strcmp("modPtr", symbol) == 0) *adr = (int)mod;
  else if (strcmp("cmdPtr", symbol) == 0) *adr = (int)cmd;
  else if (strcmp("fontnameadr", symbol) == 0) *adr = (int)fontname;
  else if (strcmp("dispnameadr", symbol) == 0) *adr = (int)dispname;
  else if (strcmp("geometryadr", symbol) == 0) *adr = (int)geometry;
  else if (strcmp("debugOn", symbol) == 0) *adr = (int)debugOn;
  else if (strcmp("defaultFont", symbol) == 0) *adr = (int)fontname;
  
  else if (strcmp("coption", symbol) == 0) *adr = coption;
  
  else if (strcmp("argc", symbol) == 0) *adr = Argc;
  else if (strcmp("argv", symbol) == 0) *adr = (int)Argv;
  else if (strcmp("errno", symbol) == 0) *adr = (int)&errno;
  else if (strcmp("OBERON", symbol) == 0) *adr = (int)OBERON;
  else if (strcmp("SHLPATH", symbol) == 0) *adr = (int)SHLPATH;
  else if (strcmp("exit", symbol) == 0) *adr = (int)exit;
  /* Math.Mod stuff -- added by RLI */  
  else if (strcmp("sin", symbol) == 0) *adr = (int)sin;
  else if (strcmp("cos", symbol) == 0) *adr = (int)cos;
  else if (strcmp("log", symbol) == 0) *adr = (int)log;
  else if (strcmp("atan", symbol) == 0) *adr = (int)atan;
  else if (strcmp("exp", symbol) == 0) *adr = (int)exp;
  else if (strcmp("sqrt", symbol) == 0) *adr = (int)sqrt;
  else if (strcmp("oberonPixmap", symbol) == 0) *adr = (int)oberonPixmap;
  else {
    *adr = (int)dlsym((void *) handle, symbol);
    if (*adr == 0) {
      printf("symbol %s not found\n", symbol); exit(-1);
    }
  }
}


/*----- Files Reading primitives -----*/

int Rint() 

{
  unsigned char b[4];
  /*
     b[3] = fgetc(fd); b[2] = fgetc(fd); b[1] = fgetc(fd); b[0] = fgetc(fd);
     */
  /* little endian machine reading little endian integer */
  b[0] = fgetc(fd); b[1] = fgetc(fd); b[2] = fgetc(fd); b[3] = fgetc(fd);
  return *((int *) b);
}

int RNum()
{
  int n, shift;
  unsigned char x;
  shift = 0; n = 0; x = fgetc(fd);
  while (x >= 128) {
    n += (x & 0x7f) << shift;
    shift += 7;
    x = fgetc(fd);
  }
  return n + (((x & 0x3f) - ((x >> 6) << 6)) << shift);
}
	
void Relocate(int heapAdr, int shift)
{
  LONGINT len, adr; 
  
  len = RNum(); 
  while (len != 0) { 
    adr = RNum(); 
    adr += heapAdr; 
    *((LONGINT *)adr) += shift; 
    len--; 
  } 
}

void Boot()
{
  int i, adr, val, len, shift1, d, notfound, fileHeapAdr, fileHeapSize,  
  dlsymAdr;
  Proc body;

  d = 0; notfound = 1;
  while ((d < nofdir) && notfound) {
    strcat(strcat(strcpy(fullname, dirs[d++]), "/"), bootname);
    fd = fopen(fullname, "r");
    if (fd != NULL) notfound = 0;
  }
  if (notfound) {
    printf("oberon: boot file %s not found\n", bootname);  
    exit(-1);
  }
  fileHeapAdr = Rint(); fileHeapSize = Rint();
  if (fileHeapSize >= heapSize) {
    printf("oberon: heap too small\n");  
    exit(-1);
  }
  d = heapAdr; i = fileHeapSize + 32; 
  while (i > 0) { 
    *((LONGINT *) d) = 0; 
    i -= 4; d += 4; 
  } 
  shift1 = heapAdr - fileHeapAdr;
  adr = Rint(); len = Rint();
  while (len != 0) {
    adr += shift1;
    len += adr;
    while (adr != len) { *((int *) adr) = Rint(); adr += 4; }
    adr = Rint(); len = Rint();
  }
  body = (Proc)(adr + shift1);
  Relocate(heapAdr, shift1);
  dlsymAdr = Rint();
  *((LONGINT *)(heapAdr + dlsymAdr)) = (LONGINT)dl_sym;
  fclose(fd);
  (*body)();
}

InitPath()
{
  int pos;
  char ch;
  
  if ((OBERON = getenv("OBERON")) == NULL) OBERON = defaultpath;
  strcpy(path, OBERON);
  pos = 0; nofdir = 0;
  ch = path[pos++];
  while (ch != '\0') {
    while ((ch == ' ') || (ch == ':')) ch = path[pos++];
    dirs[nofdir] = &path[pos-1];
    while ((ch > ' ') && (ch != ':')) ch = path[pos++];
    path[pos-1] = '\0';
    nofdir ++;
  }
  if ((SHLPATH = getenv("SHLPATH")) == NULL) SHLPATH = defaultshlpath;
}

void doexit(int ret, void *arg)
{
  _exit(ret);
}

main(int argc, char *argv[])
{
  int res, c;
  
  
  on_exit(doexit, NULL);
  
  heapSize = 4; Argc = argc; Argv = argv; coption = 0;
  while (--argc > 0 && (*++argv)[0] == '-') {
    c = *++argv[0];
    switch (c) {
    case 'h':
      if (--argc > 0) {
	sscanf(*++argv, "%d", &heapSize);  
	if (heapSize < 1) heapSize = 1;
      }
      break;
    case 'x':
      if ((argc -= 2) > 0) {
	sscanf(*++argv, "%s", mod);  
	sscanf(*++argv, "%s", cmd);
      }
      break;
    case 'b':
      if (--argc > 0) {
	sscanf(*++argv, "%s", bootname);
      }  
      break;
    case 'f': 
      if (--argc > 0) {
	sscanf(*++argv, "%s", fontname);
      }  
      break;
    case 'd': 
      if (--argc > 0) {
	sscanf(*++argv, "%s", dispname);
      }  
      break;
    case 'g': 
      if (--argc > 0) {
	sscanf(*++argv, "%s", geometry);
      }  
      break;
    case 'c':
      coption = 1;
      break;
    default:
      printf("oberon: illegal option %c\n", c);
      argc = -1;
      break;
    }
  }
  if (argc != 0) {
    printf("Usage: oberon [-h heapsizeinMB] [-x module command] [-b bootfile]\n");
    printf("              [-f fontmapfile] [-d displayname] [-g geometry] [-c]\n");
    exit(-1);
  }
  /*----- heap space allocation -----*/
  heapSize *= 0x100000;
  heapAdr = (int) malloc(heapSize);
  if (heapAdr == 0) {
    printf("oberon: cannot allocate heap space\n");  
    exit(-1);
  }
  heapSize -= (-heapAdr) & 0x1f;
  heapAdr += (-heapAdr) & 0x1f;
  /* printf("heap at 0x%x\n", heapAdr); */
  /*----- Initialisation -----*/
  InitPath();
  /*----- Boot -----*/
  Boot();
}










