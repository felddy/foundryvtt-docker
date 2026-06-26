# Deploying with Docker Compose #

[Docker Compose] is the simplest way to run a single Foundry Virtual Tabletop
instance on one host.  A `compose.yml` file captures the image, configuration,
storage, and ports in one place, so the server is easy to start, stop, and
reproduce.

This guide covers a complete single-host deployment.  For the full catalog of
settings, see the [environment variables] and [secrets] sections of the project
README.

## Prerequisites ##

- [Docker Engine] with the Compose plugin (the `docker compose` command).  Any
  runtime that understands Compose files works too; Podman users should read the
  [Podman guide](podman.md).
- A [foundryvtt.com] account with a purchased software license.

> [!NOTE]
> These examples use the `docker` command line, which also drives other
> drop-in backends such as [Colima] or [Rancher Desktop].  Use whichever you
> prefer; the commands are the same.

## Minimal example ##

1. Create a `compose.yml` file.  Supply your credentials as the values of the
   environment variables:

    ```yaml
    ---
    services:
      foundry:
        image: ghcr.io/felddy/foundryvtt:14
        hostname: my_foundry_host
        environment:
          - FOUNDRY_USERNAME=<your_username>
          - FOUNDRY_PASSWORD=<your_password>
          - FOUNDRY_ADMIN_KEY=<your_admin_key>
          - FOUNDRY_TELEMETRY=true
        volumes:
          - type: bind
            source: ./data
            target: /data
        ports:
          - target: 30000
            published: 30000
            protocol: tcp
        restart: unless-stopped
    ```

1. Start the server and detach:

    ```console
    docker compose up --detach
    ```

1. Open [http://localhost:30000](http://localhost:30000).  You should be
   prompted to accept the license agreement, then for the admin access key you
   set in `FOUNDRY_ADMIN_KEY`.

> [!IMPORTANT]
> Always set a stable `hostname`.  Foundry binds its software license to the
> container hostname.  Without one, the runtime assigns a random container ID on
> each start and license verification fails after every restart.

## How configuration works ##

[Configuration options] are supplied as [environment variables].  Each time the
container starts, it regenerates Foundry's configuration files from those
variables.  This means **changes made in the in-application configuration GUI do
not persist across restarts** — manage configuration through `compose.yml`
instead.  To preserve hand-edited configuration files, set
`CONTAINER_PRESERVE_CONFIG` to `true`.

## Using secrets ##

Sensitive values can be passed as a secret file instead of environment
variables.  The file may have any name, but it must be mounted to `config.json`
inside the container.  See the [secrets] reference for every supported key.

1. Create a `secrets.json` file with the values you want to set:

    ```json
    {
      "foundry_admin_key": "<your_admin_key>",
      "foundry_password": "<your_password>",
      "foundry_username": "<your_username>"
    }
    ```

1. Reference it from `compose.yml` and drop the matching environment variables:

    ```yaml
    ---
    secrets:
      config_json:
        file: secrets.json

    services:
      foundry:
        image: ghcr.io/felddy/foundryvtt:14
        hostname: my_foundry_host
        environment:
          - FOUNDRY_TELEMETRY=true
        volumes:
          - type: bind
            source: ./data
            target: /data
        ports:
          - target: 30000
            published: 30000
            protocol: tcp
        secrets:
          - source: config_json
            target: config.json
        restart: unless-stopped
    ```

## Updating ##

The in-application "Update Software" tab is disabled in this image.  To move
to a newer release, pull a fresh image and recreate the container:

```console
docker compose pull
docker compose up --detach
```

Because the image is pinned to the major tag `:14`, `pull`
fetches the newest release that is compatible with your existing data.  To move
to a new major version, change the tag in `compose.yml` first, then pull.

## Next steps ##

- Add automatic HTTPS with the
  [Caddy reverse proxy recipe](reverse-proxy-caddy/README.md).
- Publish the server without port forwarding using the
  [Cloudflare Tunnel recipe](cloudflare-tunnel/README.md).

[Configuration options]: https://foundryvtt.com/article/configuration/
[Colima]: https://github.com/abiosoft/colima
[Docker Compose]: https://docs.docker.com/compose/
[Docker Engine]: https://docs.docker.com/get-docker/
[Rancher Desktop]: https://rancherdesktop.io/
[environment variables]: ../../README.md#environment-variables
[foundryvtt.com]: https://foundryvtt.com/auth/register/
[secrets]: ../../README.md#secrets
