#!/bin/bash

#apt-cache policy | grep circle || curl https://s3.amazonaws.com/circleci-enterprise/provision-builder.sh | bash
#curl https://s3.amazonaws.com/circleci-enterprise/init-builder-0.2.sh | \
#    SERVICES_PRIVATE_IP='${services_private_ip}' \
#    CIRCLE_SECRET_PASSPHRASE='${circle_secret_passphrase}' \
#    bash

BUILDER_IMAGE="circleci/build-image:ubuntu-14.04-XXL-1167-271bbe4"

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

echo "-------------------------------------------"
echo "      Pulling Server Builder Image"
echo "-------------------------------------------"
sudo docker pull $BUILDER_IMAGE

echo "-------------------------------------------"
echo "           Starting Builder"
echo "-------------------------------------------"
sudo docker run -d -p 443:443 -v /var/run/docker.sock:/var/run/docker.sock \
      -e CIRCLE_CONTAINER_IMAGE_URI="docker://$BUILDER_IMAGE" \
      -e CIRCLE_SECRET_PASSPHRASE='${circle_secret_passphrase}' \
      -e SERVICES_PRIVATE_IP='${services_private_ip}'  \
      circleci/builder-base:1.1
