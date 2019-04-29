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

variable "application" {
  default = "circleci"
}
