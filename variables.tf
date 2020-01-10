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

variable "aws_ssh_key_name" {
  description = "The SSH key to be used for the instances"
}

variable "enable_govcloud" {
  description = "Allows deployment into AWS GovCloud"
  default = "false"
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
  default     = "true"
}

variable "legacy_builder_spot_price" {
  default = ""
}

variable "ubuntu_ami" {
  default = {
    ap-east-1      = "ami-736d1602"
    ap-northeast-1 = "ami-096c57cee908da809"
    ap-northeast-2 = "ami-0a25005e83c56767a"
    ap-northeast-3 = "ami-04c5893bcd93bc072"
    ap-southeast-1 = "ami-04613ff1fdcd2eab1"
    ap-southeast-2 = "ami-000c2343cf03d7fd7"
    ap-south-1     = "ami-03dcedc81ea3e7e27"
    ca-central-1   = "ami-0eb3e12d3927c36ef"
    cn-north-1     = "ami-05bf8d3ead843c270"
    cn-northwest-1 = "ami-09081e8e3d61f4b9e"
    eu-central-1   = "ami-0085d4f8878cddc81"
    eu-north-1     = "ami-4bd45f35"
    eu-west-1      = "ami-03746875d916becc0"
    eu-west-2      = "ami-0cbe2951c7cd54704"
    eu-west-3      = "ami-080d4d4c37b0aa206"
    sa-east-1      = "ami-09beb384ba644b754"
    us-east-1      = "ami-0cfee17793b08a293"
    us-east-2      = "ami-0f93b5fd8f220e428"
    us-gov-east-1  = "ami-0933d278"
    us-gov-west-1  = "ami-1580c474"
    us-west-1      = "ami-09eb5e8a83c7aa890"
    us-west-2      = "ami-0b37e9efc396e4c38"
  }
}

