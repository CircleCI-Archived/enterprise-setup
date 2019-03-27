#
# Config SES for email sending
#
resource "aws_ses_domain_identity" "main" {
  domain = "${var.fqdn}"
}

resource "aws_ses_domain_dkim" "main" {
  domain = "${aws_ses_domain_identity.main.domain}"
}

output "ses_verification_token" {
  value = "${aws_ses_domain_identity.main.verification_token}"
}

output "ses_dkim_tokens" {
  value = "${aws_ses_domain_dkim.main.dkim_tokens}"
}