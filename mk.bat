@echo off
ca65 squirrel_domino.s -o squirrel_domino.o -l squirrel_domino.lst -g
ld65 -C nrom128.x squirrel_domino.o -o squirrel_domino.nes --dbgfile squirrel_domino.dbg
pause