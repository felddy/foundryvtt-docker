# Traefik v2.x Example
This is an example config for setting up `foundryvtt-docker` to run behind a Traefik v2.x reverse proxy.

Example `traefik.yml` and Traefik `docker-compose.yml` files are included in the `traefik config` folder for reference.

## Assumptions
This file makes assumptions about the names used for your Docker and Traefik config. Replace them where necessary with the correct name from your config.

For example: replace `your.hostname.com` with the hostname of your Foundry server.

### Docker Network
This compose file assumes you have an existing external Docker network named `proxy` that Traefik is a part of.

### Traefik Entrypoints
This file assumes you use the name `http` for your non-secure http Traefik entrypoint and `https` for the secure entrypoint.

### Traefik Certresolver
This file assumes you use the name `http` for your `certresolver`.
