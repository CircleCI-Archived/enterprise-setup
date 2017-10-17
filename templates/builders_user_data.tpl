#!/bin/bash

set -exu

#apt-cache policy | grep circle || curl https://s3.amazonaws.com/circleci-enterprise/provision-builder.sh | bash
#curl https://s3.amazonaws.com/circleci-enterprise/init-builder-0.2.sh | \
#    SERVICES_PRIVATE_IP='${services_private_ip}' \
#    CIRCLE_SECRET_PASSPHRASE='${circle_secret_passphrase}' \
#    bash

BUILDER_IMAGE="circleci/build-image:ubuntu-14.04-XXL-1239-04cfc8d"

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
apt-get install -y linux-image-extra-$(uname -r) linux-image-extra-virtual
apt-get install -y apt-transport-https ca-certificates curl
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get -y install docker-ce=17.03.2~ce-0~ubuntu-trusty cgmanager

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
