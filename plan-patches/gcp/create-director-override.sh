#!/bin/sh
bosh create-env \
  ${BBL_STATE_DIR}/bosh-deployment/bosh.yml \
  --state  ${BBL_STATE_DIR}/vars/bosh-state.json \
  --vars-store  ${BBL_STATE_DIR}/vars/director-vars-store.yml \
  --vars-file  ${BBL_STATE_DIR}/vars/director-vars-file.yml \
  -o  ${BBL_STATE_DIR}/bosh-deployment/gcp/cpi.yml \
  -o  ${BBL_STATE_DIR}/bosh-deployment/jumpbox-user.yml \
  -o  ${BBL_STATE_DIR}/bosh-deployment/uaa.yml \
  -o  ${BBL_STATE_DIR}/bosh-deployment/credhub.yml \
  -o  ${BBL_STATE_DIR}/bbl-ops-files/gcp/bosh-director-ephemeral-ip-ops.yml \
  --var-file  gcp_credentials_json="${BBL_GCP_SERVICE_ACCOUNT_KEY_PATH}" \
  -v  project_id="${BBL_GCP_PROJECT_ID}" \
  -v  zone="${BBL_GCP_ZONE}"

bosh_director_name="$(bbl outputs | bosh int - --path=/director_name)"
k8s_host_url="$(bbl outputs | bosh int - --path=/k8s_host_url)"
k8s_service_username="$(bbl outputs | bosh int - --path=/k8s_service_username)"
k8s_service_token="$(bbl outputs | bosh int - --path=/k8s_service_token)"
k8s_ca="$(bbl outputs | bosh int - --path=/k8s_ca)"

eval "$(bbl print-env -s ${BBL_STATE_DIR})"
credhub set --name=/${bosh_director_name}/cf/k8s_host_url --value="${k8s_host_url}" -t value
credhub set --name=/${bosh_director_name}/cf/k8s_service_username --value="${k8s_service_username}" -t value
credhub set --name=/${bosh_director_name}/cf/k8s_service_token --value="${k8s_service_token}" -t value
credhub set --name=/${bosh_director_name}/cf/k8s_node_ca --value="${k8s_ca}" -t value
