# Labels

Here is a data dictionary of our labels; not including auto-generated ones.

| **Label Key**         | **On Types**                   | **Values**     | **Notes**  |
|-----------------------|--------------------------------|----------------|------------|
| alertmanager          | Pod                            | sa             | This comes from prometheus-operator |
| app                   | Pod, Service, DeploymentConfig | alertmanager, prometheus, prometheus-operator, qdr, qdr-operator, saf-smoketest, smart-gateway, smart-gateway-operator | Primary way to identify a specific component |
| application           | Pod, Service, ReplicaSet       | qdr-white | This comes from qdr-operator |
| name                  | Service                        | smart-gateway-operator | This is required for operator-sdk framework metrics |
| operated-alertmanager | Service                        | true | This comes from prometheus-operator |
| operated-prometheus   | Service                        | true | This comes from prometheus-operator |
| prometheus            | Pod                            | white | This comes from prometheus-operator |
| qdr_cr                | Pod, Service, ReplicaSet       | qdr-white | Where does this come from? |
