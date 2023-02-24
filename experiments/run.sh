#!/bin/bash
# runs a batch of experiments.

echo "READING TEST CONFIGURATION..."

# test that everything seems to be fine.
if [ "$#" -eq 0 ]
then
    echo "No arguments supplied!"
    echo "    Please specify target directory"
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

outfile=$solution_dir/idesyde.out
timesfile=$solution_dir/times
touch $outfile
touch $timesfile
for sm in ${spa_muls[@]}
do
    for md in ${mem_divs[@]}
    do
	out_name="${sm}_${md}.fiodl"
	echo "Running sm=$sm, md=$md... -> $out_name"
	{ time java -jar cli-assembly.jar --time-multiplier $sm --memory-divider $md -o "$solution_dir/$out_name" ${model[@]} >> $outfile ; } 2>> $timesfile
    done
done

echo "SOLUTIONS DONE!"
echo "EVALUATING SOLUTIONS..."

resultfile=out_case_${identifier}.csv
java -cp evaluator.jar evaluator.Main $identifier > $resultfile

echo "EVALUATION DONE!"
echo "GENERATING PLOTS..."

bash plotter.jl $identifier

echo "DONE!"
