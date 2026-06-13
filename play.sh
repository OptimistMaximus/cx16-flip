#!/bin/sh

make zzz/MAIN.PRG
cd zzz
rm -f IMAGE.FLI
ln -s $1 IMAGE.FLI
x16emu -prg MAIN.PRG -run # -debug 080D
rm IMAGE.FLI

