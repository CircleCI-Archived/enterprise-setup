#!/bin/bash
IP="$$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"

cat << EOF > /etc/circle-installation-customizations
MONGO_BASE_URI=mongodb://circle:${mongo_password}@$${IP}:27017
export CIRCLE_SECRETS_MONGODB_MAIN_URI="$MONGO_BASE_URI/circle_ghe?authSource=admin"
export CIRCLE_SECRETS_MONGODB_ACTION_LOGS_URI="$MONGO_BASE_URI/circle_ghe?authSource=admin"
export CIRCLE_SECRETS_MONGODB_BUILD_STATE_URI="$MONGO_BASE_URI/build_state_dev_ghe?authSource=admin"
export CIRCLE_SECRETS_MONGODB_CONTAINERS_URI="$MONGO_BASE_URI/containers_dev_ghe?authSource=admin"

# Postgres DB
export CIRCLE_SECRETS_POSTGRES_MAIN_URI='postgres://circle:${postgres_password}@$${IP}:5432/circle'

# Vault
export VAULT__SCHEME="https"
export VAULT__HOST="$${IP}"
export VAULT__PORT=8200
export VAULT__CLIENT_TOKEN="<vault-client-token>"
export VAULT__TRANSIT_MOUNT="transit"
EOF
