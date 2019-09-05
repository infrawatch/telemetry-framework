# Setup and Deploy Performance Test

## Environment

minishift v1.34.1
docker v17.05+

### Setup

SAF must already be deployed on a local minishift with the registry-route addon
enabled. A quick way to do this is using the `quickstart.sh` script in
`telemetry-framework/deploy/` directory to run SAF upstream version (quickstart
 can also be used to deploy the downstream):

```shell
minishift addons enable registry-route   # Run BEFORE starting minishift
minishift start
eval $(minishift oc-env)
cd $WORKDIR/telemetry-framework/deploy/; ./quickstart.sh
```

More details about deploying SAF on Minishift can be found in the
[SAF deployment docs](../../../deploy/)

The Minishift registry needs to be configured such that a local docker image can
be pushed to it. To do this, a new account must be created on Minishift that has
admin privledges. The default admin account cannot be used because it does not
provide a token with which to login to the registry with docker.

```shell
oc login -u developer -p passwd   # create new user if it does not already exist
oc login -u system:admin
oc adm policy add-cluster-role-to-user cluster-admin developer  # give user admin privlidges
oc login -u developer -p passwd
oc project sa-telemetry          # must use same project as SAF
```

## Build

Minishift does not have an up-to-date version of docker and cannot execute
multistage builds. As a result, the performance test image must be built locally
with docker v17.05 or higher and pushed to the minshift internal docker registry.

The Minishift registry must be registered as an insecure registry for the local
docker daemon to be able to push to it. On Fedora 30, this can be done like so:

```shell
$ echo { \"insecure-registries\" : [\"$(minishift openshift registry)\"] } \
| sudo tee  /etc/docker/daemon.json # add -a if you wish to preserve other insecure registry configurations
$ sudo systemctl daemon-reload
$ sudo systemctl restart docker
$ docker login -u developer -p $(oc whoami -t) $(minishift openshift registry) # log in to registry
```

Check that docker is using the new registry - the address should match that
shown by `oc get routes -n default`

```shell
$ docker info
[...]
Insecure Registries:
 docker-registry-default.192.168.42.121.nip.io
```

Create and push the image to the Minishift registry

```shell
cd $WORKDIR/telemetry-framework/tests/performance-test/
DOCKER_IMAGE="$(minishift openshift registry)/$(oc project -q)/performance-test:dev"
docker build -t $DOCKER_IMAGE .
docker push $DOCKER_IMAGE   #sometimes this needs to be run more than once
```

Note: if an earlier version of the performance test image has been previously
uploaded to the Minishift registry, the previous image stream and associated
containers must be deleted before pushing up the new version else it will not
be properly updated. Refer to the `performance-test/docker-push.sh` steps to
do that.

## Deploy

Ensure that all of the SAF pods are already marked running with `oc get pods`.
Next, launch the grafana instance for test results gathering. This only needs
to be done once:

```shell
cd $WORKDIR/telemetry-framework/tests/performance-test/deploy
./grafana-launcher.sh
```

The grafana launcher script will output a URL that can be used to log into the
dashboard. This Grafana instance has all authentication disabled - if, in the
future, the performance test should report to an authenticated grafana instance,
the test scripts must be modified. Once the Grafana instance is running, launch
the performance test OpenShift job:

```shell
./performance-test.sh
```

This will run all of the tests specified in the test-configs.yaml file in
sequence.

Monitor the performance test status by watching the job with
`oc get job saf-performance-test -w`. The job will run for the sum of the lengths
of all of the tests in the test-config file. Logs can be viewed with
`oc logs -f saf-performance-test-<unique-pod-id>`
