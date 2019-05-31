#!/bin/bash
# shellcheck disable=SC2016

set -e
#set -x


function generate_configs() {
  # configure postfix
  echo "Generating postfix configurations for ${PRIMARY_DOMAIN}"
  envsubst '\$PRIMARY_DOMAIN \$RELAY_IP' < templates/main.cf > /etc/postfix/main.cf
  cp /etc/postfix/master.cf.orig /etc/postfix/master.cf
  envsubst '\$PRIMARY_DOMAIN \$RELAY_IP' < templates/master.cf >> /etc/postfix/master.cf
  envsubst '\$PRIMARY_DOMAIN \$RELAY_IP' < templates/opendkim.conf > /etc/opendkim.conf

  # configure opendkim
  echo "Generating opendkim configurations for ${PRIMARY_DOMAIN}"
  mkdir -p "/etc/opendkim/keys/${PRIMARY_DOMAIN}"
  opendkim-genkey --verbose --bits=1024 --selector=mail --directory="/etc/opendkim/keys/${PRIMARY_DOMAIN}"
  envsubst '\$PRIMARY_DOMAIN \$RELAY_IP' < templates/TrustedHosts > /etc/opendkim/TrustedHosts
  cp /etc/default/opendkim.orig /etc/default/opendkim
  echo 'SOCKET="inet:12301"' >> /etc/default/opendkim
  chown -R opendkim:opendkim /etc/opendkim

  # configure opendmarc
  echo "Generating opendmarc configurations for ${PRIMARY_DOMAIN}"
  envsubst '\$PRIMARY_DOMAIN \$RELAY_IP' < templates/opendmarc.conf > /etc/opendmarc.conf
  mkdir "/etc/opendmarc/"
  echo "localhost" > /etc/opendmarc/ignore.hosts
  chown -R opendmarc:opendmarc /etc/opendmarc
  cp /etc/default/opendmarc.orig /etc/default/opendmarc
  echo 'SOCKET="inet:54321"' >> /etc/default/opendmarc

  # configure dovecot
  echo "Generating dovecot configurations for ${PRIMARY_DOMAIN}"
  envsubst '\$PRIMARY_DOMAIN \$RELAY_IP' < templates/dovecot.conf > /etc/dovecot/dovecot.conf

  # create a file marking the configuration as completed for this domain
  echo "All configurations generated for ${PRIMARY_DOMAIN}"
}


function generate_users() {
  echo "Generating users and passwords:"
  echo "--------------------------------------------"
  while IFS=" " read -r username password || [ -n "$username" ]
  do
    if [ -z "$password" ]; then password=$(diceware -d-);
      echo -e "$username\t$password"
    else
      echo -e "$username\t<set by secrets file>"
    fi
    adduser "$username" --quiet --disabled-password --shell /usr/sbin/nologin --gecos "" &>/dev/null || true
    echo "$username:$password" | chpasswd || true
  done
  echo "--------------------------------------------"
}


if [ "$1" = 'postfix' ]; then
  echo "Starting mail server with:"
  echo "  PRIMARY_DOMAIN=${PRIMARY_DOMAIN}"
  echo "  RELAY_IP=${RELAY_IP}"

  # check to see if the configuration was completed for this domain
  if [[ ! -f conf_gen_done.txt ]] || [[ $(< conf_gen_done.txt) != "${PRIMARY_DOMAIN}" ]]; then
    generate_configs
    echo "${PRIMARY_DOMAIN}" > conf_gen_done.txt
  else
    echo "Configurations already generated for ${PRIMARY_DOMAIN}, preserving."
  fi

  # generate the users from the secrets
  grep -v '^#\|^$' /run/secrets/users.txt | generate_users

  # postfix needs fresh copies of files in its chroot jail
  cp /etc/{hosts,localtime,nsswitch.conf,resolv.conf,services} /var/spool/postfix/etc/

  echo "DKIM DNS entry:"
  echo "--------------------------------------------"
  cat "/etc/opendkim/keys/${PRIMARY_DOMAIN}/mail.txt"
  echo "--------------------------------------------"

  opendmarc
  opendkim
  dovecot
  exec "$@"
fi

exec "$@"
