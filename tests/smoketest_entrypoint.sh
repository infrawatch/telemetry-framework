#!/bin/sh
set -e

# Executes inside the test harness container to start collectd and look for resulting metrics in prometheus
PROMETHEUS=${PROMETHEUS:-"prometheus-operated.sa-telemetry.svc.cluster.local:9090"}

# Run collectd in foreground mode to generate some metrics
/usr/sbin/collectd -f 2>&1 | tee /tmp/collectd_output &

# Wait until collectd appears to be up and running
retries=3
until [ $retries -eq 0 ] || grep "Initialization complete, entering read-loop" /tmp/collectd_output; do
  retries=$[$retries-1]
  echo "Sleeping for 3 seconds waiting for collectd to enter read-loop"
  sleep 3
done

# Checks that the metrics actually appear in prometheus
# The egrep exit code is the result of the test and becomes the container/pod/job exit code
curl -g "${PROMETHEUS}/api/v1/query?" --data-urlencode 'query=sa_collectd_cpu_total{cpu="0",type="user"}' \
   | egrep '"result":\[{"metric":{"__name__":"sa_collectd_cpu_total","cpu":"0","endpoint":"metrics","exported_instance":"saf-smoketest-.*","service":"white-smartgateway","type":"user"},"value":\[.+,".+"\]'