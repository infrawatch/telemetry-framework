#!/bin/sh
set -e

# Runs on the dev/CI machine to execute the test harness job in the cluster
# Requires:
#   oc tools pointing at your SAF instance
oc delete configmap/saf-smoketest-collectd-config configmap/saf-smoketest-entrypoint-script job/saf-smoketest || true

oc create configmap saf-smoketest-collectd-config --from-file=collectd.conf=./minimal-collectd.conf
oc create configmap saf-smoketest-entrypoint-script --from-file ./smoketest_entrypoint.sh
oc create -f smoketest_job.yaml

# Trying to find a less brittle test than a timeout, but this is a reasonable starting point
TIMEOUT=300s
if oc wait --for=condition=complete --timeout=${TIMEOUT} job/saf-smoketest; then
    echo "*** [SUCCESS] Smoke test job completed successfully"
    RET=0
else
    echo "*** [FAILURE] Smoke test job still not succeeded after ${TIMEOUT}"
    RET=1
fi

echo "*** [INFO] Showing oc get all..."
oc get all
echo

echo "*** [INFO] Showing servicemonitors..."
oc get servicemonitor -o yaml
echo

echo "*** [INFO] Logs from smoketest container..."
oc logs "$(oc get pod -l job-name=saf-smoketest -o jsonpath='{.items[0].metadata.name}')"
echo

echo "*** [INFO] Logs from qdr..."
oc logs "$(oc get pod -l application=qdr-white -o jsonpath='{.items[0].metadata.name}')"
echo

echo "*** [INFO] Logs from smart gateway..."
oc logs "$(oc get pod -l deploymentconfig=white-smartgateway -o jsonpath='{.items[0].metadata.name}')"
echo

echo "*** [INFO] Logs from prometheus..."
oc logs "$(oc get pod -l prometheus=white -o jsonpath='{.items[0].metadata.name}')" -c prometheus

exit $RET