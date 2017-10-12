# variables
variable "spin_up_schedule" {
  description = "cron string for autoscaling scheduler"
}

variable "spin_down_schedule" {
  description = "cron string for autoscaling scheduler"
}

# variables
variable "services_scheduler_up" {
  description = "cron string for starting services box"
}

variable "services_scheduler_down" {
  description = "cron string for stopping services box"
}

# nomad scheduler up
resource "aws_autoscaling_schedule" "clients_asg_up" {
  scheduled_action_name  = "spin_up"
  recurrence             = "${var.spin_up_schedule}"
  max_size               = 1 
  desired_capacity       = 1
  autoscaling_group_name = "${var.prefix}_nomad_clients_asg"
}

# nomad scheduler down
resource "aws_autoscaling_schedule" "clients_asg_down" {
  scheduled_action_name  = "spin_down"
  recurrence             = "${var.spin_down_schedule}"
  desired_capacity       = 0
  autoscaling_group_name = "${var.prefix}_nomad_clients_asg"
}

# builder scheduler up
resource "aws_autoscaling_schedule" "builder_asg_up" {
  scheduled_action_name  = "spin_up"
  recurrence             = "${var.spin_up_schedule}"
  max_size               = 1
  desired_capacity       = 1
  autoscaling_group_name = "${var.prefix}_builders_asg"
}

# builder scheduler down
resource "aws_autoscaling_schedule" "builder_asg_down" {
  scheduled_action_name  = "spin_down"
  recurrence             = "${var.spin_down_schedule}"
  desired_capacity       = 0
  autoscaling_group_name = "${var.prefix}_builders_asg"
}

# elastic IP for services since it will be stopping/starting every day
resource "aws_eip" "services" {
  instance = "${aws_instance.services.id}"
  vpc      = true
}

# see https://blog.goodmirek.com/periodically-start-and-stop-ec2-instance-bf25c01e68f1 for more on what follows
# iam policy for starting/stopping services box
resource "aws_iam_policy" "ec2_start_stop_policy" {
  name   = "${var.prefix}_ec2_start_stop_policy"
  policy = "${file("templates/ec2_start_stop_policy.tpl")}"
}

# role for the above policy
resource "aws_iam_role" "ec2_start_stop_role" {
  name = "${var.prefix}_ec2_start_stop_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# attach policy to role
resource "aws_iam_role_policy_attachment" "ec2_start_stop_attach" {
    role       = "${aws_iam_role.ec2_start_stop_role.name}"
    policy_arn = "${aws_iam_policy.ec2_start_stop_policy.arn}"
}

# function to start services box
resource "aws_lambda_function" "start_services_box" {
  filename         = "files/start-server.zip"
  function_name    = "${var.prefix}_start_services_box"
  role             = "${aws_iam_role.ec2_start_stop_role.arn}"
  handler          = "start-server.handler"
  runtime          = "nodejs6.10"
  timeout          = 59

  environment {
    variables = {
      servicesInstanceId = "${aws_instance.services.id}"
      awsRegion          = "${var.aws_region}"
    }
  }
}

# function to stop services box
resource "aws_lambda_function" "stop_services_box" {
  filename         = "files/stop-server.zip"
  function_name    = "${var.prefix}_stop_services_box"
  role             = "${aws_iam_role.ec2_start_stop_role.arn}"
  handler          = "stop-server.handler"
  runtime          = "nodejs6.10"
  timeout          = 59

  environment {
    variables = {
      servicesInstanceId = "${aws_instance.services.id}"
      awsRegion          = "${var.aws_region}"
    }
  }
}

# cloudwatch rule to start services box
resource "aws_cloudwatch_event_rule" "start_services_box" {
  name                = "${var.prefix}_start_services_box"
  schedule_expression = "${var.services_scheduler_up}"
}

# target to connect start rule to start lambda function
resource "aws_cloudwatch_event_target" "start_services_box" {
  rule      = "${aws_cloudwatch_event_rule.start_services_box.name}"
  target_id = "start_services_box"
  arn       = "${aws_lambda_function.start_services_box.arn}"
}

# cloudwatch rule to stop services box
resource "aws_cloudwatch_event_rule" "stop_services_box" {
  name                = "${var.prefix}_stop_services_box"
  schedule_expression = "${var.services_scheduler_down}"
}

# target to connect stop rule to stop lambda function
resource "aws_cloudwatch_event_target" "stop_services_box" {
  rule      = "${aws_cloudwatch_event_rule.stop_services_box.name}"
  target_id = "stop_services_box"
  arn       = "${aws_lambda_function.stop_services_box.arn}"
}