data "aws_route53_zone" "zone" {
  zone_id = "${var.zone_id}"
}

module "cloudinit" {
  source                 = "../mongodb-cloudinit-config-v1"
  num_instances          = "${var.num_instances}"
  prefix                 = "${var.prefix}"
  cluster_id             = "${var.cluster_id}"
  zone_name              = "${data.aws_route53_zone.zone.name}"
  mongo_replica_set_name = "${format("%smongodb-%s", var.prefix, var.cluster_id)}"
  mongo_device_path      = "/dev/xvdi"
  mongo_domain           = "${var.mongo_domain}"
}

resource "aws_security_group" "mongodb_clients" {
  name   = "${format("%smongodb-%s-clients", var.prefix, var.cluster_id)}"
  vpc_id = "${var.vpc_id}"

  egress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name      = "${format("%smongodb-%s-clients", var.prefix, var.cluster_id)}"
    Role      = "${format("%smongodb-%s", var.prefix, var.cluster_id)}"
    Terraform = "yes"
  }
}

resource "aws_security_group" "mongodb_servers" {
  name   = "${format("%smongodb-%s-servers", var.prefix, var.cluster_id)}"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = ["${concat(list(aws_security_group.mongodb_clients.id), var.service_sgs)}"]
    self            = true
  }

  egress {
    from_port = 27017
    to_port   = 27017
    protocol  = "tcp"
    self      = true
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name      = "${format("%smongodb-%s-servers", var.prefix, var.cluster_id)}"
    Role      = "${format("%smongodb-%s", var.prefix, var.cluster_id)}"
    Terraform = "yes"
  }
}

resource "aws_ebs_volume" "mongodb_primary" {
  availability_zone = "${element(var.azs, var.num_instances - 1)}"
  encrypted         = true
  type              = "io1"
  size              = "${var.ebs_size}"
  iops              = "${var.ebs_iops}"

  tags {
    Name      = "${format("%smongodb-%s-%02d", var.prefix, var.cluster_id, count.index + 1)}"
    Role      = "${format("%smongodb-%s", var.prefix, var.cluster_id)}"
    Terraform = "yes"
  }

  count = "${var.num_instances}"

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_ebs_volume" "mongodb_secondary" {
  availability_zone = "${element(var.azs, count.index)}"
  encrypted         = true
  type              = "io1"
  size              = "${var.ebs_size}"
  iops              = "${var.ebs_iops}"

  tags {
    Name      = "${format("%smongodb-%s-%02d", var.prefix, var.cluster_id, count.index + 2)}"
    Role      = "${format("%smongodb-%s", var.prefix, var.cluster_id)}"
    Terraform = "yes"
  }

  count = "${var.num_instances}"

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_instance" "mongodb_secondary" {
  ami                                  = "${var.ami_id}"
  availability_zone                    = "${element(var.azs, count.index)}"
  ebs_optimized                        = "${var.ebs_optimized}"
  instance_initiated_shutdown_behavior = "stop"
  instance_type                        = "${var.instance_type}"
  key_name                             = "${var.key_name}"
  vpc_security_group_ids               = ["${concat(list(aws_security_group.mongodb_servers.id), var.security_group_ids)}"]
  subnet_id                            = "${element(var.subnet_ids, count.index)}"
  user_data                            = "${element(module.cloudinit.rendered_secondary, count.index)}"
  iam_instance_profile                 = "${var.instance_profile_name}"
  disable_api_termination              = true

  tags {
    Name      = "${format("%smongodb-%s-%02d", var.prefix, var.cluster_id, count.index + 2)}"
    Role      = "${format("%smongodb-%s", var.prefix, var.cluster_id)}"
    Terraform = "yes"
  }

  count = "${var.num_instances - 1}"

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_instance" "mongodb_primary" {
  ami                                  = "${var.ami_id}"
  availability_zone                    = "${element(var.azs, var.num_instances - 1)}"
  ebs_optimized                        = "${var.ebs_optimized}"
  instance_initiated_shutdown_behavior = "stop"
  instance_type                        = "${var.instance_type}"
  key_name                             = "${var.key_name}"
  vpc_security_group_ids               = ["${concat(list(aws_security_group.mongodb_servers.id), var.security_group_ids)}"]
  subnet_id                            = "${element(var.subnet_ids, var.num_instances - 1)}"
  user_data                            = "${element(module.cloudinit.rendered_primary, count.index)}"
  iam_instance_profile                 = "${var.instance_profile_name}"
  disable_api_termination              = true

  tags {
    Name      = "${format("%smongodb-%s-%02d", var.prefix, var.cluster_id, count.index + 1)}"
    Role      = "${format("%smongodb-%s", var.prefix, var.cluster_id)}"
    Terraform = "yes"
  }

  depends_on = ["aws_instance.mongodb_secondary"]

  count = 1

  # TODO(saj): Remove comments following testing.
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_volume_attachment" "mongodb_primary" {
  device_name = "/dev/sdi"
  volume_id   = "${element(aws_ebs_volume.mongodb_primary.*.id, count.index)}"
  instance_id = "${element(aws_instance.mongodb_primary.*.id, count.index)}"
  count       = 1
}

resource "aws_volume_attachment" "mongodb_secondary" {
  device_name = "/dev/sdi"
  volume_id   = "${element(aws_ebs_volume.mongodb_secondary.*.id, count.index)}"
  instance_id = "${element(aws_instance.mongodb_secondary.*.id, count.index)}"
  count       = "${var.num_instances - 1}"
}

resource "aws_route53_record" "mongodb_primary" {
  zone_id = "${var.zone_id}"
  name    = "${format("%smongodb-%s-%02d", var.prefix, var.cluster_id, count.index + 1)}"
  type    = "A"
  ttl     = "300"
  records = ["${element(aws_instance.mongodb_primary.*.private_ip, count.index)}"]
  count   = 1
}

resource "aws_route53_record" "mongodb_secondary" {
  zone_id = "${var.zone_id}"
  name    = "${format("%smongodb-%s-%02d", var.prefix, var.cluster_id, count.index + 2)}"
  type    = "A"
  ttl     = "300"
  records = ["${element(aws_instance.mongodb_secondary.*.private_ip, count.index)}"]
  count   = "${var.num_instances - 1}"
}
