source ./config

infrared tripleo-overcloud -vv \
    -o outputs/overcloud-install.yml \
    --version 16 \
    --deployment-files virt \
    --overcloud-templates outputs/metrics-collectd-qdr.yaml \
    --overcloud-debug yes \
    --network-backend geneve \
    --network-protocol ipv4 \
    --network-dvr yes \
    --storage-backend lvm \
    --storage-external no \
    --overcloud-ssl no \
    --introspect yes \
    --tagging yes \
    --deploy yes \
    --ntp-server ${NTP_SERVER} \
    --containers yes

#infrared tripleo-overcloud \
#    -vv \
#    -o outputs/overcloud-install.yml \
#    --version 16 \
#    --deployment-files virt \
#    --overcloud-templates outputs/metrics-collectd-qdr.yaml \
#    --overcloud-debug yes \
#    --network-backend geneve \
#    --network-protocol ipv4 \
#    --network-dvr yes \
#    --storage-backend lvm \
#    --storage-external no \
#    --overcloud-ssl no \
#    --introspect yes \
#    --tagging yes \
#    --deploy yes \
#    --ntp-server ${NTP_SERVER} \
#    --tls-everywhere no \
#    --network-lbaas false \
#    --vbmc-force true \
#    --introspect yes \
#    --public-network yes \
#    --public-subnet default_subnet \
#    --containers yes \
#    --registry-mirror docker-registry.engineering.redhat.com \
#    --registry-undercloud-skip no
