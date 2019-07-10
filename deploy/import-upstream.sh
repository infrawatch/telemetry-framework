#!/bin/sh
oc import-image prometheus:v2.11 --from=quay.io/openshift/origin-prometheus:v3.11 --confirm
oc import-image prometheus-operator:latest --from=quay.io/openshift/origin-prometheus-operator:v3.11 --confirm
oc import-image prometheus-configmap-reloader:latest --from=quay.io/openshift/origin-configmap-reload:v3.11 --confirm
oc import-image prometheus-config-reloader:latest --from=quay.io/openshift/origin-prometheus-config-reloader:v3.11 --confirm
oc import-image prometheus-alertmanager:v0.15.0 --from=quay.io/openshift/origin-prometheus-alertmanager:v3.11 --confirm

oc import-image amq-interconnect:1.4-6 --from=quay.io/interconnectedcloud/qdrouterd:1.7.0 --confirm
oc import-image amq-interconnect-operator:latest --from=quay.io/interconnectedcloud/qdr-operator:1.0.0-beta2 --confirm

oc import-image smart-gateway --from=quay.io/redhat-service-assurance/smart-gateway:latest --confirm
oc import-image smart-gateway-operator --from=quay.io/redhat-service-assurance/smart-gateway-operator:latest --confirm

oc set image-lookup prometheus prometheus-operator prometheus-configmap-reloader prometheus-config-reloader prometheus-alertmanager amq-interconnect amq-interconnect-operator smart-gateway smart-gateway-operator
