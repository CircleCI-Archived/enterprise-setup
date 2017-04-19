provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.aws_region}"
}

# SQS queue for hook

resource "aws_sqs_queue" "shutdown_queue" {
    name = "${var.prefix}_queue"
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
    # For SSH traffic to builder boxes
    # TODO: Update once services box has ngrok
    ingress {
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "tcp"
        from_port = 64535
        to_port = 65535
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

apt-cache policy | grep circle || curl https://s3.amazonaws.com/circleci-enterprise/provision-builder.sh | bash
curl https://s3.amazonaws.com/circleci-enterprise/init-builder-0.2.sh | \
    SERVICES_PRIVATE_IP='${aws_instance.services.private_ip}' \
    CIRCLE_SECRET_PASSPHRASE='${var.circle_secret_passphrase}' \
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
