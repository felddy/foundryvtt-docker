FROM debian:buster-slim
MAINTAINER Mark Feldhousen <mark.feldhousen@trio.dhs.gov>

RUN apt-get update && \
DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
ca-certificates \
dovecot-imapd \
dovecot-lmtpd \
gettext-base \
mailutils \
opendkim \
opendkim-tools \
opendmarc \
postfix \
procmail \
sasl2-bin \
&& apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN adduser mailarchive --quiet --disabled-password \
--shell /usr/sbin/nologin --gecos "Mail Archive"

USER root
WORKDIR /root

# make backups of configurations.  These are modified at startup.
RUN mv /etc/postfix/master.cf /etc/postfix/master.cf.orig
RUN mv /etc/default/opendkim /etc/default/opendkim.orig
RUN mv /etc/default/opendmarc /etc/default/opendmarc.orig

COPY ./src/templates ./templates/
COPY ./src/docker-entrypoint.sh .

VOLUME ["/var/log", "/var/spool/postfix"]
EXPOSE 25/TCP 587/TCP 993/TCP

ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["postfix", "-v", "start-fg"]
