#
# Configure default region for this account.
#
locals {
  region  = "us-gov-west-1"
  account = "aws-cms-oit-iusg-gc-cs-prod"
}

#
# Load the account template. This template creates a dynamodb lock table and
# terraform state file S3 bucket.
#
module "terraform-bootstrap" {
  source = "git@github.com:CMSgov/CMS-AWS-West-Pipelines.git//bootstrap/template-govcloud"
  #source = "../../../../CMS-AWS-West-Pipelines/bootstrap/template-govcloud"

  # Set to the name of the account you are bootstrapping
  region = "${local.region}"
}

#
# Configure providers for this bootstrap. These are the latest versions as of 1/10/2019
#
provider "aws" {
  version = "~> 1.55.0"
  region  = "${local.region}"
}

provider "template" {
  version = "~> 1.0.0"
}

terraform {
  required_version = "~> 0.11.11"
}
