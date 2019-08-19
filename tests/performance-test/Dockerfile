#--- Build SAF performance test ---
FROM golang:1.12.7
WORKDIR /go/src/performance-test/

COPY ./dashboard.go ./main.go ./parser.go .

RUN go get gopkg.in/yaml.v2 && \
    go get github.com/grafana-tools/sdk && \
    go build -o main && \
    mv main /tmp/

#--- Create performance test layer ---
FROM tripleomaster/centos-binary-collectd:current-tripleo-rdo
USER root

RUN yum install golang -y && \
    yum update -y && \
    yum clean all

COPY --from=0 /tmp/main /performance-test/exec/main
COPY grafana/apikey /performance-test/grafana/apikey
COPY deploy/scripts/unit-test.sh /performance-test/exec/unit-test.sh