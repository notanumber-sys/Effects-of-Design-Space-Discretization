#!/bin/bash

# removes carriage returns from line breaks.
# (Who even thought that computers were typewriters?)

if [ $# -eq 0 ]
then
    echo "Usage: w2u.sh <target>"
    exit 0
fi

sed -i.bak 's/\r$//g' $1
echo "DONE"
