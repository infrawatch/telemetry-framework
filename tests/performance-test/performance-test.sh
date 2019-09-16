#!/bin/bash
set -e

usage(){
    cat << ENDUSAGE
Runs on the dev/CI machine to execute a performance test and abstracts between
running collectd-tg (tg) or telemetry-bench (tb).

Requires:
  * oc tools pointing at your SAF instance
  * gnu sed

Usage: ./performance-test.sh -t <tg|tb> -c <intervals> -h <#hosts> -p <#plugins> -i <seconds>
  -t: Which tool to use ('tg' = collectd-tg, 'tb' = telemetry-bench)
  -c: The number of intervals to run for
  -h: The number of hosts to simulate per batch
  -p: The nuber of plugins to simulate per batch
  -i: The (target) interval over which a message batch is sent
ENDUSAGE
    exit 1
}

while getopts t:c:h:p:i: option
do
    case "${option}"
    in
        t) TOOL=${OPTARG};;
        c) COUNT=${OPTARG};;
        h) HOSTS=${OPTARG};;
        p) PLUGINS=${OPTARG};;
        i) INTERVAL=${OPTARG};;
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
    export COUNT HOSTS PLUGINS INTERVAL
    cd deploy
    ./performance-test-tb.sh

else
    usage
fi