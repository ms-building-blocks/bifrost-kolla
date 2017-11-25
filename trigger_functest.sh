#!/bin/bash

curl -X POST \
  -F token=${functest_token} \
  -F ref=${functest_ref_name} \
  -F "variables[pod]=${pod}" \
  -F "variables[scenario]=${scenario}" \
  -F "variables[creds_path]=/etc/bolla" \
  https://gitlab.forge.orange-labs.fr/api/v4/projects/1674/trigger/pipeline
