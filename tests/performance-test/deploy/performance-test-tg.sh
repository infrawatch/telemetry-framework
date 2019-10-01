#!/bin/bash
# Sets up the envirovnment for performance testing
TG_CONFIGFILE=${TG_CONFIGFILE:-./config/test-configs.yml}

oc delete configmap/saf-performance-test-collectd-config \
   configmap/saf-performance-test-entrypoint-script \
   configmap/saf-performance-test-configs \
   configmap/saf-performance-test-hosts \
   job/saf-performance-test || true

GRAF_HOST=$(oc get routes --field-selector metadata.name=grafana -o jsonpath="{.items[0].spec.host}")
PROM_HOST=$(oc get routes --field-selector metadata.name=prometheus -o jsonpath="{.items[0].spec.host}")

printf '{"grafana-host":"%s","prometheus-host":"%s"}\n' "$GRAF_HOST" "$PROM_HOST" | tee ./config/hosts.json

oc create configmap saf-performance-test-collectd-config --from-file=collectd.conf=./config/minimal-collectd.conf
oc create configmap saf-performance-test-entrypoint-script --from-file ./scripts/performance-test-entrypoint.sh
oc create configmap saf-performance-test-configs --from-file test-configs.yml="${TG_CONFIGFILE}"
oc create configmap saf-performance-test-hosts --from-file ./config/hosts.json

oc create -f <(sed -e "s/<<REGISTRY_INFO>>/$(oc registry info)/" performance-test-job-tg.yml.template)
