# telemetry-framework  [![Build Status](https://travis-ci.org/redhat-service-assurance/telemetry-framework.svg?branch=master)](https://travis-ci.org/redhat-service-assurance/telemetry-framework)

The telemetry framework is a project that aims to centralize metrics and events
of various platform components (not applications) in order to provide a
centralized view of multiple platform deployments.

## Documentation

Documentation for the Service Assurance Framework is available at
https://redhat-service-assurance.github.io/saf-documentation

The source of that documentation is available at
https://github.com/redhat-service-assurance/saf-documentation

## Development

The quickest way to start up Service Assurance Framework is to run the
`quickstart.sh` script located in the `deploy/` directory after starting up a
[MiniShift](https://github.com/minishift/minishift) environment.

(A simple script to start MiniShift for you is located in
`tests/infrared/baremetal-scripts/install-and-run-minishift.sh`)

See the [official
documentation](https://redhat-service-assurance.github.io/saf-documentation)
for more information about installing for production-style use cases.
