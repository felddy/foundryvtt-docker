ARG VERSION=unspecified

FROM python:3.10.1-alpine

ARG VERSION

###
# For a list of pre-defined annotation keys and value types see:
# https://github.com/opencontainers/image-spec/blob/master/annotations.md
#
# Note: Additional labels are added by the build workflow.
###
LABEL org.opencontainers.image.authors="mark.feldhousen@cisa.dhs.gov"
LABEL org.opencontainers.image.vendor="Cybersecurity and Infrastructure Security Agency"

###
# Unprivileged user setup variables
###
ARG CISA_GID=421
ARG CISA_UID=${CISA_GID}
ENV CISA_USER="cisa"
ENV CISA_GROUP=${CISA_USER}
ENV CISA_HOME="/home/cisa"

###
# Unprivileged user setup dependencies
#
# Install shadow, so we have adduser and addgroup.
#
# Note that we use apk --no-cache to avoid writing to a local cache.
# This results in a smaller final image, at the cost of slightly
# longer install times.
#
# Setup user dependencies are only needed for setting up the user and
# will be removed at the end of that process.
###
ENV SETUP_USER_DEPS \
    shadow
RUN apk --update --no-cache --quiet upgrade
RUN apk --no-cache --quiet add ${SETUP_USER_DEPS}

###
# Create unprivileged user
###
RUN addgroup --system --gid ${CISA_UID} ${CISA_GROUP} \
    && adduser --system --uid ${CISA_UID} --ingroup ${CISA_GROUP} ${CISA_USER}

###
# Remove build dependencies for unprivileged user
###
RUN apk --no-cache --quiet del ${SETUP_USER_DEPS}

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
    https://github.com/cisagov/skeleton-python-library/archive/v${VERSION}.tar.gz && \
    tar --extract --gzip --file sourcecode.tgz --strip-components=1 && \
    pip install --no-cache-dir --requirement requirements.txt && \
    ln -snf /run/secrets/quote.txt src/example/data/secret.txt && \
    rm sourcecode.tgz

###
# Prepare to run
###
ENV ECHO_MESSAGE="Hello World from Dockerfile"
USER cisa
EXPOSE 8080/TCP
VOLUME ["/var/log"]
ENTRYPOINT ["example"]
CMD ["--log-level", "DEBUG"]
