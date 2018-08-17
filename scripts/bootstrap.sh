#!/usr/bin/env bash

BASE_INFRA_BOOTSTRAP_GIT_REPO="https://github.com/redhat-nfvpe/base-infra-bootstrap"
OPENSHIFT_GIT_REPO="https://github.com/openshift/openshift-ansible"
OPENSHIFT_BRANCH="openshift-ansible-3.9.39-1"
_TOPDIR=`pwd`

echo "-- Create working directory"
if [ ! -d working ]; then
    mkdir working
fi

pushd working

    echo "-- Clone base-infra-bootstrap"
    git clone --depth 1 --branch master ${BASE_INFRA_BOOTSTRAP_GIT_REPO} > /dev/null 2>&1
    pushd base-infra-bootstrap
        ansible-galaxy install -r requirements.yml
    popd

    echo "-- Clone OpenShift ${OPENSHIFT_BRANCH}"
    git clone --depth 1 --branch ${OPENSHIFT_BRANCH} ${OPENSHIFT_GIT_REPO} > /dev/null 2>&1

    echo "-- Overlay telemetry-framework on openshift-ansible"
    pushd openshift-ansible
        echo "  -- apply components.yml patch"
        patch -p1 < $_TOPDIR/patches/components.yml.patch > /dev/null 2>&1

        echo "  -- link playbooks"
        pushd playbooks
        cp -r $_TOPDIR/playbooks/* ./
        popd

        echo "  -- link roles"
        pushd roles
        cp -r $_TOPDIR/roles/* ./
        popd

        # ignore symlinks we're adding
        cat > .gitignore <<EOF
playbooks/sa-telemetry
roles/sa_telemetry*
EOF
    popd

popd

echo "-- Done."
