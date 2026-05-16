#!/bin/sh

cd zzz

for dude in *.FLI ; do
  rm -f IMAGE.FLI
  ln -s $dude IMAGE.FLI
  echo ""
  echo "NOW PLAYING ... $dude"
  x16emu -prg MAIN.PRG -run
done

