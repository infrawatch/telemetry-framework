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
    'operators/qdrouterd/crds/interconnectedcloud_v1alpha1_qdrouterd_crd.yaml'
    'operators/qdrouterd/service_account.yaml'
    'operators/qdrouterd/role.yaml'
    'operators/qdrouterd/role_binding.yaml'
    'operators/qdrouterd/operator.yaml'
    'operators/smartgateway/crds/smartgateway_v1alpha1_smartgateway_crd.yaml'
    'operators/smartgateway/service_account.yaml'
    'operators/smartgateway/role.yaml'
    'operators/smartgateway/role_binding.yaml'
    'operators/smartgateway/operator.yaml'
)

declare -a application_list=(
    'service-assurance/qdrouterd/qdrouterd-interior.yaml'
    'service-assurance/smartgateway/smartgateway.yaml'
    'service-assurance/prometheus/service_account.yaml'
    'service-assurance/prometheus/role.yaml'
    'service-assurance/prometheus/rolebinding.yaml'
    'service-assurance/prometheus/service_monitor.yaml'
    'service-assurance/prometheus/prometheus.yaml'
    'service-assurance/prometheus/route.yaml'
    'service-assurance/prometheusrules/prometheusrules.yaml'
    'service-assurance/grafana/service_account.yaml'
    'service-assurance/grafana/secret.yaml'
    'service-assurance/grafana/configmap-dashboard-definitions.yaml'
    'service-assurance/grafana/configmap-datasource.yaml'
    'service-assurance/grafana/configmap-dashboards.yaml'
    'service-assurance/grafana/deploymentconfig.yaml'
    'service-assurance/grafana/service.yaml'
    'service-assurance/grafana/route.yaml'
    'service-assurance/alertmanager/service_account.yaml'
    'service-assurance/alertmanager/secret.yaml'
    'service-assurance/alertmanager/alertmanager.yaml'
    'service-assurance/alertmanager/service.yaml'
    'service-assurance/alertmanager/route.yaml'
)

create() {
    # create our objects by building a list
    built_list=""
    object_list=("$@")
    for spec in ${object_list[@]}; do
        built_list+=" -f $spec"
    done

    oc create --save-config=true $built_list
}

delete() {
    # delete our objects by building a list
    built_list=""
    object_list=("$@")
    for (( idx=${#object_list[@]}-1 ; idx >= 0 ; idx-- )); do
        built_list+=" -f ${object_list[idx]}"
    done

    oc delete --wait=true $built_list
}

# create the objects
if [ "$method" == "CREATE" ]; then
    echo "  * [ii] Creating the operators" ; create ${operator_list[@]} && sleep 5
    echo "  * [ii] Creating the application" ; create ${application_list[@]}
fi

# delete the objects
if [ "$method" == "DELETE" ]; then
    echo "  * [ii] Deleteing the application" ; delete ${application_list[@]} && sleep 5
    echo "  * [ii] Deleteing the operators" ; delete ${operator_list[@]}
fi

echo "-- Completed."
exit 0
