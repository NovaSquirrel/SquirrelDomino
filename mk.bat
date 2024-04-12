@echo off
ca65 squirrel_domino.s -o squirrel_domino.o -l squirrel_domino.lst
ld65 -C nrom128.x squirrel_domino.o -o squirrel_domino.nes
pause