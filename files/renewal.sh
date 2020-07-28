#!/bin/sh
# Automatically updates and installs the letsencrypt certificates in
# replicated and circleci.
#
# Requirements:
#   * Certbot
#
# Steps:
#  1. Ensure certbot is configured and can renew certificates
#  2. Install the following cronjob
#
#      0 22 */10 * * DOMAIN=circleci.example.org /etc/letsencrypt/renew.sh

set -eu

DOMAIN="${1:?}"
CERTIFICATE="/etc/letsencrypt/live/${DOMAIN:?}/fullchain.pem"
PRIVATE_KEY="/etc/letsencrypt/live/${DOMAIN:?}/privkey.pem"

certificate_renew() {
    certbot renew
}

# Is update required?
certificate_update_required() {
    DAYS=${1:-30}
    if openssl x509 -checkend $(( 24*3600*${DAYS} )) -noout -in ${CERTIFICATE:?}; then
        return 1
    fi
}

# Update circleci certificate
update_app_certificate() {
replicatedctl app-config set 'ssl_cert' --value "$(basename ${CERTIFICATE})" --data "$(cat ${CERTIFICATE} | base64)"
replicatedctl app-config set 'ssl_private_key' --value "$(basename ${PRIVATE_KEY})" --data "$(cat ${PRIVATE_KEY} | base64)"
}

# Update replicated cli certificate
update_replicated_certificate() {
replicated console cert set ${DOMAIN:?} ${PRIVATE_KEY} ${CERTIFICATE}
}

# Retrieve current app state
get_app_state() {
    replicatedctl app status | grep '"State":' | cut -d'"' -f4
}

# Stop replicated in a blocking manner.
stop_replicated() {
    if [ $(get_app_state) = 'stopped' ]; then
        return 0
    fi
    replicatedctl app stop
    wait_for_replicated_status stopped
}

restart_replicatedui() {
    service replicated-ui restart
}

# Start replicated in a blocking manner.
start_replicated() {
    if [ $(get_app_state) = 'started' ]; then
        return 0
    fi
    replicatedctl app start
    wait_for_replicated_status started
}

# Block for 10 minutes or until replicated is in desired state.
wait_for_replicated_status() {
    desired_status=${1:?}
    printf "Waiting for app to report ${desired_status}..."
    started=0
    for i in $(seq 1 60); do
        if [ $(get_app_state) = "${desired_status}" ]; then
            echo " done."
            started=1
            break;
        fi
        printf '.'
        sleep 10
    done

    if [ $started = 0 ]; then
        echo "!! Exceeded 10 minutes."
        echo "!! Something has gone wrong and replicated was unable to start."
        exit 1
    fi
}


if certificate_update_required; then
    echo "Stopping replicated"
    stop_replicated

    echo "Renewing certificates"
    certificate_renew

    echo "Installing certificates"
    update_replicated_certificate
    update_app_certificate

    echo "Restarting replicated-ui"
    restart_replicatedui

    echo "Starting replicated"
    start_replicated
else
    echo "Skipping certificate renewal process."
fi
