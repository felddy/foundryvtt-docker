#!/bin/bash
# shellcheck disable=SC2016

set -e

if [ "$1" = 'postfix' ]; then

    # generate confgurations using environment variables
    envsubst '\$PRIMARY_DOMAIN \$RELAY_IP' < templates/main.cf > /etc/postfix/main.cf
    cp /etc/postfix/master.cf.orig /etc/postfix/master.cf
    envsubst '\$PRIMARY_DOMAIN \$RELAY_IP' < templates/master.cf >> /etc/postfix/master.cf

    exec "$@"
fi

exec "$@"
