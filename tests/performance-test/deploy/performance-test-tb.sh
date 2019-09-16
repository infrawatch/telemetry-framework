#!/bin/bash

COUNT=${COUNT:-180}
HOSTS=${HOSTS:-20}
PLUGINS=${PLUGINS:-1000}
INTERVAL=${INTERVAL:-1}

oc delete job/saf-performance-test || true

oc create -f <(sed  -e "s/<<COUNT>>/${COUNT}/;
                        s/<<HOSTS>>/${HOSTS}/;
                        s/<<PLUGINS>>/${PLUGINS}/;
                        s/<<INTERVAL>>/${INTERVAL}/"\
                    performance-test-job-tb.yml.template)
