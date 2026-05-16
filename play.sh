#!/bin/sh

cd zzz
rm -f IMAGE.FLI
ln -s $1 IMAGE.FLI
x16emu -prg MAIN.PRG -run
rm IMAGE.FLI

