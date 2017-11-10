#!/bin/bash
set -ex
TLS_DIR="$HOME/.circleci/server/tls"
IP="${1}"
SHOULD_RSYNC="${2}"
REMOTE_IP="${3}"
mkdir -m 744 -p ${TLS_DIR}
cd ${TLS_DIR}
if [ ! -s "${TLS_DIR}/ca.key" ] && [ ! -s "${TLS_DIR}/ca.pem" ]; then
	openssl genrsa -out ca.key 2048
	openssl req -x509 -new -nodes -key ca.key -sha256 -days 1825 -out ca.pem \
			-subj "/C=US/ST=California/L=San Francisco/O=CircleCI/CN=SphereCI Certificate Authority"
	openssl pkcs12 -export -in ca.pem -inkey ca.key -name "SphereCI Certificate Authority" -out ca.p12
fi

# Service Box
openssl req \
		-newkey rsa:2048 -nodes -keyout server.key \
		-out server.csr \
		-subj "/C=US/ST=California/L=San Francisco/O=CircleCI/CN=SphereCI"
openssl x509 -req -in server.csr \
		-extfile <(printf "subjectAltName=IP:${REMOTE_IP}") \
		-CA ca.pem -CAkey ca.key -CAcreateserial \
		-out server.crt -days 1825 -sha256
rm server.csr
chmod 744 server.key

# HA Box
openssl req \
		-newkey rsa:2048 -nodes -keyout ha.key \
		-out ha.csr \
		-subj "/C=US/ST=California/L=San Francisco/O=CircleCI/CN=${IP}"
openssl x509 -req -in ha.csr \
		-extfile <(printf "subjectAltName=IP:${IP},DNS:${IP}") \
		-CA ca.pem -CAkey ca.key -CAcreateserial \
		-out ha.crt -days 1825 -sha256
rm ha.csr
echo -e "$(cat ha.crt)\n$(cat ha.key)" > ha.pem
chmod 700 ha.key ha.pem
rm ca.srl

if [ "${SHOULD_RSYNC}" = "true" ]; then
	set +e
	RC=1
	TRY=1
	RETRIES=12
	INTERVAL=10
	while [[ ${RC} -ne 0 ]] && [[ ${TRY} -le ${RETRIES} ]]
	do
	   rsync -avze "ssh -o StrictHostKeyChecking=no" \
	               ${TLS_DIR}/ca.pem \
				   ${TLS_DIR}/ha.pem \
				   ${TLS_DIR}/ha.crt \
				   ${TLS_DIR}/ha.key \
				ubuntu@${REMOTE_IP}:~/
	   RC=$?
	   TRY=$((TRY+1))
	   sleep $INTERVAL
	done
	if [ ${RC} -ne 0 ]; then
		exit 1
	fi
	set -e
	ssh ubuntu@${REMOTE_IP} 'sudo mkdir -p /etc/ssl/circleci; \
					  sudo cp ~/ca.pem /usr/local/share/ca-certificates/ca.crt; \
					  sudo mv ~/ca.pem ~/ha.pem ~/ha.key ~/ha.crt /etc/ssl/circleci; \
					  sudo mkdir -p /etc/ssl/circleci/vault;
					  sudo cp /etc/ssl/circleci/ha.key /etc/ssl/circleci/ha.crt /etc/ssl/circleci/vault/; \
					  cat /etc/ssl/circleci/ca.pem | sudo tee -a /etc/ssl/circleci/vault/ha.crt'
fi
