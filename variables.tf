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
    ap-northeast-1 = "ami-2d69f14b"
    ap-northeast-2 = "ami-cd78d8a3"
    ap-southeast-1 = "ami-c38bf8bf"
    ap-southeast-2 = "ami-a437cac6"
    ca-central-1   = "ami-c1a227a5"
    eu-central-1   = "ami-ff30a290"
    eu-west-1      = "ami-3cf36145"
    eu-west-2      = "ami-fd47a59a"
    sa-east-1      = "ami-24642648"
    us-east-1      = "ami-0ce3bb76"
    us-east-2      = "ami-01664c64"
    us-west-1      = "ami-98595af8"
    us-west-2      = "ami-779a2d0f"
  }
}

### Data Persistence

variable "application_data_ebs_size" {
  description = ""
  default = "200"
}

variable "application_data_ebs_iops" {
  description = ""
  default = "100"
}

variable "application_data_device_path" {
  description = ""
  default = "/dev/xvdi"
}

variable "application_data_mount_path" {
  description = ""
  default = "/data/circle"
}

variable "nomad_data_ebs_size" {
  description = ""
  default = "50"
}

variable "nomad_data_ebs_iops" {
  description = ""
  default = "100"
}

variable "nomad_data_device_path" {
  description = ""
  default = "/dev/xvdj"
}

variable "nomad_data_mount_path" {
  description = ""
  default = "/opt/nomad"
}

variable "force_detach_volumes" {
  default = "false"
}
