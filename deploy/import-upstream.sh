#!/bin/sh
#
# [NOTE]
# When deploying SAF you can choose to use container images from either
# upstream (public open source), or downstream (published to the Red Hat
# Container Catalog).
#
# Two scripts,`import-downstream.sh` and `import-upstream.sh` are provided to
# help with this. In the scripts we attempt to hook into specific versions for
# deployment from the source registry. When importing those into our
# ImageStream source for delivery of the images from the internal OpenShift
# registry, we often use `latest` where possible. In certain instances an
# Operator or container artifact may require a specific version format, and
# thus is reflected in the container image tag imported into the internal
# registry.
#
# In the future we hope to better align the versions across the various
# ImageStreams and to build a more consistent view between the deployment
# methods. It's possible our issues will be resolved with the migration to the
# Operator Lifecycle Manager as well.

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
oc import-image smart-gateway:latest --from=quay.io/redhat-service-assurance/smart-gateway:latest --confirm
oc import-image smart-gateway-operator:latest --from=quay.io/redhat-service-assurance/smart-gateway-operator:latest --confirm

oc import-image ose-elasticsearch-operator:latest --from=quay.io/openshift/origin-elasticsearch-operator:4.2.0 --confirm
oc import-image ose-oauth-proxy:latest --from=quay.io/openshift/origin-oauth-proxy:4.2.0 --confirm
oc import-image ose-elasticsearch5:latest --from=quay.io/openshift/origin-logging-elasticsearch5:4.2.0 --confirm

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
