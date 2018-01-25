output "clients_security_group_id" {
  value = "${aws_security_group.mongodb_clients.id}"
}

output "server_primary_fqdn" {
  value = ["${aws_route53_record.mongodb_primary.*.fqdn}"]
}

output "server_secondary_fqdn" {
  value = ["${aws_route53_record.mongodb_secondary.*.fqdn}"]
}

output "ca_key_pem" {
  value = "${module.cloudinit.ca_key_pem}"
}

output "ca_cert_pem" {
  value = "${module.cloudinit.ca_cert_pem}"
}

output "root_key_pem" {
  value = "${module.cloudinit.root_key_pem}"
}

output "root_cert_pem" {
  value = "${module.cloudinit.root_cert_pem}"
}

