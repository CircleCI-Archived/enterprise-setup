# Configure the AWS Provider

# AWS Specific configuration
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

provider "aws" {
    region = "${var.aws_region}"
}

## Configure the role

resource "aws_iam_role" "circleci_role" {
    name = "circleci_role"
    path = "/"
    assume_role_policy = <<EOF
{
   "Version": "2012-10-17",
    "Statement" : [
       {
          "Action" : ["sts:AssumeRole"],
          "Effect" : "Allow",
          "Principal" : {
            "Service": ["ec2.amazonaws.com"]
          }
       }
    ]
}
EOF
}

resource "aws_iam_role_policy" "circleci_policy" {
  name = "circleci_policy"
  role = "${aws_iam_role.circleci_role.id}"
  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement" : [
      {
         "Action" : ["s3:*"],
         "Effect" : "Allow",
         "Resource" : [
            "arn:aws:s3:::circleci-*",
            "arn:aws:s3:::circleci-*/*"
         ]
      },
      {
          "Action" : [
              "sqs:*"
          ],
          "Effect" : "Allow",
          "Resource" : ["${aws_sqs_queue.shutdown_queue.arn}"]
      },
      {
          "Action": [
              "ec2:Describe*",
              "ec2:CreateTags",
	      "cloudwatch:*",
              "iam:GetUser"
          ],
          "Resource": ["*"],
          "Effect": "Allow"
      }
   ]
}
EOF
}

resource "aws_iam_instance_profile" "circleci_profile" {
  name = "circleci_profile"
  roles = ["${aws_iam_role.circleci_role.name}"]
}


## Configure the services machine

resource "aws_security_group" "circleci_builders_sg" {
    name = "circleci_builders_sg"
    description = "SG for CircleCI Builder instances"

    vpc_id = "${var.aws_vpc_id}"
    ingress {
        self = true
        from_port = 0
        to_port = 0
        protocol = "-1"
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "circleci_services_sg" {
    name = "circleci_services_sg"
    description = "SG for CircleCI services/database instances"

    vpc_id = "${var.aws_vpc_id}"
    ingress {
        security_groups = ["${aws_security_group.circleci_builders_sg.id}"]
        protocol = "-1"
        from_port = 0
        to_port = 0
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
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
    name = "circleci_builders_admin_sg"
    description = "SG for services to masters communication - avoids circular dependency"

    vpc_id = "${var.aws_vpc_id}"
    ingress {
        security_groups = ["${aws_security_group.circleci_services_sg.id}"]
        protocol = "tcp"
        from_port = 443
        to_port = 443
    }
}

#
# This should be configured by admins to restrict access to machines
# TODO: Make this more extensible
#
resource "aws_security_group" "circleci_users_sg" {
    name = "circleci_users_sg"
    description = "SG representing users of CircleCI Enterprise"

    vpc_id = "${var.aws_vpc_id}"
    ingress {
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "tcp"
        from_port = 22
        to_port = 22
    }
    # For Web traffic to services
    ingress {
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "tcp"
        from_port = 80
        to_port = 80
    }
    ingress {
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "tcp"
        from_port = 443
        to_port = 443
    }
    ingress {
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "tcp"
        from_port = 8800
        to_port = 8800
    }
    # For SSH traffic to builder boxes
    # TODO: Update once services box has ngrok
    ingress {
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "tcp"
        from_port = 64535
        to_port = 65535
    }
}

variable "base_services_image" {
    default = {
      ap-northeast-1  = "ami-c6293ca8"
      ap-northeast-2  = "ami-38814956"
      ap-southeast-1  = "ami-85ee3be6"
      ap-southeast-2  = "ami-dcddfdbf"
      eu-central-1    = "ami-175ebf78"
      eu-west-1       = "ami-1955d16a"
      sa-east-1       = "ami-a723accb"
      us-east-1       = "ami-edc7cb87"
      us-west-1       = "ami-ade597cd"
      us-west-2       = "ami-934ca4f3"
    }
}

variable "builder_image" {
    default = {
      ap-northeast-1  = "ami-e12d2c8f"
      ap-northeast-2  = "ami-3931f857"
      ap-southeast-1  = "ami-a7ec39c4"
      ap-southeast-2  = "ami-2694b345"
      eu-central-1    = "ami-69a14106"
      eu-west-1       = "ami-a02597d3"
      sa-east-1       = "ami-9a3db2f6"
      us-east-1       = "ami-6658690c"
      us-west-1       = "ami-a9abdac9"
      us-west-2       = "ami-2932d149"
      ap-southeast-2  = "ami-2694b345"
    }
}

resource "aws_instance" "services" {
    # Instance type - any of the c4 should do for now
    instance_type = "${var.services_instance_type}"

    ami = "${lookup(var.base_services_image, var.aws_region)}"

    key_name = "${var.aws_ssh_key_name}"

    subnet_id = "${var.aws_subnet_id}"
    associate_public_ip_address = true
    security_groups = ["${aws_security_group.circleci_services_sg.id}",
                       "${aws_security_group.circleci_users_sg.id}"]

    iam_instance_profile = "${aws_iam_instance_profile.circleci_profile.name}"
    tags {
        Name = "circleci_services"
    }


    root_block_device {
        volume_type = "gp2"
	volume_size = "150"
	delete_on_termination = false
    }

}


## Builders ASG
resource "aws_launch_configuration" "builder_lc" {
    # 4x or 8x are best
    instance_type = "${var.builder_instance_type}"


    image_id = "${lookup(var.builder_image, var.aws_region)}"
    key_name = "${var.aws_ssh_key_name}"

    security_groups = ["${aws_security_group.circleci_builders_sg.id}",
                       "${aws_security_group.circleci_builders_admin_sg.id}",
                       "${aws_security_group.circleci_users_sg.id}"]

    iam_instance_profile = "${aws_iam_instance_profile.circleci_profile.name}"

    user_data = <<EOF
#!/bin/bash
curl https://s3.amazonaws.com/circleci-enterprise/init-builder-0.2.sh | \
    SERVICES_PRIVATE_IP=${aws_instance.services.private_ip} \
    bash

EOF

    # To enable using spots
    # spot_price = "1.00"

    # Can't delete an LC until the replacement is applied
    lifecycle {
      create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "builder_asg" {
    name = "circleci_builders_asg"

    vpc_zone_identifier = ["${var.aws_subnet_id}"]
    launch_configuration = "${aws_launch_configuration.builder_lc.name}"
    max_size = "${var.max_builders_count}"
    min_size = 0
    desired_capacity = 1
    force_delete = true
    tag {
      key = "Name"
      value = "circleci_builder"
      propagate_at_launch = "true"
    }
}

# SQS queue for hook

resource "aws_sqs_queue" "shutdown_queue" {
  name = "circleci_shutdown_queue"
}


# IAM for shutdown queue

resource "aws_iam_role" "shutdown_queue_role" {
    name = "circleci_shutdown_queue_role"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "autoscaling.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "shutdown_queue_role_policy" {
    name = "circleci_shutdown_queue_role"
    role = "${aws_iam_role.shutdown_queue_role.id}"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "sqs:GetQueueUrl",
        "sqs:SendMessage"
      ],
      "Effect": "Allow",
      "Resource": [ "${aws_sqs_queue.shutdown_queue.arn}" ]
    }
  ]
}
EOF
}

# Shutdown hooks

resource "aws_autoscaling_lifecycle_hook" "builder_shutdown_hook" {
    name = "builder_shutdown_hook"
    autoscaling_group_name = "${aws_autoscaling_group.builder_asg.name}"
    heartbeat_timeout = 3600
    lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"
    notification_target_arn = "${aws_sqs_queue.shutdown_queue.arn}"
    role_arn = "${aws_iam_role.shutdown_queue_role.arn}"
}

output "installation_wizard_url" {
    value = "http://${aws_instance.services.public_ip}/"
}

output "shutdown_hook_queue_url" {
    value = "${aws_sqs_queue.shutdown_queue.id}"
}
