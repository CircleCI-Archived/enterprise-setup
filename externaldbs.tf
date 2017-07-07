## Postgres RDS

resource "aws_db_instance" "circle_postgres" {  
  allocated_storage       = "${var.postgres_db_size}"
  backup_retention_period = "${var.postgres_db_backup_retention}"
  db_subnet_group_name    = "${aws_db_subnet_group.default.name}"
  engine                  = "postgres"
  engine_version          = "9.5.4"
  identifier              = "${var.prefix}-circle-pg"
  instance_class          = "db.m3.xlarge"
  multi_az                = true
  username                = "${var.postgres_db_master_user}"
  password                = "${var.postgres_db_master_password}"
  name                    = "${var.postgres_db_name}"
  port                    = "${var.postgres_port}"
  skip_final_snapshot     = true  ## CHANGE THIS TO FALSE IN PRODUCTION
  publicly_accessible     = false
  storage_encrypted       = true
  storage_type            = "io1"
  iops                    = "${var.postgres_db_iops}"
  vpc_security_group_ids  = ["${aws_security_group.circle_postgres_sg.id}"]
}

resource "aws_db_subnet_group" "default" {
    name       = "${var.prefix}_dbsubnet"
    subnet_ids = ["${var.aws_subnet_id}","${var.aws_subnet_id_2}"]

    tags {
        Name      = "${var.prefix}_dbsubnet"
    }
}

resource "aws_security_group" "circle_postgres_sg" {  
  name        = "${var.prefix}_postgres_sg"
  description = "RDS postgres servers (terraform-managed)"
  vpc_id      = "${var.aws_vpc_id}"

  # Only postgres in
  ingress {
    security_groups = ["${aws_security_group.circleci_builders_sg.id}","${aws_security_group.circleci_services_sg.id}"]
    from_port   = "${var.postgres_port}"
    to_port     = "${var.postgres_port}"
    protocol    = "tcp"
    #cidr_blocks = ["${var.cidr}"]
  }

  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}