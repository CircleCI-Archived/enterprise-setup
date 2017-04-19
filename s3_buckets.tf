#----------------------------------
# Single general-purpose bucket
#----------------------------------

resource "aws_s3_bucket" "circleci_bucket" {
    # VPC ID is used here to make bucket name globally unique(ish) while
    # uuid/ignore_changes have some lingering issues
    bucket = "${replace(var.prefix, "_", "-")}-bucket-${replace(var.aws_vpc_id, "vpc-", "")}"
    cors_rule {
        allowed_methods = ["GET"]
        allowed_origins = ["*"]
        max_age_seconds = 3600
    }
}