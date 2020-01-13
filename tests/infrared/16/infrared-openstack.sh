#!/usr/bin/env bash
set -e

# Usage:
#  VIRTHOST=my.big.hypervisor.net
#  ./infrared-openstack.sh

VIRTHOST=${VIRTHOST:-my.big.hypervisor.net}
AMQP_HOST=${AMQP_HOST:-saf-default-interconnect-5671-sa-telemetry.apps-crc.testing}
AMQP_PORT=${AMQP_PORT:-443}
SSH_KEY="${SSH_KEY:-${HOME}/.ssh/id_rsa}"
VM_IMAGE="${VM_IMAGE:-http://download.devel.redhat.com/brewroot/packages/rhel-guest-image/8.1/333/images/rhel-guest-image-8.1-333.x86_64.qcow2}"
OSP_BUILD="${OSP_BUILD:-latest-RHOS_TRUNK-16-RHEL-8.1}"
NTP_SERVER="${NTP_SERVER:-8.8.8.8}"

infrared virsh \
    -vv \
    -o outputs/cleanup.yml \
    --host-address "${VIRTHOST}" \
    --host-key "${SSH_KEY}" \
    --cleanup yes

infrared virsh \
    -vvv \
    -o outputs/provision.yml \
    --topology-nodes undercloud:1,controller:1,compute:1 \
    --host-address "${VIRTHOST}" \
    --host-key "${SSH_KEY}" \
    --image-url "${VM_IMAGE}" \
    --host-memory-overcommit True \
    -e override.controller.cpu=8 \
    -e override.controller.memory=16384

infrared tripleo-undercloud \
    -vv \
    -o outputs/undercloud-install.yml \
    --mirror rdu2 \
    --version 16 \
    --build "${OSP_BUILD}" \
    --registry-mirror docker-registry.engineering.redhat.com \
    --registry-undercloud-skip no

infrared tripleo-undercloud -vv \
   -o outputs/images_settings.yml \
   --images-task rpm \
   --build "${OSP_BUILD}" \
   --images-update no

sed -e "s/<<AMQP_HOST>>/${AMQP_HOST}/;s/<<AMQP_PORT>>/${AMQP_PORT}/" metrics-collectd-qdr.yaml.template > outputs/metrics-collectd-qdr.yaml

infrared tripleo-overcloud \
    -vv \
    -o outputs/overcloud-install.yml \
    --version 16 \
    --deployment-files virt \
    --overcloud-debug yes \
    --network-backend vxlan \
    --network-protocol ipv4 \
    --storage-backend lvm \
    --storage-external no \
    --overcloud-ssl no \
    --tls-everywhere no \
    --network-dvr false \
    --network-lbaas false \
    --vbmc-force true \
    --introspect yes \
    --tagging yes \
    --deploy yes \
    --public-network yes \
    --public-subnet default_subnet \
    --containers yes \
    --registry-mirror docker-registry.engineering.redhat.com \
    --overcloud-templates outputs/metrics-collectd-qdr.yaml \
    --registry-undercloud-skip no
