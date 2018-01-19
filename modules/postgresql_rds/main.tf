resource "aws_db_instance" "mod" {
  allocated_storage        = "${var.postgres_db_size}"
  backup_retention_period  = "${var.postgres_db_backup_retention}"
  db_subnet_group_name     = "${aws_db_subnet_group.mod.name}"
  engine                   = "postgres"
  engine_version           = "${var.pg_version}"
  identifier               = "${var.postgres_identifier}"
  instance_class           = "db.m3.medium"
  multi_az                 = true
  username                 = "${var.postgres_db_master_user}"
  password                 = "${var.postgres_db_master_password}"
  name                     = "circle"
  port                     = 5432
  publicly_accessible      = false
  skip_final_snapshot      = true
  storage_encrypted        = false
  storage_type             = "io1"
  iops                     = "${var.postgres_db_iops}"
  vpc_security_group_ids   = [
    "${aws_security_group.mod.id}"
  ]
}

resource "aws_db_subnet_group" "mod" {
    name = "${var.postgres_identifier}-dbsubnet"
    subnet_ids = ["${var.subnet_ids}"]

    tags {
        Name      = "${var.postgres_identifier}"
        Terraform = "yes"
    }
}

resource "aws_security_group" "mod" {
  name        = "${var.postgres_identifier}_postgres_sg"
  description = "RDS postgres servers for ${var.postgres_identifier} (terraform-managed)"
  vpc_id      = "${var.vpc_id}"

  # Only postgres in
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = ["${var.ingress_sg_group_ids}"]
  }
  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.cidr}"]
  }
}

resource "random_string" "application_password" {
  length  = 45
  special = false
}

data "template_file" "setup_script" {
  template = "${file("${path.module}/templates/pg_setup.sh")}"

  vars {
    databases            = "${join(" ", var.databases)}"
    postgres_host        = "${aws_db_instance.mod.address}"
    postgres_username    = "${var.postgres_db_master_user}"
    postgres_password    = "${var.postgres_db_master_password}"
    postgres_version     = "${var.pg_version}"
    application_password = "${random_string.application_password.result}"
  }
}
