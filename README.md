# foundryvtt-docker ⚔️🛡🐳 #

[![GitHub Build Status](https://github.com/felddy/foundryvtt-docker/workflows/build/badge.svg)](https://github.com/felddy/foundryvtt-docker/actions)
[![Total alerts](https://img.shields.io/lgtm/alerts/g/felddy/foundryvtt-docker.svg?logo=lgtm&logoWidth=18)](https://lgtm.com/projects/g/felddy/foundryvtt-docker/alerts/)
[![Language grade: Python](https://img.shields.io/lgtm/grade/python/g/felddy/foundryvtt-docker.svg?logo=lgtm&logoWidth=18)](https://lgtm.com/projects/g/felddy/foundryvtt-docker/context:python)
[![Language grade: JavaScript](https://img.shields.io/lgtm/grade/javascript/g/felddy/foundryvtt-docker.svg?logo=lgtm&logoWidth=18)](https://lgtm.com/projects/g/felddy/foundryvtt-docker/context:javascript)

This docker container can be used to quickly get a
[FoundryVTT](https://foundryvtt.com) instance up and running.

## Prerequisites ##

* A functioning [Docker](https://docs.docker.com/get-docker/) installation.
* The [`docker-compose`](https://docs.docker.com/compose/install/) tool.
* A [FoundryVTT](https://foundryvtt.com/auth/register/) account with a purchased
  software license.

## Building ##

1. Check out the project:

    ```console
    git clone https://github.com/felddy/foundryvtt-docker.git
    cd foundryvtt-docker
    ```

1. Build the container using your FoundryVTT site credentials:

    ```console
    docker-compose build \
    --build-arg USERNAME=your_username \
    --build-arg PASSWORD=your_password
    ```

See the [Cross-platform builds](#cross-platform-builds) instructions below for
additional build options.

## Running ##

A sample [`docker-compose.yml`](docker-compose.yml) file is included in this
repository.  Modify any configuration options as needed:

1. Create a directory on the host to store the configuration files:

    ```console
    mkdir data
    ```

1. Start the container and detach:

    ```console
    docker-compose up --detach
    ```

1. Access the web application at:
[http://localhost:30000](http://localhost:30000).  If all goes well you should
be prompted for the administrator's password from the `docker-compose.yml` file.
If you used the example, the password is `atropos`.

## Volumes ##

| Mount point | Purpose        |
|-------------|----------------|
| /data    | configuration, data, and log storage |

## Environment Variables ##

| Mount point  | Purpose | Default |
|--------------|---------|---------|
| TIMEZONE     | Container [TZ database name](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List) | UTC |
| FOUNDRY_UID    | `uid` the daemon will be run under. | foundry |
| FOUNDRY_GID    | `gid` the deamon will be run under. | foundry |
| FOUNDRY_ADMIN_KEY | Admin password.  |  |
| FOUNDRY_HOSTNAME | A custom hostname to use in place of the host machine's public IP address when displaying the address of the game session. This allows for reverse proxies or DNS servers to modify the public address. | null |
| FOUNDRY_PROXY_PORT | Inform the Foundry Server that the software is running behind a reverse proxy on some other port. This allows the invitation links created to the game to include the correct external port. | null |
| FOUNDRY_PROXY_SSL | Indicates whether the software is running behind a reverse proxy that uses SSL. This allows invitation links and A/V functionality to work as if the Foundry Server had SSL configured directly. | false |
| FOUNDRY_ROUTE_PREFIX | A string path which is appended to the base hostname to serve Foundry VTT content from a specific namespace. For example setting this to `demo` will result in data being served from `http://x.x.x.x:30000/demo/`. | null |
| FOUNDRY_SSL_CERT | An absolute or relative path that points towards a SSL certificate file which is used jointly with the sslKey option to enable SSL and https connections. If both options are provided, the server will start using HTTPS automatically. | null |
| FOUNDRY_SSL_KEY | An absolute or relative path that points towards a SSL key file which is used jointly with the sslCert option to enable SSL and https connections. If both options are provided, the server will start using HTTPS automatically. | null |
| FOUNDRY_UPDATE_CHANNEL | The update channel to subscribe to.  "alpha", "beta", or "release". | "beta" |
| FOUNDRY_UPNP | Allow Universal Plug and Play to automatically request port forwarding for the Foundry VTT port to your local network address. | false |
| FOUNDRY_WORLD | The world startup at system start. | null |

## Cross-platform builds ##

To create images that are compatible with other platforms you can use the
[`buildx`](https://docs.docker.com/buildx/working-with-buildx/) feature of
Docker:

1. Create an new `Dockerfile` with `buildx` support:

    ```console
    ./buildx-dockerfile.sh
    ```

1. Build the image using `buildx`:

    ```console
    docker buildx build \
      --file Dockerfile-x \
      --platform linux/amd64 \
      --build-arg PASSWORD=your_password \
      --build-arg USERNAME=your_username \
      --build-arg VERSION=0.6.0 \
      --output type=docker \
      --tag felddy/foundryvtt:0.6.0 .
    ```

## Hosting behind Nginx with TLS ##

Below is an example configuration that will serve the FoundryVTT application at
a specific path.  In this example, the application container will be accessible
at `https://example.com/vtt`:

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
        # FoundryVTT routePrefix = "vtt"

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

There are a few helper arguments that can be used to diagnose container issues
in your environment.

| Purpose | Command |
|---------|---------|
| Drop into a shell in the container | `docker-compose run foundry --shell` |

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
