.. Telemetry Framework documentation master file, created by
   sphinx-quickstart on Wed Apr  3 10:56:17 2019.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.


===============================================

Project Overview
----------------

The telemetry framework is a system that allows for collection of metrics and
events using collectd (or other collection methods that support an AMQP 1.x
Proton client connection), sending them across an AMQP 1.x message bus back to
the server side for storage (such as Prometheus, ElasticSearch, etc).

Once data is stored, metrics and events can be used as the sources for alerts,
visualization, or the source of truth for orchestration frameworks.

Since the project is a framework, you can also add, remove, or replace
components within the telemetry deployment. For example, you might add Grafana
for visualization, or integrate third-party applications to leverage the data
for automate decision making, or predicting long term trends.

Get The Code
------------

The `source <https://github.com/redhat-service-assurance/telemetry-framework>`_
is available on GitHub.

Contents
--------

.. toctree::
   :maxdepth: 2
   :glob:

   architecture

Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`

