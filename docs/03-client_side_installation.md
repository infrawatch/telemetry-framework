Installation of the client will result in two containers running, along with two folders
installed on the host system which provides the configuration to the Docker containers.

Containers being installed and executing will be `barometer` and `qdr` for the Barometer
collectd and the local QPID Dispatch Router.

# Configuration

Configuration of the clients requires an inventory file, along with a `vars` file, or
alternatively, overrides placed directly in the inventory file.

An example inventory is located in the `inventory/examples/cloud` file. Defaults that can
be overridden are located in the `roles` directory within
`roles/telemetry.qdr-deployer/defaults/main.yml` and 
`roles/telemetry.barometer-deployer/defaults/main.yml`.

The defaults for the QDR deployment assumes you're deploying in an internal lab, so you'll
need to override the values for the DNS server, and the hostname/port for where the QDR
should connect.

The defaults for the barometer deployment assumes that you're connecting to a local QDR
that is available via localhost. There should be changes necessary, unless you want to
change the list of modules being loaded.

Configurations are templated, but fairly static as of now. You may want to deploy and then
manually tweak the configurations, or change the templates locally if you have a lot of
nodes you're deploying to.

# Deployment

Deployment of the clients can be found in the [README](https://github.com/redhat-nfvpe/telemetry-ansible/blob/master/README.md)
