#! /bin/sh

set -exu

export http_proxy="${http_proxy}"
export https_proxy="${https_proxy}"
export no_proxy="${no_proxy}"

echo "-------------------------------------------"
echo "     Performing System Updates"
echo "-------------------------------------------"
apt-get update && apt-get -y upgrade

echo "--------------------------------------"
echo "        Installing Docker"
echo "--------------------------------------"
apt-get install -y linux-image-extra-virtual
apt-get install -y apt-transport-https ca-certificates curl
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get -y install docker-ce=17.03.2~ce-0~ubuntu-xenial cgmanager

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
mkdir -p /etc/nomad
cat <<EOT > /etc/nomad/config.hcl
log_level = "DEBUG"

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
echo "      Creating nomad.service"
echo "--------------------------------------"
cat <<EOT > /etc/systemd/system/nomad.service
[Unit]
Description=Nomad
Documentation=https://nomadproject.io/docs/
[Service]
KillMode=process
KillSignal=SIGINT
ExecStart=/usr/bin/nomad agent -config /etc/nomad
ExecReload=/bin/kill -HUP \$MAINPID
LimitNOFILE=65536
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
systemctl daemon-reload
systemctl enable nomad
systemctl restart nomad
