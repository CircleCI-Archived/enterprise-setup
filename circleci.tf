data "aws_subnet" "subnet" {
  id = "${var.aws_subnet_id}"
}

data "template_file" "services_user_data" {
  // CMS: add path.module
  template = "${file("${path.module}/templates/services_user_data.tpl")}"

  vars {
    circle_secret_passphrase = "${var.circle_secret_passphrase}"
    sqs_queue_url            = "${module.shutdown_sqs.sqs_id}"
    s3_bucket                = "${aws_s3_bucket.circleci_bucket.id}"
    aws_region               = "${var.aws_region}"
    subnet_id                = "${var.aws_subnet_id}"
    vm_sg_id                 = "${aws_security_group.circleci_vm_sg.id}"
    http_proxy               = "${var.http_proxy}"
    https_proxy              = "${var.https_proxy}"
    no_proxy                 = "${var.no_proxy}"
  }
}

data "template_file" "circleci_policy" {
  // CMS: add path.module
  template = "${file("${path.module}/templates/circleci_policy.tpl")}"

  vars {
    bucket_arn    = "${aws_s3_bucket.circleci_bucket.arn}"
    sqs_queue_arn = "${module.shutdown_sqs.sqs_arn}"
    role_name     = "${aws_iam_role.circleci_role.name}"
    aws_region    = "${var.aws_region}"
    // CMS: Add arn prefix for govcloud
    arn_prefix    = "${var.arn_prefix}"
  }
}

data "template_file" "output" {
  // CMS: add path.module
  template = "${file("${path.module}/templates/output.tpl")}"

  vars {
    services_public_ip = "${aws_instance.services.public_ip}"
    ssh_key            = "${var.aws_ssh_key_name}"
  }
}
/* CMS: remove AWS configuration in module
provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}
*/

module "shutdown_sqs" {
  source = "./modules/aws_sqs"
  name   = "shutdown"
  prefix = "${var.prefix}"
}

# Single general-purpose bucket

resource "aws_s3_bucket" "circleci_bucket" {
  # VPC ID is used here to make bucket name globally unique(ish) while
  # uuid/ignore_changes have some lingering issues
  bucket = "${replace(var.prefix, "_", "-")}-bucket-${replace(var.aws_vpc_id, "vpc-", "")}"

  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    max_age_seconds = 3600
  }

  force_destroy = "${var.force_destroy_s3_bucket}"
}

## IAM for instances

resource "aws_iam_role" "circleci_role" {
  name               = "${var.prefix}_role"
  path               = "/"
  // CMS: add path.module
  assume_role_policy = "${file("${path.module}/files/circleci_role.json")}"
}

resource "aws_iam_role_policy" "circleci_policy" {
  name   = "${var.prefix}_policy"
  role   = "${aws_iam_role.circleci_role.id}"
  policy = "${data.template_file.circleci_policy.rendered}"
}

resource "aws_iam_instance_profile" "circleci_profile" {
  name = "${var.prefix}_profile"
  role = "${aws_iam_role.circleci_role.name}"
}

## Configure the services machine

resource "aws_security_group" "circleci_builders_sg" {
  name        = "${var.prefix}_builders_sg"
  description = "SG for CircleCI Builder instances"
  vpc_id      = "${var.aws_vpc_id}"

  ingress {
    self      = true
    from_port = 0
    to_port   = 0
    protocol  = "-1"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "circleci_services_sg" {
  name        = "${var.prefix}_services_sg"
  description = "SG for CircleCI services/database instances"
  vpc_id      = "${var.aws_vpc_id}"

  ingress {
    security_groups = ["${aws_security_group.circleci_builders_sg.id}"]
    protocol        = "-1"
    from_port       = 0
    to_port         = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # If using github.com (not GitHub Enterprise) whitelist GitHub cidr block
  # https://help.github.com/articles/what-ip-addresses-does-github-use-that-i-should-whitelist/
  #
  #ingress {
  #    security_groups = ["192.30.252.0/22"]
  #    protocol = "tcp"
  #    from_port = 443
  #    to_port = 443
  #}
  #ingress {
  #    security_groups = ["192.30.252.0/22"]
  #    protocol = "tcp"
  #    from_port = 80
  #    to_port = 80
  #}
}

resource "aws_security_group" "circleci_builders_admin_sg" {
  name        = "${var.prefix}_builders_admin_sg"
  description = "SG for services to masters communication - avoids circular dependency"
  vpc_id      = "${var.aws_vpc_id}"

  ingress {
    security_groups = ["${aws_security_group.circleci_services_sg.id}"]
    protocol        = "tcp"
    from_port       = 443
    to_port         = 443
  }
}

#
# This should be configured by admins to restrict access to machines
# TODO: Make this more extensible
#
resource "aws_security_group" "circleci_users_sg" {
  name        = "${var.prefix}_users_sg"
  description = "SG representing users of CircleCI Enterprise"

  vpc_id = "${var.aws_vpc_id}"

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
  }

  # For Web traffic to services
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 8800
    to_port     = 8800
  }

  # For Nomad server in 2.0 clustered installation
  ingress {
    cidr_blocks = ["${data.aws_subnet.subnet.cidr_block}"]
    protocol    = "tcp"
    from_port   = 4647
    to_port     = 4647
  }

  # For output-processor in 2.0 clustered installation
  ingress {
    cidr_blocks = ["${data.aws_subnet.subnet.cidr_block}"]
    protocol    = "tcp"
    from_port   = 8585
    to_port     = 8585
  }

  # For embedded storage in 2.0 clustered installation
  ingress {
    cidr_blocks = ["${data.aws_subnet.subnet.cidr_block}"]
    protocol    = "tcp"
    from_port   = 7171
    to_port     = 7171
  }

  # For build-agent to talk to vm-service
  ingress {
    cidr_blocks = ["${data.aws_subnet.subnet.cidr_block}"]
    protocol    = "tcp"
    from_port   = 3001
    to_port     = 3001
  }

  # For SSH traffic to builder boxes
  # TODO: Update once services box has ngrok
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 64535
    to_port     = 65535
  }
}

resource "aws_security_group" "circleci_vm_sg" {
  name        = "${var.prefix}_vm_sg"
  description = "SG for VMs allocated by CircleCI for Remote Docker and machine executor"

  vpc_id = "${var.aws_vpc_id}"

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
  }

  # For Web traffic to services
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 2376
    to_port     = 2376
  }

  # For SSHing into 2.0 build
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 54782
    to_port     = 54782
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "services" {
  instance_type               = "${var.services_instance_type}"
  ami                         = "${var.services_ami != "" ? var.services_ami : lookup(var.ubuntu_ami, var.aws_region)}"
  key_name                    = "${var.aws_ssh_key_name}"
  subnet_id                   = "${var.aws_subnet_id}"
  // CMS: disable public IP
  #associate_public_ip_address = true
  disable_api_termination     = "${var.services_disable_api_termination}"
  iam_instance_profile        = "${aws_iam_instance_profile.circleci_profile.name}"

  vpc_security_group_ids = [
    "${aws_security_group.circleci_services_sg.id}",
    "${aws_security_group.circleci_users_sg.id}",
  ]

  tags {
    Name = "${var.prefix}_services"
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "150"
    delete_on_termination = "${var.services_delete_on_termination}"
  }

  user_data = "${ var.services_user_data_enabled ? data.template_file.services_user_data.rendered : "" }"

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_route53_record" "services_route" {
  count   = "${var.enable_route}"
  zone_id = "${var.route_zone_id}"
  name    = "${var.route_name}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.services.public_ip}"]
}

## Builders ASG
module "legacy_builder_user_data" {
  source = "./modules/legacy-builder-cloudinit-ubuntu-docker-v1"

  services_private_ip = "${aws_instance.services.private_ip}"

  circle_secret_passphrase = "${var.circle_secret_passphrase}"
  https_proxy              = "${var.https_proxy}"
  http_proxy               = "${var.http_proxy}"
  no_proxy                 = "${var.no_proxy}"
}

module "legacy_builder" {
  source = "./modules/legacy-builder"

  prefix                    = "${var.prefix}"
  name                      = "builders"
  aws_subnet_id             = "${var.aws_subnet_id}"
  aws_ssh_key_name          = "${var.aws_ssh_key_name}"
  aws_instance_profile_name = "${aws_iam_instance_profile.circleci_profile.name}"

  builder_security_group_ids = [
    "${aws_security_group.circleci_builders_sg.id}",
    "${aws_security_group.circleci_builders_admin_sg.id}",
    "${aws_security_group.circleci_users_sg.id}",
  ]

  asg_max_size     = "${var.max_builders_count}"
  asg_min_size     = 0
  asg_desired_size = "${var.desired_builders_count}"

  user_data                     = "${module.legacy_builder_user_data.rendered}"
  delete_volume_on_termination  = "${var.services_delete_on_termination}"
  image_id                      = "${lookup(var.ubuntu_ami, var.aws_region)}"
  instance_type                 = "${var.builder_instance_type}"
  spot_price                    = "${var.legacy_builder_spot_price}"
  shutdown_queue_target_sqs_arn = "${module.shutdown_sqs.sqs_arn}"
  shutdown_queue_role_arn       = "${module.shutdown_sqs.queue_role_arn}"
}

module "nomad" {
  source                = "./modules/nomad"
  enabled               = "${var.enable_nomad}"
  prefix                = "${var.prefix}"
  instance_type         = "${var.nomad_client_instance_type}"
  aws_vpc_id            = "${var.aws_vpc_id}"
  aws_subnet_id         = "${var.aws_subnet_id}"
  aws_ssh_key_name      = "${var.aws_ssh_key_name}"
  http_proxy            = "${var.http_proxy}"
  https_proxy           = "${var.https_proxy}"
  no_proxy              = "${var.no_proxy}"
  ami_id                = "${(var.services_ami != "") ? var.services_ami : lookup(var.ubuntu_ami, var.aws_region)}"
  aws_subnet_cidr_block = "${data.aws_subnet.subnet.cidr_block}"
  services_private_ip   = "${aws_instance.services.private_ip}"
}

output "success_message" {
  value = "${data.template_file.output.rendered}"
}

output "install_url" {
  value = "http://${aws_instance.services.public_ip}/"
}

output "ssh-services" {
  value = "ssh ubuntu@${aws_instance.services.public_ip}"
}
