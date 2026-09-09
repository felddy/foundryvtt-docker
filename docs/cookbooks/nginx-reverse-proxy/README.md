# Nginx Reverse Proxy with Let's Encrypt

This cookbook adds an `nginx` reverse proxy and `certbot` service in
front of Foundry, handling TLS termination and automatic certificate
renewal.

## Files

- `compose.yml` — full stack: `foundry`, `nginx`, `certbot`
- `nginx/conf.d/foundry.conf.bootstrap` — HTTP-only config used to
  obtain the first certificate
- `nginx/conf.d/foundry.conf.example` — final HTTPS config, used
  after the certificate exists

## Setup

1. Point DNS (`A` record) for your domain at this server's public IP.

2. Create the required directories:
```bash
   mkdir -p nginx/conf.d nginx/certs nginx/www data
```

3. Copy the bootstrap config and edit `server_name` which is named as foundry.example.com:
```bash
   cp nginx/conf.d/foundry.conf.bootstrap nginx/conf.d/foundry.conf
   sed -i 's/foundry.example.com/your.domain.com/' nginx/conf.d/foundry.conf
```

4. Edit `compose.yml`: set `FOUNDRY_USERNAME`, `FOUNDRY_PASSWORD`,
   `FOUNDRY_HOSTNAME`, and `server_name` to your domain.

5. Start `foundry` and `nginx`:
```bash
   docker compose up -d foundry nginx
```

6. Request the certificate:
```bash
   docker compose run --rm certbot certonly --webroot \
     -w /var/www/certbot -d <your>.domain.com \
     --email <you>@example.com --agree-tos --no-eff-email
```

7. Swap in the HTTPS config:
```bash
   cp nginx/conf.d/foundry.conf.example nginx/conf.d/foundry.conf
   sed -i 's/foundry.example.com/your.domain.com/' nginx/conf.d/foundry.conf
   docker compose up -d --force-recreate nginx
```

8. Start the renewal service:
```bash
   docker compose up -d certbot
```

## Notes

- `FOUNDRY_PROXY_SSL=true` and `FOUNDRY_PROXY_PORT=443` are required
  so Foundry generates correct `wss://` URLs behind the TLS-terminating
  proxy.
- The `foundry` service uses `expose` rather than `ports`, so it is
  only reachable from `nginx` inside the `internal` network — not
  published to the host directly.
- Certificates renew automatically every 12 hours via the `certbot`
  service loop.