#!/bin/sh

sed 's:DEVKITPRO:'"$DEVKITPRO"':g' libc.txt.template > ./libc.txt

