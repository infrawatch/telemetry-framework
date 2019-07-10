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
    'service-assurance/qdrouterd/qdrouterd.yaml'
    'service-assurance/smartgateway/smartgateway.yaml'
    'service-assurance/prometheus/service_account.yaml'
    'service-assurance/prometheus/role.yaml'
    'service-assurance/prometheus/rolebinding.yaml'
    'service-assurance/prometheus/service_monitor.yaml'
    'service-assurance/prometheus/prometheus.yaml'
    'service-assurance/prometheus/route.yaml'
    'service-assurance/prometheusrules/prometheusrules.yaml'
    'service-assurance/alertmanager/service_account.yaml'
    'service-assurance/alertmanager/secret.yaml'
    'service-assurance/alertmanager/alertmanager.yaml'
    'service-assurance/alertmanager/service.yaml'
    'service-assurance/alertmanager/route.yaml'
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

# create the objects
if [ "$method" == "CREATE" ]; then
    echo "  * [ii] Creating the operators" ; create "${operator_list[@]}"
    echo ""
    echo "+--------------------------------------------------------+"
    echo "| Waiting for prometheus-operator deployment to complete |"
    echo "+--------------------------------------------------------+"
    echo ""
    oc rollout status dc/prometheus-operator
    oc get pods
    echo "  * [ii] Creating the application" ; create "${application_list[@]}"
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
