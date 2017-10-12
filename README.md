# CircleCI Enterprise Setup

This package allows you to easily orchestrate your CCIE cluster in AWS using Terraform.

# Getting Started

## Pre Reqs

- Terraform

## Installation

### Basic

1. Clone or download this repository
1. Execute `make init`
1. Fill in the configuration vars in `terraform.tfvars` for your cluster. see [Configuration](#configuration)
1. Run `terraform apply`

### Advanced: Ansible provisioning

Advanced install involves using Ansible to fully configure your services box without having to configure it via the user interface. This installation method requires having Ansible locally installed on the machine you will be running Terraform on.

To enable Ansible provisioning, set `enable_ansible_provisioning = true` in your tfvars file. Then add a dictionary to your tfvars file called `ansible_extra_vars` containing the extra variables that will be passed to the Ansible playbook in this project.

Example:

```
enable_ansible_provisioning = true
ansible_extra_vars = {
  license_file_path = "/path/to/my/CircleCILicense.rli"
  ghe_type = "github_type_enterprise"
  ghe_domain = "ghe.example.com"
  github_client_id = "insertclientidfromghe"
  github_client_secret = "insertclientsecretfromghe"
  aws_access_key_id = "insertawskey"
  aws_access_secret_key = "insertawssecretkey"
}
```

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
  | enable_nomad | provisions a nomad cluster for CCIE v2 | 0 |
  | enable_ansible_provisioner | enable provisioning of Services box via Ansible | 0 |
  | enable_route | enable creating a Route53 route for the Services box | 0 |
  | route_name | Route name to configure for Services box | "" |
  | route_zone_id | Zone to configure route in | "" |
