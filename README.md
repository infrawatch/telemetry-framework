# telemetry-framework

The telemetry framework is a project that aims to centralize metrics and events
of various platform components (not applications) in order to provide a
centralized view of multiple platform deployments.

Telemetry framework is also known as Service Assurance (SA), or Service
Assurance Framework, and naming may be interchangable throughout the
documentation.

## Documentation

Documentation is available in the [documentation](docs/README.md) folder.

## Installation

Installation of the telemetry framework is currently being developed. The
recommended installation method out of this repository is currently to leverage
RHV (Red Hat Virtualization) on top of RHEL to build out a place to run the
initial bits of infrastructure.

## Dependencies

The focus of this repository is to gather the information required to build out
the infrastructure to result in a near-production (i.e. staging) environment
for evaluation of the telemetry framework micro-service application, which runs
on top of OpenShift. It is installed via the [Automation
Broker](https://automationbroker.io) using an Ansible Playbook Bundle.

The primary dependency is to provide an OpenShift cluster (virtual or
otherwise) which has a working `ansible-service-broker` and service catalog,
pointing at a registry with the APB available to it, and listed in the service
catalog. OpenShift must also have persistent storage configured so that
persistent volume claims (PVC) can be made by the APB for persistent storage.

Our testing and automation were designed with GlusterFS in mind for the
persistent storage backend. Using other methods may result in issues that we
haven't seen.
