#!/bin/sh

cat $1 | sed 's/#.*//' | xxd -r -p > $2

