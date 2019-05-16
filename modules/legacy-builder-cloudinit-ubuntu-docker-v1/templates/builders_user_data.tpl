#!/bin/bash

set -exu

BUILDER_IMAGE="circleci/build-image:ubuntu-14.04-XXL-upstart-1189-5614f37"
UNAME="$(uname -r)"

export http_proxy="${http_proxy}"
export https_proxy="${https_proxy}"
export no_proxy="${no_proxy}"
export DEBIAN_FRONTEND=noninteractive

echo "-------------------------------------------"
echo "     Performing System Updates"
echo "-------------------------------------------"
apt-get update && apt-get -y upgrade

echo "--------------------------------------"
echo "        Set clocksource to tsc"
echo "--------------------------------------"
echo "tsc" > /sys/devices/system/clocksource/clocksource0/current_clocksource

echo "--------------------------------------"
echo "        Creating timesyncd.conf"
echo "--------------------------------------"
cat <<EOT > /etc/systemd/timesyncd.conf
[Time]
NTP=169.254.169.123
#FallbackNTP=0.debian.pool.ntp.org 1.debian.pool.ntp.org 2.debian.pool.ntp.org 3.debian.pool.ntp.org
EOT

echo "--------------------------------------"
echo "           Restart timesyncd"
echo "--------------------------------------"
sudo systemctl restart systemd-timesyncd.service

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
while ! docker info; do echo "Waiting for docker..."; sleep 1; done

echo "-------------------------------------------"
echo "      Pulling Server Builder Image"
echo "-------------------------------------------"
sudo docker pull $BUILDER_IMAGE

# Make a new docker network
docker network create -d bridge -o "com.docker.network.bridge.name"="circle0" circle-bridge

# Block traffic from build containers to the EC2 metadata API
iptables -I FORWARD -d 169.254.169.254 -p tcp -i docker0 -j DROP

# Block traffic from build containers to non-whitelisted ports on the services box
iptables -I FORWARD -d ${services_private_ip} -p tcp -i docker0 -m multiport ! --dports 80,443 -j DROP

echo "-------------------------------------------"
echo "           Starting Builder"
echo "-------------------------------------------"
sudo docker run -d -p 443:443 -v /var/run/docker.sock:/var/run/docker.sock \
      -e CIRCLE_CONTAINER_IMAGE_URI="docker://$BUILDER_IMAGE" \
      -e CIRCLE_SECRET_PASSPHRASE='${circle_secret_passphrase}' \
      -e SERVICES_PRIVATE_IP='${services_private_ip}'  \
      --net circle-bridge \
      circleci/builder-base:1.1
