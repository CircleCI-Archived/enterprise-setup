{
   "Version": "2012-10-17",
   "Statement" : [
      {
         "Action" : ["s3:*"],
         "Effect" : "Allow",
         "Resource" : [
            "${bucket_arn}",
            "${bucket_arn}/*"
         ]
      },
      {
          "Action" : [
              "sqs:*"
          ],
          "Effect" : "Allow",
          "Resource" : ["${sqs_queue_arn}"]
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
      },

      {
              "Action": [
                  "ec2:RunInstances",
                  "ec2:CreateTags"
              ],
              "Effect": "Allow",
              "Resource": "arn:aws:ec2:${aws_region}:*"
          },
          {
              "Action": [
                  "ec2:Describe*"
              ],
              "Effect": "Allow",
              "Resource": "*"
          },
          {
              "Action": [
                  "ec2:TerminateInstances"
              ],
              "Effect": "Allow",
              "Resource": "arn:aws:ec2:${aws_region}:*:instance/*",
              "Condition": {
                  "StringEquals": {
                      "ec2:ResourceTag/ManagedBy": "circleci-vm-service"
                  }
              }
          },
          {
              "Action": [
                 "sts:AssumeRole"
              ],
              "Resource": [
                  "arn:aws:iam::*:role/${role_name}"
              ],
              "Effect": "Allow"
          }
   ]
}
