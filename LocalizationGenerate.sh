#!/bin/bash  

for i in *.nib; do

    ibtool --strings-file ${i%.nib}.strings --write ${i%.nib}.nib2 "$i"

    rm -R "$i"

    mv ${i%.nib}.nib2 "$i"

    rm ${i%.nib}.strings

done