#!/bin/bash

export PRIVATE_IP="$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')"

curl -sSL -o /tmp/get_replicated.sh https://get.replicated.com/docker

bash /tmp/get_replicated.sh local-address="$PRIVATE_IP" no-proxy docker-version="17.06.0-ce"

curl -o /tmp/1EAA813E.pub https://circleci-enterprise.s3.amazonaws.com/1EAA813E.pub
apt-key add /tmp/1EAA813E.pub
echo "deb http://circleci-enterprise.s3.amazonaws.com/debs stable main" > /etc/apt/sources.list.d/circle.list
apt-get update
apt-get install -y circle-replicated
service circle-splash start

config_dir=/var/lib/replicated/circle-config
mkdir -p $config_dir
echo '${circle_secret_passphrase}' > $config_dir/circle_secret_passphrase
echo '${sqs_queue_url}' > $config_dir/sqs_queue_url
echo '${s3_bucket}' > $config_dir/s3_bucket
echo '${aws_region}' > $config_dir/aws_region
echo '${subnet_id}' > $config_dir/subnet_id
echo '${vm_sg_id}' > $config_dir/vm_sg_id
