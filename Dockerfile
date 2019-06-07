ARG GIT_COMMIT=unspecified
ARG GIT_REMOTE=unspecified
ARG VERSION=unspecified

FROM python:3.7-alpine

ARG GIT_COMMIT
ARG GIT_REMOTE
ARG VERSION

LABEL git_commit=${GIT_COMMIT}
LABEL git_remote=${GIT_REMOTE}
LABEL maintainer="mark.feldhousen@trio.dhs.gov"
LABEL vendor="Cyber and Infrastructure Security Agency"
LABEL version=${VERSION}

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
