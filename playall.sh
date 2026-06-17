#!/bin/sh

top=`pwd`

program=$top/zzz/FLIP.PRG
dirs="fps-20-up"
dirs="fps-10-1F"
dirs="fps-04"

make zzz/FLIP.PRG
cd zzz
for dir in $dirs ; do
  for file in $top/images/$dir/*.FLI ; do
    rm -f IMAGE.FLI
    ln  $file IMAGE.FLI
    echo now playing $file ...
    x16emu -prg $program -run
    if [ -e omg.stop ] ; then break ; fi
  done
done

