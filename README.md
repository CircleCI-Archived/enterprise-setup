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
1. Run `terraform apply`

### Advanced: Ansible provisioning

Advanced install involves using Ansible to fully configure your services box without having to use the user interface. This installation uses a Terraform plugin that adds Ansible as a provisioner.

https://github.com/jonmorehouse/terraform-provisioner-ansible/releases/download/0.0.2/terraform-provisioner-ansible

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
  | services_instance_type | instance type for the centralized services box.  We recommend a c4 instance | c4.2xlarge |
  | builder_instance_type | instance type for the builder machines.  We recommend a r3 instance | r3.2xlarge |
  | max_builders_count | max number of builders | 2 |
  | nomad_client_instance_type | instance type for the nomad clients. We recommend a XYZ instance | m4.xlarge |
  | max_clients_count | max number of nomad clients | 2 |
  | prefix   | prefix for resource names | circleci |
