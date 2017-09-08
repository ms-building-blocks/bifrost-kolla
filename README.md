# Openstack install on baremetal OPNFV pods with OSA and Bifrost

Note 0: This bunch of scripts is not an installer, just a recipe to install
Openstack on an OPNFV pods for developper needs and XCI jobs.

Note 1: The target is only Orange pod1 for now

# About the jumphost

The jumphost is a fresh ubuntu 16.04 install with a direct internet connection,
and a network interface linked with the openstack br-mgmt network.

This jumphost can be virtual.

The openstack nodes are split in 2: 3 for controllers and 2 for computes

# About log servers

This server is not installed by bifrost today, and is an ubuntu VM
installed closed to the jumphost.

# Prepare baremetal description

Please take a non null time to prepare all config files in vars/ folder.

Today, the baremetal description is done with vars/pods.yaml for the pod
description and vars/servers.yaml for the servers description accross several
pods. **Those files will be replaced by the Pod Description File.**

The vars/defaults.yaml contains all vars not directly related to baremetal.

# Run everything:

The installation is done from the jumphost

(this need to be checked)
./run.sh
