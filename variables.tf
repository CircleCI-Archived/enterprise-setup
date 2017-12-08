# AWS Specific configuration

# Service Box and Builders

variable "aws_access_key" {
  description = "Access key used to create instances"
}

variable "aws_secret_key" {
  description = "Secret key used to create instances"
}

variable "aws_region" {
  description = "Region where instances get created"
}

variable "aws_vpc_id" {
  description = "The VPC ID where the instances should reside"
}

variable "aws_subnet_id" {
  description = "The subnet-id to be used for the instance"
}

variable "aws_subnet_ids" {
  description = "subnet-ids to be used for HA instances"
  default = []
}

variable "aws_ssh_key_name" {
  description = "The SSH key to be used for the instances"
}

variable "circle_secret_passphrase" {
  description = "Decryption key for secrets used by CircleCI machines"
}

variable "services_ami" {
  description = "Override AMI lookup with provided AMI ID"
  default     = ""
}

variable "services_instance_type" {
  description = "instance type for the centralized services box.  We recommend a c4 instance"
  default     = "c4.2xlarge"
}

variable "builder_instance_type" {
  description = "instance type for the builder machines.  We recommend a r3 instance"
  default     = "r3.2xlarge"
}

variable "max_builders_count" {
  description = "max number of 1.0 builders"
  default     = "2"
}

variable "desired_builders_count" {
  description = "desired number of 1.0 builders"
  default     = "1"
}

variable "enable_nomad" {
  description = "enable running 2.0 builds"
  default     = 1
}

variable "nomad_client_instance_type" {
  description = "instance type for the nomad clients. It must be a valid aws instance type."
  default     = "m4.xlarge"
}

variable "prefix" {
  description = "prefix for resource names"
  default     = "circleci"
}

variable "services_disable_api_termination" {
  description = "Enable or disable service box termination prevention"
  default     = "true"
}

variable "services_delete_on_termination" {
  description = "Configures AWS to delete the ELB volume for the Services box upon instance termination."
  default     = "false"
}

variable "enable_route" {
  description = "enable creating a Route53 route for the Services box"
  default     = 0
}

variable "route_name" {
  description = "Route name to configure for Services box"
  default     = ""
}

variable "route_zone_id" {
  description = "Zone to configure route in"
  default     = ""
}

variable "http_proxy" {
  default = ""
}

variable "https_proxy" {
  default = ""
}

variable "no_proxy" {
  default = ""
}

variable "services_user_data_enabled" {
  description = "Disable User Data for Services Box"
  default     = "1"
}

variable "legacy_builder_spot_price" {
  default = ""
}

variable "azs" {
  default = []
}

# HA Mongodb

variable "mongodb_instance_type" {
  description = "instance type for mongodb replicas.  We recommend a c4 instance"
  default     = "c4.large"
}

variable "mongo_image" {
    default = "ami-fc4f5e85"
}

variable "ubuntu_ami" {
  default = {
    ap-northeast-1 = "ami-0a16e26c"
    ap-northeast-2 = "ami-ed6fb783"
    ap-southeast-1 = "ami-5929b23a"
    ap-southeast-2 = "ami-40180023"
    eu-central-1   = "ami-488e2727"
    eu-west-1      = "ami-a142b2d8"
    sa-east-1      = "ami-ec1b6a80"
    us-east-1      = "ami-845367ff"
    us-east-2      = "ami-43391926"
    us-west-1      = "ami-5185ae31"
    us-west-2      = "ami-103fdc68"
  }
}
