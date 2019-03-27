output "aws_instance_id" {
  value       = "${aws_instance.services.id}"
  description = "AWS service instance ID"
}

output "circleci_users_sg_id" {
  value       = "${aws_security_group.circleci_users_sg.id}"
  description = "Security group for ingress for Circle CI consumers"
}
