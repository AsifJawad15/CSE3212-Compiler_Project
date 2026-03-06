CC = gcc
BISON = bison
FLEX = flex

all: parser run

parser: lex.yy.c 2107007.tab.c
	$(CC) lex.yy.c 2107007.tab.c -o parser.exe -lm

lex.yy.c: 2107007.l 2107007.tab.h
	$(FLEX) 2107007.l

2107007.tab.c 2107007.tab.h: 2107007.y
	$(BISON) -d 2107007.y

run:
	parser.exe

clean:
	del /Q parser.exe lex.yy.c 2107007.tab.c 2107007.tab.h testout.txt intermediate_code.txt optimized_code.txt 2>nul
