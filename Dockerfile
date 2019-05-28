FROM debian:buster-slim
MAINTAINER Mark Feldhousen <mark.feldhousen@trio.dhs.gov>

RUN apt-get update && \
apt-get install --no-install-recommends -y \
ca-certificates \
gettext-base \
opendkim \
opendkim-tools \
postfix \
sasl2-bin \
&& apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER root
WORKDIR /root

RUN mv /etc/postfix/master.cf /etc/postfix/master.cf.orig

COPY ./templates ./templates/
COPY ./src/docker-entrypoint.sh .

VOLUME ["/var/log", "/var/spool/postfix"]
EXPOSE 25/TCP 587/TCP

ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["postfix", "-v", "start-fg"]
