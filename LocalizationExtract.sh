#!/bin/bash  

for i in *.nib; do     

    ibtool --generate-strings-file ${i%.nib}.strings "$i"

done