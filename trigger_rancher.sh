#!/bin/bash

curl -X POST \
  -F token=${rancher_token} \
  -F ref=${rancher_ref_name} \
  -F "variables[pod]=${pod}" \
  -F "variables[scenario]=${scenario}" \
  -F "variables[openstack_creds]=/etc/bolla/openstack_openrc" \
  https://gitlab.forge.orange-labs.fr/api/v4/projects/7169/trigger/pipeline
