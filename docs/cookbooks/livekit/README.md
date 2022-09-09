# Foundry VTT running behind Caddy with LiveKit #

## Notable features of this setup ##

- Three services running in [Docker] containers
- TLS provided by [Caddy] proxy
- Free certificates provided by [LetsEncrypt]
- Certificates are automatically installed and updated
- LiveKit server integration
- FoundryVTT distributions are cached after download
- FoundryVTT data stored in local file system

## How to create this setup ##

1. Download this cookbook:

    ```bash
    curl https://codeload.github.com/felddy/foundryvtt-docker/tar.gz/improvement/cookbooks | \
    tar xz --strip-components=4 --exclude .gitignore --include '*/cookbooks/livekit'
    ```

1. Diagram

    ```mermaid
    graph LR;
    LK(LiveKit)
    R(Redis)
    C(Caddy)
    F(Foundry)
    I((Internet))

    I -- 433 TCP --> C -- 30000 TCP --> F
    I -- 7800 TCP --> C -- 7800 TCP --> LK
    I -- 50000-60000 UDP --> LK
    I -- 7881 TCP --> LK
    I -- 7882 UDP --> LK

    ```

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
