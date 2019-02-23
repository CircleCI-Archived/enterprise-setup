module "cloudinit" {
  source            = "../nomad-cloudinit-ubuntu-v1"
  server_private_ip = "${var.services_private_ip}"
  http_proxy        = "${var.http_proxy}"
  https_proxy       = "${var.https_proxy}"
  no_proxy          = "${var.no_proxy}"
}

resource "aws_security_group" "nomad_sg" {
  count       = "${var.enabled}"
  name        = "${var.prefix}_nomad_sg"
  description = "SG for CircleCI nomad server/client"
  vpc_id      = "${var.aws_vpc_id}"

  ingress {
    from_port   = 4646
    to_port     = 4648
    protocol    = "tcp"
    cidr_blocks = ["${var.aws_subnet_cidr_block}"]
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
  count       = "${var.enabled}"
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

resource "aws_launch_configuration" "clients_lc" {
  count         = "${var.enabled}"
  instance_type = "${var.instance_type}"
  image_id      = "${var.ami_id}"
  key_name      = "${var.aws_ssh_key_name}"

  root_block_device = {
    volume_type = "gp2"
    volume_size = "200"
  }

  security_groups = ["${aws_security_group.nomad_sg.id}", "${aws_security_group.ssh_sg.id}"]

  user_data = "${module.cloudinit.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "clients_asg" {
  count                = "${var.enabled}"
  name                 = "${var.prefix}_nomad_clients_asg"
  vpc_zone_identifier  = ["${var.aws_subnet_id}"]
  launch_configuration = "${aws_launch_configuration.clients_lc.name}"
  max_size             = "${var.max_instances}"
  min_size             = 0
  desired_capacity     = "${var.desired_instances}"
  force_delete         = true

  tag {
    key                 = "Name"
    value               = "${var.prefix}-nomad-client"
    propagate_at_launch = "true"
  }
}
