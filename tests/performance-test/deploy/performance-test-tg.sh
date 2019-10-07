#!/bin/bash
# Sets up the envirovnment for performance testing

#set -e

oc project openshift-monitoring
OCP_PROM_HOST=$(oc get routes --field-selector metadata.name=prometheus-k8s -o jsonpath="{.items[0].spec.host}")
OCP_DATASOURCE=$(oc get secret -n openshift-monitoring grafana-datasources -o jsonpath='{.data.prometheus\.yaml}' \
                | base64 -d)
OCP_DATASOURCE=$(echo $OCP_DATASOURCE | python -c "import sys, json; source=json.load(sys.stdin)['datasources'][0]; \
                source['url']='https://$OCP_PROM_HOST'; source['name']='OCPPrometheus'; print(json.dumps(source))")

oc project sa-telemetry
GRAF_HOST=$(oc get routes --field-selector metadata.name=grafana -o jsonpath="{.items[0].spec.host}")
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

TG_CONFIGFILE=${TG_CONFIGFILE:-./config/test-configs.yml}

oc delete configmap/saf-performance-test-collectd-config \
   configmap/saf-performance-test-entrypoint-script \
   configmap/saf-performance-test-configs \
   configmap/saf-performance-test-hosts \
   configmap/perftest-dashboard-template \
   job/saf-performance-test || true

printf '{"grafana-host":"%s","prometheus-host":"%s", "ocp-prometheus-host":"%s"}\n' \
        "$GRAF_HOST" "$SAF_PROM_HOST" "$OCP_PROM_HOST" | tee ./config/hosts.json

echo "Creating OCP datasource"
curl -d "$OCP_DATASOURCE" -H 'Content-Type: application/json' "$GRAF_HOST/api/datasources"
echo "Creating SAF datasource"
curl -d "$SAF_DATASOURCE" -H 'Content-Type: application/json' "$GRAF_HOST/api/datasources"


oc create configmap saf-performance-test-collectd-config --from-file=collectd.conf=./config/minimal-collectd.conf
oc create configmap saf-performance-test-entrypoint-script --from-file ./scripts/performance-test-entrypoint.sh
oc create configmap saf-performance-test-configs --from-file test-configs.yml="${TG_CONFIGFILE}"
oc create configmap perftest-dashboard-template --from-file ../grafana/perftest-dashboard.json
oc create configmap saf-performance-test-hosts --from-file ./config/hosts.json

oc create -f ../grafana/prom-servicemonitor.yml
oc create -f ../grafana/qdr-servicemonitor.yml

STAGE="TARGET"
while true; do
    case $STAGE in
        "TARGET")
            TARGETS=`curl "http://$(oc get route prometheus -o jsonpath='{.spec.host}')/api/v1/targets"`
            QDR=`echo $TARGETS | grep -o '"__meta_kubernetes_service_name":"qdr-white"'`
            PROM=`echo $TARGETS | grep -o '"__meta_kubernetes_service_name":"prometheus-operated"'`

            if [ -z "$QDR" ] && [ -z "$PROM" ]; then
                echo "Waiting for new targets to be recognized by Prometheus Operator"
                sleep 10
            else
                echo "Found new target endpoints. Creating performance test job"
                oc create -f <(sed -e "s/<<REGISTRY_INFO>>/$(oc registry info)/" performance-test-job-tg.yml.template)
                STAGE="TEST"
            fi
        ;;
        "TEST")
            estab=$(oc get pod -l job-name=saf-performance-test -o jsonpath='{.items[0].status.conditions[?(@.type=="ContainersReady")].status}')
            if [ "${estab}" != "True" ]; then
                echo "Waiting on SAF performance test pod creation..."
                sleep 3
            else
                echo "SAF performance test pod established"
                break
            fi
        ;;
        *)
            echo "Unrecognized state"
            exit 2
        ;;
    esac
done

oc logs -f $(oc get pod -l job-name=saf-performance-test -o jsonpath='{.items[0].metadata.name}')

