variable "num_instances" {}

variable "prefix" {}

variable "cluster_id" {}

variable "zone_name" {}

variable "mongo_replica_set_name" {}

# mongo_device_path is the fully-qualified Linux filesystem path to the block
# device used to store all MongoDB data.  This should point at an EBS volume.
# cloudinit will format the device, if necessary, and mount it.
variable "mongo_device_path" {}

# mongo_mount_path is the fully-qualified Linux filesystem path at which
# mongo_device_path will be mounted.
variable "mongo_mount_path" {
  default = "/mongo"
}

variable "mongo_domain" {}

variable "is_master" {
  default = ""
}
