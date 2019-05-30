variable "stack" {
  type = "string"
}

variable "fqdn" {
  type        = "string"
  description = "FQDN that this circle instance will listen on. Used to request an ACM certificate."
}

variable "aws_ssh_key_name" {
  description = "Optional ssh key to install"
  default     = ""
}

variable "rds_instance" {
  type        = "string"
  description = "RDS postgres instance size"

  # CircleCI recommendations for <50 daily active CircleCI users are:
  #   8 cores, 16GB ram, 100GB disk space, 1 Gbps NIC speed, as per
  #   https://confluenceent.cms.gov/download/attachments/24089194/external-services.pdf?version=1&modificationDate=1553082082450&api=v2

  # The "db.m5.2xlarge" instance class maps closest to these requirements:
  #   https://aws.amazon.com/rds/instance-types/
  default = "db.m5.2xlarge"
}

variable "rds_allocated_storage" {
  type        = "string"
  description = "allocated RDS storage in gigabytes"
  default     = 100
}

variable "application" {
  default = "circleci"
}
