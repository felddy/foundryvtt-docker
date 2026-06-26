# Deploying on Kubernetes #

This guide runs Foundry Virtual Tabletop on a Kubernetes cluster using a small
set of plain manifests.  They are intentionally generic — no specific ingress
controller, storage provider, or secrets tooling is assumed — so you can adapt
them to your environment.

The manifests live in [`manifests/`](manifests) and are pinned to the major
image tag `:14`:

| File | Resource | Purpose |
| ---- | -------- | ------- |
| [`namespace.yaml`](manifests/namespace.yaml) | `Namespace` | Isolates the instance. |
| [`pvc.yaml`](manifests/pvc.yaml) | `PersistentVolumeClaim` | Persistent `/data` storage. |
| [`secret.yaml`](manifests/secret.yaml) | `Secret` | Credentials as a `config.json`. |
| [`deployment.yaml`](manifests/deployment.yaml) | `Deployment` | The Foundry pod. |
| [`service.yaml`](manifests/service.yaml) | `Service` | Cluster-internal endpoint. |
| [`ingress.yaml`](manifests/ingress.yaml) | `Ingress` | External HTTPS access. |

## Prerequisites ##

- A Kubernetes cluster and `kubectl` configured to reach it.
- A default `StorageClass` (or edit [`pvc.yaml`](manifests/pvc.yaml)).
- An ingress controller and DNS if you want external access.
- A [foundryvtt.com](https://foundryvtt.com/auth/register/) account with a
  purchased software license.

## Deploy ##

1. Edit [`secret.yaml`](manifests/secret.yaml) with your credentials, and set
   `FOUNDRY_HOSTNAME` (in [`deployment.yaml`](manifests/deployment.yaml)) and
   the `host` (in [`ingress.yaml`](manifests/ingress.yaml)) to your domain.

1. Apply the manifests:

    ```console
    kubectl apply -f manifests/
    ```

1. Watch the pod start.  On first launch it downloads and installs the Foundry
   distribution, so give it a minute:

    ```console
    kubectl --namespace foundryvtt rollout status deployment/foundryvtt
    ```

1. Reach the server.  Before wiring up DNS you can port-forward to it directly:

    ```console
    kubectl --namespace foundryvtt port-forward service/foundryvtt 30000:80
    ```

   Then open [http://localhost:30000](http://localhost:30000).  Once your
   ingress and DNS are in place, browse to your configured hostname instead.

## How the manifests fit together ##

A few choices are worth understanding before you adapt these.

- **Stable hostname for licensing.** Foundry binds its license to the container
  hostname.  The Deployment sets `hostname: foundryvtt` so the binding survives
  pod restarts.  `FOUNDRY_HOSTNAME` is separate — it is the public address
  Foundry advertises in invitation links.

- **One replica, `Recreate` strategy.** Foundry writes to a single
  `ReadWriteOnce` volume and is not designed to run as multiple concurrent
  replicas.  `replicas: 1` plus `strategy: Recreate` guarantees the old pod
  releases the volume before the new pod claims it.  (To run *several* games,
  see [running multiple instances](#running-multiple-foundry-instances) — each
  is its own single-replica deployment.)

- **Hardened, read-only root filesystem.** The pod runs as non-root
  (UID/GID `1000`), drops all capabilities, and mounts its root filesystem
  read-only.  Foundry still needs to write a couple of paths outside `/data`, so
  `/tmp` and `/home/node/resources` are backed by ephemeral `emptyDir` volumes.

- **Credentials as a mounted secret.** The `Secret` is projected to
  `/run/secrets/config.json`, the location the image reads for credentials.
  This keeps usernames, passwords, and keys out of the pod's environment.  See
  the [secrets reference](../../README.md#secrets) for every supported key.

- **TLS at the edge.** The Service speaks plain HTTP on port `80`.  Terminate
  TLS at your ingress controller and set `FOUNDRY_PROXY_SSL=true` (already in
  the Deployment) so invitation links and audio/video use `https`.  Foundry
  relies on WebSockets; most ingress controllers proxy them without extra
  configuration, but confirm yours does.

> [!TIP]
> Prefer the Gateway API?  Swap [`ingress.yaml`](manifests/ingress.yaml) for an
> `HTTPRoute` pointing at the `foundryvtt` Service on port `80`.  Nothing else
> changes.

## Running multiple Foundry instances ##

A common need is hosting more than one game at once — for example a stable
"production" table and a "staging" instance for testing modules.  Run each as an
independent, single-replica deployment.  Each instance needs:

- **its own namespace** (or a unique name prefix), so the resources do not
  collide;
- **its own `PersistentVolumeClaim`**, since data must not be shared;
- **its own `Secret`**; and
- **a unique `FOUNDRY_HOSTNAME`** and ingress `host`.  Foundry licenses are
  bound per hostname, so each running instance must present a distinct one.

The simplest approach is to deploy the same manifests into a second namespace
with different values:

```console
kubectl apply -f manifests/    # namespace: foundryvtt        -> vtt.example.com
# ...copy and edit for a second instance...
kubectl apply -f staging/      # namespace: foundryvtt-staging -> vtt-staging.example.com
```

To avoid copy-pasting, layer the differences with [Kustomize].  Treat
[`manifests/`](manifests) as a `base` and add a small overlay per instance that
patches only what differs — the namespace, the `FOUNDRY_HOSTNAME`, the ingress
`host`, and optionally the image tag:

```yaml
# overlays/staging/kustomization.yaml
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: foundryvtt-staging
resources:
  - ../../manifests
patches:
  - patch: |
      - op: replace
        path: /spec/template/spec/containers/0/env/1/value
        value: vtt-staging.example.com
    target:
      kind: Deployment
      name: foundryvtt
```

Apply an overlay with `kubectl apply -k overlays/staging/`.  This is exactly how
the maintainer runs production and staging side by side: one shared base, a thin
overlay per instance that changes the hostname (and, for staging, tracks a
newer image tag).

> [!NOTE]
> Different instances can run different Foundry versions.  Pin each overlay's
> image tag — for example `:14.364` for an exact minor release —
> and set the `FOUNDRY_VERSION` environment variable to match the version you
> want installed.

## Updating ##

The in-application "Update Software" tab is disabled in this image.  The
Deployment pins the `:14` tag with `imagePullPolicy: Always`,
so a rollout re-pulls the newest matching image:

```console
kubectl --namespace foundryvtt rollout restart deployment/foundryvtt
```

To move to a new major version, change the image tag in
[`deployment.yaml`](manifests/deployment.yaml) (and `FOUNDRY_VERSION` if you pin
it) and re-apply.

[Kustomize]: https://kustomize.io/
