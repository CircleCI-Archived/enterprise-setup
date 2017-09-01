#! /bin/sh

echo "-------------------------------------------"
echo "     Performing System Updates"
echo "-------------------------------------------"
apt-get update and apt-get -y upgrade

echo "--------------------------------------"
echo "        Installing Docker"
echo "--------------------------------------"
apt-get install -y linux-image-extra-$(uname -r) linux-image-extra-virtual
apt-get install -y apt-transport-https ca-certificates curl
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get -y install docker-ce=17.06.0~ce-0~ubuntu cgmanager

echo "--------------------------------------"
echo "   Creating ci-privileged network"
echo "--------------------------------------"
docker network create --driver=bridge --opt com.docker.network.bridge.name=ci-privileged ci-privileged

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
mkdir -p /etc/nomad
cat <<EOT > /etc/nomad/config.hcl
log_level = "DEBUG"

data_dir = "/opt/nomad"
datacenter = "us-east-1"

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
cat <<EOT > /etc/init/nomad.conf
start on filesystem or runlevel [2345]
stop on shutdown

script
    exec nomad agent -config /etc/nomad/config.hcl
end script
EOT

echo "--------------------------------------"
echo "      Starting Nomad service"
echo "--------------------------------------"
service nomad restart
