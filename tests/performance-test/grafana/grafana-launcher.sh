#!/bin/sh

# Launches a grafana pod with a pre-determined graph format and exposes routes
# Important: this grafana instance is initialized with Admin permissions on the anonymous user
# That is, authentication is disabled 

oc delete svc/grafana \
   route/grafana \
   deployment/grafana-deployment \
   configmap/grafana-config \
   configmap/datasources-config

if ! oc get project openshift-monitoring; then
    echo "Error: openshift monitoring does not exist in cluster. Make sure monitoring is enabled" 1>&2
    exit 1
fi

OCP_PASS=$(oc get secret -n openshift-monitoring grafana-datasources -o jsonpath='{.data.prometheus\.yaml}' | base64 -d |
    python -c "import sys, json; print json.load(sys.stdin)['datasources'][0]['basicAuthPassword']")
sed -e "s|<<OCP_PASS>>|${OCP_PASS}|g" ./datasource.yaml > /tmp/datasource.yaml

oc create configmap grafana-config --from-file ../grafana/grafana.ini
oc create configmap datasources-config --from-file /tmp/datasource.yaml
oc create -f ../grafana/grafana-service.yml
oc create -f ../grafana/grafana-route.yml
oc create -f ../grafana/grafana-deploy.yml

printf "\nGraphing dashboard available at: \n"
oc get routes --field-selector metadata.name=grafana -o jsonpath="{.items[0].spec.host}"
printf "\n"
