module "circle_pg" {
  source = "./modules/postgresql_rds"

  postgres_db_master_user     = "root"
  postgres_db_master_password = "${var.postgres_db_password}"
  postgres_identifier         = "${var.prefix != "" ? format("%s-circle", var.prefix) : "circle"}"
  subnet_ids                  = "${var.aws_subnet_ids}"
  region                      = "${var.aws_region}"
  cidr                        = "${var.postgresql_egress_cidr}"
  vpc_id                      = "${var.aws_vpc_id}"
  ingress_sg_group_ids        = "${concat(var.postgresql_ingress_sg_group_ids, list(aws_security_group.circleci_services_sg.id))}"
  databases                   = "${var.postgresql_databases}"
}

resource "null_resource" "pg_setup" {
  # Changes to any instance of the cluster requires re-provisioning
  depends_on = ["module.circle_pg"]

  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    type        = "ssh"
    host = "${var.bastion_host != "" ? var.bastion_host : aws_instance.services.public_ip}"
    port = "${var.bastion_port != "" ? var.bastion_port : "22"}"
    user = "${var.bastion_user != "" ? var.bastion_user : "ubuntu"}"
    private_key  = "${file(var.bastion_key != "" ? var.bastion_key : "~/.ssh/id_rsa")}"
  }

  provisioner "file" {
    content     = "${module.circle_pg.postgres_setup_script}"
    destination = "/tmp/pg_setup.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/pg_setup.sh",
      "sudo /tmp/pg_setup.sh",
    ]
  }
}

output "posgresql_endpoint" {
  value = "${module.circle_pg.endpoint}"
}

output "postgres_application_user" {
  value = "${module.circle_pg.application_user}"
}

output "postgres_application_password" {
  value = "${module.circle_pg.application_password}"
}
