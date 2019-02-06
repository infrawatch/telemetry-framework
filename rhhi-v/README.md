# Red Hat Hyperconverged Infrastructure

In this directory are the playbooks and roles to automate the installation of
OpenShift 3.11 on top of RHHI-V (Red Hat Hyperconverged Infrastructure for
Virtualization) which is made up of RHV for virtualization + GlusterFS for
replicated storage across the cluster.

# Quickstart

    cd rhhi/
    ansible-galaxy install -r requirements.yml
    # <modify your inventory>
    ansible-playbook -i inventory/v3.11/nfvha-lab -e "@./vars/rhsub.vars" \
        --vault-password-file=~/ansible/vault.sh playbooks/vm-infra.yml

# Prerequisites

You must install RHHI-v along with a working engine so that we can connect to
it via the Ansible roles supplied by the oVirt team. Testing for upstream and
downstream installations have been performed. For upstream (oVirt) installation
you won't need to supply the `rhsub.vars` file which contains the login for
registering your virtual machines.

Downloading of the RHEL 7.6 qcow2 image is a manual step that must be performed
after installation of the RHHI-V engine.

More information about RHHI-V is available at
https://access.redhat.com/products/red-hat-hyperconverged-infrastructure or for
upstream see https://www.ovirt.org/documentation/gluster-hyperconverged/
