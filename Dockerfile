ARG VERSION=unspecified

FROM python:3.10.1-alpine

ARG VERSION

###
# For a list of pre-defined annotation keys and value types see:
# https://github.com/opencontainers/image-spec/blob/master/annotations.md
#
# Note: Additional labels are added by the build workflow.
###
# github@cisa.dhs.gov is a very generic email distribution, and it is
# unlikely that anyone on that distribution is familiar with the
# particulars of your repository.  It is therefore *strongly*
# suggested that you use an email address here that is specific to the
# person or group that maintains this repository; for example:
# LABEL org.opencontainers.image.authors="vm-fusion-dev-group@trio.dhs.gov"
LABEL org.opencontainers.image.authors="github@cisa.dhs.gov"
LABEL org.opencontainers.image.vendor="Cybersecurity and Infrastructure Security Agency"

###
# Unprivileged user setup variables
###
ARG CISA_UID=421
ARG CISA_GID=${CISA_UID}
ARG CISA_USER="cisa"
ENV CISA_GROUP=${CISA_USER}
ENV CISA_HOME="/home/${CISA_USER}"

###
# Upgrade the system
#
# Note that we use apk --no-cache to avoid writing to a local cache.
# This results in a smaller final image, at the cost of slightly
# longer install times.
###
RUN apk --update --no-cache --quiet upgrade

###
# Create unprivileged user
###
RUN addgroup --system --gid ${CISA_GID} ${CISA_GROUP} \
    && adduser --system --uid ${CISA_UID} --ingroup ${CISA_GROUP} ${CISA_USER}

###
# Dependencies
#
# Note that we use apk --no-cache to avoid writing to a local cache.
# This results in a smaller final image, at the cost of slightly
# longer install times.
###
ENV DEPS \
    ca-certificates \
    openssl \
    py-pip
RUN apk --no-cache --quiet add ${DEPS}

###
# Make sure pip and setuptools are the latest versions
#
# Note that we use pip --no-cache-dir to avoid writing to a local
# cache.  This results in a smaller final image, at the cost of
# slightly longer install times.
###
RUN pip install --no-cache-dir --upgrade pip setuptools

WORKDIR ${CISA_HOME}

###
# Install Python dependencies
#
# Note that we use pip --no-cache-dir to avoid writing to a local
# cache.  This results in a smaller final image, at the cost of
# slightly longer install times.
###
RUN wget --output-document sourcecode.tgz \
    https://github.com/cisagov/skeleton-python-library/archive/v${VERSION}.tar.gz \
    && tar --extract --gzip --file sourcecode.tgz --strip-components=1 \
    && pip install --no-cache-dir --requirement requirements.txt \
    && ln -snf /run/secrets/quote.txt src/example/data/secret.txt \
    && rm sourcecode.tgz

###
# Prepare to run
###
ENV ECHO_MESSAGE="Hello World from Dockerfile"
USER ${CISA_USER}
EXPOSE 8080/TCP
VOLUME ["/var/log"]
ENTRYPOINT ["example"]
CMD ["--log-level", "DEBUG"]
