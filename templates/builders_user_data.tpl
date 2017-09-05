#!/bin/bash

apt-cache policy | grep circle || curl https://s3.amazonaws.com/circleci-enterprise/provision-builder.sh | bash
curl https://s3.amazonaws.com/circleci-enterprise/init-builder-0.2.sh | \
    SERVICES_PRIVATE_IP='${services_private_ip}' \
    CIRCLE_SECRET_PASSPHRASE='${circle_secret_passphrase}' \
    bash
