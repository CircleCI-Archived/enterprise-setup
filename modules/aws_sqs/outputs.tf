output "sqs_id" {
  value = "${aws_sqs_queue.mod_queue.id}"
}

output "sqs_arn" {
  value = "${aws_sqs_queue.mod_queue.arn}"
}

output "queue_role_name" {
  value = "${aws_iam_role.mod_role.name}"
}

output "queue_role_arn" {
  value = "${aws_iam_role.mod_role.arn}"
}
