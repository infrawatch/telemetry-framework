#!/bin/sh

# Launches a grafana pod with a pre-determined graph format and exposes routes minishift
# Important: this grafana instance is initialized with Admin permissions on the anonymous user
# That is, authentication is disabled 

oc delete svc/grafana \
   route/grafana \
   deployment/grafana-deployment \
   configmap/grafana-config \
   configmap/grafana-graph-template

oc create configmap grafana-config --from-file ../grafana/grafana.ini
oc create configmap grafana-graph-template --from-file ../grafana/graph-template.json
oc create -f ../grafana/grafana-service.yml
oc create -f ../grafana/grafana-route.yml
oc create -f ../grafana/grafana-deploy.yml

printf "\nGraphing dashboard available at: \n"
oc get routes --field-selector metadata.name=grafana -o jsonpath="{.items[0].spec.host}"
printf "\n"
