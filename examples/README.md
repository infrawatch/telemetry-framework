# 61will.space worked example

This folder contains a worked example for `61will.space`, the home lab of [Leif
Madsen](http://blog.leifmadsen.com/).

In this simplified example I build out a development system using a single
physical machine with 64GB of memory, which is a decent enough system that
likely matches real work development systems.

## Overview

In my lab environment, I have a single whitebox desktop with 64GB of memory, 2
disk drives (host operating system drive, storage M.2 disk for fast spin up of
virtual machines mounted at `/home/`), Intel i7 CPU, and 2+ network interfaces
(one for management, one for bridged interfaces assigned to the virtual
machines).

The physical machine will host the blue and green side of the telemetry
framework platform running on top of OpenShift 3.9. I'll then create 2 virtual
machines which will simulate the OpenStack compute nodes that we would be
monitoring. Running on those two virtual machines will be Docker that will
execute the barometer and QPID dispatch router (QDR) containers that will
connect back to the telemetry framework platform. All virtual machines will be
running CentOS 7.5 as deployed from
[base-infra-bootstrap](https://github.com/redhat-nfvpe/base-infra-bootstrap).

## Prerequisites

Other than the virtual machine host (described above) requiring a base
operating sytem (CentOS 7.5 recommended), the only other infrastructure setup
you need is DNS. In my lab environment I run an Ubiquiti EdgeRouter that
provides DNS to all the nodes, including the wildcard configuration for the
`*.apps.home.61will.space` DNS namespace. Your environment may not have this
capability, in which case you'll need to run an additional DNS server with
DNSmasq.

**TODO**: _build virtual machine with DNSmasq per our existing documentation to
make the worked example more complete for environments without external DNS
configuration abilities._

## Inventory

The inventory files that live in this directory are directly applicable to my
single node environment. You can use them as a starting example, but unless you
have a network namespace setup the same as mine, you're going to be expected to
modify the inventory files to match your network setup. Luckily, it should be
pretty straight forward to modify the base files.

Here is our directory structure for the worked example:

    .
    ├── inventory
    │   ├── blue.vars
    │   ├── green.vars
    │   ├── telemetry.inventory
    │   └── virthost.inventory
    └── README.md

### virthost.inventory

The first file to modify is our `virthost.inventory` file. This contains the
location of our virthost (physical) machine that will run our virtual machines.

The only thing you should need to change is the `ansible_host=virthost` section
on the first line. Alternatively, create an entry in your `/etc/hosts` file
which points at the IP address for your `virthost` machine. Validate this file
works with the following command.

    ansible -i inventory/virthost.inventory -m raw -a "echo hello" virthosts
    virt_host | SUCCESS | rc=0 >>
    hello
    Shared connection to virthost closed.

### blue and green vars files

This step is arguable the most critical to get right. Take your time here and
make sure you have all the networking setup properly, the hostnames, directory
paths, etc. If the `vars` files are wrong, you're going to run into problems
with the installation.

Both the `blue` and `green` files are very similar to each other; the primary
difference is they split the OpenShift infrastructure across two physical
nodes. In our case we're only using a single node, so in theory we could
flatten this file out, but it could be useful to have them separated so you can
get a better idea how a dual-node system would be created.

Let's work through the various sections of the `blue.vars` file. You'll do the
same work in the `green.vars` file when you're done.

    centos_genericcloud_url: https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2
    image_destination_name: CentOS-7-x86_64-GenericCloud.qcow2
    host_type: "centos"
    images_directory: /home/images/telemetryframework
    spare_disk_location: /home/images/telemetryframework
    ssh_proxy_user: root
    ssh_proxy_host: virthost
    vm_ssh_key_path: /home/lmadsen/.ssh/bluetf

## Deployment

The first step (after getting your virthost machine setup with an operating
system, networking, SSH, etc.) is to create the virtual machines for our
environment.

The virtual machines are created via the
[base-infra-bootstrap](https://github.com/redhat-nfvpe/base-infra-bootstrap)
playbooks.

**TODO:** _below is work in progress and needs fleshing out; just raw commandst _

    for n in blue green; do ansible-playbook -i ../inventory/virthost.inventory -e "@../inventory/$n.vars" playbooks/vm-teardown.yml playbooks/virt-host-setup.yml ; done

Then install NetworkManager (required for 3.9, but no provided by OpenShift
Ansible playbooks).

    ansible -i ../inventory/telemetry.inventory -m raw --become -a "yum install NetworkManager -y; systemctl enable NetworkManager.service ; systemctl start NetworkManager.service"

Back to installing OpenShift. Need to bootstrap first.

    cd ~/src/github/redhat-nfvpe/telemetry-framework
    ./scripts/bootstrap.sh
    cd working/openshift-ansible
    ansible-playbook -i ../../examples/61will.space/inventory/telemetry.inventory playbooks/prerequisites.yml playbooks/deploy_cluster.yml
