#!/bin/bash
#
# Runs on the dev/CI machine to execute the test harness job in the cluster
#
# Requires:
#   * oc tools pointing at your SAF instance
#   * gnu sed
#
# Usage: ./smoketest.sh [NUMCLOUDS]
#
# NUMCLOUDS - how many clouds to simulate (that number of smart gateways and
# collectd pods will be created)

# Generate an array of cloud names to use
NUMCLOUDS=${1:-1}
CLOUDNAMES=()
for ((i=1; i<=NUMCLOUDS; i++)); do
  NAME="smoke${i}"
  CLOUDNAMES+=(${NAME})
done

echo "*** [INFO] Creating configmaps..."
oc delete configmap/saf-smoketest-collectd-config configmap/saf-smoketest-entrypoint-script job/saf-smoketest || true
oc create configmap saf-smoketest-collectd-config --from-file ./minimal-collectd.conf.template
oc create configmap saf-smoketest-entrypoint-script --from-file ./smoketest_entrypoint.sh

echo "*** [INFO] Creating smart gateways..."
for NAME in "${CLOUDNAMES[@]}"; do
    # NOTE: Using this as our source file requires that we have actually run a
    # deploy from this same directory, which may not be ideal for a smoke test.
    # Carrying around a second copy of this resource manifest is also not ideal,
    # though.
    oc delete smartgateway "${NAME}"
    oc create -f <(
      sed -e "s/name: cloud1/name: ${NAME}/"\
          -e "s/\(amqp_url: .*\)telemetry/\\1${NAME}-telemetry/"\
          ../../deploy/service-assurance/smartgateway/smartgateway.yaml
    )
done

echo "*** [INFO] Creating smoketest jobs..."
oc delete job -l app=saf-smoketest
for NAME in "${CLOUDNAMES[@]}"; do
    oc create -f <(sed -e "s/<<CLOUDNAME>>/${NAME}/" smoketest_job.yaml.template)
done

# Trying to find a less brittle test than a timeout
TIMEOUT=300s
for NAME in "${CLOUDNAMES[@]}"; do
    echo "*** [INFO] Waiting on job/saf-smoketest-${NAME}..."
    oc wait --for=condition=complete --timeout=${TIMEOUT} "job/saf-smoketest-${NAME}"
    RET=$((RET || $?)) # Accumulate exit codes
done

echo "*** [INFO] Showing oc get all..."
oc get all
echo

echo "*** [INFO] Showing servicemonitors..."
oc get servicemonitor -o yaml
echo

echo "*** [INFO] Logs from smoketest containers..."
for NAME in "${CLOUDNAMES[@]}"; do
    oc logs "$(oc get pod -l "job-name=saf-smoketest-${NAME}" -o jsonpath='{.items[0].metadata.name}')"
done
echo

echo "*** [INFO] Logs from qdr..."
oc logs "$(oc get pod -l application=qdr-white -o jsonpath='{.items[0].metadata.name}')"
echo

echo "*** [INFO] Logs from smart gateways..."
for NAME in "${CLOUDNAMES[@]}"; do
    oc logs "$(oc get pod -l "deploymentconfig=${NAME}-smartgateway" -o jsonpath='{.items[0].metadata.name}')"
done
echo

echo "*** [INFO] Logs from smart gateway operator..."
oc logs "$(oc get pod -l app=smart-gateway-operator -o jsonpath='{.items[0].metadata.name}')"
echo

echo "*** [INFO] Logs from prometheus..."
oc logs "$(oc get pod -l prometheus=white -o jsonpath='{.items[0].metadata.name}')" -c prometheus
echo

if [ $RET -eq 0 ]; then
    echo "*** [SUCCESS] Smoke test job completed successfully"
else
    echo "*** [FAILURE] Smoke test job still not succeeded after ${TIMEOUT}"
fi
echo

exit $RET