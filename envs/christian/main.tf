# TODO: remove the dynamodb lock table, remove s3 state file & folder, destroy jump instance
# TODO: document how to set RDS admin password somewhere more prominent


locals {
  # UPDATE: set this to your stack (dev,prod,imp, etc)
  stack = "christian"

  # UPDATE: set this to the front facing fqdn of your installation
  fqdn = "circleci-christian.west.cms.gov"
}

module "app" {
  source                  = "../../modules/cms"
  stack                   = "${local.stack}"
  fqdn                    = "${local.fqdn}"
  rds_instance            = "db.m5.large"
  # rds_snapshot_identifier = "christian-2019-05-30-13-48est"

  # Optional, install an ssh key
  aws_ssh_key_name = "circleci"
}

#
# Print out the ACM validation record
#
output "acm_validation" {
  value = "${module.app.domain_validation_options}"
}

#
# Print out the ELB dns name
#
output "elb_name" {
  value = "${module.app.elb_name}"
}

#
# Configure providers for this bootstrap. These are the latest versions as of 1/10/2019
#
provider "aws" {
  version = "~> 1.56.0"
  region  = "us-west-2"
}

provider "template" {
  version = "~> 1.0.0"
}

#
# Configure Terraform
#
terraform {
  required_version = "~> 0.11.11"

  backend "s3" {
    # UPDATE: set your bucket to the one created by the bootstrap module
    bucket = "aws-cms-oit-iusg-draas-circleci-dev-us-west-2-terraform"

    # UPDATE: set this to your environment name
    key = "circleci-christian/main.tfstate"

    dynamodb_table = "terraform-lock-christian"
    region         = "us-west-2"
    encrypt        = "true"
  }
}
