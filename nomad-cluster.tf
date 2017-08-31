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
    ap-northeast-1 = "ami-0a16e26c"
    ap-northeast-2 = ""
    ap-southeast-1 = "ami-5929b23a"
    ap-southeast-2 = "ami-40180023"
    eu-central-1   = "ami-488e2727"
    eu-west-1      = "ami-a142b2d8"
    sa-east-1      = "ami-ec1b6a80"
    us-east-1      = "ami-845367ff"
    us-east-2      = ""
    us-west-1      = "ami-5185ae31"
    us-west-2      = "ami-103fdc68"
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

# data "template_file" "nomad_client_config" {
#   template = "${file("templates/nomad-client.hcl.tpl")}"

#   vars {
#     nomad_server = "${aws_instance.services.private_ip}"
#   }
# }

data "template_file" "nomad_user_data"{
  template = "${file("templates/nomad_user_data.tpl")}"

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

  user_data = "${data.template_file.nomad_user_data.rendered}"

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
