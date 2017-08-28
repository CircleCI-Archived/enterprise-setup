variable "enable_nomad" {
  description = "Nomad builder fleet is used for CCIE v2. It is disabled by default."
  default     = "0"
}

variable "nomad_client_instance_type" {
  description = "instance type for the nomad clients. We recommend a XYZ instance"
  default     = "m4.xlarge"
}

variable "max_clients_count" {
  description = "max number of nomad clients"
  default     = "2"
}

variable "client_amis" {
  default = {
	"ap-northeast-1" = "ami-52cf2f34"
	"ap-northeast-2" = "ami-499c4527"
	"ap-south-1"     = "ami-6fb1c900"
	"ap-southeast-1" = "ami-4da5362e"
	"ap-southeast-2" = "ami-85647be6"
	"ca-central-1"   = "ami-492b942d"
	"eu-central-1"   = "ami-7553fe1a"
	"eu-west-1"      = "ami-3833da41"
	"eu-west-2"      = "ami-564c5d32"
	"sa-east-1"      = "ami-7e295e12"
	"us-east-1"      = "ami-92f6a7e9"
	"us-east-2"      = "ami-984363fd"
	"us-west-1"      = "ami-c3cae3a3"
	"us-west-2"      = "ami-b7b1a9ce"
  }
}

resource "aws_security_group" "nomad_sg" {
  count       = "${var.enable_nomad}"
  name        = "${var.prefix}_nomad_sg"
  description = "SG for CircleCI nomad server/client"
  vpc_id      = "${var.aws_vpc_id}"

  ingress {
    from_port   = 4646
    to_port     = 4648
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_subnet.subnet.cidr_block}"]
  }

  # For SSHing into 2.0 build
  ingress {
    from_port   = 64535
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ssh_sg" {
  count       = "${var.enable_nomad}"
  name        = "${var.prefix}_ssh_sg"
  description = "SG for SSH access"
  vpc_id      = "${var.aws_vpc_id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "template_file" "nomad_client_config" {
  template = "${file("templates/nomad-client.hcl.tpl")}"

  vars {
    nomad_server = "${aws_instance.services.private_ip}"
  }
}

resource "aws_launch_configuration" "clients_lc" {
  count         = "${var.enable_nomad}"
  instance_type = "${var.nomad_client_instance_type}"
  image_id      = "${lookup(var.client_amis, var.aws_region)}"
  key_name      = "${var.aws_ssh_key_name}"

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
  count                = "${var.enable_nomad}"
  name                 = "${var.prefix}_nomad_clients_asg"
  vpc_zone_identifier  = ["${var.aws_subnet_id}"]
  launch_configuration = "${aws_launch_configuration.clients_lc.name}"
  max_size             = "${var.max_clients_count}"
  min_size             = 0
  desired_capacity     = 1
  force_delete         = true

  tag {
    key                 = "Name"
    value               = "${var.prefix}-nomad-client"
    propagate_at_launch = "true"
  }
}
