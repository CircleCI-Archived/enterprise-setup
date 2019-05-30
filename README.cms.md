# CMS Installation Notes

The default CircleCI repository is setup to create only one installation. This doesn't
allow to to easily test across multiple environments, or manage multiple deployments.
In order to create a more seamless process we've made the following modifications to this
repository.

- Add bootstrap directories for each environment/account we're installing into.
- Modifications to circle CI's terraform.
  - Disable the public IP of of the services host.
  - Disable provider configuration, use parent environment, remove from variables.tf
  - Add outputs.tf to expose select id's of created resources.
  - add ${path.module} to template files
- Create a cms module and env directories for each deployment.
  - Pull network and tag configuration from West pipelines.
  - Create LB and security group for services host.
  - Creates a certificate in ACM (validation needs to be done after the fact)
  - Create an RDS instance for postgres externalizion.

## Approach

In order to allow upstream changes to easily be merged into this repository in the future
we are making as few as possible changes to the main circle terraform and instead wrapping
the existing configuration into a 'cms' module which supplies configuration to the circle
terraform and creates any additional CMS resources.

## Files

- /bootstrap/* - Terraform environment setup directories (CMS West Standard)
- /modules/cms - Main application module for customizing the Circle environment
- /envs/* - environment directories which consume the cms module.

## Bootstrapping

We follow the CMS West procedure for bootstrapping and environment. The
bootstrap/* directory contains terraform setup for creating buckets in all environments.

## Creating a new environment

1. Setup bootstrap directory and terraform apply.
    - Create a new directory with your account in /bootstrap
    - Copy a main.tf from an existing and update the `locals` parameters
    - Run `terraform init && terraform -out plan.out`, review then `terraform apply plan.out`
    - Add `main.tf`, and `terraform.tfstate` to git and push.

2. Create application environment and terraform it into existence

    - Create a new directory in /envs/ENV/ and copy the dev main.tf to it.
    - Edit main.tf and set the variables in local, and update the terraform config.
    - Create environment by `terraform init && terraform plan -out plan.out`. Review then `terraform plan.out`

3. Verify ACM certificate

    - Use the output from the above plan and setup the required CNAMES and TXT records for the following:
        - CNAME for your fqdn to elb name.
        - CNAME for ACM.

4. Perform Circle online setup.

---

## Troubleshooting

When creating a new environment, you may encounter an error creating aws_lb_listeners.
This is due to ACM not validating the certificate. To handle validation, you will
need to:

  1. Go to the AWS console and get the dns validation record for your DNS, (or run `terraform output`)
  2. Install the requested CNAME
  3. Re-run terraform plan/apply once ACM shows the certificate validated

Example Error:

```text
 module.app.aws_lb_listener.https8800: 1 error(s) occurred:

* aws_lb_listener.https8800: Error creating LB Listener: CertificateNotFound: Certificate 'arn:aws:acm:us-west-2:664598445001:certificate/a823c69b-7aeb-46c7-b9d7-3727b90adf81' not found
        status code: 400, request id: 5848d2c0-4bd7-11e9-b5a2-f9406cfc5cc7
* module.app.aws_lb_listener.https: 1 error(s) occurred:

* aws_lb_listener.https: Error creating LB Listener: CertificateNotFound: Certificate 'arn:aws:acm:us-west-2:664598445001:certificate/a823c69b-7aeb-46c7-b9d7-3727b90adf81' not found
        status code: 400, request id: 58387f2a-4bd7-11e9-943f-b5cd56d4e453
```