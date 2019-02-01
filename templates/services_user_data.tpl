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
export PRIVATE_IP="$(/usr/bin/curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"

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

##### fluentd configuration #####
if [[ "${enable_fluentd_logging}" == "true" ]];
then

curl -L https://toolbelt.treasuredata.com/sh/install-ubuntu-xenial-td-agent3.sh | sh

# Enable docker fluentd logging driver
cat <<EOF > /etc/docker/daemon.json
{
  "log-driver": "fluentd",
  "log-opts": {
    "fluentd-address": "$PRIVATE_IP:24224",
    "fluentd-async-connect": "true"
  }
}
EOF

# fluentd configuration
cat <<EOF > /etc/td-agent/input-syslog.conf
<source>
  @type syslog
  port 5140
  bind 0.0.0.0
  tag syslog
  protocol_type tcp
</source>
EOF

cat <<EOF > /etc/td-agent/output-elasticsearch.conf
<filter **>
  @type record_transformer
  <record>
    app "circleci"
    env "${env}"
  </record>
</filter>
<match **>
  @type elasticsearch
  host ${es_host}
  port ${es_port}
  scheme ${es_scheme}
  user ${es_user}
  password ${es_password}
  logstash_format true
</match>
EOF

# Remove existing lines as we restore from a AMI snapshot that would
# already have these included
sed -i '/@include match-all.conf/d' /etc/td-agent/td-agent.conf
sed -i '/@include input-syslog.conf/d' /etc/td-agent/td-agent.conf
sed -i '/@include output-elasticsearch.conf/d' /etc/td-agent/td-agent.conf

echo "@include input-syslog.conf" >> /etc/td-agent/td-agent.conf
echo "@include output-elasticsearch.conf" >> /etc/td-agent/td-agent.conf

# start fluentd
systemctl enable td-agent
systemctl restart td-agent

# Restart docker to update logging driver to fluentd
sudo service docker restart
sleep 5

fi
##### end fluentd configuration #####

# telegraf configuration for custom monitoring
if [[ "${enable_telegraf_metrics}" == "true" ]];
then

# create directories to avoid failure on first installation
mkdir -p /etc/circleconfig/telegraf

cat <<EOF > /etc/circleconfig/telegraf/telegraf.conf
[global_tags]
  service = "circleci-server"
  app = "circleci"
  env = "${env}"
  host = "circleci-server-${env}"
EOF

cat <<EOF > /etc/circleconfig/telegraf/datadog.conf
[[outputs.datadog]]
  apikey = "${datadog_api_key}"
EOF

sudo docker restart telegraf || echo "telegraf container doesnt exist"

fi
#end telegraf configuration

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
