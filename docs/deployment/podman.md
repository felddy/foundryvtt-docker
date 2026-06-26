# Deploying with Podman #

[Podman] runs the image without a daemon and, by default, as a rootless user.
The image is [OCI] compliant, so everything in the
[Docker Compose guide](docker-compose.md) applies here too: `podman` mirrors the
`docker` command line, and `podman compose` reads the same `compose.yml`.  This
guide focuses on the Podman-specific details.

## Prerequisites ##

- [Podman] 4.4 or newer (Quadlet support).
- A [foundryvtt.com] account with a purchased software license.

## Running with `podman run` ##

```console
podman run \
  --env FOUNDRY_USERNAME='<your_username>' \
  --env FOUNDRY_PASSWORD='<your_password>' \
  --env FOUNDRY_ADMIN_KEY='<your_admin_key>' \
  --hostname my_foundry_host \
  --publish 30000:30000/tcp \
  --volume ./data:/data:Z \
  ghcr.io/felddy/foundryvtt:14
```

> [!IMPORTANT]
> Always set `--hostname`.  Foundry binds its software license to the container
> hostname; without a stable value, license verification fails after each
> restart.

### Rootless notes ###

- **Volume permissions.** The container runs as a non-root user (UID/GID
  `1000`).  Rootless Podman maps that to a subordinate UID on the host, so make
  the data directory writable inside the user namespace:

    ```console
    podman unshare chown 1000:1000 ./data
    ```

- **SELinux.** On SELinux systems, add the `:Z` suffix to bind mounts (as shown
  above) so Podman relabels the content for container access.

- **Low ports.** Rootless Podman cannot bind host ports below `1024`.  Publish a
  high port and let a [reverse proxy](reverse-proxy-caddy/README.md) terminate
  `80`/`443`, or lower `net.ipv4.ip_unprivileged_port_start`.

## Running as a `systemd` service (Quadlet) ##

For a server that starts at boot, describe it as a [Quadlet] `.container` unit.
Create `~/.config/containers/systemd/foundry.container`:

```ini
[Unit]
Description=Foundry Virtual Tabletop

[Container]
Image=ghcr.io/felddy/foundryvtt:14
HostName=my_foundry_host
PublishPort=30000:30000/tcp
Volume=%h/foundry/data:/data:Z
Environment=FOUNDRY_TELEMETRY=true
Secret=foundry_config,target=config.json

[Service]
Restart=always

[Install]
WantedBy=default.target
```

Store your credentials as a Podman secret (see the [secrets] reference for the
`config.json` format), then load and start the service:

```console
podman secret create foundry_config secrets.json
systemctl --user daemon-reload
systemctl --user start foundry
```

The `Secret=` line mounts the secret at `/run/secrets/config.json`, where the
image expects it.

## Using Compose ##

`podman compose` (or the `podman-compose` package) runs the examples from the
[Docker Compose guide](docker-compose.md) and the recipes unchanged — substitute
`podman compose` for `docker compose`.

## nerdctl and containerd ##

[nerdctl] offers the same Docker-compatible command line on top of
[containerd].  The `podman run` and Compose examples translate directly; swap
`podman` (or `docker`) for `nerdctl`.  The low-level `ctr` client is not
recommended for day-to-day use.

[OCI]: https://opencontainers.org/
[Podman]: https://podman.io/
[Quadlet]: https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html
[containerd]: https://containerd.io/
[foundryvtt.com]: https://foundryvtt.com/auth/register/
[nerdctl]: https://github.com/containerd/nerdctl
[secrets]: ../../README.md#secrets
