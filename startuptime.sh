#!/usr/bin/env bash

TIMESTR=$(date +%Y%m%d%H%M%S) # Assumption - running this script will take more than one second
VERSIONFILE=./startup_versions_"$TIMESTR"
OUTPUTFILE=./startup_output_"$TIMESTR"
TIMEFORMAT='%R %U %S'

REPS=10

function log_version {
    # Print version
    echo "$1" >> "$VERSIONFILE"
    "$1" "$2" >> "$VERSIONFILE"
}

function test_null {
    # Arguments:
    # $1 - Command
    # $2 - Script flag (if any)

    for ((n=0;n<REPS;n++)); do
        printf "%s " "$1" >> "$OUTPUTFILE"
        # Don't double quote - $3 might not exist
        # Use builtin time
        # shellcheck disable=SC2086 disable=SC2023
        { time $1 $3 /dev/null; } 2>> $OUTPUTFILE
        # builtin time's output is generated at end of line
    done


    # builtin time is more precise:
    # https://unix.stackexchange.com/questions/70653/increase-e-precision-with-usr-bin-time-shell-command

    # /bin/time --format="%e %S %U" $1 $3 /dev/null
}

runtest "bash" "--version"
runtest "node" "--version"
runtest "sbcl" "--version" "--script"

# runtest2 "sbcl" "--version" "--script"
