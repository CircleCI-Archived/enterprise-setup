prefix = "..."

aws_access_key   = "..."
aws_secret_key   = "..."
aws_region       = "..."
aws_vpc_id       = "..."
aws_subnet_id    = "..."
aws_ssh_key_name = "..."

circle_secret_passphrase = "..."

services_instance_type = "c4.2xlarge"
builder_instance_type  = "r3.4xlarge"

accepts_connection = [
  "198.51.100.0/24",
  "203.0.113.0/24"
]
accepts_seacret_connection = [
  "10.0.64.0/26",
  "10.0.64.64/26",
]
