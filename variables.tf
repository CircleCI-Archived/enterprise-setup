# Configure the AWS Provider

# AWS Specific configuration
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

variable "services_instance_type" {
    description = "instance type for the centralized services box.  We recommend a c4 instance"
    default = "c4.2xlarge"
}

variable "builder_instance_type" {
    description = "instance type for the builder machines.  We recommend a r3 instance"
    default = "r3.2xlarge"
}

variable "max_builders_count" {
    description = "max number of builders"
    default = "2"
}

variable "prefix" {
    description = "prefix for resource names"
    default = "circleci"
}