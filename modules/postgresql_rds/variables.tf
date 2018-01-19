variable "vpc_id" {}
variable "region" {}
variable "cidr"   {}

variable "postgres_db_size" {
	default = "100"  #gigabytes
}

variable "postgres_db_iops" {
  default = "1000"
}

variable "postgres_db_backup_retention" {
  default = "7"    # in days
}

variable "postgres_db_master_user" {
  default = "circle"
}
variable "postgres_db_master_password" {
  default = ""
}

variable "postgres_identifier" {
  default = "circle"
}

variable "subnet_ids" {
	type = "list"
}

variable "ingress_sg_group_ids" {
  default = []
}

variable "pg_version" {
  default = "9.5.4"
}

variable "databases" {
  default = []
}
