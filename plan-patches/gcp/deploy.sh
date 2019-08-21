#!/usr/bin/env bash

set -euxo pipefail

if [ "$#" -ne 1 ]; then
  set +x
  echo "Expected usage: deploy.sh SYSTEM_DOMAIN"
  exit 1
fi
bosh upload-release https://bosh.io/d/github.com/cloudfoundry-community/eirini-bosh-release
# pin to version 2.28.0 of bits-service until we've added support for auth with bits-service registry
bosh upload-release https://bosh.io/d/github.com/cloudfoundry-incubator/bits-service-release?v=2.28.0

STEMCELL_VERSION=$(bosh int --path /stemcells/0/version ${HOME}/workspace/cf-deployment/cf-deployment.yml)
bosh upload-stemcell "https://s3.amazonaws.com/bosh-gce-light-stemcells/$STEMCELL_VERSION/light-bosh-stemcell-$STEMCELL_VERSION-google-kvm-ubuntu-xenial-go_agent.tgz"

bosh -d cf deploy ${HOME}/workspace/cf-deployment/cf-deployment.yml --no-redact \
  -o ${HOME}/workspace/cf-deployment/operations/use-compiled-releases.yml \
  -o ${HOME}/workspace/cf-deployment/operations/bits-service/use-bits-service.yml \
  -o ${HOME}/workspace/eirini-bosh-release/operations/add-eirini.yml \
  -o ${HOME}/workspace/eirini-bosh-release/operations/scale-down-bits-service.yml \
  -o ${HOME}/workspace/eirini-bosh-release/operations/hardcode-doppler-ip.yml \
  -o ${HOME}/workspace/cf-deployment/operations/experimental/fast-deploy-with-downtime-and-danger.yml \
  -o ${HOME}/workspace/cf-deployment/operations/scale-to-one-az.yml \
  -v system_domain="${1}"
