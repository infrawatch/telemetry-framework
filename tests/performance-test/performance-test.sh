#!/bin/bash
set -e

usage(){
    cat << ENDUSAGE
Runs on the dev/CI machine to execute a performance test and abstracts between
running collectd-tg (tg) or telemetry-bench (tb).

Requires:
  * oc tools pointing at your SAF instance
  * gnu sed

Usage: ./performance-test.sh -t <tg|tb> -c <intervals> -h <#hosts> -p <#plugins> -i <seconds> [-n <#concurrent>]
  -t: Which tool to use ('tg' = collectd-tg, 'tb' = telemetry-bench (recommended))
  -c: The number of intervals to run for
  -h: The number of hosts to simulate per batch
  -p: The nuber of plugins to simulate per batch
  -i: The (target) interval over which a message batch is sent
  -n: The number of concurrent batches to run (telemetry-bench only)

NOTES:
  * The expected message throughput is roughly: <#hosts> * <#plugins> * <#concurrent> per <interval>
  * The tools themselves are known to top out around ~18k/s (tb) and ~28k/s (tg) on modern CPUs
  * The best way to run this at scale is with batches of 5k or 10k and a concurrency setting to acheive the desired
    throughput
  * telemetry-bench is recommended since there are problems getting collectd-tg to scale concurrently
  * telemetry-bench somewhat underperforms (runs too slow), but every message does get sent
  * A plugin setting of 1000 reasonably matches the plugins/host we expect to see from OSP

EXAMPLES:
  Quick minimal test ~1k/s (1 min)
  ./performance-test.sh -t tb -c 60 -h 1 -p 1000 -i 1 -n 1

  Recommended command for ~20k/s (10 mins)
  ./performance-test.sh -t tb -c 600 -h 5 -p 1000 -i 1 -n 4
ENDUSAGE
    exit 1
}

while getopts t:c:h:p:i:n: option
do
    case "${option}"
    in
        t) TOOL=${OPTARG};;
        c) COUNT=${OPTARG};;
        h) HOSTS=${OPTARG};;
        p) PLUGINS=${OPTARG};;
        i) INTERVAL=${OPTARG};;
        n) CONCURRENT=${OPTARG};;
        *) ;;
    esac
done

if [ "${TOOL}" = "tg" ]; then
    MSGS=$((HOSTS * PLUGINS))
    LENGTH_S=$((COUNT / INTERVAL))
    CONFIG="\
- metadata:
    name: SAF Performance Test 1
  spec:
    value-lists: ${MSGS}
    hosts: ${HOSTS}
    plugins: ${PLUGINS}
    interval: ${INTERVAL}
    length: ${LENGTH_S}"

    echo "${CONFIG}" > deploy/config/generated-test-configs.yml
    cd deploy
    export TG_CONFIGFILE=./config/generated-test-configs.yml
    ./performance-test-tg.sh

elif [ "${TOOL}" = "tb" ]; then
    export COUNT HOSTS PLUGINS INTERVAL CONCURRENT
    cd deploy
    ./performance-test-tb.sh

else
    usage
fi
