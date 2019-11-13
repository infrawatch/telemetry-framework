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

# Ellipse - update an ellipse string everytime called. Conveys loading, waiting, etc
ELLIPSE=".  "
ellipse(){
    case $ELLIPSE in
    ".  ") printf "%s" "$ELLIPSE"
         ELLIPSE=".. "
    ;;
    ".. ") printf "%s" "$ELLIPSE"
          ELLIPSE="..."
    ;;
    "...") printf "%s" "$ELLIPSE"
           ELLIPSE=".  "
    ;;
    esac
    printf "\r"
}

make_service_monitors(){
    oc apply -f ./grafana/prom-servicemonitor.yml 
    oc apply -f ./grafana/qdr-servicemonitor.yml
}

# create edge router for more realistic env setup: telemetry-bench -> qdr -> qdr -> SG
make_qdr_edge_router(){
    if ! oc get qdr qdr-test; then
        printf "\n*** Deploying Edge Router ***\n"
        oc create -f <(sed -e "s/<<REGISTRY_INFO>>/$(oc registry info)/g" ./deploy/qdrouterd.yaml.template)
        return
    fi
    echo "Utilizing existing edge router"
}

# basic check if necessary resources exist. DOES NOT verify they work correctly
check_resources(){
    printf "\n*** Performing Resource Checks ***\n"
    if ! oc get project sa-telemetry; then 
        echo "Error: SAF does not exist on cluster. Deploy SAF before running performance test" 1>&2
        exit 1
    fi

    if ! oc get project openshift-monitoring; then 
        echo "Error: openshift-monitoring not enabled on host. Continuing without it will result \
        in reduced functionality of performance test. Would you like to continue without \
        it? [y/n]"
        read RESP
        case $RESP in
            "y") 
            ;;
            *)
                exit 1
            ;;
        esac
    fi

    if ! GRAF_HOST=$(oc get routes --field-selector metadata.name=grafana -o jsonpath="{.items[0].spec.host}") 2> /dev/null; then 
        echo "Error: cannot find Grafana instance in cluster. Has it been deployed?" 1>&2
        exit 1
    fi

    local datasources=$(curl --silent -X GET "http://${GRAF_HOST}/api/datasources")
    if ! echo $datasources | grep -q "OCPPrometheus"; then
        echo "Error: unable to find Grafana datasource OCPPrometheus"
        exit 1
    fi

    if ! echo $datasources | grep -q "SAFPrometheus"; then
        echo "Error: unable to find Grafana datasource SAFPrometheus"
        exit 1
    fi

    if ! echo $datasources | grep -q "SAFElasticsearch"; then
        echo "Error: unable to find Grafana datasource SAFElasticsearch"
        exit 1
    fi
}

# Post dashboards to grafana - overwrites if they already exist
post_dashboards(){
    printf "\n*** Creating new dashboards in Grafana ***\n"
    curl --silent --output /dev/null -d "{\"overwrite\": true, \"dashboard\": $(cat ./grafana/perftest-dashboard.json)}" \
        -H 'Content-Type: application/json' "$GRAF_HOST/api/dashboards/db"
        
    curl --silent --output /dev/null -d "{\"overwrite\": true, \"dashboard\": $(cat ./grafana/prom2-dashboard.json)}" \
        -H 'Content-Type: application/json' "$GRAF_HOST/api/dashboards/db"
}

# Delete recorded events in Elastic Search
delete_es_events(){
    local esPod=$(oc get elasticsearch elasticsearch -o jsonpath='{.status.pods.master.ready[0]}')
    local secretPath="/etc/elasticsearch/secret/"
    local esQuery=$(cat <<EOF
        {
            "query" : {
                "bool": {
                    "must": {
                        "match_phrase": {
                            "labels.instance": {
                                "query": "saf-perftest-notify-*"
                            }
                        }
                    }
                }
            }
        }
EOF
)
    printf "\n*** Deleting ES Events ***\n"

    local response=$(oc exec "$esPod" -- curl -k --silent --trace --cacert "${secretPath}admin-ca" --cert \
        "${secretPath}admin-cert" --key "${secretPath}admin-key" -X POST "https://localhost:9200/collectd_interface_if/_delete_by_query" \
        -d "$esQuery")
}

# Get number of events recorded by elastic search since last clear
get_es_event_count(){
        local esPod=$(oc get elasticsearch elasticsearch -o jsonpath='{.status.pods.master.ready[0]}')
        local secretPath="/etc/elasticsearch/secret/"
        local esQuery=$(cat <<EOF
        {
            "query" : {
                "bool": {
                    "must": {
                        "match_phrase": {
                            "labels.instance": {
                                "query": "saf-perftest-notify-*"
                            }
                        }
                    }
                }
            }
        }
EOF
)
    ES_EVENT_RECV_COUNT=$(oc exec "$esPod" -- curl -k --silent --trace --cacert "${secretPath}admin-ca" --cert \
         "${secretPath}admin-cert" --key "${secretPath}admin-key" -X GET "https://localhost:9200/collectd_interface_if/_count" \
         -d "$esQuery")

    ES_EVENT_RECV_COUNT=$(echo "$ES_EVENT_RECV_COUNT" | python -c "import sys, json; print json.load(sys.stdin)['count']")
}

# Post result of events test into Elastic Search
post_ratio_to_es(){
    local esPod=$(oc get elasticsearch elasticsearch -o jsonpath='{.status.pods.master.ready[0]}')
    local secretPath="/etc/elasticsearch/secret/"

    local esPost=$(cat <<EOF
    {
        "events_successful": $SUCCESS_RATIO,
        "startsAt": "$(date --utc +"%Y-%m-%dT%H:%M:%S.%NZ")"
    }
EOF
)
    # tell ES to map data to float
    local response=$(oc exec "$esPod" -- curl -k --silent --trace --cacert "${secretPath}admin-ca" --cert \
        "${secretPath}admin-cert" --key "${secretPath}admin-key" -X PUT "https://localhost:9200/performance-test" \
        -d '
            {
                "mappings": {
                    "status": {
                        "properties": {
                            "events_successful": { "type": "float" },
                            "startsAt": { 
                                "type": "date",
                                "format": "strict_date_optional_time||epoch_millis"
                            }
                        }
                    }
                }
            }
        '
        )
    local response=$(oc exec "$esPod" -- curl -k --silent --trace --cacert "${secretPath}admin-ca" --cert \
        "${secretPath}admin-cert" --key "${secretPath}admin-key" -X PUT "https://localhost:9200/performance-test/status/1" \
        -d "$esPost")
}

# Main

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
    echo "Collectd-tg not implemented. Try running with '-t tb' instead"
    exit 1
elif [ "${TOOL}" = "tb" ]; then
    :
else
    usage
fi

# Test groundwork
check_resources
make_service_monitors
delete_es_events
post_dashboards

SUCCESS_RATIO=0.00
post_ratio_to_es

# Test procedure
STAGE="TARGET"
while true; do
    case $STAGE in
        "TARGET")
            TARGETS=$(curl --silent "http://$(oc get route prometheus -o jsonpath='{.spec.host}')/api/v1/targets")
            QDR=$(echo "$TARGETS" | grep -o '"__meta_kubernetes_service_name":"qdr-white"')
            PROM=$(echo "$TARGETS" | grep -o '"__meta_kubernetes_service_name":"prometheus-operated"')

            if [ -z "$QDR" ] && [ -z "$PROM" ]; then
                printf "%s" "Waiting for new targets to be recognized by Prometheus Operator"; ellipse
                sleep 10
            else
                echo "Found new target endpoints"
                make_qdr_edge_router
                STAGE="ROUTER"
            fi
        ;;
        "ROUTER")
            estab=$(oc get pod -l qdr_cr=qdr-test -o jsonpath='{.items[0].status.conditions[?(@.type=="ContainersReady")].status}') || true
            if [ "${estab}" != "True" ]; then
                printf "%s" "Waiting on qdr edge test pod creation"; ellipse
                sleep 1
            else
                echo "Qdr edge test pod established"
                printf "\n*** Creating performance test job ***\n"
                export COUNT HOSTS PLUGINS INTERVAL CONCURRENT
                cd deploy
                ./performance-test-tb.sh
                STAGE="TEST"
            fi
        ;;
        "TEST")
            estab=$(oc get pod -l job-name=saf-perftest-1-runner -o jsonpath='{.items[0].status.conditions[?(@.type=="ContainersReady")].status}') || true
            if [ "${estab}" != "True" ]; then
                printf '%s' "Waiting on SAF performance test pod creation"; ellipse
                sleep 1
            else
                echo "SAF performance test pod established"
                printf "\n*** Listening to job runner ***\n"

                oc logs -f "$(oc get pod -l job-name=saf-perftest-1-runner -o jsonpath='{.items[0].metadata.name}')" |  grep -E 'total [0-9]+'
                STAGE="RESULTS"
            fi
        ;;
        "RESULTS")
            printf "\n*** Collecting test results ***\n"
            PODNAME=$(oc get pod -l job-name=saf-perftest-notify -o jsonpath='{.items[0].metadata.name}')
            oc exec "$PODNAME" -- pkill collectd > /dev/null
            sleep 3
            oc cp "sa-telemetry/${PODNAME}:/tmp/events.json" /tmp/events.json

            # get total number of events generated by collectd
            NUM_COLLECTD_EVENTS=$(wc -l /tmp/events.json | awk '{ print $1 }')

            # get number of events seen by elasticsearch
            get_es_event_count

            # calulate success ratio
            SUCCESS_RATIO=$(( ES_EVENT_RECV_COUNT / NUM_COLLECTD_EVENTS)).$(( (ES_EVENT_RECV_COUNT * 100 / NUM_COLLECTD_EVENTS) % 100 ))

            # DEBUG and TESTING - DELETE 
            echo "EVENTS generated: $NUM_COLLECTD_EVENTS, recieved by Elastic Search: $ES_EVENT_RECV_COUNT, success rate: $SUCCESS_RATIO"

            printf "\n*** Posting events results to Elastic Search ***\n"
            post_ratio_to_es

            break
        ;;
        *)
            echo "Unrecognized state"
            exit 1
        ;;
    esac
done

printf "\n*** Test complete ***\n"




