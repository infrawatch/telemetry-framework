#!/bin/sh
#
# See the README.md file for an explanation on why some ImageStreams have tags
# other than 'latest'
#

# Version v2.11.0 is here because the Prometheus Operator in use requires a
# major version of '2' and the version format of vMajor.Minor.Patch
oc import-image prometheus:v2.11.0 --from=registry.redhat.io/openshift3/prometheus:v3.11.104-14 --confirm
oc import-image prometheus-operator:latest --from=registry.redhat.io/openshift3/ose-prometheus-operator:v3.11.104-14 --confirm
oc import-image prometheus-configmap-reloader:latest --from=registry.redhat.io/openshift3/ose-configmap-reloader:v3.11.104-14 --confirm
oc import-image prometheus-config-reloader:latest --from=registry.redhat.io/openshift3/ose-prometheus-config-reloader:v3.11.104-14 --confirm

# Deployment of the Prometheus Alertmanager from the Operator also requires a
# specific version format which effectively assumes a version of 0.15.0.
oc import-image prometheus-alertmanager:v0.15.0 --from=registry.redhat.io/openshift3/prometheus-alertmanager:v3.11.104-14 --confirm

# Version 1.4-6 here is used to reference the expected downstream version from
# the template and to provide some additional context for understanding the
# mapping of upstream to downstream versions of the qdrouterd container image.
oc import-image amq-interconnect:1.4-6 --from=registry.redhat.io/amq7/amq-interconnect:1.4-6 --confirm

# Use of amq-interconnect-operator is within a tech preview space and is not
# eligible for support, and thus is not listed on RHCC. Version for this
# container image was obtained with 'skopeo inspect' after pulling image down.
oc import-image amq-interconnect-operator:latest --from=registry.redhat.io/amq7-tech-preview/amq-interconnect-operator:1.0-7 --confirm

# Currently we don't have a robust release process for the Smart Gateway or
# corresponding Operator, so we just pull the latest version down for now.
oc import-image smart-gateway:latest --from=registry.redhat.io/saf/smart-gateway:1.0-3 --confirm
oc import-image smart-gateway-operator:latest --from=registry.redhat.io/saf/smart-gateway-operator:1.0-3 --confirm

oc set image-lookup prometheus prometheus-operator prometheus-configmap-reloader prometheus-config-reloader prometheus-alertmanager amq-interconnect amq-interconnect-operator smart-gateway smart-gateway-operator
