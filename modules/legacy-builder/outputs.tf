output "asg_name" {
  value = aws_autoscaling_group.mod_asg.name
}

output "shutdown_hook_name" {
  value = aws_autoscaling_lifecycle_hook.mod_shutdown_hook.name
}

