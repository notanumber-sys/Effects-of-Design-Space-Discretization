#!/bin/bash

sed -i.bak 's/\r$//g' $1
echo "DONE"
