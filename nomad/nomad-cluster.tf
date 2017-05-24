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

variable "server_instance_type" {
  description = "instance type for the nomad servers. We recommend a XYZ instance"
  default = "t2.medium"
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

variable "client_amis" {
  default = {
    "us-west-1" = "ami-03456563"
  }
}

variable "server_amis" {
  default = {
    "us-west-1" = "ami-24476744"
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

resource "aws_route53_zone" "local" {
  name = "circleci.vpc"
  vpc_id = "${var.aws_vpc_id}"
  force_destroy = true
}

resource "aws_route53_record" "nomad_server" {
  zone_id = "${aws_route53_zone.local.zone_id}"
  name    = "nomad-server.circleci.vpc"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.server.private_ip}"]
}

resource "aws_instance" "server" {
  ami = "${lookup(var.server_amis, var.aws_region)}"
  instance_type = "${var.server_instance_type}"
  subnet_id = "${var.aws_subnet_id}"
  key_name = "${var.aws_ssh_key_name}"
  security_groups = ["${aws_security_group.nomad_sg.id}", "${aws_security_group.ssh_sg.id}"]

  tags {
       Name = "${var.prefix}-nomad-server"
  }
}

resource "aws_launch_configuration" "clients_lc" {
  instance_type = "${var.client_instance_type}"
  image_id = "${lookup(var.client_amis, var.aws_region)}"
  key_name = "${var.aws_ssh_key_name}"
  security_groups = ["${aws_security_group.nomad_sg.id}", "${aws_security_group.ssh_sg.id}"]
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
  # ASG should be created after DNS record for nomad server, otherwise
  # clients would start before DNS exists and would ignore this record indefinetelly
  depends_on = ["aws_route53_record.nomad_server"]
}

output "nomad cluster" {
  value = "http://${aws_route53_record.nomad_server.name}:4646"
}