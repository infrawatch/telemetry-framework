# SAF Performance Test

## Introduction
The performance test provides an automated environment in which to to run stress tests on the SAF locally using Minishift. Collectd-tg is used to simulate extensive netwrok traffic to pump through SAF. Because Minishift only supports a single node at a time, this test demonstrates the limits of SAF in a constrained environment. Test scenarios are manually configured in a yaml file and results can be analyzed in a series of grafana dashboards.

Two additional pods are deployed by the performance test: one that hosts a grafana instance and one that executes the testing logic. 

![A Performance Test Dashboard](https://github.com/redhat-service-assurance/telemetry-framework/blob/performance-test/tests/performance-test/images/dashboard.png)

## Configuring Tests

Individual tests are configured in the `deploy/config/test-configs.yaml` file. Each test uses the following format:

```yaml
- metadata:
    name:
  spec:
    value-lists:
    hosts:
    plugins:
    interval:
    length:
    queries:
```

To run multiple tests in sequence, utilize the above format in additional list entries within the config file. Each test generates a unique dashboard within grafana and each query adds a new graph to its respective dashboard.

# Options

Option | Description
-------|------------
name | name of the test entry. This will be reflected in the dashboard title
value-lists | collectd-tg option
hosts | collectd-tg option
plugins | collectd-tg option
interval | collectd-tg option
length | number of seconds the test should run, expressed as an unsigned integer
queries | list of PromQL queries that will be graphed within the Grafana dashboard

More information about collectd-tg options can be found  in the [collectd-tg docs](https://collectd.org/documentation/manpages/collectd-tg.1.shtml).

# Example Test
```yaml
- metadata:
    name: SAF Performance Test 1
  spec:
    value-lists: 10000
    hosts: 5000
    plugins: 100
    interval: 1
    length: 900
    queries:
      - rate(sa_collectd_total_amqp_processed_message_count[10s])
      - sa_collectd_cpu_total
```
View the [performance test deployment instructions](https://github.com/redhat-service-assurance/telemetry-framework/tree/performance-test/tests/performance-test/deploy) to launch the performance test on Minishift.

Once each test is completed, a new dashboard will be written to grafana at which all of the queries will be graphed. This can be seen by navigating to `http://<grafana route URL>/dashboards` in a local browser. 
