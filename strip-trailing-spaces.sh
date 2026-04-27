#!/bin/bash

# My text editor has an annoying habit of putting trailing spaces
# everywhere, especially due to auto-indenting.  This script will
# clean up all the assembly files.

for dude in `find . -name \*.asm` `find . -name \*.inc` ; do
  sed -i '' 's/[[:space:]]*$//' $dude
done

