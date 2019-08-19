#!/bin/sh
#
# See the README.md file for an explanation on why some ImageStreams have tags
# other than 'latest'

# Version v2.11.0 is here because the Prometheus Operator in use requires a
# major version of '2' and the version format of vMajor.Minor.Patch
oc import-image prometheus:latest --from=quay.io/openshift/origin-prometheus:v3.11 --confirm
oc import-image prometheus-operator:latest --from=quay.io/openshift/origin-prometheus-operator:v3.11 --confirm
oc import-image prometheus-configmap-reloader:latest --from=quay.io/openshift/origin-configmap-reload:v3.11 --confirm
oc import-image prometheus-config-reloader:latest --from=quay.io/openshift/origin-prometheus-config-reloader:v3.11 --confirm

# Deployment of the Prometheus Alertmanager from the Operator also requires a
# specific version format which effectively assumes a version of 0.15.0.
oc import-image prometheus-alertmanager:v0.15.0 --from=quay.io/openshift/origin-prometheus-alertmanager:v3.11 --confirm

# Version 1.4-6 here is used to reference the expected downstream version from
# the template and to provide some additional context for understanding the
# mapping of upstream to downstream versions of the qdrouterd container image.
oc import-image amq-interconnect:1.4-7 --from=quay.io/interconnectedcloud/qdrouterd:1.8.0 --confirm
oc import-image amq-interconnect-operator:latest --from=quay.io/interconnectedcloud/qdr-operator:1.0.0-beta2 --confirm

# Currently we don't have a robust release process for the Smart Gateway or
# corresponding Operator, so we just pull the latest version down for now.
oc import-image smart-gateway:latest --from=quay.io/redhat-service-assurance/smart-gateway:mmagr-627-sg-es --confirm
oc import-image smart-gateway-operator:latest --from=quay.io/redhat-service-assurance/smart-gateway-operator:mmagr-627-sg-es --confirm

oc import-image ose-elasticsearch-operator:latest --from=quay.io/openshift/origin-elasticsearch-operator:latest --confirm
oc import-image ose-oauth-proxy:latest --from=quay.io/openshift/origin-oauth-proxy:v4.0.0 --confirm
oc import-image ose-elasticsearch5:latest --from=quay.io/openshift/origin-logging-elasticsearch5:latest --confirm

oc set image-lookup prometheus \
    prometheus-operator \
    prometheus-configmap-reloader \
    prometheus-config-reloader \
    prometheus-alertmanager \
    amq-interconnect \
    amq-interconnect-operator \
    smart-gateway \
    smart-gateway-operator \
    ose-elasticsearch-operator \
    ose-oauth-proxy \
    ose-elasticsearch5
