ARG VERSION=unspecified

FROM python:3.10.1-alpine

ARG VERSION

# For a list of pre-defined annotation keys and value types see:
# https://github.com/opencontainers/image-spec/blob/master/annotations.md
# Note: Additional labels are added by the build workflow.
LABEL org.opencontainers.image.authors="mark.feldhousen@cisa.dhs.gov"
LABEL org.opencontainers.image.vendor="Cybersecurity and Infrastructure Security Agency"

ARG CISA_UID=421
ENV CISA_HOME="/home/cisa"
ENV ECHO_MESSAGE="Hello World from Dockerfile"

RUN addgroup --system --gid ${CISA_UID} cisa \
  && adduser --system --uid ${CISA_UID} --ingroup cisa cisa

RUN apk --update --no-cache add \
ca-certificates \
openssl \
py-pip

WORKDIR ${CISA_HOME}

RUN wget -O sourcecode.tgz https://github.com/cisagov/skeleton-python-library/archive/v${VERSION}.tar.gz && \
  tar xzf sourcecode.tgz --strip-components=1 && \
  pip install --requirement requirements.txt && \
  ln -snf /run/secrets/quote.txt src/example/data/secret.txt && \
  rm sourcecode.tgz

USER cisa

EXPOSE 8080/TCP
VOLUME ["/var/log"]
ENTRYPOINT ["example"]
CMD ["--log-level", "DEBUG"]
