#!/usr/bin/env bash

# WARNING! This is going to destroy stuff without asking. Should have read the
#          code before running this!

inventory=61will.space_dev

#*** clean
for d in base-infra-bootstrap openshift-ansible
do
    rm -rf working/$d
done

#*** bootstrap
./scripts/bootstrap.sh

#*** build inventory
cp ./examples/${inventory}/inventory/base-infra-bootstrap/* ./working/base-infra-bootstrap/inventory/
cp ./examples/${inventory}/inventory/openshift-ansible/* ./working/openshift-ansible/inventory/

#*** teardown and rebuild the environment
pushd working/base-infra-bootstrap
    ansible-playbook -i inventory/virthost.inventory -e "@./inventory/nodes.vars" \
        playbooks/vm-teardown.yml \
        playbooks/virt-host-setup.yml
popd

#*** run pre-openshift installation script
ansible --ssh-common-args="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" \
    --inventory working/openshift-ansible/inventory/telemetry.inventory \
    --module-name script \
    --become \
    --args "./scripts/post_install.sh" all

#*** install openshift with openshift-ansible
pushd working/openshift-ansible
    ansible-playbook -i inventory/telemetry.inventory \
        playbooks/prerequisites.yml \
        playbooks/deploy_cluster.yml
popd

exit 0
