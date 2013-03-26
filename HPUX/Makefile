# Make File for building the HP Oberon Loader
# Runs on HP serie 700 with HP-UX

CFLAGS = -Aa +O3

oberon:	flush_cache.o HP.oberon.o
	cc $(CFLAGS) -o oberon HP.oberon.o flush_cache.o -ldld -lM -lAlib
	strip oberon
	
oberon.debug:	flush_cache.o HP.oberon.o
	cc -Aa -g -o oberon.debug HP.oberon.o flush_cache.o -ldld -lM -lAlib

flush_cache.o:	flush_cache.s
	as flush_cache.s
	
HP.oberon.o:	HP.oberon.c
	cc $(CFLAGS) -c HP.oberon.c

clean:
	rm oberon HP.oberon.o flush_cache.o
