Telemetry Framework Installation
================================

Once you have your `OpenShift environment setup <platform_installation.html>`__
you can install the core components of the telemetry framework.

Installation of telemetry framework is handled through the use of Kubernetes
spec objects that you load into OpenShift via the `oc` console (or web
interface should you so desire). These spec objects set the desired state for
the object, for example, creating a Deployment. The spec objects for the
telemetry framework can be found in the `deploy/` directory of the
`telemetry-framework` repository hosted on GitHub.

These spec objects then load the various `Operators
<https://coreos.com/blog/introducing-operators.html>`__ into memory. We can
then load some additional spec objects into memory where the Operators will
start to deploy our various application components for us, and managing their
lifecycle, application configurations, etc.

Installation
------------

There are 3 core components to the telemetry framework:

* Prometheus (and the AlertManager)
* Smart Gateway
* QPID Dispatch Router

Each of these components has a corresponding Operator that we'll use to spin up
the various application components and objects.

Using the provided script
~~~~~~~~~~~~~~~~~~~~~~~~~

You can use the provided script in the `deploy/` directory of the
`telemetry-framework` repository. Simply run the `deploy.sh` script with no
arguments (or the `CREATE` argument) to instantiate the various components in
your OpenShift deployment. If you want to remove the components you can supply
the `DELETE` argument to the script.

Prior to running the `deploy.sh` script you must already be logged into
OpenShift as an administrator, and have the `oc` application readily available
in your `$PATH`. The script will do some basic checks to make sure this is
true.

Additionally, the script will switch to the `sa-telemetry` namespace prior to
deploying, and if it can't find that namespace, will attempt to create it.

To deploy telemetry framework from the script, simply run the following command
after cloning the `telemetry-framework` repo into the following directory.

    cd ~/src/github.com/redhat-service-assurance/telemetry-framework/deploy/
    ./deploy.sh CREATE

Deploying manually
~~~~~~~~~~~~~~~~~~

If you want to deploy the components manually you can review the
order-of-operations within the `deploy.sh` script for the recommended object
creation order.

The high level order would be:

* deploy the Operators first (order does not matter)
* deploy the application components

Each of the Operators have a similar directory layout, and you should install
the objects in this order:

* service account
* role
* role binding
* operator

For the applications they also have a similar layout and the recommended order
is (with some objects not part of all application components):

* service account
* role
* role binding
* config map
* secret
* deployment
* route

.. vim: set shiftwidth=4 tabstop=4 expandtab smartindent ft=rst:
