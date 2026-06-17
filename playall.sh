#!/bin/sh

top=`pwd`
version=080
program=$top/zzz/FLIP${version}.PRG
dirs="fps-0E fps-0F"
dirs="fps-20-up"
dirs="fps-10-1F"

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

