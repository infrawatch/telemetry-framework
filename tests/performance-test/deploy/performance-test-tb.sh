#!/bin/bash

COUNT=${COUNT:-180}
HOSTS=${HOSTS:-20}
PLUGINS=${PLUGINS:-1000}
INTERVAL=${INTERVAL:-1}
CONCURRENT=${CONCURRENT:-1}

oc delete job -l app=saf-performance-test || true

for i in $(seq 1 ${CONCURRENT}); do

  oc create -f <(sed  -e "s/<<PREFIX>>/saf-perftest-${i}-/g;
                          s/<<COUNT>>/${COUNT}/g;
                          s/<<HOSTS>>/${HOSTS}/g;
                          s/<<PLUGINS>>/${PLUGINS}/g;
                          s/<<INTERVAL>>/${INTERVAL}/g"\
                          performance-test-job-tb.yml.template)
done
