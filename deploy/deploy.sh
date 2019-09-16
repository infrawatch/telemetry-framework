#!/usr/bin/env bash

# prerequisite checks
echo "-- Prerequisite checks"
command -v oc >/dev/null 2>&1 || { echo >&2 "  * [XX] I require 'oc' but it's not installed. Aborting."; exit 1; }
echo "  * [OK] Found 'oc' application"
oc status >/dev/null 2>&1 || { echo >&2 "  * [XX] Not logged into an openshift cluster. Aborting."; exit 1; }
echo "  * [OK] Logged into OpenShift cluster"
oc get project sa-telemetry >/dev/null 2>&1 || { echo >&2 "  * [--] Project not found. Creating."; oc new-project sa-telemetry >/dev/null 2>&1; }
oc project sa-telemetry >/dev/null 2>&1
echo "  * [OK] Switched to sa-telemetry project"

# setup our default method
method="CREATE"

# checking if we're deleting or creating
if [[ "$1" != "" ]]; then
    if [[ "$1" != "CREATE" && "$1" != "DELETE" ]]; then
        echo "  * [XX] Must use a method of 'CREATE' or 'DELETE'"
        exit 0
    fi
    method="$1"
fi
echo "-- We are going to $method the telemetry framework"

# declare the list of objects we're going to build out
declare -a operator_list=(
    'operators/prometheus/service_account.yaml'
    'operators/prometheus/clusterrole.yaml'
    'operators/prometheus/clusterrolebinding.yaml'
    'operators/prometheus/operator.yaml'
    'operators/elasticsearch/01-service-account.yaml'
    'operators/elasticsearch/02-role.yaml'
    'operators/elasticsearch/03-role-bindings.yaml'
    'operators/elasticsearch/04-crd.yaml'
    'operators/elasticsearch/05-deployment.yaml'
    'operators/qdrouterd/crds/interconnectedcloud_v1alpha1_qdr_crd.yaml'
    'operators/qdrouterd/service_account.yaml'
    'operators/qdrouterd/role.yaml'
    'operators/qdrouterd/role_binding.yaml'
    'operators/qdrouterd/cluster_role.yaml'
    'operators/qdrouterd/cluster_role_binding.yaml'
    'operators/qdrouterd/operator.yaml'
    'operators/smartgateway/crds/smartgateway_v1alpha1_smartgateway_crd.yaml'
    'operators/smartgateway/service_account.yaml'
    'operators/smartgateway/role.yaml'
    'operators/smartgateway/role_binding.yaml'
    'operators/smartgateway/operator.yaml'
)

declare -a application_list=(
    'service-assurance/elasticsearch/elasticsearch.yaml'
    'service-assurance/prometheus/service_account.yaml'
    'service-assurance/prometheus/role.yaml'
    'service-assurance/prometheus/rolebinding.yaml'
    'service-assurance/prometheus/prometheus.yaml'
    'service-assurance/prometheus/route.yaml'
    'service-assurance/prometheusrules/prometheusrules.yaml'
    'service-assurance/alertmanager/service_account.yaml'
    'service-assurance/alertmanager/secret.yaml'
    'service-assurance/alertmanager/alertmanager.yaml'
    'service-assurance/alertmanager/route.yaml'
    'service-assurance/qdrouterd/qdrouterd.yaml'
    'service-assurance/smartgateway/metrics-smartgateway.yaml'
    'service-assurance/smartgateway/events-smartgateway.yaml'
)

declare -a crds_to_wait_for=(
    'alertmanagers.monitoring.coreos.com'
    'prometheuses.monitoring.coreos.com'
    'prometheusrules.monitoring.coreos.com'
    'qdrs.interconnectedcloud.github.io'
    'servicemonitors.monitoring.coreos.com'
    'smartgateways.smartgateway.infra.watch'
    'elasticsearches.logging.openshift.io'
)

create() {
    object_list=("$@")
    # shellcheck disable=SC2068
    oc create --save-config=true ${object_list[@]/#/-f }
}

delete() {
    object_list=("$@")
    # shellcheck disable=SC2068
    oc delete --wait=true ${object_list[@]/#/-f }
}

wait_for_crds(){
    while true; do
        not_ready=0
        # shellcheck disable=SC2068
        for crd in ${crds_to_wait_for[@]}; do
            echo -n "Checking if '${crd}' is Established..."
            estab=$(oc get crd "${crd}" -o jsonpath='{.status.conditions[?(@.type=="Established")].status}')
            if [ "${estab}" != "True" ]; then
                echo "Not Established"
                not_ready=1
                break
            fi
            echo "Established"
        done
        if [ ${not_ready} -eq 0 ]; then
            break
        fi
        echo "Still waiting on CRDs..."
        sleep 3;
    done

    # "there is a race in Kubernetes that the CRD creation finished but the API
    # is not actually available"
    # https://github.com/coreos/prometheus-operator/issues/1866#issuecomment-419191907
    #
    # This code (ideally this whole function) should go away when we add better
    # failure handling in the operator
    # https://github.com/redhat-service-assurance/smart-gateway-operator/issues/6
    echo 'Confirming we can instantiate a ServiceMonitor'
    until oc create -f - <<EOSM
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: dummy-race-condition-checker
spec:
  endpoints:
    - port: "11111"
  selector:
    matchLabels:
     dummy-race-condition-checker: true
EOSM
    do
        sleep 3;
    done
    oc delete servicemonitor/dummy-race-condition-checker

    # Nothing above actually works to solve the problem, so instead of sleep 300
    # we force the SGO to restart, which DOES solve the problem
    echo 'Restarting SGO to clear API condition'
    oc delete pod -l app=smart-gateway-operator
}

# create the objects
if [ "$method" == "CREATE" ]; then
    echo "  * [ii] Creating the operators" ; create "${operator_list[@]}"
    echo "  * [ii] Waiting for prometheus-operator deployment to complete"
    until oc rollout status dc/prometheus-operator; do sleep 3; done
    echo "  * [ii] Waiting for elasticsearch-operator deployment to complete"
    until oc rollout status deploy/elasticsearch-operator; do sleep 3; done
    echo ""
    echo "+---------------------------------------------------+"
    echo "| Waiting for CRDs to become established in the API |"
    echo "+---------------------------------------------------+"
    echo ""
    wait_for_crds
    echo "  * [ii] Creating the application" ; create "${application_list[@]}"
    echo "  * [ii] Waiting for QDR deployment to complete"
    until oc rollout status deployment.apps/qdr-white; do sleep 3; done
    echo "  * [ii] Waiting for prometheus deployment to complete"
    until oc rollout status statefulset.apps/prometheus-white; do sleep 3; done
    echo "  * [ii] Waiting for elasticsearch deployment to complete"
    ES=$(oc get deployment.apps -l cluster-name=elasticsearch --template='{{range .items}}{{.metadata.name}}{{end}}')
    until oc rollout status deployment.apps/${ES}; do sleep 3; done
    echo "  * [ii] Waiting for smart-gateway deployment to complete"
    until oc rollout status deploymentconfig.apps.openshift.io/cloud1-notify-smartgateway; do sleep 3; done
    until oc rollout status deploymentconfig.apps.openshift.io/cloud1-telemetry-smartgateway; do sleep 3; done
    echo "  * [ii] Waiting for all pods to show Ready"
    while oc get pods -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}' | grep False; do
        oc get pods
        sleep 3
    done
fi

# delete the objects
if [ "$method" == "DELETE" ]; then
    echo "  * [ii] Deleting the application" ; delete "${application_list[@]}"
    echo ""
    echo "+--------------------------------------------------------+"
    echo "| Press Ctrl+C when only operators are marked as Running |"
    echo "+--------------------------------------------------------+"
    echo ""
    trap ' ' INT
    oc get pods -w
    echo "  * [ii] Deleting the operators" ; delete "${operator_list[@]}" ; oc delete service alertmanager-operated prometheus-operated
fi

echo "-- Completed."
exit 0
