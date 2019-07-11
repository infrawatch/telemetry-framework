#!/bin/sh
#set -e

# OC command line tools
OC_VER=v3.11.0
OC_HASH=0cbc58b
OC_NAME="openshift-origin-client-tools-${OC_VER}-${OC_HASH}-linux-64bit"
wget https://github.com/openshift/origin/releases/download/${OC_VER}/${OC_NAME}.tar.gz
tar -xvzf ${OC_NAME}.tar.gz 
sudo mv ${OC_NAME}/oc /usr/local/bin/

# Start the containerized openshift
sudo sed -i "s/\DOCKER_OPTS=\"/DOCKER_OPTS=\"--insecure-registry=172.30.0.0\/16 /g" /etc/default/docker
sudo cat /etc/default/docker
sudo service docker restart
oc cluster up --public-hostname=$(hostname) #--base-dir /var/lib/minishift
