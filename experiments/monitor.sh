#!/bin/bash

if [ $# -eq 0 ]
then
    echo "Please specify the target case identifier."
    exit 0
fi

watch -n 1 -d "cat ${1}.nohup.out | tail -n $((72 - 2))"
