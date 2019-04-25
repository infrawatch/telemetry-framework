Platform Installation
=====================

The installation of the telemetry framework simply requires the deployment of
OpenShift 3.11 or later and bastion node for executing the supplied
`bash` script to load the components into the `sa-telemetry` namespace. As we
documented in the `architecture overview <architecture.html>`__.

Our reference implementation leverages 3 physical nodes using oVirt
hyperconverged platform which provides us with virtualization and distributed
storage.

More information about deploying oVirt hyperconverged in a 1 or 3 node
configuration is available at `oVirt Gluster-Hyperconverged documentation
<https://ovirt.org/documentation/gluster-hyperconverged/chap-Introduction.html>`__.

Once you have the platform installed, then we can install OpenShift and
Telemetry Framework.

Deploying OpenShift Via Ansible
-------------------------------
