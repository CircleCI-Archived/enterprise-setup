# num_instances defines the number of MongoDB server instances to provision for
# this MongoDB replica set.  num_instances should be an odd number.  e.g.: "3".
variable "num_instances" {}

# prefix is an optional string that will be used to namespace all AWS resources
# created by this module.  The value of this string should match the regular
# expression ^[a-z][a-z0-9-]+$.  e.g.: "circleci-".
variable "prefix" {
  default = ""
}

# cluster_id is a short string used to identify all resources related to this
# MongoDB replica set.  The value of this string should match the regular
# expression ^[a-z][a-z0-9-]+$.  cluster_id MUST be unique amongst all MongoDB
# replica sets in the AWS account.
variable "cluster_id" {}

variable "instance_type" {}

variable "key_name" {}

# ebs_optimized provisions an EBS Optimized EC2 instance when "true".
#
# Not all AWS EC2 instance types support EBS Optimization.  Cross-check the
# value of instance_type with the AWS documentation before enabling this flag:
#
# http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSOptimized.html#ebs-optimization-support
variable "ebs_optimized" {
  default = "false"
}

variable "ami_id" {}

variable "azs" {
  default = []
}

variable "vpc_id" {}

variable "subnet_ids" {
  default = []
}

variable "instance_profile_name" {}

# security_group_ids is an optional list of AWS Security Group IDs to attach to
# each MongoDB server instance.
variable "security_group_ids" {
  type    = "list"
  default = []
}

variable "service_sgs" {
  type    = "list"
  default = []
}

# ebs_size defines the size, in gigabytes, of the persistent EBS volume to
# attach to each MongoDB server instance.  e.g.: "100".
variable "ebs_size" {}

# ebs_iops defines the IOPS reservation of the persistent EBS volume to attach
# to each MongoDB server instance.  e.g.: "100".  The EBS volume is always
# provisioned as an 'io1' type (Provisioned IOPS SSD).
variable "ebs_iops" {}

# zone_id is the ID of a Route53 zone into which DNS A RRs will be added, one
# for each MongoDB server instance.  Each name will resolve to the instance's
# private IPv4 address.
variable "zone_id" {}
variable "mongo_domain" {}
variable "aws_access_key_location" {}
variable "key_location" {}
