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
    {
        echo "$1"
        "$1" "$VERSIONFLAG"
        echo ""
    } &>> "$VERSIONFILE"
}

function test_null {
    for ((n=0;n<REPS;n++)); do
        printf "%s " "$1" >> "$NULLFILE"
        # Don't double quote - $3 might not exist
        # Use builtin time
        # shellcheck disable=SC2086 disable=SC2023
        { time $1 $2 /dev/null; } 2>> "$NULLFILE"
        # builtin time's output is generated at end of line
    done
}

function test_script {
    for ((n=0;n<REPS;n++)); do
        printf "%s " "$1" >> "$SCRIPTFILE"
        printf "%s " "$1" >> "$CHECKSUMFILE"
        # Don't double quote - $3 might not exist
        # Use builtin time
        # shellcheck disable=SC2086 disable=SC2023
        { time $1 $3 "./test$2" >> "$CHECKSUMFILE"; } 2>> "$SCRIPTFILE"
        # builtin time's output is generated at end of line
    done
}

function run_test {
    # $1 - Program name
    # $2 - Script extension
    # $3 - Script flag
    # $4 - Version flag
    log_version $1 $4
    test_null $1 $3
    test_script $1 $2 $3
}

NUMPROGRAMS=11

run_test    bash    .sh
run_test    node    .js
run_test    sbcl    .lsp     --script
run_test    ruby    .rb
run_test    perl    .pl
run_test    perl6   .pl
run_test    python3 3.py
run_test    python2 2.py
run_test    deno    .js     run         version
run_test    lua     .lua    " "         -v
run_test    racket  .rkt    --script

lines=$(wc -l < "$CHECKSUMFILE")
expected=$((NUMPROGRAMS * REPS))

if [ "$lines" -ne $expected ]; then
    echo "ERROR: unexpected number of outputlines printed"
    printf "Found %d, expected %d\n" "$lines" "$expected"
fi

