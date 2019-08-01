resource "aws_launch_configuration" "mod_lc" {
  # 4x or 8x are best
  instance_type        = var.instance_type
  image_id             = var.image_id
  key_name             = var.aws_ssh_key_name
  iam_instance_profile = var.aws_instance_profile_name
  security_groups      = var.builder_security_group_ids

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "150"
    delete_on_termination = var.delete_volume_on_termination
  }

  user_data = var.user_data

  spot_price = var.spot_price

  # Can't delete an LC until the replacement is applied
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "mod_asg" {
  name = "${var.prefix}_${var.name}_asg"

  vpc_zone_identifier  = [var.aws_subnet_id]
  launch_configuration = aws_launch_configuration.mod_lc.name
  max_size             = var.asg_max_size
  min_size             = var.asg_min_size
  desired_capacity     = var.asg_desired_size
  force_delete         = true

  tag {
    key                 = "Name"
    value               = "${var.prefix}_${var.name}"
    propagate_at_launch = "true"
  }
}

resource "aws_autoscaling_lifecycle_hook" "mod_shutdown_hook" {
  name                    = "${var.prefix}_${var.name}_shutdown_hook"
  autoscaling_group_name  = aws_autoscaling_group.mod_asg.name
  heartbeat_timeout       = 3600
  lifecycle_transition    = "autoscaling:EC2_INSTANCE_TERMINATING"
  notification_target_arn = var.shutdown_queue_target_sqs_arn
  role_arn                = var.shutdown_queue_role_arn
}

