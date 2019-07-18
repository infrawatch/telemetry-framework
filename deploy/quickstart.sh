#!/usr/bin/env bash
#
# Usage:
#
#  Upstream containers: ./quickstart.sh
#  Downstream containers: ./quickstart.sh --downstream-secret=~/6340056-cloudops-pull-secret.yaml
oc login -u system:admin
oc new-project sa-telemetry

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

# import container images
if [[ "$*" =~ --downstream-secret=(.*) ]]; then
    echo "Importing containers from downstream"
    eval secret_file="${BASH_REMATCH[1]}"  # eval is for ~ expansion
    # shellcheck disable=SC2154
    oc create -f "${secret_file}"
    ./import-downstream.sh
else
    echo "Importing containers from upstream"
    ./import-upstream.sh
fi

# deploy the environment (requires interaction)
./deploy.sh

# teardown the environment when done (requires interaction)
echo "Your environment should now be ready."
echo "-- To teardown your environment, run:   ./deploy.sh DELETE"
