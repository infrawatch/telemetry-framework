#!/bin/sh
oc import-image prometheus:v2.11.104 --from=registry.redhat.io/openshift3/prometheus:v3.11.104-14 --confirm
oc import-image prometheus-operator --from=registry.redhat.io/openshift3/ose-prometheus-operator --confirm
oc import-image prometheus-configmap-reloader --from=registry.redhat.io/openshift3/ose-configmap-reloader --confirm
oc import-image prometheus-config-reloader --from=registry.redhat.io/openshift3/ose-prometheus-config-reloader --confirm
oc import-image prometheus-alertmanager:v0.15.0 --from=registry.redhat.io/openshift3/prometheus-alertmanager:v3.11.104-14 --confirm
oc import-image amq-interconnect:1.4-6 --from=registry.redhat.io/amq7/amq-interconnect:1.4-6 --confirm
oc import-image amq-interconnect-operator --from=registry.redhat.io/amq7-tech-preview/amq-interconnect-operator --confirm
oc import-image smart-gateway --from=registry.redhat.io/saf/smart-gateway --confirm
oc import-image smart-gateway-operator --from=registry.redhat.io/saf/smart-gateway-operator --confirm
oc set image-lookup prometheus prometheus-operator prometheus-configmap-reloader prometheus-config-reloader prometheus-alertmanager amq-interconnect amq-interconnect-operator smart-gateway smart-gateway-operator
