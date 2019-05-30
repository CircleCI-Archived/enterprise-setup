#
# Externalize RDS.
#
# You will need to set an RDS password before you can provision RDS, like so:
#   aws ssm put-parameter \
#     --name circleci-REPLACEME_WITH_STACK_NAME-rds-admin-pass \
#     --value REPLACEME_WITH_PASSWORD \
#     --type String
#

#
# Define postgres ingress. This only allows access in from the ecs tasks
#
resource "aws_security_group" "postgres_ingress" {
  name        = "${local.prefix}-postgres-ingress"
  description = "allow inbound access from ECS tasks only"
  vpc_id      = "${module.network.vpc_id}"
  tags        = "${module.tags.application_tags}"

  ingress {
    protocol        = "tcp"
    from_port       = "5432"
    to_port         = "5432"
    security_groups = ["${module.circleci.circleci_services_sg_id}"]
  }
}

module "rds_postgres" {
  source = "terraform-aws-modules/rds/aws"

  identifier        = "${var.application}-${var.stack}-db"
  name              = "circle" # This creates a database with this name when the DB instance is created
  engine            = "postgres"
  engine_version    = "10.6" # Note that circle's implementation is currently running on postgres 9.5.15
  instance_class    = "${var.rds_instance}"
  allocated_storage = "${var.rds_allocated_storage}"
  storage_encrypted = true

  # uncomment to use specific/non-default key
  # kms_key_id        = "arm:aws:kms:<region>:<account id>:key/<kms key id>"

  username               = "circle"
  password               = "${data.aws_ssm_parameter.rds_admin_pass.value}"
  port                   = "5432"
  vpc_security_group_ids = ["${aws_security_group.postgres_ingress.id}"]
  maintenance_window     = "Mon:00:00-Mon:03:00"
  backup_window          = "03:00-06:00"
  # disable backups to create DB faster
  backup_retention_period = 0
  tags                    = "${module.tags.application_tags}"
  # DB subnet group
  subnet_ids = ["${module.network.private_subnet_ids}"]
  # DB parameter group
  family = "postgres10"
  # DB option group
  major_engine_version = "10.6"
  # Snapshot name upon DB deletion
  # final_snapshot_identifier = "circleci"
  # Database Deletion Protection
  deletion_protection = true
  # Enable enhanced monitoring
  # For this demo, we will create role automatically.
  create_monitoring_role = true
  monitoring_role_name = "${local.prefix}-rds-monitoring"
  monitoring_interval  = "30"
}

#
# Store the RDS hostname in 'rds_db_host'
#
resource "aws_ssm_parameter" "rds_db_host" {
  name      = "${local.prefix}-rds-db-host"
  type      = "String"
  overwrite = true
  value     = "${module.rds_postgres.this_db_instance_address}"
}

#
# SSM Parameters used by this application
#
data "aws_ssm_parameter" "rds_admin_user" {
  name = "${local.prefix}-rds-admin-user"
}

data "aws_ssm_parameter" "rds_admin_pass" {
  name = "${local.prefix}-rds-admin-pass"
}
