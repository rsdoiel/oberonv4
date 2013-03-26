# Make File for building the Linux Oberon Loader
# Runs on Linux ELF 

CFLAGS = -O2

all:	oberon wrapper

oberon:	linux.oberon.o
	gcc $(CFLAGS) -o oberon linux.oberon.o -ldl -lm
	strip oberon
	
linux.oberon.o:
	gcc $(CFLAGS) -c linux.oberon.c

wrapper: 
	gcc -c obwrapper.c
	gcc -lpthread -shared -o libobwrapper.so obwrapper.o

clean:
	rm oberon linux.oberon.o
	rm libobwrapper.so obwrapper.o 
