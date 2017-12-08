resource "tls_private_key" "ca" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "ca" {
  key_algorithm   = "RSA"
  private_key_pem = "${tls_private_key.ca.private_key_pem}"

  subject = {
    common_name         = "CCIE CA"
    organization        = "CircleCI"
    organizational_unit = "MongoDB replica set - ${var.mongo_replica_set_name}"
    street_address      = ["201 Spear St", "#1200"]
    locality            = "San Francisco"
    province            = "CA"
    country             = "US"
    postal_code         = "94105"
  }

  validity_period_hours = 175200 # ~20 years

  allowed_uses = [
    "cert_signing",
    "crl_signing",
  ]

  is_ca_certificate = true
}

resource "tls_private_key" "server" {
  algorithm = "RSA"
  count     = "${var.num_instances}"
}

resource "tls_cert_request" "server" {
  key_algorithm   = "RSA"
  private_key_pem = "${element(tls_private_key.server.*.private_key_pem, count.index)}"

  subject {
    common_name         = "${format("%smongodb-%s-%02d.%s", var.prefix, var.cluster_id, count.index + 1, replace(var.zone_name, "/\\.$/", ""))}"
    organization        = "CircleCI"
    organizational_unit = "MongoDB replica set - ${var.mongo_replica_set_name} - servers"
    street_address      = ["201 Spear St", "#1200"]
    locality            = "San Francisco"
    province            = "CA"
    country             = "US"
    postal_code         = "94105"
  }

  dns_names = [
    "${format("%smongodb-%s-%02d.%s", var.prefix, var.cluster_id, count.index + 1, replace(var.zone_name, "/\\.$/", ""))}",
    "${format("%smongodb-%s-%02d", var.prefix, var.cluster_id, count.index + 1)}",

    # By default, the mongo shell will attempt to connect to a mongod listening
    # on 127.0.0.1.  This is convenient when administering a local mongod.
    # 127.0.0.1 must be listed here because MongoDB does not inspect IP SANs.
    #
    # https://github.com/mongodb/mongo/blob/r3.2.13/src/mongo/util/net/ssl_manager.cpp#L1145-L1156
    "127.0.0.1",
  ]

  ip_addresses = ["127.0.0.1"]

  count = "${var.num_instances}"
}

resource "tls_locally_signed_cert" "server" {
  cert_request_pem   = "${element(tls_cert_request.server.*.cert_request_pem, count.index)}"
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = "${tls_private_key.ca.private_key_pem}"
  ca_cert_pem        = "${tls_self_signed_cert.ca.cert_pem}"

  validity_period_hours = 175200 # ~20 years

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "key_agreement",
    "server_auth",
    "client_auth",
  ]

  count = "${var.num_instances}"
}

resource "tls_private_key" "root" {
  algorithm = "RSA"
}

resource "tls_cert_request" "root" {
  key_algorithm   = "RSA"
  private_key_pem = "${tls_private_key.root.private_key_pem}"

  subject = {
    common_name         = "root"
    organization        = "CircleCI"
    organizational_unit = "MongoDB replica set - ${var.mongo_replica_set_name} - clients"
    street_address      = ["201 Spear St", "#1200"]
    locality            = "San Francisco"
    province            = "CA"
    country             = "US"
    postal_code         = "94105"
  }
}

resource "tls_locally_signed_cert" "root" {
  cert_request_pem   = "${tls_cert_request.root.cert_request_pem}"
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = "${tls_private_key.ca.private_key_pem}"
  ca_cert_pem        = "${tls_self_signed_cert.ca.cert_pem}"

  validity_period_hours = 175200 # ~20 years

  allowed_uses = [
    "digital_signature",
    "key_agreement",
    "client_auth",
  ]
}

resource "random_id" "telegraf_mongo_password" {
  byte_length = 32
}
