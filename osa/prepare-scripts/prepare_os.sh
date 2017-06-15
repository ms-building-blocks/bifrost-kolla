#!/bin/sh

# update and install deps
apt update
apt -y dist-upgrade
apt -y  install aptitude build-essential git ntp ntpdate \
  openssh-server python-dev sudo

# Check br-mgmt is present
echo "Check bridge br-mgmt is present:"
ip a l | grep br-mgmt: > /dev/null  && \
    echo -e "\e[32mPresent\e[39m" || \
    echo -e "\e[31mAbsent \e[39m - please set br-mgmt"

# Install sources and deps
git clone -b 15.1.4 https://git.openstack.org/openstack/openstack-ansible \
  /opt/openstack-ansible
cd /opt/openstack-ansible
./scripts/bootstrap-ansible.sh
