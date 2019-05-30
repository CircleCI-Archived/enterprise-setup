/* CMS: Disable secret passing into this module
variable "aws_access_key" {
  description = "Access key used to create instances"
}

variable "aws_secret_key" {
  description = "Secret key used to create instances"
}
*/
variable "arn_prefix" {
  default     = "aws"
  description = "ARN Prefix to use, aws for commercial, aws-us-gov for govcloud"
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
  description = "instance type for the centralized services box.  We recommend a m4.2xlarge instance, with 32G of RAM"
  default     = "m4.2xlarge"
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

variable "force_destroy_s3_bucket" {
  description = "Enable or disable ability to destroy non-empty S3 buckets"
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

variable "ubuntu_ami" {
  default = {
    ap-northeast-1 = "ami-032b53ea1222f69eb"
    ap-northeast-2 = "ami-013dda6d4ad165475"
    ap-northeast-3 = "ami-0e751e4aa374cd8c2"
    ap-southeast-1 = "ami-0b4d63df52bb04cb3"
    ap-southeast-2 = "ami-0df84623c5651856b"
    ap-south-1     = "ami-0a01bf036d8cf964c"
    ca-central-1   = "ami-0855ce2497d6ac2d9"
    eu-central-1   = "ami-00259791f61937520"
    eu-west-1      = "ami-00cc9e3eecbef4b46"
    eu-west-2      = "ami-04a46267269408754"
    eu-west-3      = "ami-0d682f9e8c835173d"
    sa-east-1      = "ami-065d2aa938a7eb3eb"
    us-east-1      = "ami-0f9351b59be17920e"
    us-east-2      = "ami-0b19eeac8c68a0d2d"
    us-west-1      = "ami-0e066bd33054ef120"
    us-west-2      = "ami-0afae182eed9d2b46"
  }
}

variable "postgres_rds_host" {
  description = "DNS for the RDS host. e.g. circleci-dev-db.c3qg1rzruhwh.us-west-2.rds.amazonaws.com"
}

variable "postgres_rds_port" {
  description = "port used by the postgres db"
  default = "5432"
}

variable "postgres_user" {
  description = "postgres user for circleci application"
  default = "circle"
}

variable "postgres_password" {
  description = "the postgres login password used by the postgres_user"
}
