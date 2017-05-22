#! /bin/sh

echo "Installing Docker"
apt-get update
apt-get install -y apt-transport-https ca-certificates curl
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get -y install docker-ce

echo "Creating ci-privileged network"
docker network create --driver=bridge --opt com.docker.network.bridge.name=ci-privileged ci-privileged

echo "Installing nomad"
apt-get install -y zip
curl -o nomad.zip https://releases.hashicorp.com/nomad/0.5.6/nomad_0.5.6_linux_amd64.zip
unzip nomad.zip
mv nomad /usr/bin

echo "Initing Nomad service"
mkdir -p /etc/nomad
cp nomad-config.hcl /etc/nomad/config.hcl
cp nomad-upstart.conf /etc/init/nomad.conf
