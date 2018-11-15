output "asg_name" {
  value = "${var.enabled ? aws_autoscaling_group.clients_asg.*.name[0] : ""}"
}

output "client_security_group_name" {
  value = "${var.enabled ? aws_security_group.nomad_sg.*.name[0] : ""}"
}

output "ssh_security_group_name" {
  value = "${var.enabled ? aws_security_group.ssh_sg.*.name[0] : ""}"
}

output "client_launch_config_name" {
  value = "${var.enabled ? aws_launch_configuration.clients_lc.*.name[0] : ""}"
}
