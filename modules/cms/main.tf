locals {
  application = "circleci"
  prefix      = "${local.application}-${var.stack}"
}

#
# Here we treat the main circle config in the root of enterprise-setup
# as a module. Rather than configuring these through tfvars as circle
# setup is normally done, we do a mix of hard coding and variable passing
# here. 
module "circleci" {
  source        = "../../"
  aws_vpc_id    = "${module.network.vpc_id}"
  aws_subnet_id = "${module.network.private_subnet_ids[0]}"
  aws_region    = "${data.aws_region.current.name}"
  prefix        = "${local.prefix}"

  # Disable CircleCI 1.0 builders
  desired_builders_count = "0"

  # For appliances this is disabled and a no-op
  aws_ssh_key_name = "${var.aws_ssh_key_name}"

  # TODO: Move this to param store
  circle_secret_passphrase = "setecastronomy"
}

data "aws_region" "current" {}

module "tags" {
  source      = "git@github.com:CMSgov/CMS-AWS-West-Pipelines.git//terraform/modules/cms-tags"
  application = "${local.application}"
  stack       = "${var.stack}"
}

module "network" {
  source      = "git@github.com:CMSgov/CMS-AWS-West-Pipelines.git//terraform/modules/network-v4"
  application = "${local.application}"
  stack       = "${var.stack}"
}
