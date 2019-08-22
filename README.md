# eirini-bosh-release

This is a BOSH release for [eirini](https://code.cloudfoundry.org/eirini).

## Deploying CF+Eirini with BOSH
1. Ensure you have the following utilities:
  - [`bosh`](https://bosh.io/docs/cli-v2-install/)
  - [`bosh-bootloader`](https://github.com/cloudfoundry/bosh-bootloader#prerequisites)

1. Create a GCP service account for use by BBL (BOSH Bootloader): [Getting
   Started: GCP # Create a Service
   Account](https://github.com/cloudfoundry/bosh-bootloader/blob/master/docs/getting-started-gcp.md#create-a-service-account)

1. Create and bootstrap the directory to store your BBL (BOSH Bootloader) state:
    ```
    mkdir -p ~/path/to/envs/new_environment
    pushd ~/path/to/envs/new_environment

    # export BBL_IAAS=gcp
    # export BBL_...
    bbl plan
    ```

 <!-- TODO: name the plan patches directory? -->
1. Apply the `gcp` plan patch to the BBL state dir (defaults to
   `new_environment/bbl_state`):
    ```
    cp -R ~/path/to/eirini-bosh-release/plan-patches/gcp/. ~/path/to/envs/new_environment/bbl_state
    ```
1. Deploy CF
    ```
    ./deploy.sh
    ```

1. Create a new DNS record
       DNS Name: `*.$ENVIRONMENT.tld.`
       Resource Record Type: `A`
       TTL: 5 minutes
       IPv4 addresses: IP of the router load balancer, e.g. `bbl outputs | grep
       router_lb_ip`

1. Run the post-deploy errands:
    ```
    bosh -d cf run-errand configure-eirini-bosh
    ```

## Contributing

1. Fork this project into your GitHub organisation or username
1. Make sure you are up-to-date with the upstream master and then create your feature branch (`git checkout -b amazing-new-feature`)
1. Add and commit the changes (`git commit -am 'Add some amazing new feature'`)
1. Push to the branch (`git push origin amazing-new-feature`)
1. Create a PR against this repository
