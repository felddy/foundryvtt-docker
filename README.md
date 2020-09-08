<div align="center">
<img width="460" src="https://raw.githubusercontent.com/felddy/foundryvtt-docker/develop/assets/logo.png">
</div>

# foundryvtt-docker #

[![GitHub Build Status](https://github.com/felddy/foundryvtt-docker/workflows/build/badge.svg)](https://github.com/felddy/foundryvtt-docker/actions)
[![FoundryVTT Version: v0.7.2](https://img.shields.io/badge/foundry-v0.7.2-brightgreen?logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAYAAAAfSC3RAAAAAXNSR0IArs4c6QAAAIRlWElmTU0AKgAAAAgABQESAAMAAAABAAEAAAEaAAUAAAABAAAASgEbAAUAAAABAAAAUgEoAAMAAAABAAIAAIdpAAQAAAABAAAAWgAAAAAAAABIAAAAAQAAAEgAAAABAAOgAQADAAAAAQABAACgAgAEAAAAAQAAAA6gAwAEAAAAAQAAAA4AAAAATspU+QAAAAlwSFlzAAALEwAACxMBAJqcGAAAAVlpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IlhNUCBDb3JlIDUuNC4wIj4KICAgPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4KICAgICAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIKICAgICAgICAgICAgeG1sbnM6dGlmZj0iaHR0cDovL25zLmFkb2JlLmNvbS90aWZmLzEuMC8iPgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KTMInWQAAAiFJREFUKBVVks1rE1EUxc+d5tO0prZVSZsUhSBIPyC02ooWurJ0I7rQlRvdC/4N4h9gt7pyoRTswpWgILgQBIOIiC340VhbpC0Ek85MGmPmXc+baWpNGJg77/7uOffeB+z9FHB0FrH9eLwwqpOF0f34KrpsTicW+6L8KE8QhO/n8n1IOgtQHYZA+a/Ai9+Wd6v1g7liq5A2OjKSQNa9hkO4hAzOIylf6CHALk6hoWXsylPkfjyyApaJhVCxmERy5zLSuI7D8h1H5BWht1aBhS6wdI3pN7GabyuyS4JPrchzujmNjDxAVrrRL2PoxRSGxOfjssgEjkkJvVJBWu6h5M7YenvDoOO0OgicD4TPIKWbBG6xvwTaKCMwSU7hKxK6gt8mbsFIMaF5iDyjUg6iPnqc58higCr9fD4iTvWMziAmK2g73f/AADVWX0YXrlChirgOcqL3WXYBYpTfUuxzjkW30dI1C0ZW1RnjMopo4C56MIs6CgQrMER2cJoz9zjdO2iz17g2yZUjqzHWbuA4/ugiEz7DVRe/aLxmcvDQ5Cq+oWGWeDbAgiETXgArrVOFGzR0EkclxrVMcpfLgFThY5roe2yz95ZZkzcbj22+w2VG8Pz6Q/b5Gr6uM9mw04uo6ll4tOlhE8a8xNzGYihCJoT+u3I4kUIp6OM0X9CHHds8frbqsrXlh9CB62nj8L5a9Y4DHR/K68TgcHhoz607Qp34L72X0rdSdM+vAAAAAElFTkSuQmCC)](https://foundryvtt.com/releases/0.7.2)
[![Known Vulnerabilities](https://snyk.io/test/github/felddy/foundryvtt-docker/badge.svg)](https://snyk.io/test/github/felddy/foundryvtt-docker)
[![Total alerts](https://img.shields.io/lgtm/alerts/g/felddy/foundryvtt-docker.svg?logo=lgtm&logoWidth=18)](https://lgtm.com/projects/g/felddy/foundryvtt-docker/alerts/)
[![Language grade: Python](https://img.shields.io/lgtm/grade/python/g/felddy/foundryvtt-docker.svg?logo=lgtm&logoWidth=18)](https://lgtm.com/projects/g/felddy/foundryvtt-docker/context:python)
[![Language grade: JavaScript](https://img.shields.io/lgtm/grade/javascript/g/felddy/foundryvtt-docker.svg?logo=lgtm&logoWidth=18)](https://lgtm.com/projects/g/felddy/foundryvtt-docker/context:javascript)

[![Docker Pulls](https://img.shields.io/docker/pulls/felddy/foundryvtt)](https://hub.docker.com/r/felddy/foundryvtt)
[![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/felddy/foundryvtt)](https://hub.docker.com/r/felddy/foundryvtt)
[![Platforms](https://img.shields.io/badge/platforms-386%20%7C%20amd64%20%7C%20arm%2Fv6%20%7C%20arm%2Fv7%20%7C%20arm64%20%7C%20ppc64le%20%7C%20s390x-blue)](https://hub.docker.com/r/felddy/foundryvtt/tags)

You can get a [Foundry Virtual Tabletop](https://foundryvtt.com) instance up and
running in minutes using this container.  This Docker container is designed to
be secure, reliable, compact, and simple to use.  It only requires that you
provide the credentials or URL needed to download a Foundry Virtual Tabletop
release.

## Prerequisites ##

* A functioning [Docker](https://docs.docker.com/get-docker/) installation.
* A [FoundryVTT.com](https://foundryvtt.com/auth/register/) account with a purchased
  software license.

## Running ##

### Using Docker with credentials ###

You can use the following command to start up a Foundry Virtual Tabletop server.
Your [foundryvtt.com](https://foundryvtt.com) credentials are required so the
container can install and license your server.

```console
docker run \
  --env FOUNDRY_USERNAME='<your_username>' \
  --env FOUNDRY_PASSWORD='<your_password>' \
  --publish 30000:30000/tcp \
  --volume <your_data_dir>:/data \
  felddy/foundryvtt:release
```

If you are using `bash`, or a similar shell, consider pre-pending the Docker
command with a space to prevent your credentials from being committed to the
shell history list.  See:
[`HISTCONTROL`](https://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html#index-HISTCONTROL)

### Using Docker with a temporary URL ###

Alternatively, you may acquire a temporary download token from your user profile
page on the Foundry website.  On the "Purchased Licenses" page, click the [🔗]
icon to the right of the standard `Node.js` download link to obtain a temporary
download URL for the software.

```console
docker run \
  --env FOUNDRY_RELEASE_URL='<temporary_url>' \
  --publish 30000:30000/tcp \
  --volume <your_data_dir>:/data \
  felddy/foundryvtt:release
```

## Using a Docker composition ###

Using [`docker-compose`](https://docs.docker.com/compose/install/) to manage your
server is highly recommended.  A `docker-compose.yml` file is a more reliable
way to start and maintain a container while capturing its configurations.  All
of Foundry's [configuration
options](https://foundryvtt.com/article/configuration/) can be specified using
[environment variables](#environment-variables).

1. Create a `docker-compose.yml` file similar to the one below.  Provide
   your credentials as values to the environment variables:

    ```yaml
    version: "3.8"

    services:
      foundry:
        image: felddy/foundryvtt:release
        hostname: my_foundry_host
        init: true
        restart: "unless-stopped"
        volumes:
          - type: bind
            source: <your_data_dir>
            target: /data
        environment:
          - FOUNDRY_PASSWORD=<your_password>
          - FOUNDRY_USERNAME=<your_username>
          - FOUNDRY_ADMIN_KEY=atropos
        ports:
          - target: "30000"
            published: "30000"
            protocol: tcp
            mode: host
    ```

1. Start the container and detach:

    ```console
    docker-compose up --detach
    ```

1. Access the web application at:
[http://localhost:30000](http://localhost:30000).

If all goes well you should be prompted with the license agreement, and then
"admin access key" set with the `FOUNDRY_ADMIN_KEY` variable.

## Using secrets ##

This container also supports passing sensitive values via [Docker
secrets](https://docs.docker.com/engine/swarm/secrets/).  Passing sensitive
values like your credentials can be more secure using secrets than using
environment variables.  Your secrets json file can have any name.  This example
uses `secrets.json`.  Regardless of the name you choose it must be targeted to
`config.json` within the container as in the example below.  See the
[secrets](#secrets) section below for a table of all supported secret keys.

1. To use secrets, create a `secrets.json` file containing the values you want set:

    ```json
    {
      "foundry_admin_key": "atropos",
      "foundry_password": "your_password",
      "foundry_username": "your_username"
    }
    ```

1. Then add the secret to your `docker-compose.yml` file:

    ```yaml
    version: "3.8"

    secrets:
      config_json:
        file: secrets.json

    services:
      foundry:
        image: felddy/foundryvtt:release
        hostname: my_foundry_host
        init: true
        restart: "unless-stopped"
        volumes:
          - type: bind
            source: <your_data_dir>
            target: /data
        environment:
        ports:
          - target: "30000"
            published: "30000"
            protocol: tcp
            mode: host
        secrets:
          - source: config_json
            target: config.json
    ```

## Updating ##

The Foundry "Update Software" tab is disabled by default in this container.  To
upgrade to a new version of Foundry pull an updated image version.

### Docker-compose ###

1. Pull the new image from Docker hub:

    ```console
    docker-compose pull
    ```

1. Recreate the running container:

    ```console
    docker-compose up --detach
    ```

### Docker ###

1. Stop the running container:

    ```console
    docker stop <container_id>
    ```

1. Pull the new image:

    ```console
    docker pull felddy/foundryvtt:release
    ```

1. Follow the previous instructions for [running](#running) the container above.

## Image tags ##

The images of this container are tagged to add additional flexibility during
deployment.  It is recommended that most users use the `:release` tag.  This tag
will only be applied to images that support versions from the Foundry "release"
channel.

| Image:tag | Description |
|-----------|-------------|
|`felddy/foundryvtt:release` | The most recent image from the release channel.  These images are **considered stable**, and well-tested.  Most users will use this tag. |
|`felddy/foundryvtt:beta` | Beta channel releases **should be stable** for all users, but may impose some module conflicts or compatibility issues. It is only recommended for users to update to this version if they are comfortable with accepting some minor risks. Users are discouraged from updating to this version if it is immediately before a game session. _Please take care to periodically back up your critical user data in case you experience any issues._ |
|`felddy/foundryvtt:alpha` | Alpha channel releases are **VERY LIKELY to introduce breaking bugs** that will be disruptive to play. Do not install this update unless you are using for the specific purposes of testing. The intention of Alpha builds are to allow for previewing new features and to help developers to begin updating modules which are impacted by the changes. If you choose to update to this version for a live game you do so entirely at your own risk of having a bad experience. _Please back up your critical user data before installing this update._ |
|`felddy/foundryvtt:0.7.2`| A specific version. |

See the [tags tab](https://hub.docker.com/r/felddy/foundryvtt/tags) on Docker
Hub for a list of all the supported tags.

## Volumes ##

| Mount point | Purpose        |
|-------------|----------------|
| /data    | configuration, data, and log storage |

## Environment variables ##

### Required combinations ###

There are three combinations of environment variables that are required to start
the container.  Either (`FOUNDRY_USERNAME` and `FOUNDRY_PASSWORD`), or
`FOUNDRY_RELEASE_URL`, or `CONTAINER_CACHE` must be provided.

#### Credentials variables ####

***Note:*** `FOUNDRY_USERNAME` and `FOUNDRY_PASSWORD` may be set [using
secrets](#using-secrets) instead of environment variables.

| Name             | Purpose  |
|------------------|----------|
| FOUNDRY_PASSWORD | Account password for foundryvtt.com.  Required for downloading an application release. |
| FOUNDRY_USERNAME | Account username or email address for foundryvtt.com.  Required for downloading an application release. |

#### Pre-signed URL variable ####

| Name             | Purpose  |
|------------------|----------|
| FOUNDRY_RELEASE_URL | S3 pre-signed URL generate from the user's profile.  Required for downloading an application release. |

#### Pre-cached release variable ####

A release can be downloaded and placed into a cache directory.  It's name should
be of the form: `foundryvtt-0.7.2.zip`

| Name             | Purpose  |
|------------------|----------|
| CONTAINER_CACHE | Set a path to cache downloads of the Foundry release archive and speed up subsequent container startups.  The path should be in `/data` or another persistent mount point in the container. e.g.; `/data/container_cache`| |

### Optional ###

| Name  | Purpose | Default |
|-------|---------|---------|
| CONTAINER_PATCHES | Set a path to a directory of shell scripts to be sourced after Foundry is installed but before it is started.  The path should be in `/data` or another persistent mount point in the container. e.g.; `/data/container_patches`| |
| CONTAINER_VERBOSE | Set to `true` to enable verbose logging for the container utility scripts. | |
| FOUNDRY_ADMIN_KEY | Admin password to be applied at startup.  If omitted the admin password will be cleared.  May be set [using secrets](#using-secrets). | |
| FOUNDRY_AWS_CONFIG | An absolute or relative path that points to the [awsConfig.json](https://foundryvtt.com/article/aws-s3/) or `true` for AWS environment variable [credentials evaluation](https://docs.aws.amazon.com/sdk-for-javascript/v2/developer-guide/setting-credentials-node.html) usage. | null |
| FOUNDRY_GID    | `gid` the deamon will be run under. | foundry |
| FOUNDRY_HOSTNAME | A custom hostname to use in place of the host machine's public IP address when displaying the address of the game session. This allows for reverse proxies or DNS servers to modify the public address. | null |
| FOUNDRY_LICENSE_KEY | The license key to install. e.g.; `AAAA-BBBB-CCCC-DDDD-EEEE-FFFF`  If left unset, a license key will be fetched when using account authentication.   If multiple license keys are associated with an account, one will be chosen at random.  Specific licenses can be selected by passing in an integer index.  The first license key being `1`.  May be set [using secrets](#using-secrets). | |
| FOUNDRY_NO_UPDATE | Prevent the application from being updated from the web interface.  The application code is immutable when running in a container.  See the [Updating](#updating) section for the steps needed to update this container. | true |
| FOUNDRY_PROXY_PORT | Inform the Foundry Server that the software is running behind a reverse proxy on some other port. This allows the invitation links created to the game to include the correct external port. | null |
| FOUNDRY_PROXY_SSL | Indicates whether the software is running behind a reverse proxy that uses SSL. This allows invitation links and A/V functionality to work as if the Foundry Server had SSL configured directly. | false |
| FOUNDRY_ROUTE_PREFIX | A string path which is appended to the base hostname to serve Foundry VTT content from a specific namespace. For example setting this to `demo` will result in data being served from `http://x.x.x.x:30000/demo/`. | null |
| FOUNDRY_SSL_CERT | An absolute or relative path that points towards a SSL certificate file which is used jointly with the sslKey option to enable SSL and https connections. If both options are provided, the server will start using HTTPS automatically. | null |
| FOUNDRY_SSL_KEY | An absolute or relative path that points towards a SSL key file which is used jointly with the sslCert option to enable SSL and https connections. If both options are provided, the server will start using HTTPS automatically. | null |
| FOUNDRY_UID    | `uid` the daemon will be run under. | foundry |
| FOUNDRY_UPDATE_CHANNEL | The update channel to subscribe to.  "alpha", "beta", or "release". | "release" |
| FOUNDRY_UPNP | Allow Universal Plug and Play to automatically request port forwarding for the Foundry VTT port to your local network address. | false |
| FOUNDRY_VERSION | Version of Foundry Virtual Tabletop to install. | 0.7.2 |
| FOUNDRY_WORLD | The world to startup at system start. | null |
| TIMEZONE     | Container [TZ database name](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List) | UTC |

## Secrets ##

| Filename     | Key | Purpose |
|--------------|-----|---------|
| `config.json` | `foundry_admin_key` | Overrides `FOUNDRY_ADMIN_KEY` environment variable. |
| `config.json` | `foundry_license_key` | Overrides `FOUNDRY_LICENSE_KEY` environment variable. |
| `config.json` | `foundry_password` | Overrides `FOUNDRY_PASSWORD` environment variable. |
| `config.json` | `foundry_username` | Overrides `FOUNDRY_USERNAME` environment variable. |

## Building from source ##

Build the image locally using this git repository as the [build context](https://docs.docker.com/engine/reference/commandline/build/#git-repositories):

```console
docker build \
  --build-arg VERSION=0.7.2 \
  --tag felddy/foundryvtt:0.7.2 \
  https://github.com/felddy/foundryvtt-docker.git#develop
```

## Cross-platform builds ##

To create images that are compatible with other platforms you can use the
[`buildx`](https://docs.docker.com/buildx/working-with-buildx/) feature of
Docker:

1. Copy the project to your machine using the `Clone` button above
   or the command line:

    ```console
    git clone https://github.com/felddy/foundryvtt-docker.git
    cd foundryvtt-docker
    ```

1. Create the `Dockerfile-x` file with `buildx` platform support:

    ```console
    ./buildx-dockerfile.sh
    ```

1. Build the image using `buildx`:

    ```console
    docker buildx build \
      --file Dockerfile-x \
      --platform linux/amd64 \
      --build-arg VERSION=0.7.2 \
      --output type=docker \
      --tag felddy/foundryvtt:0.7.2 .
    ```

## Pre-installed release builds ##

It is possible to install a Foundry Virtual Tabletop release into the Docker
image at build-time.  This results in a significantly larger Docker image, but
removes the need to install a release at container startup, resulting in a
faster startup.  It also moves the user authentication to build-time instead of
start-time.  **Note**: Credentials are only used to fetch a release, and are not
stored in the resulting image.

Build the image with credentials:

```console
docker build \
  --build-arg FOUNDRY_USERNAME='<your_username>' \
  --build-arg FOUNDRY_PASSWORD='<your_password>' \
  --build-arg VERSION=0.7.2 \
  --tag felddy/foundryvtt:0.7.2 \
  https://github.com/felddy/foundryvtt-docker.git#develop
```

Or build the image using a temporary URL:

```console
docker build \
  --build-arg FOUNDRY_RELEASE_URL='<temporary_url>' \
  --build-arg VERSION=0.7.2 \
  --tag felddy/foundryvtt:0.7.2 \
  https://github.com/felddy/foundryvtt-docker.git#develop
```

## Hosting behind Nginx with TLS ##

Below is an example configuration that will serve the Foundry Virtual Tabletop
application at a specific path.  In this example, the application container will
be accessible at `https://example.com/vtt`:

```nginx
server {
    listen 443 ssl http2 default_server;
    listen [::]:443 ssl http2 default_server;
    server_name example.com www.example.com;

    if ($host = www.example.com) {
        return 301 https://example.com$request_uri;
    }

    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/example.com/chain.pem;

    add_header Access-Control-Allow-Origin https://example.com always;

    location /vtt {
        # Foundry Virtual Tabletop routePrefix = "vtt"

        proxy_http_version 1.1;
        access_log /var/log/nginx/upstream_log upstream_logging;

        proxy_read_timeout 90;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Real-IP $remote_addr;

        proxy_pass http://localhost:30000;
    }
}

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name example.com www.example.com;
    return 301 https://example.com$request_uri;
}
```

## Debugging ##

Here are a couple of options that can help if the container isn't working as it
should.

Making the logging more verbose will provide more information about what is
going on during container startup.  When reporting an issue, verbose output is
always more helpful.  Simply set the `CONTAINER_VERBOSE` environment variable to
`true` to generate more detailed logging.

To drop into a shell after release installation but before it is started, you
can pass the `--shell` option to the entrypoint:

| Purpose | Command |
|---------|---------|
| Drop into a shell in the container before switching uid:gid | `docker-compose run foundry --root-shell` |
| Drop into a shell in the container after switching uid:gid | `docker-compose run foundry --shell` |

## Contributing ##

We welcome contributions!  Please see [here](CONTRIBUTING.md) for
details.

## License ##

This project is released as open source under the [MIT license](LICENSE).

All contributions to this project will be released under the same MIT license.
By submitting a pull request, you are agreeing to comply with this waiver of
copyright interest.
