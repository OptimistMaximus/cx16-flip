#!/bin/sh

make zzz/FLIP.PRG
cd zzz
rm -f IMAGE.FLI
ln -s $1 IMAGE.FLI
x16emu -prg FLIP.PRG -run # -debug 080D
rm IMAGE.FLI

