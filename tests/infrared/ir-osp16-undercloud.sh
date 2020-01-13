source ./config

# OSP 13 method with container images. Might only work once post-GA?
#infrared tripleo-undercloud \
#    -vv \
#    -o outputs/undercloud-install.yml \
#    --mirror rdu2 \
#    --version 16 \
#    --build "${OSP_BUILD}" \
#    --registry-mirror docker-registry.engineering.redhat.com \
#    --registry-undercloud-skip no
#
#infrared tripleo-undercloud -vv \
#   -o outputs/images_settings.yml \
#   --images-task rpm \
#   --build "${OSP_BUILD}" \
#   --images-update no


# OSP 16 method as done by Jenkins QE Phase 1
infrared tripleo-undercloud \
	-vv \
	-o outputs/undercloud.yml \
	--mirror "rdu2" \
	--version 16 \
	--build "${OSP_BUILD}" \
	--images-task rpm \
	--images-update no \
	--tls-ca https://password.corp.redhat.com/RH-IT-Root-CA.crt
	--config-options DEFAULT.undercloud_timezone=UTC
