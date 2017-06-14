provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.aws_region}"
}

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

variable "client_instance_type" {
  description = "instance type for the nomad clients. We recommend a XYZ instance"
  default = "m4.large"
}

variable "max_clients_count" {
  description = "max number of nomad clients"
  default = "2"
}

variable "prefix" {
  description = "prefix for resource names"
  default = "circleci"
}

variable "service_box_private_ip" {
  description = "private IP address of the service box"
}

variable "client_amis" {
  default = {
    "ap-northeast-1" = "ami-2faaa348"
    "ap-northeast-2" = "ami-5289563c"
    "ap-southeast-1" = "ami-4ca2202f"
    "ap-southeast-2" = "ami-a73524c4"
    "eu-central-1" = "ami-352e8a5a"
    "eu-west-1" = "ami-728e9114"
    "sa-east-1" = "ami-512d463d"
    "us-east-1" = "ami-2ebeeb38"
    "us-east-2" = "ami-31b79154"
    "us-west-1" = "ami-963d1ef6"
    "us-west-2" = "ami-78515a01"
  }
}

data "aws_subnet" "subnet" {
  id = "${var.aws_subnet_id}"
}

resource "aws_security_group" "nomad_sg" {
  name = "${var.prefix}_nomad_sg"
  description = "SG for CircleCI nomad server/client"
  vpc_id = "${var.aws_vpc_id}"
  ingress {
    from_port = 4646
    to_port = 4648
    protocol = "tcp"
    cidr_blocks = ["${data.aws_subnet.subnet.cidr_block}"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ssh_sg" {
  name = "${var.prefix}_ssh_sg"
  description = "SG for SSH access"

  vpc_id = "${var.aws_vpc_id}"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}
}

data "template_file" "nomad_client_config" {
  template = "${file("nomad-client.hcl.tpl")}"

  vars {
    nomad_server = "${var.service_box_private_ip}"
  }
}

resource "aws_launch_configuration" "clients_lc" {
  instance_type = "${var.client_instance_type}"
  image_id = "${lookup(var.client_amis, var.aws_region)}"
  key_name = "${var.aws_ssh_key_name}"
  root_block_device = {
    volume_type = "gp2"
    volume_size = "200"
  }
  security_groups = ["${aws_security_group.nomad_sg.id}", "${aws_security_group.ssh_sg.id}"]
  user_data = <<EOF
#! /bin/bash
cat <<EOT > /etc/nomad/config.hcl
${data.template_file.nomad_client_config.rendered}
EOT

sudo service nomad restart
EOF
  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_autoscaling_group" "clients_asg" {
  name = "${var.prefix}_nomad_clients_asg"
  vpc_zone_identifier = ["${var.aws_subnet_id}"]
  launch_configuration = "${aws_launch_configuration.clients_lc.name}"
  max_size = "${var.max_clients_count}"
  min_size = 0
  desired_capacity = 1
  force_delete = true
  tag {
    key = "Name"
    value = "${var.prefix}-nomad-client"
    propagate_at_launch = "true"
  }
}
