<div align="center">
<img width="460" src="https://raw.githubusercontent.com/felddy/foundryvtt-docker/develop/assets/logo.png">
</div>

# foundryvtt-docker #

[![GitHub Build Status](https://github.com/felddy/foundryvtt-docker/workflows/build/badge.svg)](https://github.com/felddy/foundryvtt-docker/actions/workflows/build.yml)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/5966/badge)](https://bestpractices.coreinfrastructure.org/projects/5966)
[![CodeQL](https://github.com/felddy/foundryvtt-docker/workflows/CodeQL/badge.svg)](https://github.com/felddy/foundryvtt-docker/actions/workflows/codeql-analysis.yml)
[![FoundryVTT Release Version: v10.276](https://img.shields.io/badge/prerelease-v10.276-red?logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAYAAAAfSC3RAAAAAXNSR0IArs4c6QAAAIRlWElmTU0AKgAAAAgABQESAAMAAAABAAEAAAEaAAUAAAABAAAASgEbAAUAAAABAAAAUgEoAAMAAAABAAIAAIdpAAQAAAABAAAAWgAAAAAAAABIAAAAAQAAAEgAAAABAAOgAQADAAAAAQABAACgAgAEAAAAAQAAAA6gAwAEAAAAAQAAAA4AAAAATspU+QAAAAlwSFlzAAALEwAACxMBAJqcGAAAAVlpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IlhNUCBDb3JlIDUuNC4wIj4KICAgPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4KICAgICAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIKICAgICAgICAgICAgeG1sbnM6dGlmZj0iaHR0cDovL25zLmFkb2JlLmNvbS90aWZmLzEuMC8iPgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KTMInWQAAAiFJREFUKBVVks1rE1EUxc+d5tO0prZVSZsUhSBIPyC02ooWurJ0I7rQlRvdC/4N4h9gt7pyoRTswpWgILgQBIOIiC340VhbpC0Ek85MGmPmXc+baWpNGJg77/7uOffeB+z9FHB0FrH9eLwwqpOF0f34KrpsTicW+6L8KE8QhO/n8n1IOgtQHYZA+a/Ai9+Wd6v1g7liq5A2OjKSQNa9hkO4hAzOIylf6CHALk6hoWXsylPkfjyyApaJhVCxmERy5zLSuI7D8h1H5BWht1aBhS6wdI3pN7GabyuyS4JPrchzujmNjDxAVrrRL2PoxRSGxOfjssgEjkkJvVJBWu6h5M7YenvDoOO0OgicD4TPIKWbBG6xvwTaKCMwSU7hKxK6gt8mbsFIMaF5iDyjUg6iPnqc58higCr9fD4iTvWMziAmK2g73f/AADVWX0YXrlChirgOcqL3WXYBYpTfUuxzjkW30dI1C0ZW1RnjMopo4C56MIs6CgQrMER2cJoz9zjdO2iz17g2yZUjqzHWbuA4/ugiEz7DVRe/aLxmcvDQ5Cq+oWGWeDbAgiETXgArrVOFGzR0EkclxrVMcpfLgFThY5roe2yz95ZZkzcbj22+w2VG8Pz6Q/b5Gr6uM9mw04uo6ll4tOlhE8a8xNzGYihCJoT+u3I4kUIp6OM0X9CHHds8frbqsrXlh9CB62nj8L5a9Y4DHR/K68TgcHhoz607Qp34L72X0rdSdM+vAAAAAElFTkSuQmCC)](https://foundryvtt.com/releases/10.276)

[![Docker Pulls](https://img.shields.io/docker/pulls/felddy/foundryvtt)](https://hub.docker.com/r/felddy/foundryvtt)
[![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/felddy/foundryvtt)](https://hub.docker.com/r/felddy/foundryvtt)
[![Platforms](https://img.shields.io/badge/platforms-amd64%20%7C%20arm%2Fv6%20%7C%20arm%2Fv7%20%7C%20arm64%20%7C%20ppc64le%20%7C%20s390x-blue)](https://hub.docker.com/r/felddy/foundryvtt/tags)

You can get a [Foundry Virtual Tabletop](https://foundryvtt.com) instance up and
running in minutes using this container.  This Docker container is designed to
be secure, reliable, compact, and simple to use.  It only requires that you
provide the credentials or URL needed to download a Foundry Virtual Tabletop
distribution.

## Prerequisites ##

- A functioning [Docker](https://docs.docker.com/get-docker/) installation.
- A [FoundryVTT.com](https://foundryvtt.com/auth/register/) account with a purchased
  software license.

## Running ##

### Running with Docker and credentials ###

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

### Running with Docker and a temporary URL ###

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

### Configuration management ###

[Configuration options](https://foundryvtt.com/article/configuration/) are
specified using [environment variables](#environment-variables).  It is highly
recommended that you use [`docker compose`](https://docs.docker.com/compose/) or
similar container orchestration to manage your server's configuration.  A
`docker-compose.yml` file, like the example below, is a reliable way to start
and maintain a container while capturing its configurations.

Each time the container starts it generates the configuration files needed by
Foundry Virtual Tabletop using the values of the environment variables.  That
means **changes made in the server's configuration GUI will not persist between
container restarts**.  If you would like to disable the regeneration of these
configuration files, set `CONTAINER_PRESERVE_CONFIG` to `true`.

1. Create a `docker-compose.yml` file similar to the one below.  Provide
   your credentials as values to the environment variables:

    ```yaml
    ---
    version: "3.8"

    services:
      foundry:
        image: felddy/foundryvtt:release
        hostname: my_foundry_host
        init: true
        volumes:
          - type: bind
            source: <your_data_dir>
            target: /data
        environment:
          - FOUNDRY_PASSWORD=<your_password>
          - FOUNDRY_USERNAME=<your_username>
          - FOUNDRY_ADMIN_KEY=atropos
        ports:
          - target: 30000
            published: 30000
            protocol: tcp
    ```

1. Start the container and detach:

    ```console
    docker compose up --detach
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
    ---
    version: "3.8"

    secrets:
      config_json:
        file: secrets.json

    services:
      foundry:
        image: felddy/foundryvtt:release
        hostname: my_foundry_host
        init: true
        volumes:
          - type: bind
            source: <your_data_dir>
            target: /data
        environment:
        ports:
          - target: 30000
            published: 30000
            protocol: tcp
        secrets:
          - source: config_json
            target: config.json
    ```

## Updating your container ##

The Foundry "Update Software" tab is disabled by default in this container.  To
upgrade to a new version of Foundry pull an updated image version.

### Updating with Docker Compose ###

1. Pull the new image from Docker Hub:

    ```console
    docker compose pull
    ```

1. Recreate the running container:

    ```console
    docker compose up --detach
    ```

### Updating with Docker ###

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

The images of this container are tagged with [semantic
versions](https://semver.org) that align with the [version and build of Foundry
Virtual Tabletop](https://foundryvtt.com/article/versioning/) that they support.
It is recommended that most users use the `:release` tag.

| Image:tag | Description |
|-----------|-------------|
|`felddy/foundryvtt:release` | The most recent image from the `stable` channel.  These images are **considered stable**, and well-tested.  Most users will use this tag.  The `latest` tag always points to the same version as `release`.|
|`felddy/foundryvtt:prerelease` | The most recent image from the `testing`, `development`, or `prototype` channels.  Pre-releases are **VERY LIKELY to introduce breaking bugs** that will be disruptive to play. Do not install this version unless you are using for the specific purposes of testing. The intention of pre-release builds are to allow for previewing new features and to help developers to begin updating modules which are impacted by the changes. If you choose to update to this version for a live game you do so entirely at your own risk of having a bad experience. *Please back up your critical user data before installing this version.* |
|`felddy/foundryvtt:10.276.0`| An exact image version. |
|`felddy/foundryvtt:10.276`| The most recent image matching the major and minor version numbers. |
|`felddy/foundryvtt:10`| The most recent image matching the major version number. |
|`felddy/foundryvtt:latest`| See the `release` tag.  [Why does `latest` == `release`?](https://vsupalov.com/docker-latest-tag/) |

See the [tags tab](https://hub.docker.com/r/felddy/foundryvtt/tags) on Docker
Hub for a list of all the supported tags.

## Volumes ##

| Mount point | Purpose        |
|-------------|----------------|
| `/data`    | Configuration, data, and log storage. |

## Ports ##

The following ports are exposed by this container:

| Port | Purpose        |
|------|----------------|
| `30000` | Foundry Virtual Tabletop server web interface |

## Environment variables ##

### Required variable combinations ###

One of the three combinations of environment variables listed below must be set
in order for the container to locate and install a Foundry Virtual Tabletop
distribution.  Although all variables may be specified together, they are
evaluated in the following order of precedence:

 1. `FOUNDRY_RELEASE_URL`, *or*
 1. `FOUNDRY_USERNAME` and `FOUNDRY_PASSWORD`, *or*
 1. `CONTAINER_CACHE`

#### Credentials variables ####

| Name             | Purpose  |
|------------------|----------|
| `FOUNDRY_PASSWORD` | Account password for foundryvtt.com.  Required for downloading an application distribution. |
| `FOUNDRY_USERNAME` | Account username or email address for foundryvtt.com.  Required for downloading an application distribution. |

***Note:*** `FOUNDRY_USERNAME` and `FOUNDRY_PASSWORD` may be set [using
secrets](#using-secrets) instead of environment variables.

#### Pre-signed URL variable ####

| Name             | Purpose  |
|------------------|----------|
| `FOUNDRY_RELEASE_URL` | S3 pre-signed URL generate from the user's profile.  Required for downloading an application distribution. |

### Optional variables ###

| Name  | Purpose | Default |
|-------|---------|---------|
| `CONTAINER_CACHE` | Set a path to cache downloads of the Foundry distribution archive and speed up subsequent container startups.  The path should be in `/data` or another persistent mount point in the container.  Set to `""` to disable.  ***Note***: When the cache is disabled the container may sleep instead of exiting, in certain circumstances, to prevent a download loop.  A distribution can be pre-downloaded and placed into a cache directory.  The distribution's name must be of the form: `foundryvtt-10.276.zip`| `/data/container_cache` |
| `CONTAINER_PATCHES` | Set a path to a directory of shell scripts to be sourced after Foundry is installed but before it is started.  The path should be in `/data` or another persistent mount point in the container. e.g.; `/data/container_patches`  Patch files are sourced in lexicographic order.  `CONTAINER_PATCHES` are processed after `CONTAINER_PATCH_URLS`.| |
| `CONTAINER_PATCH_URLS` | Set to a space-delimited list of URLs to be sourced after Foundry is installed but before it is started.  Patch URLs are sourced in the order specified.  `CONTAINER_PATCH_URLS` are processed before `CONTAINER_PATCHES`.  ⚠️ **Only use patch URLs from trusted sources!** | |
| `CONTAINER_PRESERVE_CONFIG` | Normally new `options.json` and `admin.txt` files are generated by the container at each startup.  Setting this to `true` prevents the container from modifying these files when they exist.  If they do not exist, they will be created as normal. | `false` |
| `CONTAINER_PRESERVE_OWNER` | Normally the ownership of the `/data` directory and its contents are changed to match that of the server at startup.  Setting this to a regular expression will exclude any matching paths and preserve their ownership.   *Note: This is a match on the whole path, not a search.*  This is useful if you want mount a volume as read-only inside `/data` (e.g.; a volume that contains assets mounted at `/data/Data/assets`).  | |
| `CONTAINER_VERBOSE` | Set to `true` to enable verbose logging for the container utility scripts. | `false` |
| `FOUNDRY_ADMIN_KEY` | Admin password to be applied at startup.  If omitted the admin password will be cleared.  May be set [using secrets](#using-secrets). | |
| `FOUNDRY_AWS_CONFIG` | An absolute or relative path that points to the [awsConfig.json](https://foundryvtt.com/article/aws-s3/) or `true` for AWS environment variable [credentials evaluation](https://docs.aws.amazon.com/sdk-for-javascript/v2/developer-guide/setting-credentials-node.html) usage. | `null` |
| `FOUNDRY_DEMO_CONFIG` | Demo mode allows you to configure a world which will be automatically launched and reset at a frequency of your choosing.  When the world is reset, it is deactivated.  The source data for the world is restored to its original state using a provided `.zip` file, and the next reset is automatically scheduled.  See: [Configuring demo mode](https://foundryvtt.com/article/configuration/#command-line). |  |
| `FOUNDRY_GID` | `gid` the daemon will be run under. | `foundry` |
| `FOUNDRY_HOSTNAME` | A custom hostname to use in place of the host machine's public IP address when displaying the address of the game session. This allows for reverse proxies or DNS servers to modify the public address. | `null` |
| `FOUNDRY_IP_DISCOVERY` | Allow the Foundry server to discover and report the accessibility of the host machine's public IP address and port.  Setting this to `false` may reduce server startup time in instances where this discovery would timeout. | `true` |
| `FOUNDRY_LANGUAGE` | The default application language and module which provides the core translation files. | `en.core` |
| `FOUNDRY_LOCAL_HOSTNAME` | Override the local network address used for invitation links, mirroring the functionality of the `FOUNDRY_HOSTNAME` option which configures the external address. | `null` |
| `FOUNDRY_LICENSE_KEY` | The license key to install. e.g.; `AAAA-BBBB-CCCC-DDDD-EEEE-FFFF`  If left unset, a license key will be fetched when using account authentication.   If multiple license keys are associated with an account, one will be chosen at random.  Specific licenses can be selected by passing in an integer index.  The first license key being `1`.  May be set [using secrets](#using-secrets). | |
| `FOUNDRY_MINIFY_STATIC_FILES` | Set to `true` to reduce network traffic by serving minified static JavaScript and CSS files.  Enabling this setting is recommended for most users, but module developers may wish to disable it. | `false` |
| `FOUNDRY_PASSWORD_SALT` | Custom salt string to be applied to the admin password instead of the default salt string.  May be set [using secrets](#using-secrets). | `null` |
| `FOUNDRY_PROXY_PORT` | Inform the Foundry server that the software is running behind a reverse proxy on some other port. This allows the invitation links created to the game to include the correct external port. | `null` |
| `FOUNDRY_PROXY_SSL` | Indicates whether the software is running behind a reverse proxy that uses SSL. This allows invitation links and A/V functionality to work as if the Foundry server had SSL configured directly. | `false` |
| `FOUNDRY_ROUTE_PREFIX` | A string path which is appended to the base hostname to serve Foundry VTT content from a specific namespace. For example setting this to `demo` will result in data being served from `http://x.x.x.x:30000/demo/`. | `null` |
| `FOUNDRY_SSL_CERT` | An absolute or relative path that points towards a SSL certificate file which is used jointly with the sslKey option to enable SSL and https connections. If both options are provided, the server will start using HTTPS automatically. | `null` |
| `FOUNDRY_SSL_KEY` | An absolute or relative path that points towards a SSL key file which is used jointly with the sslCert option to enable SSL and https connections. If both options are provided, the server will start using HTTPS automatically. | `null` |
| `FOUNDRY_UID` | `uid` the daemon will be run under. | `foundry` |
| `FOUNDRY_UPNP` | Allow Universal Plug and Play to automatically request port forwarding for the Foundry server port to your local network address. | `false` |
| `FOUNDRY_UPNP_LEASE_DURATION` | Sets the Universal Plug and Play lease duration, allowing for the possibility of permanent leases for routers which do not support temporary leases.  To define an indefinite lease duration set the value to `0`. | `null` |
| `FOUNDRY_VERSION` | Version of Foundry Virtual Tabletop to install. | `10.276` |
| `FOUNDRY_WORLD` | The world to startup at system start. | `null` |
| `TIMEZONE`     | Container [TZ database name](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List) | `UTC` |

### Node.js variables ###

Any [Node.js
variables](https://nodejs.org/docs/latest-v16.x/api/cli.html#environment-variables)
(`NODE_*`) supplied to the container will be passed to the underlying Node.js
server running FoundryVTT.  Listed below are some variables that are
particularly useful.

| Name | Purpose |
|------|---------|
| `NODE_DEBUG` | `,`-separated list of core modules that should print debug information. |
| `NODE_EXTRA_CA_CERTS` | When set, the well known "root" CAs (like VeriSign) will be extended with the extra certificates.  The file should consist of one or more trusted certificates in PEM format.  A message will be emitted (once) with `process.emitWarning()` if the file is missing or malformed, but any errors are otherwise ignored. |
| `NODE_OPTIONS` | A space-separated list of command-line options that are interpreted before command-line options, so command-line options will override or compound after anything supplied.  Node.js will exit with an error if an option that is not allowed in the environment is used, such as `-p` or a script file. |
| `NODE_TLS_REJECT_UNAUTHORIZED` | If the value equals `0`, certificate validation is disabled for TLS connections. This makes TLS, and HTTPS by extension, insecure.  ⚠️ **The use of this environment variable is strongly discouraged.** |

## Secrets ##

| Filename     | Key | Purpose |
|--------------|-----|---------|
| `config.json` | `foundry_admin_key` | Overrides `FOUNDRY_ADMIN_KEY` environment variable. |
| `config.json` | `foundry_license_key` | Overrides `FOUNDRY_LICENSE_KEY` environment variable. |
| `config.json` | `foundry_password` | Overrides `FOUNDRY_PASSWORD` environment variable. |
| `config.json` | `foundry_password_salt` | Overrides `FOUNDRY_PASSWORD_SALT` environment variable. |
| `config.json` | `foundry_username` | Overrides `FOUNDRY_USERNAME` environment variable. |

## Building from source ##

Build the image locally using this git repository as the [build context](https://docs.docker.com/engine/reference/commandline/build/#git-repositories):

```console
docker build \
  --build-arg VERSION=10.276.0 \
  --tag felddy/foundryvtt:10.276.0 \
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
    ./buildx-dockerfile.sh Dockerfile Dockerfile-x
    ```

1. Build the image using `buildx`:

    ```console
    docker buildx build \
      --file Dockerfile-x \
      --platform linux/amd64 \
      --build-arg VERSION=10.276.0 \
      --output type=docker \
      --tag felddy/foundryvtt:10.276.0 .
    ```

## Pre-installed distribution builds ##

It is possible to install a Foundry Virtual Tabletop distribution into the
Docker image at build-time.  This results in a significantly larger Docker
image, but removes the need to install a distribution at container startup,
resulting in a faster startup.  It also moves the user authentication to
build-time instead of start-time.  **Note**: Credentials are only used to fetch
a distribution, and are not stored in the resulting image.

Build the image with credentials:

```console
docker build \
  --build-arg FOUNDRY_USERNAME='<your_username>' \
  --build-arg FOUNDRY_PASSWORD='<your_password>' \
  --build-arg VERSION=10.276.0 \
  --tag felddy/foundryvtt:10.276.0 \
  https://github.com/felddy/foundryvtt-docker.git#develop
```

Or build the image using a temporary URL:

```console
docker build \
  --build-arg FOUNDRY_RELEASE_URL='<temporary_url>' \
  --build-arg VERSION=10.276.0 \
  --tag felddy/foundryvtt:10.276.0 \
  https://github.com/felddy/foundryvtt-docker.git#develop
```

## Contributing ##

We welcome contributions!  Please see [`CONTRIBUTING.md`](CONTRIBUTING.md) for
details.

## License ##

This project is released as open source under the [MIT license](LICENSE).

All contributions to this project will be released under the same MIT license.
By submitting a pull request, you are agreeing to comply with this waiver of
copyright interest.
