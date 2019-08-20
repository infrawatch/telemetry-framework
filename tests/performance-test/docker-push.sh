#!/bin/bash

#Automates creating and pushing new performance test image to minishift registry

DOCKER_IMAGE=$(minishift openshift registry)/$(oc project -q)/performance-test:dev

oc delete job saf-performance-test
oc delete is performance-test
minishift ssh -- docker container prune -f
IMG=$(minishift ssh -- docker images | grep performance-test | awk '{print $3}')
minishift ssh -- docker rmi "$IMG"

docker build -t "$DOCKER_IMAGE" .
docker push "$DOCKER_IMAGE"

