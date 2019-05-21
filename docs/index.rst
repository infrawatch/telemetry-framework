.. _ProjectOverview:

================
Project Overview
================

The telemetry framework is a system that allows for collection of metrics and
events using collectd (or other collection methods that support an AMQP 1.x
Proton client connection), sending data streams across an AMQP 1.x message bus
back to the server side for storage (such as Prometheus, ElasticSearch, etc).

Once data is stored, metrics and events can be used as the sources for alerts,
visualization, or the source of truth for orchestration frameworks.

Since the project is a framework, you can also add, remove, or replace
components within the telemetry deployment. For example, you might add Grafana
for visualization, or integrate third-party applications to leverage the data
for automate decision making, or predicting long term trends.

.. admonition:: About Documentation and Repository Structure

    While the telemetry framework subscribes to an upstream-first mentality, it is
    also developed primarily against products within Red Hat. All of these products
    complimentary upstream projects. Within this documentation, we're going to be
    referencing to documentation sources that are possibly not applicable to you.

    For example, the reference deployment currently in development uses the oVirt
    Hyperconverged system which is known as RHHI-V (Red Hat Hyperconverged
    Infrastructure for Virtualization). The telemetry framework has been tested
    against both the upstream and downstream versions of the application [#]_.
    That goes also for the OKD/OpenShift (Kubernetes) platform, RHOSP (OpenStack)
    and the operating system RHEL (CentOS).

    The documentation will be written from the perspective of installing from the
    downstream perspective, but we will do our best to provide sidebars pointing
    back to the equivalent upstream documentation.

    Within the repository, we've also done our best to provide an upstream-centric
    deployment as well, but note that our primary focus is on support for the
    downstream products at this time. If you happen to find an area which is
    missing the upstream-first component (documentation, examples, scripts), please
    an issue and we'll get it resolved as quickly as possible.

    .. [#] The telemetry framework is also known as a micro-service application,
        meaning that multiple containers are run and connected together using an
        orchestration platform.

Get The Code
------------

The `source <https://github.com/redhat-service-assurance/telemetry-framework>`_
is available on GitHub.

Contents
--------

.. toctree::
   :maxdepth: 2
   :glob:

   overview
   architecture
   installation_platform
   installation_telemetry_framework
   installation_client

Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
