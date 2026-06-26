# Deployment guides #

The [project README](../../README.md) is the reference for the image itself: its
[tags](../../README.md#image-tags), [volumes](../../README.md#volumes),
[ports](../../README.md#ports),
[environment variables](../../README.md#environment-variables), and
[secrets](../../README.md#secrets).  The guides here show how to put that
reference to work on a specific container runtime, plus a few worked examples
("recipes") for common networking setups.

> [!NOTE]
> Every example pins the image to the major version tag `:14`,
> matching the recommendation in the
> [Image tags](../../README.md#image-tags) section of the README.  This keeps
> you on the newest release compatible with your data while preventing
> surprise major-version upgrades.

## Choose a runtime ##

| Guide | Use it when... |
| ----- | -------------- |
| [Kubernetes](kubernetes/README.md) | You run a cluster, or you want to host one or several Foundry instances with declarative manifests. |
| [Podman](podman.md) | You prefer a daemonless, rootless runtime, or you want the server managed as a `systemd` service. |
| [Docker Compose](docker-compose.md) | You want the simplest single-host setup, with the image, configuration, storage, and ports captured in one file. |

## Recipes ##

These build on a runtime guide to solve a specific networking problem.  They are
written as Compose examples that work with both Docker and Podman.

| Recipe | What it does |
| ------ | ------------ |
| [Reverse proxy with Caddy](reverse-proxy-caddy/README.md) | Puts the server behind [Caddy](https://caddyserver.com) for automatic HTTPS with free, auto-renewing certificates. |
| [Cloudflare Tunnel](cloudflare-tunnel/README.md) | Exposes the server to the internet without opening ports or configuring NAT. |

Kubernetes users generally front the server with an `Ingress` instead; see the
[Kubernetes guide](kubernetes/README.md) for an example.
