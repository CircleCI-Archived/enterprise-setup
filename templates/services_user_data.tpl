#!/bin/bash

set -exu
REPLICATED_VERSION="2.10.3"

echo "-------------------------------------------"
echo "     Performing System Updates"
echo "-------------------------------------------"
apt-get update && apt-get -y upgrade

echo "--------------------------------------------"
echo "       Setting Private IP"
echo "--------------------------------------------"
export PRIVATE_IP="$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')"

echo "--------------------------------------------"
echo "          Download Replicated"
echo "--------------------------------------------"
curl -sSk -o /tmp/get_replicated.sh "https://get.replicated.com/docker?replicated_tag=$REPLICATED_VERSION&replicated_ui_tag=$REPLICATED_VERSION&replicated_operator_tag=$REPLICATED_VERSION"

echo "--------------------------------------------"
echo "       Installing Replicated"
echo "--------------------------------------------"
sleep 3
bash /tmp/get_replicated.sh local-address="$PRIVATE_IP" no-proxy docker-version="17.06.0"

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
