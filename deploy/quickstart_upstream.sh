#!/bin/sh
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

# import downstream container images
./import-upstream.sh

# deploy the environment (requires interaction)
./deploy.sh

# teardown the environment when done (requires interaction)
echo "Your environment should now be ready."
echo "-- To teardown your environment, run:   ./deploy.sh DELETE"
