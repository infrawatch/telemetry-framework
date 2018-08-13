# Pre-requisites Overview

Prior to deploying the telemetry platform, there is some pre-requisite builds that need to happen. Items that
need building include:

* barometer-collectd container (with patches)
* metrics and events consumer containers
* QPID dispatch router container

## barometer-collectd

The `barometer-collectd` container is made up of two components:

* forked barometer
* forked collectd

When building the `barometer-collectd` container, you'll make use of a multi-stage Docker build which pulls code from
a collectd git repository containing upstream changes that are not yet fully merged.

Code for these components are available at:

* https://github.com/redhat-nfvpe/barometer/tree/nfvpe/develop
* https://github.com/redhat-nfvpe/collectd/tree/collectd-5.8

The `barometer` changes are from the following upstream contributions:

* https://gerrit.opnfv.org/gerrit/#/c/53805/

The `collectd` changes are from the following upstream contributions

* [Write amqp1 plugin](https://github.com/collectd/collectd/pull/2618)
* [Red Hat NFVPE Connectivity Plugin](https://github.com/collectd/collectd/pull/2622)
* [Red Hat NFVPE Procevent Plugin](https://github.com/collectd/collectd/pull/2623)
* [Red Hat NFVPE Sysevent Plugin](https://github.com/collectd/collectd/pull/2624)
* [Notification nested metadata](https://github.com/collectd/collectd/pull/2705)

## metrics and events consumers

The metrics and events consumers are custom code that will (ideally) eventually make its way into the OPNFV
Barometer project as their upstream homes.

* [metrics and events consumers source](https://github.com/redhat-nfvpe/service-assurance-poc)
* [Dockerfiles for building](https://github.com/redhat-nfvpe/service-assurance-poc/tree/master/docker)

## QPID dispatch router (QDR)

Building QPID dispatch router container is primarily just a function of building an RPM, and installing that
during container build time. We currently do not have any custom patches/code for the QDR. This is simply
a packaging effort.

* [instructions for building QDR RPMs](https://github.com/redhat-nfvpe/service-assurance-poc/tree/master/qdr)
* [Dockerfile for creating QDR container](https://github.com/redhat-nfvpe/service-assurance-poc/tree/master/docker/qdr)

# Building Containers

Four container images need to be built for telemetry.

* barometer-collectd
* metrics consumer
* events consumer
* QPID dispatch router (QDR)

The instructions for building these images is being performed in a virtual machine running Fedora 28.

## Install Prerequisites

You'll need the following tools installed.

* git
* mock

```
sudo dnf install git mock -y
```

## Installing Docker

In Fedora 28, the latest version of Docker currently being shipped is Docker 1.13, which does not have multi-stage build
capabilities. We'll need to install the Docker-CE repository and install Docker 16.x which has multi-stage building. We make
use of the multi-stage build process in Docker to keep the images small, and the development tools and source off the
base image.

Work is being performed as a non-root user (`admin` user in this case).

```
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager \
    --add-repo \
    https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf config-manager --set-enabled docker-ce-edge
sudo dnf install docker-ce -y
sudo usermod -aG docker admin
newgrp docker
```

> **Login to Docker Hub**
>
> In order to push your images into a Docker Hub repository (or quay.io, or wherever you want to store your images), you'll
> need to login first. For Docker Hub you can just use `docker login` first before running the following builds.

## barometer-collectd

```
cd ~
git clone https://github.com/redhat-nfvpe/barometer
cd barometer/
git fetch --all
git checkout nfvpe/develop
docker build --tag nfvpe/barometer-collectd:latest --file ./docker/barometer-collectd/Dockerfile .
docker push nfvpe/barometer-collectd:latest
```

## Consumers

There are two consumers you need to build; metrics and events. The metrics container acts as the scrape target for
Prometheus, and also pulls messages off the QDR bus. The events container takes events from the QDR message bus and
stores them into an ElasticSearch database.

See `README.md` in the `service-assurance-poc` repository within the `docker/` subdirectory for more information about
building.

We'll build both consumers from the `service-assurance-poc` git repository.

```
cd ~
git clone https://github.com/redhat-nfvpe/service-assurance-poc.git
```

### Events consumer

```
cd ~/service-assurance-poc/
docker build --tag nfvpe/events_consumer:latest -f docker/events/Dockerfile .
```

### Metrics consumer

```
cd ~/service-assurance-poc/
docker build --tag nfvpe/metrics_consumer:latest -f docker/metrics/Dockerfile .
```

## QPID Dispatch Router (QDR)

The QPID Dispatch Router (QDR) has a slightly different build mechanism. Instead of compiling everything directly
in the container and copying things over, we build a local RPM using `mock` and then do a `COPY` of the RPMs into
the container image, where QDR is then installed.

### Building the RPMs

Build the RPMs into your working directory using the provided script in the `service-assurance-poc` repository.

```
sudo usermod -aG mock admin
newgrp mock
cd ~/service-assurance-poc/qdr/
./buildit.sh
```

### Building the container image

Now we build the container image much like we did for the events and metrics consumers.

```
cd ~/service-assurance-poc/
docker build --tag nfvpe/qpid-dispatch-router:latest -f docker/qdr/Dockerfile .
```
