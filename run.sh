#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

INVENTORY=$1
export ANSIBLE_STDOUT_CALLBACK=debug

#-------------------------------------------------------------------------------
# Check run as root
#-------------------------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit
fi

#-------------------------------------------------------------------------------
# Check pod config
#-------------------------------------------------------------------------------
echo '---- Inventory ----'
cat $INVENTORY | grep -v "^//"
echo '-------------------'
read -p "Do you confirm those parameters? (y/n) " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
 exit
fi

#-------------------------------------------------------------------------------
# cleanup
# #-------------------------------------------------------------------------------

# purge ironic DB
MPWD=$(grep ironic_db_password: vars/defaults.yaml | cut -d\  -f2)
mysql -uironic -p${MPWD} -e "show databases" | \
        grep -v Database | \
        grep -v mysql| \
        grep -v information_schema| \
        gawk '{print "drop database " $1 ";select sleep(0.1);"}' | \
        mysql -uironic -p${MPWD} || true
# remove old ansible
if test $(pip freeze|grep ansible); then
    pip uninstall -y ansible
fi
# remove folders
rm -rf /usr/local/bin/ansible*
rm -rf /opt/ansible-runtime/
rm -rf /opt/bifrost/
rm -rf /opt/openstack-ansible/
rm -rf /opt/stack/
rm -rf /etc/bosa/
# Clean OS envvars
for var in $(export |cut -d\  -f3| cut -d= -f1| grep '^OS_'); do
    unset $var;
done

#-------------------------------------------------------------------------------
# install ansible
#-------------------------------------------------------------------------------
apt-get install -y software-properties-common python-setuptools \
    python-dev libffi-dev libssl-dev git sshpass tree python-pip
pip install --upgrade pip
pip install cryptography
pip install ansible

#-------------------------------------------------------------------------------
# BIFROST
#-------------------------------------------------------------------------------
ansible-playbook -i $INVENTORY opnfv-bifrost-install.yaml
ansible-playbook -i $INVENTORY opnfv-bifrost-enroll-deploy.yaml

#-------------------------------------------------------------------------------
# Prepare nodes
#-------------------------------------------------------------------------------
ansible-playbook -i /etc/bosa/ansible_inventory opnfv-wait-for-nodes.yaml
ansible-playbook -i /etc/bosa/ansible_inventory opnfv-prepare-nodes.yaml

#-------------------------------------------------------------------------------
# Prepare OSA
#-------------------------------------------------------------------------------
ansible-playbook -i $INVENTORY opnfv-osa-prepare.yaml
pip uninstall -y ansible
/opt/openstack-ansible/scripts/bootstrap-ansible.sh
ansible-playbook -i $INVENTORY opnfv-osa-configure.yaml

#-------------------------------------------------------------------------------
# Run OSA
#-------------------------------------------------------------------------------
cd /opt/openstack-ansible/playbooks
openstack-ansible setup-hosts.yml
openstack-ansible setup-infrastructure.yml
ansible galera_container -m shell -a "mysql -h localhost -e 'show status like \"%wsrep_cluster_%\";'"
openstack-ansible setup-openstack.yml

#-------------------------------------------------------------------------------
# Fetch openrc and cert
#-------------------------------------------------------------------------------
CNT=$(ssh infra1 lxc-ls |grep utility)
ssh infra1 lxc-attach -n $CNT -- cat /root/openrc > /root/openrc
scp infra1:/etc/ssl/certs/haproxy.cert /root
echo 'CA_CERT=haproxy.cert' >> /root/openrc

#-------------------------------------------------------------------------------
# End
#-------------------------------------------------------------------------------
