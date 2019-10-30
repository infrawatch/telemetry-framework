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
}

make_grafana_datasources(){
    echo "Creating OCP datasource"
    RESP=$(curl --silent --output /dev/null -d "$OCP_DATASOURCE" -H 'Content-Type: application/json' "$GRAF_HOST/api/datasources")
    if echo "$RESP" | grep -q "RequiredError"; then
        echo "Unable to create OCP datasource with reply: "
        echo "$RESP"
        exit 1
    fi

    echo "Creating SAF datasource"
    RESP=$(curl --silent --output /dev/null -d "$SAF_DATASOURCE" -H 'Content-Type: application/json' "$GRAF_HOST/api/datasources")
    if echo "$RESP" | grep -q "RequiredError"; then
        echo "Unable to create SAF datasource with reply: "
        echo "$RESP"
        exit 1
    fi
}

make_service_monitors(){
    oc apply -f ./grafana/prom-servicemonitor.yml 
    oc apply -f ./grafana/qdr-servicemonitor.yml
}

make_qdr_edge_router(){
    if ! oc get qdr qdr-test; then
        echo "Deploying edge router"
        oc create -f ./deploy/qdrouterd.yaml
        return
    fi
    echo "Utilizing existing edge router"


}

get_sources(){
    if ! oc project openshift-monitoring; then
        echo "Error: openshift monitoring does not exist in cluster. Make sure monitoring is enabled" 1>&2
        exit 1
    fi
    OCP_PROM_HOST="https:\/\/$(oc get routes --field-selector metadata.name=prometheus-k8s -o jsonpath="{.items[0].spec.host}")"
    OCP_DATASOURCE=$(oc get secret -n openshift-monitoring grafana-datasources -o jsonpath='{.data.prometheus\.yaml}' \
        | base64 -d)
    OCP_DATASOURCE=$(echo "${OCP_DATASOURCE//$'\n'/}" | sed 's/.*\[\([^]]*\)\].*/\1/g') #get DS json from between brackets
    OCP_DATASOURCE=$(echo "$OCP_DATASOURCE" | sed 's/"name": "[a-z]*"/"name": "OCPPrometheus"/g')  #Change DS name
    OCP_DATASOURCE=$(echo "$OCP_DATASOURCE" | sed 's/"url": "[^,]*"/"url": "PROMHOST"/g')     #DS placeholder url
    OCP_DATASOURCE=$(echo "$OCP_DATASOURCE" | sed "s/\"url\": \"PROMHOST\"/\"url\": \"${OCP_PROM_HOST}\"/g") #Change DS url

    if ! oc project sa-telemetry; then 
        echo "Error: SAF does not exist on cluster. Deploy SAF before running performance test" 1>&2
        exit 1
    fi
    if ! GRAF_HOST=$(oc get routes --field-selector metadata.name=grafana -o jsonpath="{.items[0].spec.host}") 2> /dev/null; then 
        echo "Error: cannot find Grafana instance in cluster. Has it been deployed?" 1>&2
        exit 1
    fi

    SAF_PROM_HOST=$(oc get routes --field-selector metadata.name=prometheus -o jsonpath="{.items[0].spec.host}")

    SAF_DATASOURCE=$(cat << EOF
        {
            "name"  :   "SAFPrometheus",
            "type"  :   "prometheus",
            "url"   :   "http://$SAF_PROM_HOST",
            "access":   "direct",
            "basicAuth" :false,
            "jsonData": {
                "timeInterval"  :   "1s"
            }
        }
EOF
)
}

post_dashboards(){
    echo "Creating new dashboards in Grafana"
    curl --silent --output /dev/null -d "{\"overwrite\": true, \"dashboard\": $(cat ./grafana/perftest-dashboard.json)}" \
        -H 'Content-Type: application/json' "$GRAF_HOST/api/dashboards/db"
        
    curl --silent --output /dev/null -d "{\"overwrite\": true, \"dashboard\": $(cat ./grafana/prom2-dashboard.json)}" \
        -H 'Content-Type: application/json' "$GRAF_HOST/api/dashboards/db"
}

# Execute

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

get_sources
make_grafana_datasources
make_service_monitors
post_dashboards

STAGE="TARGET"
while true; do
    case $STAGE in
        "TARGET")
            TARGETS=$(curl "http://$(oc get route prometheus -o jsonpath='{.spec.host}')/api/v1/targets")
            QDR=$(echo "$TARGETS" | grep -o '"__meta_kubernetes_service_name":"qdr-white"')
            PROM=$(echo "$TARGETS" | grep -o '"__meta_kubernetes_service_name":"prometheus-operated"')

            if [ -z "$QDR" ] && [ -z "$PROM" ]; then
                printf "%s" "Waiting for new targets to be recognized by Prometheus Operator"; ellipse
                printf "\r"
                sleep 10
            else
                echo "Found new target endpoints"
                STAGE="ROUTER"
            fi
        ;;
        "ROUTER")
            make_qdr_edge_router
            estab=$(oc get pod -l qdr_cr=qdr-test -o jsonpath='{.items[0].status.conditions[?(@.type=="ContainersReady")].status}') || true
            if [ "${estab}" != "True" ]; then
                printf "%s" "Waiting on qdr edge test pod creation"; ellipse
                printf "\r"
                sleep 1
            else
                echo "Qdr edge test pod established. Creating performance test job"
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
                printf "\r"
                sleep 1
            else
                printf "\n%s\n" "SAF performance test pod established"
                break
            fi
        ;;
        *)
            echo "Unrecognized state"
            exit 1
        ;;
    esac
done

oc logs -f "$(oc get pod -l job-name=saf-perftest-1-runner -o jsonpath='{.items[0].metadata.name}')" |  grep -E 'total [0-9]+'
echo "Test complete"




