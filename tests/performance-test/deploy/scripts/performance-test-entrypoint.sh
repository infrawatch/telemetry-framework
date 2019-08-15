#!/bin/sh
set -e

hosts="/performance-test/config/hosts.json"

while IFS= read -r line
do
    GRAFANA_URL=$(echo "$line" | python -c "import sys, json; print json.load(sys.stdin)['grafana-host']")
done < "$hosts"

echo $GRAFANA_URL

#run collectd
echo "Launching collectd"
/usr/sbin/collectd -f 2>&1 &
sleep 1
echo "Retrieving API token for Grafana"
curl -X POST -H "Content-Type: application/json" -d '{"name":"apikeycurl", "role": "Admin"}' $GRAFANA_URL/api/auth/keys > /performance-test/grafana/apikey

echo "Launching performance tests"
/performance-test/exec/main
