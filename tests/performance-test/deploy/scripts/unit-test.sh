#!/bin/bash

# Run a single collectd-test for a specified amount of time
set -x
ARGS=()

while getopts l:n:H:p:i:d:h option
do
    case "${option}"
    in
        l) LENGTH=${OPTARG};;
        n) ARGS+=('-n');ARGS+=("${OPTARG}");;
        H) ARGS+=('-H');ARGS+=("${OPTARG}");;
        p) ARGS+=('-p');ARGS+=("${OPTARG}");;
        i) ARGS+=('-i');ARGS+=("${OPTARG}");;
        d) ARGS+=('-d');ARGS+=("${OPTARG}");;
    esac
done

if [ ! -v LENGTH ];
then
    echo "[unit-test.sh] Length of test unspecfied. Running for default time of 900s (15min)"
    LENGTH=900
fi

echo "[unit-test.sh] Running collectd-tg with arguments:" "${ARGS[@]}"
collectd-tg "${ARGS[@]}" > /dev/null &
sleep $LENGTH
pkill collectd-tg
echo "[unit-test.sh] Exiting test sequence"
exit


