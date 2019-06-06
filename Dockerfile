FROM python:3.7-alpine
LABEL maintainer="mark.feldhousen@trio.dhs.gov"
LABEL version="0.0.1"

ARG CISA_UID=421
ENV CISA_HOME="/home/cisa"
ENV ECHO_MESSAGE="Hello World from Dockerfile"

RUN addgroup --system --gid ${CISA_UID} cisa \
  && adduser --system --uid ${CISA_UID} --ingroup cisa cisa

RUN apk --update --no-cache add \
ca-certificates \
git \
openssl \
py-pip

WORKDIR ${CISA_HOME}

RUN git clone https://github.com/cisagov/skeleton-python-library.git . && \
pip install --requirement requirements.txt && \
ln -snf /run/secrets/quote.txt src/example/data/secret.txt

USER cisa

EXPOSE 8080/TCP
VOLUME ["/var/log"]
ENTRYPOINT ["example"]
CMD ["--log-level", "DEBUG"]
