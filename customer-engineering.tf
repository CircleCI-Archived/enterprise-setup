# variables
variable "spin_up_schedule" {
	description = "cron string for autoscaling scheduler"
	default     = "0 14 * * MON-FRI"
}

variable "spin_down_schedule" {
	description = "cron string for autoscaling scheduler"
	default     = "0 2 * * TUE-SAT"
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