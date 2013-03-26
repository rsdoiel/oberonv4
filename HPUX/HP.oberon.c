/*------------------------------------------------------
 * Oberon Boot File Loader RC, JS 27.4.93/2.12.93, HP-UX 9.0 Version
 *------------------------------------------------------*/
 
/*---------------------------------------------------------*
 *	Copyright (c) 1990-1996 ETH Z…rich. All Rights Reserved.
 *	Oberon is a trademark of Institut f…r Computersysteme, ETH Z…rich.
 *---------------------------------------------------------*/

#define _HPUX_SOURCE

#include <dl.h>
#include <math.h>
#include <sys/file.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <errno.h>

typedef void (*Proc)();
FILE *fd;
char *OBERON, *SHLPATH;
char path[512];
char *dirs[32];
char fullname[64];
int nofdir;
char defaultpath[] = ". /usr/local/Oberon /usr/local/Oberon/.Fonts";
char defaultshlpath[] = "/lib /usr/lib /usr/lib/X11R5 /usr/lib/X11R4";
char mod[64] = "Oberon", cmd[64] =  "Loop";
char dispname[64] = "";
char bootname[64] = "HPoberon.Boot";
char geometry[64] = "";
char fontname[64] = "";
int heapSize, heapAdr, GCstart;
int millicodeTable[128];	/* millicodeTable[0] = number of entries */
int Argc, coption;
char **Argv;
int buildTime, buildDate;

extern void flush_cache (int adr, int len);

extern float sinf( float);
extern float cosf( float);
extern float atanf( float);
extern float logf( float);
extern float expf( float);
extern float sqrtf(float);

extern float tanf( float);
extern float acosf( float);
extern float asinf( float);
extern float atan2f( float, float);
extern float sinhf( float);     
extern float coshf( float);
extern float tanhf( float);
extern float acosdf( float);
extern float asindf( float);
extern float atandf( float);
extern float atan2df( float, float);
extern float cosdf( float);
extern float sindf( float);
extern float tandf( float);
extern float fabsf( float);
extern float log10f( float);
extern float log2f( float);
extern float powf( float, float );
extern float fmodf(float,float);

extern void AOpenAudio();
extern void ASetErrorHandler();
extern void ALoadAFile();
extern void APlaySBucket();
extern void ASetCloseDownMode();
extern void ADestroySBucket();
extern void ACloseAudio();
extern void AGetErrorText();

void mallinfoC (struct mallinfo* p)
{
	*p = mallinfo();
}

int dlopen(char *lib, int mode)
{
	return (int) shl_load (lib, mode, 0);
}

int dlclose(int handle)	/* not necessary */
{
}

int dlsym(int handle, char *symbol, int *adr)
{
	int res;

	if (strcmp("dlopen", symbol) == 0) *adr = (int)dlopen;
	else if (strcmp("mallinfoC", symbol) == 0) *adr = (int)mallinfoC;
	else if (strcmp("dlclose", symbol) == 0) *adr = (int)dlclose;
	else if (strcmp("flush_cache", symbol) == 0) *adr = (int)flush_cache;
	else if (strcmp("heapAdr", symbol) == 0) *adr = heapAdr;
	else if (strcmp("heapSize", symbol) == 0) *adr = heapSize;
	else if (strcmp("GCstart", symbol) == 0) *adr = GCstart;
	else if (strcmp("millicodeTable", symbol) == 0) *adr = (int)millicodeTable;
	else if (strcmp("bootnameadr", symbol) == 0) *adr = (int)bootname;
	else if (strcmp("modPtr", symbol) == 0) *adr = (int)mod;
	else if (strcmp("cmdPtr", symbol) == 0) *adr = (int)cmd;
	else if (strcmp("fontnameadr", symbol) == 0) *adr = (int)fontname;
	else if (strcmp("dispnameadr", symbol) == 0) *adr = (int)dispname;
	else if (strcmp("geometryadr", symbol) == 0) *adr = (int)geometry;
	else if (strcmp("coption", symbol) == 0) *adr = coption;
	else if (strcmp("sinf", symbol) == 0) *adr = (int)sinf;
	else if (strcmp("cosf", symbol) == 0) *adr = (int)cosf;
	else if (strcmp("atanf", symbol) == 0) *adr = (int)atanf;
	else if (strcmp("logf", symbol) == 0) *adr = (int)logf;
	else if (strcmp("expf", symbol) == 0) *adr = (int)expf;
	else if (strcmp("sqrtf", symbol) == 0) *adr = (int)sqrtf;
	else if (strcmp("tanf", symbol) == 0) *adr = (int)tanf;
	else if (strcmp("acosf", symbol) == 0) *adr = (int)acosf;
	else if (strcmp("asinf", symbol) == 0) *adr = (int)asinf;
	else if (strcmp("atan2f", symbol) == 0) *adr = (int)atan2;
	else if (strcmp("sinhf", symbol) == 0) *adr = (int)sinhf;
	else if (strcmp("coshf", symbol) == 0) *adr = (int)coshf;
	else if (strcmp("tanhf", symbol) == 0) *adr = (int)tanhf;
	else if (strcmp("acosdf", symbol) == 0) *adr = (int)acosdf;
	else if (strcmp("asindf", symbol) == 0) *adr = (int)asindf;
	else if (strcmp("atandf", symbol) == 0) *adr = (int)atandf;
	else if (strcmp("atan2df", symbol) == 0) *adr = (int)atan2df;
	else if (strcmp("cosdf", symbol) == 0) *adr = (int)cosdf;
	else if (strcmp("sindf", symbol) == 0) *adr = (int)sindf;
	else if (strcmp("tandf", symbol) == 0) *adr = (int)tandf;
	else if (strcmp("fabsf", symbol) == 0) *adr = (int)fabsf;
	else if (strcmp("log10f", symbol) == 0) *adr = (int)log10f;
	else if (strcmp("log2f", symbol) == 0) *adr = (int)log2f;
	else if (strcmp("powf", symbol) == 0) *adr = (int)powf;
	else if (strcmp("fmodf", symbol) == 0) *adr = (int)fmodf;
	else if (strcmp("AOpenAudio", symbol) == 0) *adr = (int)AOpenAudio;
	else if (strcmp("ASetErrorHandler", symbol) == 0) *adr = (int)ASetErrorHandler;
	else if (strcmp("ALoadAFile", symbol) == 0) *adr = (int)ALoadAFile;
	else if (strcmp("APlaySBucket", symbol) == 0) *adr = (int)APlaySBucket;
	else if (strcmp("ASetCloseDownMode", symbol) == 0) *adr = (int)ASetCloseDownMode;
	else if (strcmp("ADestroySBucket", symbol) == 0) *adr = (int)ADestroySBucket;
	else if (strcmp("ACloseAudio", symbol) == 0) *adr = (int)ACloseAudio;
	else if (strcmp("AGetErrorText", symbol) == 0) *adr = (int)AGetErrorText;
	else if (strcmp("ecvt", symbol) == 0) *adr = (int)ecvt;
	else if (strcmp("argc", symbol) == 0) *adr = Argc;
	else if (strcmp("argv", symbol) == 0) *adr = (int)Argv;
	else if (strcmp("errno", symbol) == 0) *adr = (int)&errno;
	else if (strcmp("OBERON", symbol) == 0) *adr = (int)OBERON;
	else if (strcmp("SHLPATH", symbol) == 0) *adr = (int)SHLPATH;
	else if (strcmp("buildTime", symbol) == 0) *adr = buildTime;
	else if (strcmp("buildDate", symbol) == 0) *adr = buildDate;
	else {
		res = shl_findsym ((shl_t *) &handle, symbol, TYPE_UNDEFINED, (void *) adr);
		if ((res == -1) || (*adr == 0)) {
			printf("symbol %s not found\n", symbol); exit(-1);
		}
	}
}

/*----- Instruction format operations -----*/

long Left (long x)
{
	return (x >> 11) % 0x200000;
}

long Right (long x)
{
	return x & 0x7FF;
}

long LowSignExt14 (long x)
{
	if ((x & 1) == 0) {
		return x >> 1;
	} else {
		return (x >> 1) - 0x2000;
	}
}

long LowSignRed14 (long x)
{
	if (x < 0) {
		return (x +  0x2000) * 2 + 1;
	} else {
		return x * 2;
	}
}

long Assemble14 (long n)	/* pattern -> integer */
{
	return n & 0x00003FFF;
}

long Disass14 (long n)	/* integer -> pattern */
{
	return n & 0x00003FFF;
}

long SignExt17 (long x)
{
	if ((x >> 16) == 0) {
		return x;
	} else {
		return x - 0x20000;
	}
}

long SignRed17 (long x)
{
	return x & 0x1FFFF;
}

long Assemble17 (long n)	/* pattern -> integer */
{
	long x, y, z;
	
	x = (n >> 16) & 0x1F;
	y = (n >> 2) & 0x7FF;
	z = (n & 0x1);
	return (z << 16) + (x << 11) + ((y & 0x1) << 10) + (y >> 1);
}

long Disass17 (long n)	/* integer -> pattern */
{
	long x, y, z;
	
	z = (n >> 16) & 0x1;
	x = (n >> 11) & 0x1F;
	y = (n & 0x3FF) * 2 + ((n >> 10) & 0x1);
	return (x << 16) + (y << 2) + z;
}

long Assemble21 (long i)
{
	return ((i & 0x1) << 20) +
		(((i >> 1) & 0x7FF) << 9) +
		(((i >> 14) & 0x3) << 7) +
		(((i >> 16) & 0x1F) << 2) +
		((i >> 12) & 0x3);
}

long Disass21 (long n)
{
	return (((n >> 2) & 0x1F) << 16) +
		(((n >> 7) & 0x3) << 14) +
		((n & 0x3) << 12) +
		(((n >> 9) & 0x7FF) << 1) +
		((n >> 20) & 0x1);
}

long ExtractInstrPattern14 (long n) {return n & 0xFFFFC000;}
long ExtractTarget14 (long n) {return LowSignExt14(Assemble14(n));}
long FormatTarget14 (long n) {return Disass14(LowSignRed14(n));}

long ExtractInstrPattern17 (long n) {return n & 0xFFE0E002;}
long ExtractTarget17 (long n) {return SignExt17(Assemble17(n));}
long FormatTarget17 (long n) {return Disass17(SignRed17(n));}

long ExtractInstrPattern21 (long n) {return n & 0xFFE00000;}
long ExtractTarget21 (long n) {return Assemble21(n);}
long FormatTarget21 (long n) {return Disass21(n);}

/*----- Files Reading primitives -----*/

int Rint() 
{
	unsigned char b[4];
	b[3] = fgetc(fd); b[2] = fgetc(fd); b[1] = fgetc(fd); b[0] = fgetc(fd);
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
	int i, val, val2, c1, c2, c3, adr;
	/*----- Pointers Relocations -----*/
	i = RNum(); 
	while ((i--) > 0) { adr = RNum(); adr = adr*4 + heapAdr;
		*((int *) adr) += shift;
	}
	/*----- Words Relocations -----*/
	i = RNum(); 
	while ((i--) > 0) { adr = RNum(); adr = adr*4 + heapAdr;
		c1 = *((int *) adr); c2 = *((int *) (adr + 4));
		val = (ExtractTarget21(c1) << 11) + ExtractTarget14(c2) + shift;
		*((int *) adr) = ExtractInstrPattern21(c1) + FormatTarget21(Left(val));
		*((int *) (adr + 4)) = ExtractInstrPattern14(c2) + FormatTarget14(Right(val));
	}
	/*----- Procs Relocations -----*/
	i = RNum(); 
	while ((i--) > 0) { adr = RNum(); adr = adr*4 + heapAdr;
		c1 = *((int *) adr); c2 = *((int *) (adr + 4));
		val = (ExtractTarget21(c1) << 11) + ExtractTarget14(c2) + shift;
		*((int *) adr) = ExtractInstrPattern21(c1) + FormatTarget21(Left(val));
		*((int *) (adr + 4)) = ExtractInstrPattern14(c2) + FormatTarget14(Right(val));
	}
	/*----- Branches Relocations -----*/
	i = RNum();
	while ((i--) > 0) { adr = RNum(); adr = adr*4 + heapAdr;
		c1 = *((int *) adr); c2 = *((int *) (adr + 4));
		val = (ExtractTarget21(c1) << 11) + (ExtractTarget17(c2) * 4) + shift;
		*((int *) adr) = ExtractInstrPattern21(c1) + FormatTarget21(Left(val));
		*((int *) (adr + 4)) = ExtractInstrPattern17(c2) + FormatTarget17(Right(val) >> 2);
	}
}

void Boot()
{
	int i, adr, val, len, shift1, d, notfound, fileHeapAdr, fileHeapSize, fileGCstart; Proc body;

	d = 0; notfound = 1;
	while ((d < nofdir) && notfound) {
		strcat(strcat(strcpy(fullname, dirs[d++]), "/"), bootname);
		fd = fopen(fullname, "r");
		if (fd != NULL) notfound = 0;
	}
	if (notfound) { printf("oberon: boot file %s not found\n", bootname); exit(-1); }
	fileHeapAdr = Rint(); fileHeapSize = Rint(); fileGCstart = Rint();
	if (fileHeapSize >= heapSize) { printf("oberon: heap too small\n"); exit(-1); }
	adr = heapAdr; len = adr + fileHeapSize + 4;
	while (adr != len) {
		*((int *) adr) = 0;
		adr += 4;
	}
	shift1 = heapAdr - fileHeapAdr;
	GCstart = fileGCstart + shift1;
	adr = Rint(); len = Rint();
	while (len != 0) {
		adr += shift1;
		len += adr;
		while (adr != len) { *((int *) adr) = Rint(); adr += 4; }
		adr = Rint(); len = Rint();
	}
	body = (Proc)(adr + shift1);
	Relocate(heapAdr, shift1);
	millicodeTable[0] = RNum();
	i = 1;
	while (i <= millicodeTable[0]) {
		millicodeTable[i] = RNum() + shift1; i++;
	}
	adr = RNum() + shift1;
	buildTime = RNum();
	buildDate = RNum();
	*((int *) (adr)) = (int) dlsym;
	fclose(fd);
	flush_cache (heapAdr, fileHeapSize);
	(*body)();
}

InitPath()
{
	int pos;
	char ch;

	OBERON = getenv("OBERON");
	if (OBERON == NULL) OBERON = defaultpath;
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
	SHLPATH = getenv("SHLPATH");
	if (SHLPATH == NULL) SHLPATH = defaultshlpath;
}

main(int argc, char *argv[])
{
	int res, c;
	
	heapSize = 4; Argc = argc; Argv = argv; coption = 0;
	while (--argc > 0 && (*++argv)[0] == '-') {
		c = *++argv[0];
		switch (c) {
		case 'h': if (--argc > 0) {sscanf(*++argv, "%d", &heapSize); if (heapSize < 1) heapSize = 1;} break;
		case 'x': if ((argc -= 2) > 0) {sscanf(*++argv, "%s", mod); sscanf(*++argv, "%s", cmd);} break;
		case 'b': if (--argc > 0) {sscanf(*++argv, "%s", bootname);} break;
		case 'f': if (--argc > 0) {sscanf(*++argv, "%s", fontname);} break;
		case 'd': if (--argc > 0) {sscanf(*++argv, "%s", dispname);} break;
		case 'g': if (--argc > 0) {sscanf(*++argv, "%s", geometry);} break;
		case 'c': coption = 1; break;
		default:
			printf("oberon: illegal option %c\n", c);
			argc = -1;
			break;
		}
	}
	if (argc != 0) {
		printf("Usage: oberon [-h heapsizeinMB] [-x module command] [-b bootfile]\n");
		printf("              [-f fontmapfile] [-d displayname] [-g geometry] [-c]\n"); exit(-1);
	}
	/*----- heap space allocation -----*/
	heapSize *= 0x100000;
	heapAdr = (int) malloc(heapSize);
	if (heapAdr == 0) { printf("oberon: cannot allocate heap space\n"); exit(-1); }
	heapSize -= (-heapAdr) & 0x1f;
	heapAdr += (-heapAdr) & 0x1f;
	/* printf("heap at 0x%x\n", heapAdr); */
	/*----- Initialisation -----*/
	InitPath();
	fpsetdefaults();
	/*----- Boot -----*/
	Boot();
}
