#!/bin/bash

set -exu
REPLICATED_VERSION="2.29.0"
UNAME="$(uname -r)"

export http_proxy="${http_proxy}"
export https_proxy="${https_proxy}"
export no_proxy="${no_proxy}"
export DEBIAN_FRONTEND=noninteractive

echo "-------------------------------------------"
echo "     Performing System Updates"
echo "-------------------------------------------"
apt-get update && apt-get -y upgrade

echo "--------------------------------------------"
echo "       Setting Private IP"
echo "--------------------------------------------"
export PRIVATE_IP="$(/sbin/ifconfig ens3 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')"

echo "--------------------------------------------"
echo "          Download Replicated"
echo "--------------------------------------------"
curl -sSk -o /tmp/get_replicated.sh "https://get.replicated.com/docker?replicated_tag=$REPLICATED_VERSION&replicated_ui_tag=$REPLICATED_VERSION&replicated_operator_tag=$REPLICATED_VERSION"

echo "--------------------------------------"
echo "        Installing Docker"
echo "--------------------------------------"
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y "linux-image-$UNAME"
apt-get -y install docker-ce="17.12.1~ce-0~ubuntu"

echo "--------------------------------------------"
echo "       Installing Replicated"
echo "--------------------------------------------"
sleep 3
bash /tmp/get_replicated.sh local-address="$PRIVATE_IP" no-proxy no-docker

echo "--------------------------------------------"
echo "       Passing Variables"
echo "--------------------------------------------"
config_dir=/var/lib/replicated/circle-config
mkdir -p $config_dir
echo '${circle_secret_passphrase}' > $config_dir/circle_secret_passphrase
echo '${sqs_queue_url}' > $config_dir/sqs_queue_url
echo '${s3_bucket}' > $config_dir/s3_bucket
echo '${aws_region}' > $config_dir/aws_region
echo '${subnet_id}' > $config_dir/subnet_id
echo '${vm_sg_id}' > $config_dir/vm_sg_id
echo '${http_proxy}' > $config_dir/http_proxy
echo '${https_proxy}' > $config_dir/https_proxy
echo '${no_proxy}' > $config_dir/no_proxy

echo "--------------------------------------------"
echo "       Setting RDS Postgres variables"
echo "--------------------------------------------"
shared_config_dir=/etc/circleconfig/shared
mkdir -p $shared_config_dir
touch $shared_config_dir/postgresql
echo 'export POSTGRES_HOST="${postgres_rds_host}"' >> $shared_config_dir/postgresql
echo 'export POSTGRES_PORT="${postgres_rds_port}"' >> $shared_config_dir/postgresql
echo 'export POSTGRES_USER="${postgres_user}"' >> $shared_config_dir/postgresql
echo 'export POSTGRES_PASSWORD="${postgres_password}"' >> $shared_config_dir/postgresql
