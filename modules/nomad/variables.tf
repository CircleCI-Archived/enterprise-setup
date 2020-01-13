# prefix is an optional string that will be used to namespace all AWS resources
# created by this module.  The value of this string should match the regular
# expression ^[a-z][a-z0-9-]+$.  e.g.: "circleci-".
variable "prefix" {
  default = ""
}

variable "enabled" {
  default = "1"
}

variable "aws_vpc_id" {
}

variable "aws_ssh_key_name" {
}

variable "aws_subnet_id" {
}

variable "aws_subnet_cidr_block" {
}

variable "ami_id" {
}

variable "os" {
  default = "ubuntu"
}

variable "instance_type" {
  default = "m5.xlarge"
}

variable "services_private_ip" {
  default = ""
}

variable "max_instances" {
  default = "2"
}

variable "desired_instances" {
  default = "1"
}

variable "http_proxy" {
}

variable "https_proxy" {
}

variable "no_proxy" {
}

