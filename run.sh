#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

export ANSIBLE_STDOUT_CALLBACK=debug
export target_folder=$(PWD)

#-------------------------------------------------------------------------------
# Check run as root
#-------------------------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit -1
fi

echo "
#-------------------------------------------------------------------------------
# install ansible
#-------------------------------------------------------------------------------
"

# remove old ansible
if pip freeze|grep ansible=; then
    pip uninstall -y ansible
fi
# remove folders
rm -rf /usr/local/bin/ansible*
rm -rf /etc/ansible/
# install ansible from package
apt update
apt install -y software-properties-common python-setuptools \
    python-dev libffi-dev libssl-dev git python-pip
pip install --upgrade pip cryptography ansible netaddr
mkdir -p /etc/ansible
echo "jumphost ansible_connection=local" > /etc/ansible/hosts

# put default values for ansible
cat > /etc/ansible/ansible.cfg <<EOF
[defaults]
forks=50
host_key_checking = False
[ssh_connection]
pipelining=True
EOF

cd ${target_folder}

echo "
#-------------------------------------------------------------------------------
# Cleanup previous install and prepare jumphost
#-------------------------------------------------------------------------------
"

ansible-playbook opnfv-jumphost.yaml

echo "
#-------------------------------------------------------------------------------
# Setup and run Bifrost
#-------------------------------------------------------------------------------
"

ansible-playbook opnfv-bifrost.yaml

echo "
#-------------------------------------------------------------------------------
# Prepare nodes and kolla
#-------------------------------------------------------------------------------
"

ansible-playbook -i /etc/bolla/ansible_inventory opnfv-prepare.yaml --vault-password-file .vault_pass.txt

echo "
#-------------------------------------------------------------------------------
# Precheck before launching
#-------------------------------------------------------------------------------
"
cd /opt/kolla-ansible
tools/kolla-ansible prechecks -i /etc/kolla/inventory
echo "
#-------------------------------------------------------------------------------
# Run Kolla
#-------------------------------------------------------------------------------
"
tools/kolla-ansible deploy -i /etc/kolla/inventory
tools/kolla-ansible post-deploy -i /etc/kolla/inventory
tools/kolla-ansible check -i /etc/kolla/inventory
sed '/OS_CACERT/d' /etc/kolla/admin-openrc.sh > /etc/bolla/openstack_openrc

echo "
#-------------------------------------------------------------------------------
# Post install
#-------------------------------------------------------------------------------
"
cd ${target_folder}
source /etc/bolla/openstack_openrc
export ANSIBLE_LIBRARY="${ANSIBLE_LIBRARY:-/etc/ansible/library}:/opt/kolla-ansible/ansible/library"
export ANSIBLE_ACTION_PLUGINS="${ANSIBLE_ACTION_PLUGINS:-/etc/ansible/roles/plugins/action}:/opt/kolla-ansible/ansible/action_plugins"
ansible-playbook opnfv-post-install.yaml -i /etc/kolla/inventory

echo "
#-------------------------------------------------------------------------------
# End
#-------------------------------------------------------------------------------
"
