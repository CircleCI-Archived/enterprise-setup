#-----------------------------------------------
# Launch Configuration
#-----------------------------------------------
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


#-----------------------------------------------
# Autoscaling Group 
#-----------------------------------------------
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

#-----------------------------------------------
# Shutdown hooks
#-----------------------------------------------

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