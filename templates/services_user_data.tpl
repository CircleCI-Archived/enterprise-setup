#!/bin/bash

set -exu
REPLICATED_VERSION="2.10.3"

export http_proxy="${http_proxy}"
export https_proxy="${https_proxy}"
export no_proxy="${no_proxy}"

echo "-------------------------------------------"
echo "     Performing System Updates"
echo "-------------------------------------------"
apt-get update && apt-get -y upgrade


echo "--------------------------------------------"
echo "       Add Block Devices"
echo "--------------------------------------------"

add_volume() {
	local data_device_path="${1}"
	local data_mount_path="${2}"
	if ! blkid ${data_device_path}; then
		mkfs -t ext4 ${data_device_path}
	fi
	if ! lsblk -o MOUNTPOINT | grep ${data_mount_path}; then
		mkdir -p ${data_mount_path}
		mount ${data_device_path} ${data_mount_path}
		cat  <<EOF >> /etc/fstab
UUID=$(blkid  -s UUID -o value ${data_device_path}) ${data_mount_path} ext4 defaults 0 0
EOF
	fi
}
add_volume ${application_data_device_path} ${application_data_mount_path}
add_volume ${nomad_data_device_path} ${nomad_data_mount_path}

if [[ ! -z "${sandbox_secure_domain}" ]]; then
echo "--------------------------------------------"
echo "       Installing Lego"
echo "--------------------------------------------"

wget https://github.com/xenolf/lego/releases/download/v0.4.1/lego_linux_amd64.tar.xz
tar -xf lego_linux_amd64.tar.xz
mv lego_linux_amd64 /usr/local/sbin/lego

echo "--------------------------------------------"
echo "       Setting Private IP"
echo "--------------------------------------------"
export PRIVATE_IP="$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')"



echo "--------------------------------------------"
echo "          Download Replicated"
echo "--------------------------------------------"
curl -sSk -o /tmp/get_replicated.sh "https://get.replicated.com/docker?replicated_tag=$REPLICATED_VERSION&replicated_ui_tag=$REPLICATED_VERSION&replicated_operator_tag=$REPLICATED_VERSION"

echo "--------------------------------------"
echo "        Installing Docker"
echo "--------------------------------------"
apt-get install -y linux-image-extra-$(uname -r) linux-image-extra-virtual
apt-get install -y apt-transport-https ca-certificates curl
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get -y install docker-ce=17.03.2~ce-0~ubuntu-trusty cgmanager

echo "--------------------------------------------"
echo "       Installing Replicated"
echo "--------------------------------------------"
sleep 3
bash /tmp/get_replicated.sh local-address="$PRIVATE_IP" no-proxy no-docker

echo "--------------------------------------------"
echo "       Persist Replicated"
echo "--------------------------------------------"

until docker stop replicated replicated-operator replicated-ui; do
	echo "...waiting to stop replicated"
	sleep 5
done

if [[ ! -d /data/circle/replicated ]]; then
	mv /var/lib/replicated /data/circle/replicated
else
	rm -r /var/lib/replicated
fi

if [[ ! -d /data/circle/replicated-operator ]]; then
	mv /var/lib/replicated-operator /data/circle/replicated-operator
else
	rm -r /var/lib/replicated-operator
fi
ln -s /data/circle/replicated /var/lib/replicated
ln -s /data/circle/replicated-operator /var/lib/replicated-operator

until docker start replicated replicated-operator replicated-ui; do
	echo "...waiting to start replicated"
	sleep 5
done


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
