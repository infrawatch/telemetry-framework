# Service Assurance Framework Deployment using Operators

This directory contains sample configurations for deployment of the Telemetry
Framework leverage Operators for the deployment. The contents here are
currently a work in a progress.

> **A word on the versions**
>
> In the `import-downstream.sh` and `import-upstream.sh` scripts we attempt to
> hook into specific versions for deployment from the source registry. When
> importing those into our ImageStream source for delivery of the images from
> the internal OpenShift registry, we often use `latest` where possible. In
> certain instances an Operator or container artifact may require a specific
> version format, and thus is reflected in the container image tag imported
> into the internal registry.
>
> In the future we hope to better align the versions across the various
> ImageStreams and to build a more consistent view between the deployment
> methods. It's possible our issues will be resolved with the migration to the
> Operator Lifecycle Manager as well.

## Quickstart (Minishift)

A script is provided to deploy SAF into a minishift created
OpenShift environment. It will allow for SAF to be started for development
purposes, and is not intended for production environments. It takes care of all
of the steps documented below for a single-cloud setup.

The script can be found here: https://github.com/redhat-service-assurance/telemetry-framework/blob/master/deploy/quickstart.sh

## Routes and Certificates

In order to get the remote QDR connections through the OpenShift operator, we
need to use TLS/SSL certificates. The following two commands will first create
the appropriate certificate files locally and then load the contents into a
secret for use by QDR.

You'll need to copy the contents of these certificates and load them into
the client side connection. The QDR on the client side will then connect to the
route address (DNS address) for the QDR service on port 443. Be sure you set
the OpenShift route to Passthrough mode to port 5671.

    openssl req -new -x509 -batch -nodes -days 11000 \
        -subj "/O=io.interconnectedcloud/CN=qdr-white.sa-telemetry.svc.cluster.local" \
        -out qdr-server-certs/tls.crt \
        -keyout qdr-server-certs/tls.key

    oc create secret tls qdr-white-cert --cert=qdr-server-certs/tls.crt --key=qdr-server-certs/tls.key

## Importing ImageStreams

In order to better separate between upstream and downstream locations of
images, we've made use of
[ImageStreams](https://docs.openshift.com/container-platform/3.11/dev_guide/managing_images.html)

To import the downstream container images into the local registry, run the
`./import-downstream.sh` script which will configure the appropriate Image
Streams for the Service Assurance Framework components.

## Generating Appropriate Manifests

The manifests provided here are used to request the appropriate state within
Kubernetes to allow for the Service Assurance Framework to exist as intended.
Part of that is to consume the container images that are made available by the
local registry.

Some manifests need to be generated with Ansible so that the path to the
container image in the local registry matches the deployed environment. For
example, installation with `openshift-ansible` provides a default registry path
via `docker-registry.default.svc:5000` while a similar installation with
_minishift_ results in a local registry available at `172.30.1.1:5000`.

You can determine the default registry path by running:

    oc registry info

To dynamically generate the manifests for a default OpenShift Ansible
installation, simply run:

    ansible-playbook deploy_builder.yaml

This will result in an image pull location of
`docker-registry.default.svc:5000/sa-telemetry/<container_id>`. If you wish to
override this (for example, when deploying to _minishift_) then you can pass
environment variables like so:

    ansible-playbook \
      -e "registry_path=$(oc registry info)" \
      -e "imagestream_namespace=$(oc project --short)" \
      deploy_builder.yml

## Instantiating Service Assurance Framework

After executing the above prerequisite steps, we need to patch a node (or
nodes) to allow for the scheduling of the Smart Gateway by the Operator. To do
that, run the following command:

    oc patch node localhost -p '{"metadata":{"labels":{"application": "sa-telemetry", "node": "white"}}}'

Then simply run the `deploy.sh` script. You will need to follow the
instructions during the script as it will pause waiting for the successful
completion at a couple of steps.

## Multi-cloud support

It is possible to deploy one intance of SAF and attach multiple openstack clouds
to it. See the [Multicloud README](README-multicloud.md) for details.

## Internals

Sections for implementation details that are helpful for developers

### Labels

Here is a data dictionary of our labels; not including auto-generated ones.

Currently we are in the process of refining the label set, so this will
temporarily document the old vs. the new. This will become canonical when the
work is complete.

#### BEFORE

| **Label Key**         | **On Types**                   | **Values**     | **Notes**  |
|-----------------------|--------------------------------|----------------|------------|
| alertmanager          | Pod                            | sa             | This comes from prometheus-operator |
| app                   | Pod, Service, DeploymentConfig | alertmanager, prometheus-operator, prometheus, prometheus-white,  sa-telemetry-alertmanager | The prometheus has a label app=prometheus, and the smart-gateway has app=prometheus-white   We should standardize this to name all components by their proper names and not use it for additional metadata (white) |
| application           | Pod, Service, ReplicaSet       | qdr-white | This comes from qdr-operator |
| name                  | Pod, ReplicaSet, Job, SmartGateway, Qdr  | qdr-operator, saf-smoketest, smart-gateway-operator, white, qdr-white | There is already metadata.name We should standardize this to 'app'  |
| operated-alertmanager | Service                        | true | These come from prometheus-operator |
| operated-prometheus   | Service                        | true | These come from prometheus-operator |
| prometheus            | Pod, StatefulSet               | white, prometheus-sa-telemetry  | The 'white' value should move to 'sa-affinity'|
| qdr_cr                | Pod, Service, ReplicaSet       | qdr-white | We should standardize this to 'app' but remove extra metadata (white) |
| sa-app                | Pod                            | prometheus-white | We should standardize this to 'app' but remove extra metadata (white) |
| sa-app-white          | ServiceMonitor                 | prometheus-white | We should standardize this to 'app' but remove extra metadata (white) |
| sa-telemetry-app-white| ServiceMonitor                 | prometheus-white | We should standardize this to 'app' but remove extra metadata (white) |
| smartgateway          | Service                        | white     |     |

#### AFTER (Proposed)

| **Label Key**         | **On Types**                   | **Values**     | **Notes**  |
|-----------------------|--------------------------------|----------------|------------|
| alertmanager          | Pod                            | sa             | This comes from prometheus-operator |
| app                   | Pod, Service, DeploymentConfig | alertmanager, prometheus, prometheus-operator, qdr, qdr-operator, smart-gateway, smart-gateway-operator | Primary way to identify a specific component |
| application           | Pod, Service, ReplicaSet       | qdr-white | This comes from qdr-operator |
| operated-alertmanager | Service                        | true | These come from prometheus-operator |
| operated-prometheus   | Service                        | true | These come from prometheus-operator |
| qdr_cr                | Pod, Service, ReplicaSet       | qdr-white | Where does this come from? |
