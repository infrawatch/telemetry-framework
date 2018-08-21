#!/usr/bin/env bash

# NOTE: this script should not be run directly. It is used by the demo_setup.sh
#       script via Ansible script module.

cat > /etc/systemd/journald.conf <<EOF
[Journal]
SystemMaxUse=500M
SystemMaxFileSize=10M
EOF

yum install NetworkManager -y
systemctl enable NetworkManager.service
systemctl start NetworkManager.service
journalctl --vacuum-size=500M
systemctl restart systemd-journald.service
