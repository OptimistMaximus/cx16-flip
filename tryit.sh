#!/bin/sh
# set -x

# This builds a zip file that works with the "Try it Now" feature
# of the Commander X16 forums.

ver=004

dir=flip${ver}
prg=FLIP${ver}.PRG

mkdir $dir
cp zzz/MAIN.PRG           $dir/$prg
cp src/resources/BELL.FLI $dir/IMAGE.FLI
cp src/resources/OWL.FLI  $dir
#cp LICENSE               $dir
#cp README.md             $dir
cd $dir
zip ../$dir.zip *
cd ..
rm -rf $dir

