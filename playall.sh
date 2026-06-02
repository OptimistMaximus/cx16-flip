#!/bin/sh

top=`pwd`
program=$top/zzz/MAIN.PRG
dirs="fps-05-0B fps-0C-0F fps-10-1F fps-20-up unknown"

for dir in $dirs ; do
  cd $top/images/$dir
  for file in *.FLI ; do
    if [ $file = "IMAGE.FLI" ] ; then continue ; fi
    rm -f IMAGE.FLI
    ln -s $file IMAGE.FLI
    echo now playing $file ...
    x16emu -prg $program -run
  done
done

