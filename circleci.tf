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

variable "services_ami" {
  description = "Override AMI lookup with provided AMI ID"
  default     = ""
}

variable "services_instance_type" {
  description = "instance type for the centralized services box.  We recommend a c4 instance"
  default     = "c4.2xlarge"
}

variable "builder_instance_type" {
  description = "instance type for the builder machines.  We recommend a r3 instance"
  default     = "r3.2xlarge"
}

variable "max_builders_count" {
  description = "max number of builders"
  default     = "2"
}

variable "prefix" {
  description = "prefix for resource names"
  default     = "circleci"
}

variable "enable_ansible_provisioning" {
  description = "Enables Ansible provisioning of the Services box for automatic / no-touch installation / configuration."
  default     = 0
}

variable "ansible_extra_vars" {
  type    = "map"
  default = {}
}

variable "services_delete_on_termination" {
  description = "Configures AWS to delete the ELB volume for the Services box upon instance termination."
  default     = "false"
}

variable "enable_route" {
  description = "enable creating a Route53 route for the Services box"
  default     = 0
}

variable "route_name" {
  description = "Route name to configure for Services box"
  default     = ""
}

variable "route_zone_id" {
  description = "Zone to configure route in"
  default     = ""
}

data "aws_subnet" "subnet" {
  id = "${var.aws_subnet_id}"
}

data "template_file" "services_user_data" {
  template = "${file("templates/services_user_data.tpl")}"

  vars {
    circle_secret_passphrase = "${var.circle_secret_passphrase}"
    sqs_queue_url            = "${aws_sqs_queue.shutdown_queue.id}"
    s3_bucket                = "${aws_s3_bucket.circleci_bucket.id}"
    aws_region               = "${var.aws_region}"
    subnet_id                = "${var.aws_subnet_id}"
    vm_sg_id                 = "${aws_security_group.circleci_vm_sg.id}"
  }
}

data "template_file" "builders_user_data" {
  template = "${file("templates/builders_user_data.tpl")}"

  vars {
    services_private_ip      = "${aws_instance.services.private_ip}"
    circle_secret_passphrase = "${var.circle_secret_passphrase}"
  }
}

data "template_file" "circleci_policy" {
  template = "${file("templates/circleci_policy.tpl")}"

  vars {
    bucket_arn    = "${aws_s3_bucket.circleci_bucket.arn}"
    sqs_queue_arn = "${aws_sqs_queue.shutdown_queue.arn}"
    role_name     = "${aws_iam_role.circleci_role.name}"
    aws_region    = "${var.aws_region}"
  }
}

data "template_file" "shutdown_queue_role_policy" {
  template = "${file("templates/shutdown_queue_role_policy.tpl")}"

  vars {
    sqs_queue_arn = "${aws_sqs_queue.shutdown_queue.arn}"
  }
}

data "template_file" "output" {
  template = "${file("templates/output.tpl")}"

  vars {
    services_public_ip = "${aws_instance.services.public_ip}"
    ssh_key            = "${var.aws_ssh_key_name}"
    ansible            = "${var.enable_ansible_provisioning}"
    nomad              = "${var.enable_nomad}"
    hostname           = "${lookup(var.ansible_extra_vars, "services_hostname", "")}"
  }
}

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

# SQS queue for hook

resource "aws_sqs_queue" "shutdown_queue" {
  name = "${var.prefix}_queue"
}

# IAM for shutdown queue

resource "aws_iam_role" "shutdown_queue_role" {
  name               = "${var.prefix}_shutdown_queue_role"
  assume_role_policy = "${file("files/shutdown_queue_role.json")}"
}

resource "aws_iam_role_policy" "shutdown_queue_role_policy" {
  name   = "${var.prefix}_shutdown_queue_role"
  role   = "${aws_iam_role.shutdown_queue_role.id}"
  policy = "${data.template_file.shutdown_queue_role_policy.rendered}"
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
}

## IAM for instances

resource "aws_iam_role" "circleci_role" {
  name               = "${var.prefix}_role"
  path               = "/"
  assume_role_policy = "${file("files/circleci_role.json")}"
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
  #    from_protocol = 443
  #    to_protocol = 443
  #}
  #ingress {
  #    security_groups = ["192.30.252.0/22"]
  #    protocol = "tcp"
  #    from_protocol = 80
  #    to_protocol = 80
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
  description = "SG form VMs allocated by CircleCI for Remote Docker and machine executor"

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

variable "ubuntu_ami" {
  default = {
    ap-northeast-1 = "ami-0a16e26c"
    ap-northeast-2 = "ami-ed6fb783"
    ap-southeast-1 = "ami-5929b23a"
    ap-southeast-2 = "ami-40180023"
    eu-central-1   = "ami-488e2727"
    eu-west-1      = "ami-a142b2d8"
    sa-east-1      = "ami-ec1b6a80"
    us-east-1      = "ami-845367ff"
    us-east-2      = "ami-1680a373"
    us-west-1      = "ami-5185ae31"
    us-west-2      = "ami-103fdc68"
  }
}

resource "aws_instance" "services" {
  # Instance type - any of the c4 should do for now
  instance_type               = "${var.services_instance_type}"
  ami                         = "${var.services_ami != "" ? var.services_ami : lookup(var.ubuntu_ami, var.aws_region)}"
  key_name                    = "${var.aws_ssh_key_name}"
  subnet_id                   = "${var.aws_subnet_id}"
  associate_public_ip_address = true
  disable_api_termination     = true
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

  user_data = "${ var.enable_ansible_provisioning ? "sudo apt-get update" : data.template_file.services_user_data.rendered }"

  provisioner "local-exec" {
    command    = "${ var.enable_ansible_provisioning ? "make ansible-setup" : "echo skipped" }"
    on_failure = "continue"
  }

  provisioner "local-exec" {
    command = "${ var.enable_ansible_provisioning ? "echo '\n[services]\n${aws_instance.services.public_ip} ansible_user=ubuntu ansible_ssh_common_args=\"-o ConnectionAttempts=30 -o StrictHostKeyChecking=no\"' > .ansible/hosts" : "echo skipped" }"
  }

  provisioner "local-exec" {
    command = "${ var.enable_ansible_provisioning ? "echo '${jsonencode(merge(var.ansible_extra_vars, map("services_ip",aws_instance.services.private_ip,"secret_passphrase",var.circle_secret_passphrase,"aws_region",var.aws_region,"s3_bucket",aws_s3_bucket.circleci_bucket.id,"sqs_queue_url",aws_sqs_queue.shutdown_queue.id,"circle_version_2",var.enable_nomad)))}' > .ansible/extra_vars.json" : "echo skipped" }"
  }

  provisioner "local-exec" {
    command = "${ var.enable_ansible_provisioning ? "ansible-playbook playbook.yml -v -i ./.ansible/hosts -e \"@./.ansible/extra_vars.json\"" : "echo skipped" }"
  }

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
resource "aws_launch_configuration" "builder_lc" {
  # 4x or 8x are best
  instance_type        = "${var.builder_instance_type}"
  image_id             = "${lookup(var.ubuntu_ami, var.aws_region)}"
  key_name             = "${var.aws_ssh_key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.circleci_profile.name}"

  security_groups = ["${aws_security_group.circleci_builders_sg.id}",
    "${aws_security_group.circleci_builders_admin_sg.id}",
    "${aws_security_group.circleci_users_sg.id}",
  ]

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "150"
    delete_on_termination = "${var.services_delete_on_termination}"
  }

  user_data = "${data.template_file.builders_user_data.rendered}"

  # To enable using spots
  # spot_price = "1.00"

  # Can't delete an LC until the replacement is applied
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "builder_asg" {
  name                 = "${var.prefix}_builders_asg"
  vpc_zone_identifier  = ["${var.aws_subnet_id}"]
  launch_configuration = "${aws_launch_configuration.builder_lc.name}"
  max_size             = "${var.max_builders_count}"
  min_size             = 0
  desired_capacity     = 1
  force_delete         = true

  tag {
    key                 = "Name"
    value               = "${var.prefix}_builder"
    propagate_at_launch = "true"
  }
}

# Shutdown hooks
resource "aws_autoscaling_lifecycle_hook" "builder_shutdown_hook" {
  name                    = "builder_shutdown_hook"
  autoscaling_group_name  = "${aws_autoscaling_group.builder_asg.name}"
  heartbeat_timeout       = 3600
  lifecycle_transition    = "autoscaling:EC2_INSTANCE_TERMINATING"
  notification_target_arn = "${aws_sqs_queue.shutdown_queue.arn}"
  role_arn                = "${aws_iam_role.shutdown_queue_role.arn}"
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
