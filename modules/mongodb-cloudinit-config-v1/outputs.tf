output "rendered" {
  value = ["${data.template_cloudinit_config.config.*.rendered}"]
}

output "ca_key_pem" {
  value = "${tls_private_key.ca.private_key_pem}"
}

output "ca_cert_pem" {
  value = "${tls_self_signed_cert.ca.cert_pem}"
}

output "root_key_pem" {
  value = "${tls_private_key.root.private_key_pem}"
}

output "root_cert_pem" {
  value = "${tls_locally_signed_cert.root.cert_pem}"
}
