# CircleCI Enterprise Setup

This package allows you to easily orchestrate your CCIE cluster in AWS using Terraform.

# Getting Started

## Pre Reqs

- Terraform

## Installation

### Basic

1. Clone or download this repository
1. Execute `make init` or save a copy of `terraform.tfvars.template` to `terraform.tfvars`
1. Fill in the configuration vars in `terraform.tfvars` for your cluster. see [Configuration](#configuration)
1. Run `terraform init` to install Terraform plugins.
1. Run `terraform apply`
1. Once your installation has finished, you can use [our realitycheck repo](https://github.com/circleci/realitycheck) to check basic CircleCI functionality

### Teardown

1.  
    1. If you set `services_termination_protection_disabled=false` in `terraform.tfvars`, skip this step.
    
    1. Manually disable termination protection in the AWS UI.  To do this, go to the EC2 Management Console, locate the services box instance, select it and click `Actions` -> `Change Termination Protection`.

1.
    1. If you set `force_destroy_s3_bucket=true` in `terraform.tfvars`, skip this step.
    1. In the AWS Management Console, locate the S3 bucket associated with your CircleCI cluster and delete all its contents.

1. Run `terraform destroy` to destroy all EC2 instances, IAM roles, ASGs and Launch configurations created by `terraform apply`.

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
  | services_instance_type | Instance type for the centralized services box.  We recommend a m4 instance | m4.xlarge |
  | builder_instance_type | Instance type for the 1.0 builder machines.  We recommend a r3 instance | r3.2xlarge |
  | max_builders_count | Max number of 1.0 builders | 2 |
  | nomad_client_instance_type | Instance type for the nomad clients (2.0 builders). We recommend a XYZ instance | m4.xlarge |
  | max_clients_count | Max number of nomad clients | 2 |
  | prefix   | Prefix for resource names | circleci |
  | enable_nomad | Provisions a nomad cluster for CCIE v2 | 1 |
  | enable_route | Enable creating a Route53 route for the Services box | 0 |
  | route_name | Route name to configure for Services box | "" |
  | route_zone_id | Zone to configure route in | "" |
  | services_user_data_enabled | Set to 0 to disable automated installation on Services Box | 1 |
  | force_destroy_s3_bucket | Add/Remove ability to forcefully destroy S3 bucket | false |
  | services_disable_api_termination | Protect the services instance from API termination | true |
