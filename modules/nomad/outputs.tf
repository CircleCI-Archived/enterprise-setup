output "asg_name" {
  value = "${aws_autoscaling_group.clients_asg.*.name}"
}

output "client_security_group_name" {
  value = "${aws_security_group.nomad_sg.*.name}"
}

output "ssh_security_group_name" {
  value = "${aws_security_group.ssh_sg.*.name}"
}

output "client_launch_config_name" {
  value = "${aws_launch_configuration.clients_lc.*.name}"
}
