#! /bin/sh

set -exu

export http_proxy="${http_proxy}"
export https_proxy="${https_proxy}"
export no_proxy="${no_proxy}"
export aws_instance_metadata_url="http://169.254.169.254"
export DEBIAN_FRONTEND=noninteractive
UNAME="$(uname -r)"

echo "-------------------------------------------"
echo "     Performing System Updates"
echo "-------------------------------------------"
apt-get update && apt-get -y upgrade

echo "--------------------------------------"
echo "        Installing Docker"
echo "--------------------------------------"
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get install -y "linux-image-$UNAME"
apt-get update
apt-get -y install docker-ce=17.03.2~ce-0~ubuntu-xenial

sudo echo 'export http_proxy="${http_proxy}"' >> /etc/default/docker
sudo echo 'export https_proxy="${https_proxy}"' >> /etc/default/docker
sudo echo 'export no_proxy="${no_proxy}"' >> /etc/default/docker
sudo service docker restart
sleep 5

echo "--------------------------------------"
echo "         Installing nomad"
echo "--------------------------------------"
apt-get install -y zip
curl -o nomad.zip https://releases.hashicorp.com/nomad/0.5.6/nomad_0.5.6_linux_amd64.zip
unzip nomad.zip
mv nomad /usr/bin

echo "--------------------------------------"
echo "      Creating config.hcl"
echo "--------------------------------------"
export PRIVATE_IP="$(/sbin/ifconfig ens3 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')"
export INSTANCE_ID="$(curl $aws_instance_metadata_url/latest/meta-data/instance-id)"
mkdir -p /etc/nomad
cat <<EOT > /etc/nomad/config.hcl
log_level = "DEBUG"
name = "$INSTANCE_ID"
data_dir = "/opt/nomad"
datacenter = "us-east-1"
advertise {
    http = "$PRIVATE_IP"
    rpc = "$PRIVATE_IP"
    serf = "$PRIVATE_IP"
}
client {
    enabled = true
    # Expecting to have DNS record for nomad server(s)
    servers = ["${nomad_server}:4647"]
    node_class = "linux-64bit"
    options = {"driver.raw_exec.enable" = "1"}
}
EOT

echo "--------------------------------------"
echo "      Creating nomad.conf"
echo "--------------------------------------"
cat <<EOT > /etc/systemd/system/nomad.service
[Unit]
Description="nomad"
[Service]
Restart=always
RestartSec=30
TimeoutStartSec=1m
ExecStart=/usr/bin/nomad agent -config /etc/nomad/config.hcl
[Install]
WantedBy=multi-user.target
EOT

echo "--------------------------------------"
echo "   Creating ci-privileged network"
echo "--------------------------------------"
docker network create --driver=bridge --opt com.docker.network.bridge.name=ci-privileged ci-privileged

echo "--------------------------------------"
echo "      Starting Nomad service"
echo "--------------------------------------"
service nomad restart
