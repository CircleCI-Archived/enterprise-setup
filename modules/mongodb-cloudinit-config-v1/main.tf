data "template_file" "cloud_config" {
  template = "${file("${path.module}/templates/cloud-config")}"

  vars {
    prefix            = "${var.prefix}"
    cluster_id        = "${var.cluster_id}"
    zone_name         = "${var.zone_name}"
    mongo_device_path = "${var.mongo_device_path}"
    mongo_mount_path  = "${var.mongo_mount_path}"

    fqdn = "${format("%smongodb-%s-%02d.%s", var.prefix, var.cluster_id, count.index + 1, var.zone_name)}"
  }

  count = "${var.num_instances}"
}

data "template_file" "config" {
  template = "${file("${path.module}/templates/config")}"

  vars {
    prefix                 = "${var.prefix}"
    cluster_id             = "${var.cluster_id}"
    zone_name              = "${var.zone_name}"
    mongo_replica_set_name = "${var.mongo_replica_set_name}"
    mongo_device_path      = "${var.mongo_device_path}"
    mongo_mount_path       = "${var.mongo_mount_path}"
    mongo_domain           = "${var.mongo_domain}"
    num_instances          = "${var.num_instances}"
    is_master              = "${count.index == 0 ? "true" : "false"}"

    ca_cert_pem             = "${tls_self_signed_cert.ca.cert_pem}"
    server_key_pem          = "${element(tls_private_key.server.*.private_key_pem, count.index)}"
    server_cert_pem         = "${element(tls_locally_signed_cert.server.*.cert_pem, count.index)}"
    root_key_pem            = "${tls_private_key.root.private_key_pem}"
    root_cert_pem           = "${tls_locally_signed_cert.root.cert_pem}"
  }

  count = "${var.num_instances}"
}

data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = "${element(data.template_file.cloud_config.*.rendered, count.index)}"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "${element(data.template_file.config.*.rendered, count.index)}"
  }

  count = "${var.num_instances}"
}
