<div align="center">

<img width="460"
  src="https://raw.githubusercontent.com/felddy/foundryvtt-docker/develop/assets/logo.png"
  alt="Docker whale logo carrying the FoundryVTT icosahedron logo while floating
  in water.">
</div>

# foundryvtt-docker #

[![Build](https://github.com/felddy/foundryvtt-docker/actions/workflows/build.yml/badge.svg)](https://github.com/felddy/foundryvtt-docker/actions/workflows/build.yml)
[![CodeQL](https://github.com/felddy/foundryvtt-docker/workflows/CodeQL/badge.svg)](https://github.com/felddy/foundryvtt-docker/actions/workflows/codeql-analysis.yml)
[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/felddy/foundryvtt-docker/badge)](https://securityscorecards.dev/viewer/?uri=github.com/felddy/foundryvtt-docker)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/5966/badge)](https://bestpractices.coreinfrastructure.org/projects/5966)
[![SLSA 3](https://slsa.dev/images/gh-badge-level3.svg)](https://slsa.dev)

[![FoundryVTT Release Version: v14.364](https://img.shields.io/badge/release-v14.364-brightgreen?logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAYAAAAfSC3RAAAAAXNSR0IArs4c6QAAAIRlWElmTU0AKgAAAAgABQESAAMAAAABAAEAAAEaAAUAAAABAAAASgEbAAUAAAABAAAAUgEoAAMAAAABAAIAAIdpAAQAAAABAAAAWgAAAAAAAABIAAAAAQAAAEgAAAABAAOgAQADAAAAAQABAACgAgAEAAAAAQAAAA6gAwAEAAAAAQAAAA4AAAAATspU+QAAAAlwSFlzAAALEwAACxMBAJqcGAAAAVlpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IlhNUCBDb3JlIDUuNC4wIj4KICAgPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4KICAgICAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIKICAgICAgICAgICAgeG1sbnM6dGlmZj0iaHR0cDovL25zLmFkb2JlLmNvbS90aWZmLzEuMC8iPgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KTMInWQAAAiFJREFUKBVVks1rE1EUxc+d5tO0prZVSZsUhSBIPyC02ooWurJ0I7rQlRvdC/4N4h9gt7pyoRTswpWgILgQBIOIiC340VhbpC0Ek85MGmPmXc+baWpNGJg77/7uOffeB+z9FHB0FrH9eLwwqpOF0f34KrpsTicW+6L8KE8QhO/n8n1IOgtQHYZA+a/Ai9+Wd6v1g7liq5A2OjKSQNa9hkO4hAzOIylf6CHALk6hoWXsylPkfjyyApaJhVCxmERy5zLSuI7D8h1H5BWht1aBhS6wdI3pN7GabyuyS4JPrchzujmNjDxAVrrRL2PoxRSGxOfjssgEjkkJvVJBWu6h5M7YenvDoOO0OgicD4TPIKWbBG6xvwTaKCMwSU7hKxK6gt8mbsFIMaF5iDyjUg6iPnqc58higCr9fD4iTvWMziAmK2g73f/AADVWX0YXrlChirgOcqL3WXYBYpTfUuxzjkW30dI1C0ZW1RnjMopo4C56MIs6CgQrMER2cJoz9zjdO2iz17g2yZUjqzHWbuA4/ugiEz7DVRe/aLxmcvDQ5Cq+oWGWeDbAgiETXgArrVOFGzR0EkclxrVMcpfLgFThY5roe2yz95ZZkzcbj22+w2VG8Pz6Q/b5Gr6uM9mw04uo6ll4tOlhE8a8xNzGYihCJoT+u3I4kUIp6OM0X9CHHds8frbqsrXlh9CB62nj8L5a9Y4DHR/K68TgcHhoz607Qp34L72X0rdSdM+vAAAAAElFTkSuQmCC)](https://foundryvtt.com/releases/14.364)
[![Platforms](https://img.shields.io/badge/platforms-amd64%20%7C%20arm64%20%7C%20ppc64le%20%7C%20s390x-blue)](https://github.com/felddy/foundryvtt-docker/pkgs/container/foundryvtt)

You can get a [Foundry Virtual Tabletop](https://foundryvtt.com) instance up and
running in minutes using this container.  This image is designed to be secure,
reliable, compact, and simple to use.  It only requires that you provide the
credentials or URL needed to download a Foundry Virtual Tabletop distribution.

This README is the reference for the image itself — its
[tags](#image-tags), [volumes](#volumes), [ports](#ports),
[environment variables](#environment-variables), and [secrets](#secrets).  For
step-by-step setups on a particular platform, see the
[deployment guides](#deployment-guides).

## Prerequisites ##

- An OCI-compatible container runtime such as [Kubernetes](https://kubernetes.io/),
  [Podman](https://podman.io/), or [Docker](https://docs.docker.com/get-docker/).
- A [FoundryVTT.com](https://foundryvtt.com/auth/register/) account with a purchased
  software license.

## Quick start ##

The fastest way to see the server running is a single command.  Your
[foundryvtt.com](https://foundryvtt.com) credentials let the container install
and license your server:

```console
docker run \
  --env FOUNDRY_USERNAME='<your_username>' \
  --env FOUNDRY_PASSWORD='<your_password>' \
  --hostname my_foundry_host \
  --publish 30000:30000/tcp \
  --volume <your_data_dir>:/data \
  ghcr.io/felddy/foundryvtt:14
```

Then open [http://localhost:30000](http://localhost:30000).

> [!TIP]
> Don't want to share your password with the container?  Acquire a temporary
> download URL from the [Purchased Software Licenses
> page](https://foundryvtt.com/me/licenses) (set `Operating System` to
> `Node.js`, then use the `🔗 Timed URL` button) and pass it as
> `FOUNDRY_RELEASE_URL` instead of your username and password.  Sensitive values
> can also be supplied as [secrets](#using-secrets).

This is enough to try things out.  For a durable, real-world deployment, pick a
[deployment guide](#deployment-guides) below.

## Configuration ##

[Configuration options](https://foundryvtt.com/article/configuration/) are
supplied through [environment variables](#environment-variables).  Each time the
container starts, it generates the configuration files Foundry needs from the
values of those variables.  This means **changes made in the in-application
configuration GUI do not persist between container restarts**.  Manage
configuration through your runtime's environment settings — a `compose.yml`
file, a Kubernetes manifest, or similar.  To disable the regeneration of these
files, set `CONTAINER_PRESERVE_CONFIG` to `true`.

> [!IMPORTANT]
> Always set a stable hostname for the container (`hostname:` in a `compose.yml`
> file, `--hostname` for `docker`/`podman`, or `hostname:` in a pod spec).
> Foundry binds its software license to the container hostname.  If no hostname
> is set, the runtime assigns a random container ID on each start, causing
> license verification to fail after every restart.

## Using secrets ##

Sensitive values — your credentials, admin key, or license key — can be supplied
through a secret file instead of environment variables.  The file may have any
name, but it must be presented to the container as `config.json`.  See the
[secrets](#secrets) reference below for the full list of supported keys, and the
[deployment guides](#deployment-guides) for how to wire up a secret on your
runtime.

## Deployment guides ##

The [deployment guides](docs/deployment/README.md) cover each runtime in depth
and include worked networking examples.  The image is the same everywhere; these
guides show how to run it well on a given platform.

| Guide | Description |
| ----- | ----------- |
| [Kubernetes](docs/deployment/kubernetes/README.md) | Cluster deployment, including running multiple Foundry instances. |
| [Podman](docs/deployment/podman.md) | Daemonless and rootless, optionally managed by `systemd`. |
| [Docker Compose](docs/deployment/docker-compose.md) | Single-host setup with the image, configuration, storage, and ports in one file. |
| [Reverse proxy with Caddy](docs/deployment/reverse-proxy-caddy/README.md) | Automatic HTTPS in front of the server. |
| [Cloudflare Tunnel](docs/deployment/cloudflare-tunnel/README.md) | Public access without port forwarding or NAT. |

## Updating ##

The Foundry "Update Software" tab is disabled by default in this container.  To
upgrade to a new version of Foundry, pull an updated image and recreate the
container.  Because the recommended `:14` tag tracks the latest
release for that major version, pulling it fetches the newest version compatible
with your data.  Your [deployment guide](#deployment-guides) lists the exact
commands for your runtime.

## Image tags ##

The images of this container are tagged with [semantic
versions](https://semver.org) that align with the [version and build of Foundry
Virtual Tabletop](https://foundryvtt.com/article/versioning/) that they support.

> [!TIP]
> It is recommended that users use the major version tag: `:14` Using the major
> tag will ensure that you receive the most recent version of the software that
> is compatible with your saved data, and prevents inadvertent upgrades to a new
> major version.

| Image:tag | Description |
| ----------- | ------------- |
| `ghcr.io/felddy/foundryvtt:14` | The most recent image matching the major version number.  Most users will use this tag. |
| `ghcr.io/felddy/foundryvtt:14.364` | The most recent image matching the major and minor version numbers. |
| `ghcr.io/felddy/foundryvtt:14.364.0` | An exact image version. |
| `ghcr.io/felddy/foundryvtt:release` | The most recent image from the `stable` channel.  These images are **considered stable**, and well-tested.  The `latest` tag always points to the same version as `release`. |
| `ghcr.io/felddy/foundryvtt:latest` | Same as the `release` tag.  [Why does `latest` == `release`?](https://vsupalov.com/docker-latest-tag/) |

See the [packages page](https://github.com/felddy/foundryvtt-docker/pkgs/container/foundryvtt)
for a complete list of available tags.

> [!NOTE]
> Stable releases are also mirrored to [Docker
> Hub](https://hub.docker.com/repository/docker/felddy/foundryvtt) and can be
> referenced using the full registry path: `docker.io/felddy/foundryvtt:14`

## Volumes ##

| Mount point | Purpose                               |
| ----------- | ------------------------------------- |
| `/data`     | Configuration, data, and log storage. |

## Ports ##

The following ports are exposed by this container:

| Port    | Purpose                                       |
| ------- | --------------------------------------------- |
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

| Name               | Purpose                                                                                                      |
| ------------------ | ------------------------------------------------------------------------------------------------------------ |
| `FOUNDRY_PASSWORD` | Account password for foundryvtt.com.  Required for downloading an application distribution.                  |
| `FOUNDRY_USERNAME` | Account username or email address for foundryvtt.com.  Required for downloading an application distribution. |

***Note:*** `FOUNDRY_USERNAME` and `FOUNDRY_PASSWORD` may be set [using
secrets](#using-secrets) instead of environment variables.

#### Presigned URL variable ####

| Name                  | Purpose                                                                                                     |
| --------------------- | ----------------------------------------------------------------------------------------------------------- |
| `FOUNDRY_RELEASE_URL` | The presigned URL generated from the user's profile.  Required for downloading an application distribution. |

### Optional variables ###

| Name | Purpose | Default |
| ---- | ------- | ------- |
| `CONTAINER_CACHE` | Set a path to cache downloads of the Foundry distribution archive and speed up subsequent container startups.  The path should be in `/data` or another persistent mount point in the container.  Set to `""` to disable.</br>***Note***: When the cache is disabled the container will sleep indefinitely on failure rather than exiting, to prevent a restart loop.  A distribution can be pre-downloaded and placed into a cache directory.  The distribution's name must be of the form: `foundryvtt-14.364.zip` | `/data/container_cache` |
| `CONTAINER_CACHE_SIZE` | Set the maximum number of distribution versions to keep in the cache.  The minimum is `1`.  When the limit is exceeded, the oldest versions (lowest version numbers) are removed first.  Unset to disable cache size management and keep all versions. | |
| `CONTAINER_PATCHES` | Set a path to a directory of shell scripts to be sourced after Foundry is installed but before it is started.  The path should be in `/data` or another persistent mount point in the container. e.g.; `/data/container_patches`  Patch files are sourced in lexicographic order.  `CONTAINER_PATCHES` are processed after `CONTAINER_PATCH_URLS`. | |
| `CONTAINER_PATCH_URLS` | Set to a space-delimited list of URLs to be sourced after Foundry is installed but before it is started.  Patch URLs are sourced in the order specified.  `CONTAINER_PATCH_URLS` are processed before `CONTAINER_PATCHES`.  ⚠️ **Only use patch URLs from trusted sources!** | |
| `CONTAINER_PRESERVE_CONFIG` | Normally new `options.json` and `admin.txt` files are generated by the container at each startup.  Setting this to `true` prevents the container from modifying these files when they exist.  If they do not exist, they will be created as normal. | `false` |
| `CONTAINER_UMASK` | Control the default permissions on new files and directories created by Foundry VTT. Set the umask to `"0002"` if you need new files to be writable by other users in the same group as the foundry user. If this is empty or not set, the umask will not be changed (the system default is `"0022"`). | |
| `CONTAINER_URL_FETCH_RETRY` | Number of times to retry fetching the presigned URL using exponential back off.  This behavior is useful in continuous integration environments where multiple parallel workflows can exceed the rate-limit of the URL generation service. | `0` |
| `CONTAINER_VERBOSE` | Set to `true` to enable verbose logging for the container utility scripts. | `false` |
| `FOUNDRY_ADMIN_KEY` | Admin password to be applied at startup.  If omitted the admin password will be cleared.  May be set [using secrets](#using-secrets). | |
| `FOUNDRY_AWS_CONFIG` | An absolute or relative path that points to the [awsConfig.json](https://foundryvtt.com/article/aws-s3/) or `true` for AWS environment variable [credentials evaluation](https://docs.aws.amazon.com/sdk-for-javascript/v2/developer-guide/setting-credentials-node.html) usage. | `null` |
| `FOUNDRY_COMPRESS_WEBSOCKET` | Set to `true` to enable compression of data sent from the server to the client via websocket. This is recommended for network performance. | `false` |
| `FOUNDRY_CSS_THEME` | Choose the CSS theme for the setup page.  Valid values are `dark`, `fantasy`, and `scifi`. | `dark` |
| `FOUNDRY_DEMO_CONFIG` | Demo mode allows you to configure a world which will be automatically launched and reset at a frequency of your choosing.  When the world is reset, it is deactivated.  The source data for the world is restored to its original state using a provided `.zip` file, and the next reset is automatically scheduled.  See: [Configuring demo mode](https://foundryvtt.com/article/configuration/#command-line). | |
| `FOUNDRY_DELETE_NEDB` | Set to `true` to automatically delete legacy NeDB `.db` files after they have been migrated to the LevelDB format introduced in Version 11.  Enabling this recovers disk space but removes the ability to roll back to a pre-migration state.  Only relevant for data volumes previously used with Foundry Version 10 or earlier. | `false` |
| `FOUNDRY_HOSTNAME` | A custom hostname to use in place of the host machine's public IP address when displaying the address of the game session. This allows for reverse proxies or DNS servers to modify the public address. | `null` |
| `FOUNDRY_HOT_RELOAD` | Set to `true` to allow packages to hot-reload certain assets, such as CSS, HTML, and localization files without a full refresh. This setting is only recommended for developers. | `false` |
| `FOUNDRY_IP_DISCOVERY` | Allow the Foundry server to discover and report the accessibility of the host machine's public IP address and port.  Setting this to `false` may reduce server startup time in instances where this discovery would timeout. | `true` |
| `FOUNDRY_LANGUAGE` | The default application language and module which provides the core translation files. | `en.core` |
| `FOUNDRY_LOCAL_HOSTNAME` | Override the local network address used for invitation links, mirroring the functionality of the `FOUNDRY_HOSTNAME` option which configures the external address. | `null` |
| `FOUNDRY_LICENSE_KEY` | The license key to install. e.g.; `AAAA-BBBB-CCCC-DDDD-EEEE-FFFF`  If left unset, a license key will be fetched when using account authentication.   If multiple license keys are associated with an account, one will be chosen at random.  Specific licenses can be selected by passing in an integer index.  The first license key being `1`.  May be set [using secrets](#using-secrets). | |
| `FOUNDRY_LOG_SIZE` | The maximum size a log file can reach before it is rotated.  Units must be included. e.g.; `1024k`, `64m`, `1g`. | |
| `FOUNDRY_MAX_LOGS` | The maximum number of log files to retain before older ones are deleted. | |
| `FOUNDRY_MINIFY_STATIC_FILES` | Set to `true` to reduce network traffic by serving minified static JavaScript and CSS files.  Enabling this setting is recommended for most users, but module developers may wish to disable it. | `false` |
| `FOUNDRY_NO_BACKUPS` | Set to `true` to disable the automatic backup of world data that Foundry creates before performing major version migrations.  Users with an external backup strategy or constrained storage may wish to enable this. | `false` |
| `FOUNDRY_PASSWORD_SALT` | Custom salt string to be applied to the admin password instead of the default salt string.  May be set [using secrets](#using-secrets). | `null` |
| `FOUNDRY_PROTOCOL` | If left unset Foundry VTT will bind to IPv4 and IPv6 interfaces.  To limit to IPv4 only, set to `4`.  To limit to IPv6 only set to `6`. | `null` |
| `FOUNDRY_PROXY_PORT` | Inform the Foundry server that the software is running behind a reverse proxy on some other port. This allows the invitation links created to the game to include the correct external port. | `null` |
| `FOUNDRY_PROXY_SSL` | Indicates whether the software is running behind a reverse proxy that uses SSL. This allows invitation links and A/V functionality to work as if the Foundry server had SSL configured directly. | `false` |
| `FOUNDRY_ROUTE_PREFIX` | A string path which is appended to the base hostname to serve Foundry VTT content from a specific namespace. For example setting this to `demo` will result in data being served from `http://x.x.x.x:30000/demo/`. | `null` |
| `FOUNDRY_SERVICE_CONFIG` | The absolute path inside the container to a service configuration file.  Must be set together with `FOUNDRY_SERVICE_KEY`. | `null` |
| `FOUNDRY_SERVICE_KEY` | Used in conjunction with `FOUNDRY_SERVICE_CONFIG`.  Setting this without `FOUNDRY_SERVICE_CONFIG` will cause the container to exit with an error. | |
| `FOUNDRY_SSL_CERT` | An absolute or relative path that points towards a SSL certificate file which is used jointly with the sslKey option to enable SSL and https connections. If both options are provided, the server will start using HTTPS automatically. | `null` |
| `FOUNDRY_SSL_KEY` | An absolute or relative path that points towards a SSL key file which is used jointly with the sslCert option to enable SSL and https connections. If both options are provided, the server will start using HTTPS automatically. | `null` |
| `FOUNDRY_TELEMETRY` | Set to `true` to enable FoundryVTT telemetry, `false` to disable.  This option allows the collection of anonymous usage data to help improve FoundryVTT.  It is recommended to explicitly set this value.  Leaving this unset will cause Foundry to prompt the user to make a choice on every launch. | |
| `FOUNDRY_TEMP_DIR` | An absolute path to a directory used for temporary storage of package `.zip` archives while they are being downloaded and installed.  When set, archives land outside the user data directory, so only the unpacked content counts against data volume space.  Useful for hosts with constrained `/data` storage. | |
| `FOUNDRY_UNIX_SOCKET` | An absolute path to a Unix domain socket for the server listener.  When set, Foundry binds to the socket instead of the TCP port, which is useful for local reverse-proxy configurations (e.g. nginx or caddy via socket).  If both a port and a socket path are configured, the socket takes precedence. | `null` |
| `FOUNDRY_UPNP` | Allow Universal Plug and Play to automatically request port forwarding for the Foundry server port to your local network address. | `false` |
| `FOUNDRY_UPNP_LEASE_DURATION` | Sets the Universal Plug and Play lease duration, allowing for the possibility of permanent leases for routers which do not support temporary leases.  To define an indefinite lease duration set the value to `0`. | `null` |
| `FOUNDRY_VERSION` | Version of Foundry Virtual Tabletop to install. | `14.364` |
| `FOUNDRY_WORLD` | The directory name of the world to launch at system start. | `null` |
| `TZ` | Container [TZ database name](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List) | `UTC` |
| `*_PROXY` | Proxy settings to use during container initialization and by Foundry at runtime.  See [proxy-from-env](https://www.npmjs.com/package/proxy-from-env#environment-variables) for the list of supported environment variable names.  See [proxy-agent](https://www.npmjs.com/package/proxy-agent) for list of supported proxy protocols. | `null` |

### Node.js variables ###

Any [Node.js
variables](https://nodejs.org/docs/latest-v16.x/api/cli.html#environment-variables)
(`NODE_*`) supplied to the container will be passed to the underlying Node.js
server running FoundryVTT.  Listed below are some variables that are
particularly useful.

| Name | Purpose |
| ---- | ------- |
| `NODE_DEBUG` | `,`-separated list of core modules that should print debug information. |
| `NODE_EXTRA_CA_CERTS` | When set, the well known "root" CAs (like VeriSign) will be extended with the extra certificates.  The file should consist of one or more trusted certificates in PEM format.  A message will be emitted (once) with `process.emitWarning()` if the file is missing or malformed, but any errors are otherwise ignored. |
| `NODE_OPTIONS` | A space-separated list of command-line options that are interpreted before command-line options, so command-line options will override or compound after anything supplied.  Node.js will exit with an error if an option that is not allowed in the environment is used, such as `-p` or a script file. |
| `NODE_TLS_REJECT_UNAUTHORIZED` | If the value equals `0`, certificate validation is disabled for TLS connections. This makes TLS, and HTTPS by extension, insecure.  ⚠️ **The use of this environment variable is strongly discouraged.** |

## Secrets ##

| Filename      | Key                     | Purpose                                                 |
| ------------  | ----------------------- | ------------------------------------------------------- |
| `config.json` | `foundry_admin_key`     | Overrides `FOUNDRY_ADMIN_KEY` environment variable.     |
| `config.json` | `foundry_license_key`   | Overrides `FOUNDRY_LICENSE_KEY` environment variable.   |
| `config.json` | `foundry_password`      | Overrides `FOUNDRY_PASSWORD` environment variable.      |
| `config.json` | `foundry_password_salt` | Overrides `FOUNDRY_PASSWORD_SALT` environment variable. |
| `config.json` | `foundry_service_key`   | Overrides `FOUNDRY_SERVICE_KEY` environment variable.   |
| `config.json` | `foundry_username`      | Overrides `FOUNDRY_USERNAME` environment variable.      |

## Building ##

Most users should pull a published image.  If you want to build the image
yourself — from source, for another architecture, or with a distribution
pre-installed — see the [building guide](docs/building.md).

## Contributing ##

We welcome contributions!  Please see [`CONTRIBUTING.md`](CONTRIBUTING.md) for
details.

## License ##

This project is released as open source under the [MIT license](LICENSE).

All contributions to this project will be released under the same MIT license.
By submitting a pull request, you are agreeing to comply with this waiver of
copyright interest.
