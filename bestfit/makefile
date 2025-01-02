CC = gcc
AS = as
CFLAGS = -g -no-pie
LFLAGS = -lm

main: main.o meuAlocador.o
	$(CC) $(CFLAGS) $(LFLAGS) -o main main.o meuAlocador.o

meuAlocador.o: meuAlocador.s 
	$(AS) $(CFLAGS) -c meuAlocador.s -o meuAlocador.o

main.o: main.c meuAlocador.h
	$(CC) $(CFLAGS) -c main.c -o main.o

clean:
	rm -rf ./*.o

purge: clean
	rm -rf main
