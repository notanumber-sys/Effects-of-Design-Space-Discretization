# sf250X-thesis
## Installation
Requirements:
 - Java 10 or higher. [check this!]
 - Bash shell (tested in Cygwin and Ubuntu)
 - Python 3.9 or higher
 - [Julia](https://julialang.org/downloads/) with packages: Printf, Plots, CSV, LinearAlgebra, Interpolations

Installation:
1. Make sure that all requirements are met.
2. Clone this repository.
3. Download [IDeSyDe](https://github.com/forsyde/IDeSyDe) 0.5.x, chose the correct version depending on your OS.
4. Extract IDeSyDe into the root directory of the repository. This should add two directories: emodules and imodules; and the platform dependent IDeSyDe entry point.

## Usage
Each experiment is identified by a unique identifier. An experiment is defined by a directory named `in_case_<identifier>`. This directory should contain a configuration file called `config` with the following format:
```
tr1 tr2 tr3 ... trN
mr1 mr2 mr3 ... mrM

```
specifying the N time resolutions and M memory resolutions to test (both in ascending order) (the file should en with an empty line). The directory should also contain at least one `.fiodl` file specifying the set of application and platform models to investigate.

The following is a valid in-directory for an experiment called `sobel8`:
```
in_case_sobel8
├── a_sobel.hsdf.fiodl
├── bus_small_platform.fiodl
└── config
```

When a correct in-directory has been created, the experiment can be started by running the `run.sh` script. `run.sh` takes the following following format:
```
./run.sh [identifier] <cores <batches <halt-early>>>
```
where:
 - **identifier** is the unique identifier for the experiment to run.
 - **cores** are the number of cores to utilize, default is 1.
 - **batches** is the number of times to run each case, default is 1.
 - **halt-early** if set to 1 makes the script halt before generating plots.

`run.sh` reads the configuration and traverses the grid of configurations. Each case is ran and timed **batches** times. The resulting data is stored as a CSV-file and then plotted. As an example, the following runs the `sobel8`-case on 16 cores with a batch size of 4:
```
./run.sh sobel8 16 4
```