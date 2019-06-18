# Deployment using Operators

This directory contains sample configurations for deployment of the Telemetry
Framework leverage Operators for the deployment. The contents here are
currently a work in a progress.

# Routes and Certificates

In order to get the remote QDR connections through the OpenShift operator, we
need to use TLS/SSL certificates. The following two commands will first create
the appropriate certificate files locally and then load the contents into a
secret for use by QDR.

You'll need to copy the contents of these certificates and load them into
the client side connection. The QDR on the client side will then connect to the
route address (DNS address) for the QDR service on port 443. Be sure you set
the OpenShift route to Passthrough mode to port 5671.

    openssl req -new -x509 -batch -nodes -days 11000 \
        -subj "/O=io.interconnectedcloud/CN=qdr-white.sa-telemetry.svc.cluster.local" \
        -out qdr-server-certs/tls.crt \
        -keyout qdr-server-certs/tls.key

    oc create secret tls qdr-white-cert --cert=qdr-server-certs/tls.crt --key=qdr-server-certs/tls.key

# Importing ImageStreams

In order to better separate between upstream and downstream locations of
images, we've made use of
[ImageStreams](https://docs.openshift.com/container-platform/3.11/dev_guide/managing_images.html)


