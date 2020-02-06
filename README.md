# CircleCI Server Setup

This package allows you to easily orchestrate your CircleCI Server cluster in AWS using Terraform. For a full step by step guide to installing CircleCI Server with Terraform, see our [installation guide](https://circleci.com/docs/2.0/circleci-install-doc-v2-17.pdf#section=administration).

**Note: This is only meant to be used for the initial setup of CircleCI Server and is not meant to be used for the ongoing maintenance of the CircleCI Server.**

**Note: Master is the only supported branch. All other branches of this repo should not be considered stable, and is to be used at your own risk.**

# Getting Started

## Pre Reqs

We use Terraform to automate parts of the infrastructure for your CircleCI Server install, so you will need to install this first:

* [Terraform](https://www.terraform.io/downloads.html)

**Note: This script only supports terraform version 0.12 and higher. Please update to the most recent version before fetching from upstream.**

## Installation

### Basic

1. Clone or download this repository
1. Execute `make init` or save a copy of `terraform.tfvars.template` to `terraform.tfvars`
1. Fill in the configuration vars in `terraform.tfvars` for your cluster. see [Configuration](#configuration)
1. Run `terraform init` to install Terraform plugins
1. Run `terraform apply`
1. Visit IP supplied at the end of the Terraform output
1. Follow instructions to setup and configure your installation
1. Once your installation has finished, you can use [our realitycheck repo](https://github.com/circleci/realitycheck) to check basic CircleCI functionality

### Teardown

1. First you need to manually disable the termination protection on the Services machine from the AWS Management Console (If you set `services_disable_api_termination = "false"` in `terraform.tfvars`, skip this step.). To do this:

    1. Navigate to the EC2 Dashboard and locate the Services machine instance
    1. Click to select it
    1. Click Actions > Instance Settings > Change Termination Protection


1. Navigate to the S3 dashboard, locate the S3 bucket associated with your CircleCI cluster and delete it/its contents (If you set `force_destroy_s3_bucket = "true"` in `terraform.tfvars`, skip this step.).
1. From a terminal, navigate to your clone of our `enterprise-setup` repo and run `terraform destroy` to destroy all EC2 instances, IAM roles, ASGs and Launch configurations created by `terraform apply`.

## Configuration

To configure the cluster that terraform will create, simply fill out the terraform.tfvars file. The following are all required vars:

  | Var      | Description |
  | -------- | ----------- |
  | aws_access_key | Access key used to create instances |
  | aws_secret_key | Secret key used to create instances |
  | aws_region | Region where instances get created |
  | aws_vpc_id | The VPC ID where the instances should reside |
  | aws_subnet_id | The subnet-id to be used for the instance |
  | aws_ssh_key_name |  The SSH key to be used for the instances|
  | circle_secret_passphrase | Decryption key for secrets used by CircleCI machines |

Optional vars:

  | Var      | Description | Default |
  | -------- | ----------- | ------- |
  | services_instance_type | Instance type for the centralized services box.  We recommend a m4 instance | m5.2xlarge |
  | builder_instance_type | Instance type for the 1.0 builder machines.  We recommend a r3 instance | r5.2xlarge |
  | max_builders_count | Max number of 1.0 builders | 2 |
  | nomad_client_instance_type | Instance type for the nomad clients (2.0 builders). We recommend a XYZ instance | m5.2xlarge |
  | max_clients_count | Max number of nomad clients | 2 |
  | prefix   | Prefix for resource names | circleci |
  | enable_nomad | Provisions a nomad cluster for CCIE v2 | 1 |
  | enable_route | Enable creating a Route53 route for the Services box | 0 |
  | enable_govcloud | Allows deployment into AWS GovCloud | false |
  | route_name | Route name to configure for Services box | "" |
  | route_zone_id | Zone to configure route in | "" |
  | services_user_data_enabled | Enable/disable automated installation on Services Box | true |
  | force_destroy_s3_bucket | Add/Remove ability to forcefully destroy S3 bucket | false |
  | services_disable_api_termination | Protect the services instance from API termination | true |
