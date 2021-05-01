# Foundry VTT running behind Caddy #

## Notable features of this setup ##

- Two services running in [Docker] containers
- TLS provided by [Caddy] proxy
- Free certificates from [LetsEncrypt]
- Certificates automatically updated

## How to create this setup ##

1. Create the following directory structure using the [`Caddyfile`](Caddyfile) and
[`docker-compose.yml`](docker-compose.yml) files from this section.

    ```console
    .
    ├── Caddyfile
    ├── docker-compose.yml
    └── volumes/
        ├── caddy_config/
        ├── caddy_data/
        └── foundry_data/
    ```

1. Edit `docker-compose.yml` and replace all the placeholder values that are
contained within `< >`.  For example, modifying the placeholders for the Caddy service:

    ```diff
          environment:
    -        - LETSENCRYPT_EMAIL=<your_email@example.com>
    +        - LETSENCRYPT_EMAIL=super_dm@minsclovesboo.net
    -        - SITE_ADDRESS=<vtt.example.com>
    +        - SITE_ADDRESS=vtt.minsclovesboo.net
          ports:
            - target: 443
    ```

1. Start the container and detach:

    ```console
    docker compose up --detach
    ```

1. Access the web application using the hostname you configured:
[https://vtt.minsclovesboo.net](https://vtt.minsclovesboo.net).

[caddy]: https://caddyserver.com
[docker]: https://docs.docker.com
[foundryvtt]: https://foundryvtt.com
[letsencrypt]: https://letsencrypt.org
