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

data "aws_subnet" "subnet" {
  id = "${var.aws_subnet_id}"
}

provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.aws_region}"
}

# SQS queue for hook

resource "aws_sqs_queue" "shutdown_queue" {
    name = "${var.prefix}_queue"
}


# IAM for shutdown queue

resource "aws_iam_role" "shutdown_queue_role" {
    name = "${var.prefix}_shutdown_queue_role"
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
    name = "${var.prefix}_shutdown_queue_role"
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
    name = "${var.prefix}_role"
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
  name = "${var.prefix}_policy"
  role = "${aws_iam_role.circleci_role.id}"
  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement" : [
      {
         "Action" : ["s3:*"],
         "Effect" : "Allow",
         "Resource" : [
            "${aws_s3_bucket.circleci_bucket.arn}",
            "${aws_s3_bucket.circleci_bucket.arn}/*"
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
              "iam:GetUser",
              "autoscaling:CompleteLifecycleAction"
          ],
          "Resource": ["*"],
          "Effect": "Allow"
      }
   ]
}
EOF
}

resource "aws_iam_instance_profile" "circleci_profile" {
  name = "${var.prefix}_profile"
  roles = ["${aws_iam_role.circleci_role.name}"]
}


## Configure the services machine

resource "aws_security_group" "circleci_builders_sg" {
    name = "${var.prefix}_builders_sg"
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
    name = "${var.prefix}_services_sg"
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
    name = "${var.prefix}_builders_admin_sg"
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
    name = "${var.prefix}_users_sg"
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

    # For Nomad server in 2.0 clustered installation
    ingress {
        cidr_blocks = ["${data.aws_subnet.subnet.cidr_block}"]
        protocol = "tcp"
        from_port = 4647
        to_port = 4647
    }

    # For output-processor in 2.0 clustered installation
    ingress {
        cidr_blocks = ["${data.aws_subnet.subnet.cidr_block}"]
        protocol = "tcp"
        from_port = 8585
        to_port = 8585
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
      ap-northeast-1 = "ami-23fcc944"
      ap-northeast-2 = "ami-6f6cbe01"
      ap-southeast-1 = "ami-7949f21a"
      ap-southeast-2 = "ami-23fff740"
      eu-central-1 = "ami-e55a868a"
      eu-west-1 = "ami-995053ff"
      sa-east-1 = "ami-59d6bb35"
      us-east-1 = "ami-edf793fb"
      us-east-2 = "ami-2c2c0b49"
      us-west-1 = "ami-0e50776e"
      us-west-2 = "ami-d43fa1b4"
    }
}

variable "builder_image" {
    default = {
      ap-northeast-1 = "ami-38d8fa5f"
      ap-northeast-2 = "ami-5ff22031"
      ap-southeast-1 = "ami-381aa45b"
      ap-southeast-2 = "ami-76bab415"
      eu-central-1 = "ami-46d50729"
      eu-west-1 = "ami-c8b288ae"
      sa-east-1 = "ami-af5c3ec3"
      us-east-1 = "ami-4d75f85b"
      us-east-2 = "ami-b78ca8d2"
      us-west-1 = "ami-8d0124ed"
      us-west-2 = "ami-feef7c9e"
    }
}

resource "aws_instance" "services" {
    # Instance type - any of the c4 should do for now
    instance_type = "${var.services_instance_type}"

    ami = "${lookup(var.base_services_image, var.aws_region)}"

    key_name = "${var.aws_ssh_key_name}"

    subnet_id = "${var.aws_subnet_id}"
    associate_public_ip_address = true
    vpc_security_group_ids = [
        "${aws_security_group.circleci_services_sg.id}",
        "${aws_security_group.circleci_users_sg.id}"
    ]

    iam_instance_profile = "${aws_iam_instance_profile.circleci_profile.name}"
    tags {
        Name = "${var.prefix}_services"
    }


    root_block_device {
        volume_type = "gp2"
	volume_size = "150"
	delete_on_termination = false
    }

    user_data = <<EOF
#!/bin/bash

replicated -version || curl https://s3.amazonaws.com/circleci-enterprise/init-services.sh | bash

config_dir=/var/lib/replicated/circle-config
mkdir -p $config_dir
echo '${var.circle_secret_passphrase}' > $config_dir/circle_secret_passphrase
echo '${aws_sqs_queue.shutdown_queue.id}' > $config_dir/sqs_queue_url
echo '${aws_s3_bucket.circleci_bucket.id}' > $config_dir/s3_bucket

EOF

    lifecycle {
        prevent_destroy = true
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

curl -sSL https://get.docker.com | sh
sudo docker pull circleci/build-image:ubuntu-14.04-XXL-1167-271bbe4
sudo docker run -d -v /var/run/docker.sock:/var/run/docker.sock \
    -e CIRCLE_CONTAINER_IMAGE_URI="docker://circleci/build-image:ubuntu-14.04-XXL-1167-271bbe4" \
    -e CIRCLE_SECRET_PASSPHRASE='${var.circle_secret_passphrase}' \
    -e SERVICES_PRIVATE_IP='${aws_instance.services.private_ip}'  \
    circleci/builder-base:1.1

EOF

    # To enable using spots
    # spot_price = "1.00"

    # Can't delete an LC until the replacement is applied
    lifecycle {
      create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "builder_asg" {
    name = "${var.prefix}_builders_asg"

    vpc_zone_identifier = ["${var.aws_subnet_id}"]
    launch_configuration = "${aws_launch_configuration.builder_lc.name}"
    max_size = "${var.max_builders_count}"
    min_size = 0
    desired_capacity = 1
    force_delete = true
    tag {
      key = "Name"
      value = "${var.prefix}_builder"
      propagate_at_launch = "true"
    }
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
