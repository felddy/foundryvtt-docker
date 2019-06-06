# skeleton-docker 💀🐳 #

[![Build Status](https://travis-ci.com/cisagov/skeleton-docker.svg?branch=develop)](https://travis-ci.com/cisagov/skeleton-docker)

## Docker Image ##

![MicroBadger Layers](https://img.shields.io/microbadger/layers/dhsncats/example.svg)
![MicroBadger Size](https://img.shields.io/microbadger/image-size/dhsncats/example.svg)

This is a docker skeleton project that can be used to quickly get a
new [cisagov](https://github.com/cisagov) GitHub docker project started.
This skeleton project contains [licensing information](LICENSE.md), as
well as [pre-commit hooks](https://pre-commit.com) and a [Travis
CI](https://travis-ci.com) configuration appropriate for docker
containers and the major languages that we use.

## Usage ##

### Install ###

Pull `dhsncats/example` from the Docker repository:

    docker pull dhsncats/example

Or build `dhsncats/example` from source:

    git clone https://github.com/cisagov/skeleton-docker.git
    cd skeleton-docker
    docker-compose build

### Run ###

## Ports ##

This container exposes the following ports:

| Port  | Protocol | Service  |
|-------|----------|----------|
| 8080  | TCP      | http     |

## Environment Variables ##

| Variable      | Default Value                 | Purpose      |
|---------------|-------------------------------|--------------|
| ECHO_MESSAGE  | `Hello World from Dockerfile` | Text to echo |

## Secrets ##

| Filename      | Purpose              |
|---------------|----------------------|
| quote.txt     | Secret text to echo  |

## Volumes ##

| Mount point | Purpose        |
|-------------|----------------|
| /var/log    | logging output |

## Contributing ##

We welcome contributions!  Please see [here](CONTRIBUTING.md) for
details.

## License ##

This project is in the worldwide [public domain](LICENSE.md).

This project is in the public domain within the United States, and
copyright and related rights in the work worldwide are waived through
the [CC0 1.0 Universal public domain
dedication](https://creativecommons.org/publicdomain/zero/1.0/).

All contributions to this project will be released under the CC0
dedication. By submitting a pull request, you are agreeing to comply
with this waiver of copyright interest.
