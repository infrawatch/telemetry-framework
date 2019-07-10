#!/bin/sh
set -e

# Runs on the dev/CI machine to execute the test harness job in the cluster
# Requires:
#   oc tools pointing at your SAF instance
oc delete configmap/saf-smoketest-collectd-config configmap/saf-smoketest-entrypoint-script job/saf-smoketest || true

oc create configmap saf-smoketest-collectd-config --from-file=collectd.conf=./minimal-collectd.conf
oc create configmap saf-smoketest-entrypoint-script --from-file ./smoketest_entrypoint.sh
oc create -f smoketest_job.yaml