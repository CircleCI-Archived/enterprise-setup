output "domain_validation_options" {
  value = "${aws_acm_certificate.cert.domain_validation_options}"
}

output "elb_name" {
  value = "${aws_lb.lb.dns_name}"
}
