#!/bin/bash
# Sets up the envirovnment for performance testing
oc project openshift-monitoring
OCP_PROM_HOST=$(oc get routes --field-selector metadata.name=prometheus-k8s -o jsonpath="{.items[0].spec.host}")

oc project sa-telemetry
GRAF_HOST=$(oc get routes --field-selector metadata.name=grafana -o jsonpath="{.items[0].spec.host}")
PROM_HOST=$(oc get routes --field-selector metadata.name=prometheus -o jsonpath="{.items[0].spec.host}")

TG_CONFIGFILE=${TG_CONFIGFILE:-./config/test-configs.yml}

oc delete configmap/saf-performance-test-collectd-config \
   configmap/saf-performance-test-entrypoint-script \
   configmap/saf-performance-test-configs \
   configmap/saf-performance-test-hosts \
   configmap/grafana-dashboard-template \
   job/saf-performance-test || true

printf '{"grafana-host":"%s","prometheus-host":"%s", "ocp-prometheus-host":"%s"}\n' "$GRAF_HOST" "$PROM_HOST" "$OCP_PROM_HOST" | tee ./config/hosts.json

oc create configmap saf-performance-test-collectd-config --from-file=collectd.conf=./config/minimal-collectd.conf
oc create configmap saf-performance-test-entrypoint-script --from-file ./scripts/performance-test-entrypoint.sh
oc create configmap saf-performance-test-configs --from-file test-configs.yml="${TG_CONFIGFILE}"
oc create configmap grafana-dashboard-template --from-file ../grafana/perftest-dashboard.json
oc create configmap saf-performance-test-hosts --from-file ./config/hosts.json

oc create -f <(sed -e "s/<<REGISTRY_INFO>>/$(oc registry info)/" performance-test-job-tg.yml.template)
