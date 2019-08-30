# Configuring Service Assurance Framework for Multiple Clouds

Multiple Openstack clouds can be configured to target a single instance of SAF.
There are a few steps to get this set up:

1. Plan the AMQP address prefixes to use for each cloud
1. Deploy metrics and notification SmartGateways for each cloud to listen on the
  corresponding address prefixes
1. Configure each cloud to send it's metrics and notifications to SAF on the
  correct address

## AMQP addresses

By default, OSP nodes are configured to send data to the `collectd/telemetry`
and `collectd/notify` addresses on the AMQP bus; and SAF is configured to
listen on those addresses for monitoring data. In order to support multiple
clouds and have the ability to easily identify which cloud genereated which
monitoring data, each cloud should be configured to send to a unique address.

It is recommended to prefix a cloud identifier to the second part of the
address. For example:

* collectd/cloud1-telemetry
* collectd/cloud1-notify
* collectd/cloud2-telemetry
* collectd/cloud2-notify
* collectd/us-east-1-telemetry
* collectd/us-west-3-telemetry
* ...etc

## Deploying SmartGateways

Two SmartGateways (one for metrics, one for events) need to be deployed
for each cloud, configured to listen on the correct AMQP address. For example:

```yaml
apiVersion: smartgateway.infra.watch/v1alpha1
kind: SmartGateway
metadata:
  name: cloud1-telemetry
spec:
  amqp_url: qdr-white.sa-telemetry.svc.cluster.local:5672/collectd/cloud1-telemetry
  serviceType: metrics

---
apiVersion: smartgateway.infra.watch/v1alpha1
kind: SmartGateway
metadata:
  name: cloud1-notify
spec:
  amqp_url: qdr-white.sa-telemetry.svc.cluster.local:5672/collectd/cloud1-notify
  serviceType: events

---
apiVersion: smartgateway.infra.watch/v1alpha1
kind: SmartGateway
metadata:
  name: cloud2-telemetry
spec:
  amqp_url: qdr-white.sa-telemetry.svc.cluster.local:5672/collectd/cloud2-telemetry
  serviceType: metrics

---
apiVersion: smartgateway.infra.watch/v1alpha1
kind: SmartGateway
metadata:
  name: cloud2-notify
spec:
  amqp_url: qdr-white.sa-telemetry.svc.cluster.local:5672/collectd/cloud2-notify
  serviceType: events
```

## Openstack configuration

In order to label traffic according to it's cloud of origin, the collectd
configuration has to be updated to have cloud-specific instance names. This is
usually accomplished by editting your triple-o configuration to have the
following CollectdAmqpInstances.

```yaml
parameter_defaults:
    CollectdAmqpInstances:
        cloud1-telemetry:
            format: JSON
            presettle: false
        cloud1-notify:
            notify: true
            format: JSON
            presettle: true
```

see "Using Customized Core Heat Templates"[1] for more information.

[1] https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/13/html-single/advanced_overcloud_customization/index (2.7. Using Customized Core Heat Templates)

## Querying metrics data from multiple clouds

Data in prometheus will have a "service" label attached according to which
smartgateway it was scraped from, so this label can be used to query data from a
specific cloud; for example: `sa_collectd_uptime{service="cloud1-smartgateway"}`
