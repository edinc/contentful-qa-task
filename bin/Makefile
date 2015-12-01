CC=gcc 
CFLAGS=-Wall -O2 -fpic -shared -ldl
override.so: clean
	$(CC) $(CFLAGS) -o override.so override.c

clean:
	rm -f override.so
