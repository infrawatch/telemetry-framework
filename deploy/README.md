# Deployment using Operators

This directory contains sample configurations for deployment of the Telemetry
Framework leverage Operators for the deployment. The contents here are
currently a work in a progress.

# Quickstart (Minishift)

minishift start
oc login -u system:admin
oc new-project sa-telemetry
oc create -f ~/699000-username-secret.yaml
openssl req -new -x509 -batch -nodes -days 11000 \
    -subj "/O=io.interconnectedcloud/CN=qdr-white.sa-telemetry.svc.cluster.local" \
    -out qdr-server-certs/tls.crt \
    -keyout qdr-server-certs/tls.key
oc create secret tls qdr-white-cert --cert=qdr-server-certs/tls.crt --key=qdr-server-certs/tls.key

ansible-playbook \
  -e "registry_path=$(oc registry info)" \
  -e "imagestream_namespace=$(oc project --short)" \
  deploy_builder.yml

# need to patch a node in order to allow the current version of the SGO to deploy a SG
oc patch node localhost -p '{"metadata":{"labels":{"application": "sa-telemetry", "node": "white"}}}'

# import downstream container images
./import-downstream.sh

# deploy the environment (requires interaction)
./deploy.sh
watch -n5 oc get pods

# teardown the environment when done (requires interaction)
./deploy.sh DELETE
watch -n10 oc get all


# Routes and Certificates

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

# Importing ImageStreams

In order to better separate between upstream and downstream locations of
images, we've made use of
[ImageStreams](https://docs.openshift.com/container-platform/3.11/dev_guide/managing_images.html)

To import the downstream container images into the local registry, run the
`./import-downstream.sh` script which will configure the appropriate Image
Streams for the Service Assurance Framework components.

# Generating Appropriate Manifests

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

# Instantiating Service Assurance Framework

After executing the above prerequisite steps, we need to patch a node (or
nodes) to allow for the scheduling of the Smart Gateway by the Operator. To do
that, run the following command:

    oc patch node localhost -p '{"metadata":{"labels":{"application": "sa-telemetry", "node": "white"}}}'

Then simply run the `deploy.sh` script. You will need to follow the
instructions during the script as it will pause waiting for the successful
completion at a couple of steps.
