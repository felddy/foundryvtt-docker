# foundryvtt-docker ⚔️🛡🐳 #

[![GitHub Build Status](https://github.com/cisagov/foundryvtt-docker/workflows/build/badge.svg)](https://github.com/cisagov/foundryvtt-docker/actions)
[![Total alerts](https://img.shields.io/lgtm/alerts/g/cisagov/foundryvtt-docker.svg?logo=lgtm&logoWidth=18)](https://lgtm.com/projects/g/cisagov/foundryvtt-docker/alerts/)
[![Language grade: Python](https://img.shields.io/lgtm/grade/python/g/cisagov/foundryvtt-docker.svg?logo=lgtm&logoWidth=18)](https://lgtm.com/projects/g/cisagov/foundryvtt-docker/context:python)

## Docker Image ##

[![MicroBadger Version](https://images.microbadger.com/badges/version/felddy/foundryvtt.svg)](https://hub.docker.com/repository/docker/felddy/foundryvtt)
![MicroBadger Layers](https://img.shields.io/microbadger/layers/felddy/foundryvtt-docker.svg)

This docker container can be used to quickly get a
[FoundryVTT](https://foundryvtt.com) instance up and running.

## Usage ##

<!-- ### Install ###

Pull `felddy/foundryvtt` from the Docker repository:

```console
docker pull felddy/foundryvtt
``` -->

### Run ###

The easiest way to start the container is to create a `docker-compose.yml`
similar to the following.  The uid/gid can be set using the environment
variables below.

Modify any paths as needed:

```yaml
---
version: "3.7"

volumes:
  data:

# This docker-compose file is used to build and test the container
services:
  foundry:
    # Run the container normally
    build:
      # VERSION must be specified on the command line:
      # e.g., --build-arg VERSION=0.0.1
      context: .
      dockerfile: Dockerfile
    image: felddy/foundryvtt
    init: true
    restart: "always"
    volumes:
      - type: bind
        source: ./data
        target: /data
    environment:
      - TIMEZONE=US/Eastern
      - FOUNDRY_ADMIN_KEY=null
      - FOUNDRY_GID=foundry
      - FOUNDRY_HOSTNAME=null
      - FOUNDRY_PROXY_PORT=null
      - FOUNDRY_PROXY_SSL=false
      - FOUNDRY_ROUTE_PREFIX=null
      - FOUNDRY_SSL_CERT=null
      - FOUNDRY_SSL_KEY=null
      - FOUNDRY_UID=foundry
      - FOUNDRY_UPDATE_CHANNEL="beta"
      - FOUNDRY_UPNP=false
      - FOUNDRY_WORLD=null
    ports:
      - target: "30000"
        published: "30000"
        protocol: tcp
        mode: host
```

Create a directory on the host to store the configuration files:

```console
mkdir data
```

If this is the first time running foundryvtt, use the following command to
start the container and generate a configuration file:

```console
docker-compose run foundryvtt
```

The configuration file will be created in the `data` directory.
You should edit this file to match the setup of your weather station.
When you are satisfied with configuration the container can be started
in the background with:

```console
docker-compose up -d
```

## Volumes ##

| Mount point | Purpose        |
|-------------|----------------|
| /data    | configuration file storage |

## Environment Variables ##

| Mount point  | Purpose | Default |
|--------------|---------|---------|
| TIMEZONE     | Container [TZ database name](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List) | UTC |
| FOUNDRY_UID    | `uid` the daemon will be run under. | foundry |
| FOUNDRY_GID    | `gid` the deamon will be run under. | foundry |
| FOUNDRY_ADMIN_KEY | Encrypted admin password. | null |
| FOUNDRY_HOSTNAME | A custom hostname to use in place of the host machine's public IP address when displaying the address of the game session. This allows for reverse proxies or DNS servers to modify the public address. | null |
| FOUNDRY_PROXY_PORT | Inform the Foundry Server that the software is running behind a reverse proxy on some other port. This allows the invitation links created to the game to include the correct external port. | null |
| FOUNDRY_PROXY_SSL | Indicates whether the software is running behind a reverse proxy that uses SSL. This allows invitation links and A/V functionality to work as if the Foundry Server had SSL configured directly. | false |
| FOUNDRY_ROUTE_PREFIX | A string path which is appended to the base hostname to serve Foundry VTT content from a specific namespace. For example setting this to demo will result in data being served from `http://x.x.x.x:30000/demo/`. | null |
| FOUNDRY_SSL_CERT | An absolute or relative path that points towards a SSL certificate file which is used jointly with the sslKey option to enable SSL and https connections. If both options are provided, the server will start using HTTPS automatically. | null |
| FOUNDRY_SSL_KEY | An absolute or relative path that points towards a SSL key file which is used jointly with the sslCert option to enable SSL and https connections. If both options are provided, the server will start using HTTPS automatically. | null |
| FOUNDRY_UPDATE_CHANNEL | The update channel to subscribe to.  "alpha", "beta", or "release". | "beta" |
| FOUNDRY_UPNP | Allow Universal Plug and Play to automatically request port forwarding for the Foundry VTT port to your local network address. | false |
| FOUNDRY_WORLD | The world startup at system start. | null |

## Building ##

This Docker container has multi-platform support and requires
the use of the
[`buildx` experimental feature](https://docs.docker.com/buildx/working-with-buildx/).
Make sure to enable experimental features in your environment.

To build the container from source:

Place the `foundryvtt-0.5.5.zip` file in the root of the repository.

```console
git clone https://github.com/felddy/foundryvtt-docker.git
cd foundryvtt-docker
docker buildx build \
  --platform linux/amd64 \
  --build-arg VERSION=0.5.5 \
  --output type=docker \
  --tag felddy/foundryvtt .
```

## Debugging ##

There are a few helper arguments that can be used to diagnose container issues
in your environment.

| Purpose | Command |
|---------|---------|
| Drop into a shell in the container | `docker-compose run foundryvtt --shell` |

## Contributing ##

We welcome contributions!  Please see [here](CONTRIBUTING.md) for
details.

## License ##

This project is in the worldwide [public domain](LICENSE).

This project is in the public domain within the United States, and
copyright and related rights in the work worldwide are waived through
the [CC0 1.0 Universal public domain
dedication](https://creativecommons.org/publicdomain/zero/1.0/).

All contributions to this project will be released under the CC0
dedication. By submitting a pull request, you are agreeing to comply
with this waiver of copyright interest.
