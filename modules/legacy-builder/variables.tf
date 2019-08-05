variable "prefix" {
}

variable "name" {
}

variable "aws_subnet_id" {
}

variable "aws_ssh_key_name" {
}

variable "aws_instance_profile_name" {
}

# Builder ASG Configurations
variable "asg_max_size" {
}

variable "asg_min_size" {
}

variable "asg_desired_size" {
}

variable "user_data" {
}

variable "builder_security_group_ids" {
  type    = list(string)
  default = []
}

variable "delete_volume_on_termination" {
}

# AMI ID to use for builders
variable "image_id" {
}

# Instance Type to use for builders
variable "instance_type" {
}

# Spot Price to use for builders or nil to use on demands
variable "spot_price" {
}

variable "shutdown_queue_target_sqs_arn" {
}

variable "shutdown_queue_role_arn" {
}

