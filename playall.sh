#!/bin/sh

top=`pwd`
program=$top/zzz/MAIN.PRG
dirs="smooth slow unknown"
dirs="unknown"

for dir in $dirs ; do
  cd $top/images/$dir
  for file in *.FLI *.fli ; do
    if [ $file = "IMAGE.FLI" ] ; then continue ; fi
    rm -f IMAGE.FLI
    ln -s $file IMAGE.FLI
    echo now playing $file ...
    x16emu -prg $program -run
  done
done

