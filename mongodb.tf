# It would seem as though we are using the 'services' box as a sort of bastion;
# however, there exists no concise security group for this purpose.
resource "aws_security_group" "ssh_from_services" {
  name   = "${var.prefix}-ssh-from-services"
  vpc_id = "${var.aws_vpc_id}"

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${aws_security_group.circleci_services_sg.id}"]
  }
}

module "mongodb" {
  count = 0
  source                = "./modules/mongodb"
  num_instances         = "3"
  prefix                = "${var.prefix}-"
  cluster_id            = "20171207"
  instance_type         = "${var.mongodb_instance_type}"
  key_name              = "${var.aws_mongodb_ssh_key_name}"
  ami_id                = "${var.mongo_image}"
  azs                   = "${var.azs}"
  vpc_id                = "${var.aws_vpc_id}"
  subnet_ids            = "${var.aws_subnet_ids}"
  instance_profile_name = "${aws_iam_instance_profile.circleci_profile.name}"

  security_group_ids = [
    "${aws_security_group.ssh_from_services.id}",
  ]

  service_sgs = [
    "${aws_security_group.circleci_builders_sg.id}",
    "${aws_security_group.circleci_services_sg.id}",
  ]

  ebs_size = "300"
  ebs_iops = "100"
  zone_id  = "${var.route_zone_id}"
  mongo_domain = "${var.route_zone_domain}"

  aws_access_key_location = "${var.aws_access_key_location}"
  key_location = "${var.mongodb_key_location}"
}

resource "aws_security_group" "ccie_mongo_client_sg" {
    name = "${var.prefix}_mongo_client_sg"
    description = "Mongo Clients"

    vpc_id = "${var.aws_vpc_id}"
    egress {
        from_port = 27017
        to_port = 27017
        protocol = "tcp"
        cidr_blocks = ["${data.aws_subnet.subnet.cidr_block}"]
    }
}

output "mongo_primary" {
  value = "${module.mongodb.server_primary_fqdn}"
}

output "mongo_secondary" {
  value = "${module.mongodb.server_secondary_fqdn}"
}
