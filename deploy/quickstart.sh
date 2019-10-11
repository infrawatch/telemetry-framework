#!/usr/bin/env bash
set -e

#
# Usage:
#
#  Upstream containers: ./quickstart.sh
#  Downstream containers: ./quickstart.sh --downstream-secret=~/6340056-cloudops-pull-secret.yaml
oc login -u system:admin
oc new-project sa-telemetry

# make sure thre is a node that matches ElasticSearch's node selector
oc patch node $(oc get node | tail -1 | awk '{print $1}') -p '{"metadata":{"labels":{"kubernetes.io/os": "linux"}}}'

# generate certificates for AMQ Interconnect
openssl req -new -x509 -batch -nodes -days 11000 \
        -subj "/O=io.interconnectedcloud/CN=qdr-white.sa-telemetry.svc.cluster.local" \
        -out qdr-server-certs/tls.crt \
        -keyout qdr-server-certs/tls.key
oc create secret tls qdr-white-cert --cert=qdr-server-certs/tls.crt --key=qdr-server-certs/tls.key

# generate certificates for ElasticSearch
WORKING_DIR=./es-certs NAMESPACE="sa-telemetry" ./cert_generation.sh
cd es-certs

# ref: https://github.com/openshift/cluster-logging-operator/blob/master/pkg/k8shandler/logstore.go#L76-L90
oc create secret generic elasticsearch \
    --from-file=elasticsearch.key \
    --from-file=elasticsearch.crt \
    --from-file=logging-es.key \
    --from-file=logging-es.crt \
    --from-file=admin-key=system.admin.key \
    --from-file=admin-cert=system.admin.crt \
    --from-file=admin-ca=ca.crt

cd ..

# build out manifests
ansible-playbook \
    -e "registry_path=$(oc registry info)" \
    -e "imagestream_namespace=$(oc project --short)" \
    -e "prometheus_pvc_storage_request=2G" \
    deploy_builder.yml

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
