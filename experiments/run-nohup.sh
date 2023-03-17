#!/bin/bash

stdoutfile=${1}.nohup.out
stderrfile=${1}.nohup.err

case $# in
    1)
	nohup ./run.sh $1 1>$stdoutfile 2>$stderrfile &
	;;
    2)
	nohup ./run.sh $1 $2 1>$stdoutfile 2>$stderrfile &
	;;
    3)
	nohup ./run.sh $1 $2 $3 1>$stdoutfile 2>$stderrfile &
	;;
    4)
	nohup ./run.sh $1 $2 $3 $4 1>$stdoutfile 2>$stderrfile &
	;;
    *)
	echo "Incorrect number of arguments! Please specify 1-4 arguments!"
	exit 0
	;;
esac

echo "Task has been started with $# arguments."
