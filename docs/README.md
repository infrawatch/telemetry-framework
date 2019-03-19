# Telemetry Framework

The telemetry framework is a system that allows for collection of metrics and
events using collectd, sending them across an AMQP 1.x message bus back to the
server side for storage (such as Prometheus, ElasticSearch, etc). Once data is
stored, metrics and events can be used as the sources for alerts, 
visualization, or the source of truth for orchestration frameworks.

# Contents

* [oVirt / RHV Infrastructure Installation](00-rhv_infrastructure_installation.md)
* [Telemetry Platform Server Side Installation](02-server_side_installation.md)
* [Telemetry Platform Client Side Installation](03-client_side_installation.md)
* [Install Telemetry Framework via Service Catalog](04-install_sa_via_apb.md)
