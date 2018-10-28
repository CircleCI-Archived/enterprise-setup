#####################################
# 1. Required Cloud Configuration
#####################################

aws_access_key = "REPLACE_WITH_REAL_VALUE"
aws_secret_key = "REPLACE_WITH_REAL_VALUE"
aws_region = "us-east-2"
aws_vpc_id = "vpc-045598befc6657e96"
aws_subnet_id = "subnet-0fda43101df099d15"
aws_ssh_key_name = "circleci-prototype-keypair1"

#####################################
# 2. Required CircleCI Configuration
#####################################

circle_secret_passphrase = "REPLACE_WITH_RANDOM_VALUE"
services_instance_type = "m4.2xlarge"
builder_instance_type = "c5.4xlarge"
nomad_client_instance_type = "c5.4xlarge"

#####################################
# 3. Optional Cloud Configuration
#####################################

# Set this to `1` or higher to enable CircleCI 1.0 builders
desired_builders_count = "0"

# Provide proxy address if your network configuration requires it
http_proxy = ""
https_proxy = ""
no_proxy = ""

# Use this var if you have multiple installation within one AWS region
# prefix = "..."
