#!/bin/sh

# update and install deps
apt update
apt -y dist-upgrade
apt -y install bridge-utils debootstrap ifenslave ifenslave-2.6 \
  lsof lvm2 ntp ntpdate openssh-server sudo tcpdump vlan python3-jinja2 \
  python3-netifaces python3-yaml

# add modules
grep 8021q /etc/modules >/dev/null  || echo '8021q' >> /etc/modules
grep bonding /etc/modules >/dev/null  || echo 'bonding' >> /etc/modules

# restart service
 service ntp restart

# LVM configuration
# https://docs.openstack.org/project-deploy-guide/openstack-ansible/ocata/targethosts-prepare.html
