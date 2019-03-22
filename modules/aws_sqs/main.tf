resource "aws_sqs_queue" "mod_queue" {
  name = "${var.prefix}_${var.name}_queue"
//  Apply common tags in tags.tf and any custom ones speicfic to this resource
  tags = "${merge(
    var.common_tags
  )}"
}

resource "aws_iam_role" "mod_role" {
  name = "${var.prefix}_${var.name}_queue_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "autoscaling.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "mod_role_policy" {
  name = "${var.prefix}_${var.name}_queue_role"
  role = "${aws_iam_role.mod_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "sqs:GetQueueUrl",
        "sqs:SendMessage"
      ],
      "Effect": "Allow",
      "Resource": [ "${aws_sqs_queue.mod_queue.arn}" ]
    }
  ]
}
EOF
}
