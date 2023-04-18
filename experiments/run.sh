#!/bin/bash
# runs a batch of experiments.
#
#     run.sh [identifier] <M <N <T>>>
#
# M   cores to utilize
# N   batch size
# T   stop after evaluation (don't generate plots)

# configuration
if [ -z $IDESYDE_TIMEOUT ]
then
    IDESYDE_TIMEOUT=7200
fi

IDESYDE_EXECUTABLE="idesyde.exe"

echo "READING TEST CONFIGURATION..."

# test that everything seems to be fine.
if [ "$#" -eq 0 ]
then
    echo "No arguments supplied!"
    echo "    Please specify the target case identifier"
    exit 1
fi

identifier="$1"
target="in_case_$1"
analysis_config="$target/config"
if [ ! -d "$target" ]
then
    echo "Please specify an existing target directory!"
    echo "    $target is not a directory."
    exit 1
fi

if [ ! -f "$analysis_config" ]
then
    echo "Unable to find case configuration!"
    echo "    $analysis_config is not a file."
    exit 1
fi

nproc=1
if [ "$#" -gt 1 ]
then
    if [[ $2 =~ ^[0-9]+$ ]]
    then
        nproc=$2
        echo "Processes set to $nproc"
    else
	echo "Failed to set processes!"
	echo "    $2 is not a number!"
	echo "    Continuing with processes=$nproc"
    fi
fi

nreps=1
if [ "$#" -gt 2 ]
then
    if [[ $3 =~ ^[0-9]+$ ]]
    then
        nreps=$3
        echo "Repetitions set to $nreps"
    else
	echo "Failed to set repetitions!"
	echo "    $3 is not a number!"
	echo "    Continuing with repetitions=$nreps"
    fi
fi

stopearly=0
if [ "$#" -eq 4 ]
then
    stopearly=1
    echo "Script will not generate any plots."
fi

shopt -s nullglob
model=($target/*.fiodl)
echo "Using model files: ${model[@]}"
if [ ${#model[@]} -eq 0 ]
then
   echo "Unable to find any model files!"
   echo "    $target does not contain any .fiodl files."
   exit 1
fi

cfg_lines=()
while read line; do
    cfg_lines+=("$line")
done < "$analysis_config"
if [ ${#cfg_lines[@]} -lt 2 ]
then
    echo "Unable to parse configuration file!"
    echo "    Not enough rows!"
    exit 1
fi

spa_muls=(${cfg_lines[0]})
mem_divs=(${cfg_lines[1]})
if [[ ${#spa_muls[@]} -eq 0 || ${#mem_divs[@]} -eq 0 ]]
then
    echo "Invalid configuratio file!"
    echo "    Found ${#spa_muls[@]} time cases and ${#mem_divs[@]} mem cases."
    exit 1
fi

solution_dir="so_case_$identifier"
if [ -d $solution_dir ]
then
    read -p "Warning! A solution already exists! Override old case [yY to confirm]? " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
	echo "User cancelled!"
	echo "    ABORTING!"
	exit 1
    else
	echo "DELETING OLD SOLUTION..."
	rm -r $solution_dir
    fi
fi	

if ! mkdir $solution_dir
then
    echo "Failed to create solution directory!"
    echo "    ABORTING!"
    exit 1
fi

# we are ready to run
echo "RUNNING TESTS..."
TIMEFORMAT="%R"
LC_NUMERIC="en_US.UTF-8"

# Utility function to execute a particular case and perform required post processing and clean-up.
execute_case () {
    # setup local environment
    local proc_sm=$1
    local proc_md=$2
    local proc_out_name_fiodl=$3
    local proc_out_name_json=$4
    local proc_name_loc=$5
    local proc_run_dir=$6
    # the following command launches a time command that redirects to a file solution_dir/procname
    # the timed command is a call to the IDeSyDe entry point with output redirected to solution_dir/idesyde.out
    # the IDeSyDe solver runs a specific case and writes output to solution_dir/out_name.fiodl and intermediate
    #     data to a temporary run folder run_dir/
    $({ time ./$IDESYDE_EXECUTABLE --x-time-resolution $proc_sm --x-memory-resolution $proc_md --x-total-time-out $IDESYDE_TIMEOUT --run-path $proc_run_dir -o "$solution_dir/$proc_out_name_fiodl" ${model[@]} >> $outfile ; } 2>$solution_dir/$proc_name_loc )
    # move resulting JSON
    local data_files=(${proc_run_dir}/explored/body_*.json)
#    echo ""
#    for str in ${data_files[@]}
#    do
#	echo "DUMP: $str"
#    done
    if [ ${#data_files[@]} -eq 0 ]
    then
	echo ""
	echo "Warning! Case tr=$proc_sm, mr=$proc_md failed to collect ANY results."
	echo "    The experiment cannot continue."
	wait
	exit 1
    else
	mv ${data_files[-1]} $solution_dir/$proc_out_name_json
	# cleans up run directory after finishing
	rm -r $proc_run_dir
    fi
}

# Starts M processes and then waits for all of them to finish,
# if less than M processes remain, it waits for all running processes
# to finish before continuing.

outfile=$solution_dir/idesyde.out
touch $outfile
started=0
for sm in ${spa_muls[@]}
do
    for md in ${mem_divs[@]}
    do
	out_name_fiodl="${sm}_${md}.fiodl"
	out_name_json="${sm}_${md}.json"
	echo -n "Running sm=$sm, md=$md"
	for (( c=1 ; c<=$nreps ; c++ ))
	do
	    echo -n "."
	    proc_name=idesyde_${sm}_${md}_${c}
	    run_dir=run_${identifier}_${started}
	    execute_case $sm $md $out_name_fiodl $out_name_json $proc_name $run_dir &
	    sleep 0.1
	    ((started++))
	    if [ $started -eq $nproc ]
	    then
		started=0
		wait
	    fi
	done
	echo ""
    done
done
wait

# The time measurements are stored in separate files to avoid
# concurrency issues. This chews through them and compiles them
# into a structured file.
echo "COLLECT TIMES..."
timesfile=$solution_dir/times
touch $timesfile
for sm in ${spa_muls[@]}
do
    for md in ${mem_divs[@]}
    do
	times_buff=()
	for (( c=1 ; c<=$nreps ; c++))
	do
	    time_measurement=${solution_dir}/idesyde_${sm}_${md}_${c}
	    read -r line < $time_measurement
	    times_buff+="$line "
	    rm $time_measurement
	done
	echo "${times_buff[@]}" >> $timesfile
    done
done
echo "TIMES COLLECTED!"

echo "SOLUTIONS DONE!"

echo "EVALUATING SOLUTIONS..."

python3 evaluator.py $identifier

echo "EVALUATION DONE!"

if [ $stopearly -eq 1 ]
then
    echo "DONE! (ignoring plots)"
    exit 0
fi

echo "GENERATING PLOTS..."

bash plotter.jl $identifier

echo "DONE!"
