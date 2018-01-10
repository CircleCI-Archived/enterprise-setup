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

  aws_access_key_location = "${var.aws_access_key_location}"
  bastion_host = "${var.bastion_host != "" ? var.bastion_host : aws_instance.services.public_ip}"
  bastion_port = "${var.bastion_port != "" ? var.bastion_port : "22"}"
  bastion_user = "${var.bastion_user != "" ? var.bastion_user : "ubuntu"}"
  bastion_key = "${var.bastion_key != "" ? var.bastion_key : "~/.ssh/id_rsa"}"
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
