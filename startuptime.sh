#!/usr/bin/env bash

TIMESTR=$(date +%Y%m%d%H%M%S) # Assumption - running this script will take more than one second
VERSIONFILE=./startup_versions_"$TIMESTR"
NULLFILE=./startup_null_"$TIMESTR"
SCRIPTFILE=./startup_script_"$TIMESTR"
CHECKSUMFILE=./startup_checksum_"$TIMESTR"
TIMEFORMAT='%R %U %S'

REPS=15

function log_version {
    VERSIONFLAG=${2:-"--version"}
    # Print version
    echo "$1" >> "$VERSIONFILE"
    "$1" "$VERSIONFLAG" >> "$VERSIONFILE"
}

function test_null {
    # Arguments:
    # $1 - Command
    # $2 - Script flag (if any)

    for ((n=0;n<REPS;n++)); do
        printf "%s " "$1" >> "$NULLFILE"
        # Don't double quote - $3 might not exist
        # Use builtin time
        # shellcheck disable=SC2086 disable=SC2023
        { time $1 $3 /dev/null; } 2>> "$NULLFILE"
        # builtin time's output is generated at end of line
    done

    # builtin time is more precise:
    # https://unix.stackexchange.com/questions/70653/increase-e-precision-with-usr-bin-time-shell-command

    # /bin/time --format="%e %S %U" $1 $3 /dev/null
}

function test_script {
    for ((n=0;n<REPS;n++)); do
        printf "%s " "$1" >> "$SCRIPTFILE"
        # Don't double quote - $3 might not exist
        # Use builtin time
        # shellcheck disable=SC2086 disable=SC2023
        { time $1 $3 $2 >> "$CHECKSUMFILE"; } 2>> "$SCRIPTFILE"
        # builtin time's output is generated at end of line
    done
}

NUMPROGRAMS=11

test_script bash ./test.sh
test_script node ./test.js
test_script sbcl ./test.lsp --script
test_script ruby ./test.rb
test_script perl ./test.pl
test_script perl6 ./test.pl
test_script python3 ./test3.py
test_script python2 ./test2.py
test_script deno ./test.js run
test_script lua ./test.lua
test_script racket ./test.rkt --script

lines=$(wc -l < "$CHECKSUMFILE")
expected=$((NUMPROGRAMS * REPS))

if [ "$lines" -ne $expected ]; then
    echo "ERROR: unexpected number of outputlines printed"
fi

# runtest "bash" "--version"
# runtest "node" "--version"
# runtest "sbcl" "--version" "--script"

# runtest2 "sbcl" "--version" "--script"
