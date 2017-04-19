#-----------------------------------------
# IAM Role and Policy for shutdown queue
#-----------------------------------------

resource "aws_iam_role" "shutdown_queue_role" {
    name = "${var.prefix}_shutdown_queue_role"
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


resource "aws_iam_role_policy" "shutdown_queue_role_policy" {
    name = "${var.prefix}_shutdown_queue_role"
    role = "${aws_iam_role.shutdown_queue_role.id}"
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
      "Resource": [ "${aws_sqs_queue.shutdown_queue.arn}" ]
    }
  ]
}
EOF
}

#-----------------------------------------
## IAM for instances
#-----------------------------------------

resource "aws_iam_role" "circleci_role" {
    name = "${var.prefix}_role"
    path = "/"
    assume_role_policy = <<EOF
{
   "Version": "2012-10-17",
    "Statement" : [
       {
          "Action" : ["sts:AssumeRole"],
          "Effect" : "Allow",
          "Principal" : {
            "Service": ["ec2.amazonaws.com"]
          }
       }
    ]
}
EOF
}

resource "aws_iam_role_policy" "circleci_policy" {
  name = "${var.prefix}_policy"
  role = "${aws_iam_role.circleci_role.id}"
  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement" : [
      {
         "Action" : ["s3:*"],
         "Effect" : "Allow",
         "Resource" : [
            "${aws_s3_bucket.circleci_bucket.arn}",
            "${aws_s3_bucket.circleci_bucket.arn}/*"
         ]
      },
      {
          "Action" : [
              "sqs:*"
          ],
          "Effect" : "Allow",
          "Resource" : ["${aws_sqs_queue.shutdown_queue.arn}"]
      },
      {
          "Action": [
              "ec2:Describe*",
              "ec2:CreateTags",
	      "cloudwatch:*",
              "iam:GetUser",
              "autoscaling:CompleteLifecycleAction"
          ],
          "Resource": ["*"],
          "Effect": "Allow"
      }
   ]
}
EOF
}

resource "aws_iam_instance_profile" "circleci_profile" {
  name = "${var.prefix}_profile"
  roles = ["${aws_iam_role.circleci_role.name}"]
}