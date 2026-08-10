---
title: "Self-hosting a Git pastebin on k3s — OpenGist goes GitOps"
mermaid: true
categories: [homelab]
tags: [opengist, k3s, kubernetes, flux, gitops, cnpg, minio, nfs, authentik, oidc, cloudflare-tunnel, sops, observability, homelab, kubecraft]
---

![header](./../assets/images/2026-07-29/header.png)

So I joined [KubeCraft](https://www.kubecraft.dev/) 🎮. If you haven't heard of it, it's a community of people running Kubernetes in their homelabs — people who think GitOps is the only way, who name their nodes after anime characters, and who would rather spend three hours automating something than do it manually once. My kind of people.

To celebrate, I wanted to deploy something new. Something small but useful. Something that fits the homelab ethos: self-hosted, GitOps-managed, observable from day one. I picked [OpenGist](https://opengist.io) — a self-hosted Git-powered pastebin. Think GitHub Gists, but yours. Your snippets, your repos, your rules.

And because I've been experimenting heavily with Kubernetes lately (who am I kidding, I've been experimenting heavily with Kubernetes since day one 😎), this was the perfect excuse to show the full playbook: how I deploy a service on k3s with Flux GitOps, CNPG Postgres, OMV NFS for data, OMV MinIO for backups, Authentik for SSO, Cloudflare Tunnel for public ingress, SOPS for secrets, and full observability wired in before the first gist is even created.

Buckle up. This is a long one. Tutorial-style, copy-paste-friendly, with all the YAML and all the facepalms.

{: .prompt-info}
This is a single-page walkthrough. You should be able to follow along, change a few values, and end up with a working OpenGist on your own k3s cluster. I'm showing the real manifests from my public repo — not cleaned-up pseudocode.

## What is OpenGist?

OpenGist is a self-hosted pastebin powered by Git. Every gist you create is a real Git repository under the hood. You can create public or private gists, fork them, star them, comment on them. It has a clean web UI, supports syntax highlighting for basically every language, and it even has an API.

The important thing for me: it's a Go binary with a Helm chart. Small footprint, easy to deploy, fits the homelab.

## Architecture — the full picture

Before we dive into the YAML, let me show you what we're building:

```mermaid
flowchart TB
    subgraph homelab["homelab-2nd (k3s)"]
        subgraph ns["namespace: opengist"]
            og["OpenGist pod<br/>:6157 HTTP, :6158 metrics"]
            nfs["NFS PVC<br/>50Gi → OMV"]
            og --> nfs
            cf["cloudflared<br/>2 replicas"]
            cf -->|"tunnel"| og
        end
        subgraph db["CNPG: opengist-db"]
            pg["PostgreSQL 18<br/>local-path 10Gi"]
            barman["Barman Cloud<br/>sidecar"]
            pg -.-> barman
        end
    end

    barman -->|"S3 backup"| minio["OMV MinIO<br/>s3://cnpg-backups/opengist/"]
    nfs -->|"NFS export"| omv["OMV disk<br/>/opengist/data"]

    cf -->|"gist.example.com<br/>TLS at edge"| user["👤 users"]

    auth["Authentik<br/>namespace: auth"] -->|"OIDC SSO"| og
    prom["Prometheus<br/>+ Grafana<br/>+ Loki"] -->|"metrics + logs"| og

    style user fill:#BFDBFE
    style auth fill:#FDE68A
    style minio fill:#A7F3D0
    style prom fill:#FDE68A
```

| Component | Where / How | Why |
|---|---|---|
| **Compute** | k3s namespace `opengist` | Single source of truth via Flux |
| **Live database** | CloudNativePG `Cluster`, 1 instance, `local-path` 10Gi | Fast NVMe for live Postgres |
| **DB backups** | Barman Cloud CNPG-I plugin → OMV MinIO | Rebuildable cluster from backups |
| **Gist data** (Git repos) | OMV NFS export mounted at `/opengist` | Git needs POSIX semantics; NFS is durable |
| **Public ingress** | Cloudflare Tunnel only, no K8s Ingress | TLS at edge; no router ports |
| **SSO** | Authentik OIDC | One login for all homelab users |
| **Secrets** | SOPS-encrypted `*sops.yaml` | Public repo, never plaintext |
| **Observability** | ServiceMonitor, PrometheusRule, AlertmanagerConfig, Loki rule, Grafana dashboard | No service is done until it's observable |

{: .prompt-info}
**Conscious simplifications:** Single OpenGist replica (RWO NFS is fine — me and my wife won't hit it at the exact same millisecond). SSH Git access disabled in this first pass — we can add it later through a separate Cloudflare Tunnel.

## Prerequisites

You need these before following along:

- k3s + Flux already bootstrapped (if you don't have this, [start here](https://fluxcd.io/flux/installation/))
- SOPS age key at `~/.keys/age-homelab-2nd.txt` with its public key in `.sops.yaml`
- MinIO running (I run it on OMV — my NAS box)
- Authentik running in namespace `auth`, with groups `homelab-admins` and `homelab-users`
- A Cloudflare Tunnel token for your domain
- Optional: Mattermost webhook URL for alerts

## Step 1 — Create the MinIO backup bucket and scoped user

First, we need a place for the CNPG backups to land. On my OMV box, MinIO is running in Docker. SSH in and create a dedicated bucket:

```bash
ssh nas.example.com
mkdir -p /tmp/mc && cd /tmp/mc
wget https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x mc
./mc alias set local http://nas.example.com:9000 ADMIN_ACCESS_KEY ADMIN_SECRET_KEY
./mc mb local/cnpg-backups/opengist
```

Now create a scoped MinIO user that can only read/write to this bucket — not a god key:

```bash
./mc admin user add local cnpg-opengist-backup GENERATED_SECRET_KEY
./mc admin policy create local cnpg-opengist-backup-only /tmp/opengist-backup-policy.json
./mc admin policy attach local cnpg-opengist-backup-only --user cnpg-opengist-backup
```

The policy JSON is minimal — Put, Get, Delete, and List on the bucket and its contents:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::cnpg-backups/opengist/*",
        "arn:aws:s3:::cnpg-backups"
      ]
    }
  ]
}
```

{: .prompt-warning}
The secret key printed by `mc admin user add` is shown **once**. Capture it immediately and encrypt it with SOPS. Do NOT paste it into your tracking notes (ask me how I know 😅). The real value lives in `apps/opengist/opengist-minio-backup-creds.sops.yaml`.

## Step 2 — Create the NFS export for OpenGist data

OpenGist stores each gist as a real Git repository on disk. Git needs a proper POSIX filesystem — you can't put Git repos on S3. So we export a directory from OMV over NFS:

```bash
ssh nas.example.com
mkdir -p /srv/dev-disk-by-uuid-REPLACE-WITH-YOUR-DISK-UUID/opengist/data
echo '/srv/dev-disk-by-uuid-REPLACE-WITH-YOUR-DISK-UUID/opengist/data 10.0.0.1(rw,sync,no_subtree_check,no_root_squash)' >> /etc/exports
exportfs -rav
showmount -e localhost | grep opengist
```

Why NFS and not `local-path` on the k3s node? Because `homelab-2nd` is a laptop. If the NVMe dies, I lose all the gists. OMV has a real disk with RAID. NFS is deliberate, not lazy.

## Step 3 — Create the Authentik OIDC provider

This is where it gets spicy 🌶️.

OpenGist supports OIDC out of the box. We already run Authentik as our SSO provider, so all homelab users (me + wife) get one login for everything. The setup is straightforward — you create an OAuth2 provider and an application in Authentik, then configure OpenGist to use it.

But there's a pitfall. In Authentik 2026.5.x, `redirect_uris` on `OAuth2Provider` is **not** a string or a list of strings. It's a list of `RedirectURI` dataclass instances. If you pass a string, you get:

```
TypeError: asdict() should be called on dataclass instances
```

Not the most helpful error message in the world 🤷. Here's the corrected script. Run it with `ak shell` inside the Authentik server pod:

```python
import secrets
from authentik.core.models import Application, Group
from authentik.flows.models import Flow
from authentik.providers.oauth2.models import (
    OAuth2Provider, ScopeMapping, RedirectURI,
    RedirectURIMatchingMode, RedirectURIType
)
from authentik.crypto.models import CertificateKeyPair
from authentik.policies.models import PolicyBinding

authz_flow = Flow.objects.get(slug="default-provider-authorization-explicit-consent")

required = {
    "openid": "return {\"openid\": True}",
    "profile": "return {\"name\": request.user.name, \"nickname\": request.user.username, \"preferred_username\": request.user.username}",
    "email": "return {\"email\": request.user.email}",
}
mapping_pks = []
for name, expr in required.items():
    m, _ = ScopeMapping.objects.get_or_create(
        name=name,
        defaults={"scope_name": name, "expression": expr},
    )
    mapping_pks.append(m.pk)

# role mapping: homelab-admins → admin, everyone else → user
role_map, _ = ScopeMapping.objects.get_or_create(
    name="homelab-role",
    defaults={"scope_name": "homelab-role",
              "expression": "groups = [group.name for group in request.user.groups.all()]\nif \"homelab-admins\" in groups:\n    return {\"role\": \"admin\"}\nreturn {\"role\": \"user\"}"},
)
mapping_pks.append(role_map.pk)

signing_key = CertificateKeyPair.objects.filter(name__icontains="authentik").first()

provider, created = OAuth2Provider.objects.get_or_create(
    name="OpenGist",
    defaults={
        "client_id": secrets.token_urlsafe(24),
        "client_secret": secrets.token_urlsafe(32),
        "authorization_flow": authz_flow,
        # THE FIX: RedirectURI dataclass instances, NOT strings
        "redirect_uris": [
            RedirectURI(
                matching_mode=RedirectURIMatchingMode.STRICT,
                url="https://gist.example.com/oauth/openid-connect/callback",
                redirect_uri_type=RedirectURIType.AUTHORIZATION,
            ),
        ],
        "access_code_validity": "minutes=1",
        "access_token_validity": "minutes=30",
        "refresh_token_validity": "days=30",
        "sub_mode": "hashed_user_id",
        "grant_types": ["authorization_code", "refresh_token"],
        "signing_key": signing_key,
        "include_claims_in_id_token": True,
    },
)
if created:
    provider.property_mappings.set(mapping_pks)
else:
    provider.redirect_uris = [
        RedirectURI(
            matching_mode=RedirectURIMatchingMode.STRICT,
            url="https://gist.example.com/oauth/openid-connect/callback",
            redirect_uri_type=RedirectURIType.AUTHORIZATION,
        ),
    ]
    provider.save()

app, _ = Application.objects.get_or_create(
    name="OpenGist",
    defaults={
        "slug": "opengist",
        "provider": provider,
        "meta_launch_url": "https://gist.example.com",
    },
)

admin_group = Group.objects.get(name="homelab-admins")
user_group = Group.objects.get(name="homelab-users")

PolicyBinding.objects.update_or_create(
    target=app.policybindingmodel_ptr, group=admin_group, order=0,
    defaults={"timeout": 30, "enabled": True},
)
PolicyBinding.objects.update_or_create(
    target=app.policybindingmodel_ptr, group=user_group, order=1,
    defaults={"timeout": 30, "enabled": True},
)

print("client_id", provider.client_id)
print("client_secret", provider.client_secret)
```

Run it:

```bash
POD=$(sudo kubectl -n auth get pod -l app.kubernetes.io/name=authentik -o jsonpath='{.items[0].metadata.name}')
scp /tmp/authentik_script_v2.txt homelab-2nd:/tmp/authentik_script_v2.txt
ssh homelab-2nd "sudo kubectl -n auth cp /tmp/authentik_script_v2.txt $POD:/tmp/authentik_script_v2.txt"
ssh homelab-2nd "sudo kubectl -n auth exec $POD -- bash -c 'ak shell < /tmp/authentik_script_v2.txt'"
```

The output gives you a `client_id` and `client_secret`. Both go into a SOPS secret — never in plaintext.

{: .prompt-danger}
In Authentik 2026.5.x, `redirect_uris` expects `RedirectURI` dataclass instances. Passing strings will blow up with `TypeError: asdict() should be called on dataclass instances`. This pitfall is documented in our homelab-gitops skill — I should have opened it earlier instead of debugging from scratch 😅.

## Step 4 — Generate SOPS-encrypted secrets

Six secrets total, all encrypted with SOPS/age:

| Secret | What it holds |
|---|---|
| `opengist-db-credentials` | Postgres username/password/host/port/database + full URI |
| `opengist-minio-backup-creds` | MinIO backup user access key/secret |
| `opengist-oidc-client` | Authentik client id, client secret, discovery URL |
| `opengist-config` | Full `config.yml` for OpenGist (db-uri, external-url, secret-key, OIDC settings, metrics) |
| `opengist-tunnel-token` | Cloudflare Tunnel token |
| `opengist-mattermost-webhook-url` | Mattermost alert webhook URL |

The generation workflow (shown with placeholder values — obviously):

```bash
export SOPS_AGE_KEY_FILE=~/.keys/age-homelab-2nd.txt
# write plaintext manifest to /tmp/...
sops --encrypt --in-place /tmp/secret-name.yaml
cp /tmp/secret-name.yaml apps/opengist/secret-name.sops.yaml
```

The `opengist-config` Secret is the interesting one — it contains the `config.yml` that OpenGist reads at runtime:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: opengist-config
  namespace: opengist
type: Opaque
stringData:
  config.yml: |
    log-level: info
    log-output: stdout
    external-url: https://gist.example.com
    opengist-home: /opengist
    secret-key: <32-byte-base64-secret-key>
    db-uri: <postgres://...>
    metrics.enabled: true
    oidc.provider-name: Authentik
    oidc.discovery-url: https://auth.example.com/application/o/opengist/.well-known/openid-configuration
    oidc.group-claim-name: groups
    oidc.admin-group: homelab-admins
```

{: .prompt-warning}
`config.yml` is a static YAML file mounted as a Secret key. It has no templating engine — you **cannot** reference Kubernetes Secrets inside it. So the OIDC client-id and client-secret can't live in `config.yml`; they go in a separate Secret and get injected as environment variables (see Step 6). This split is deliberate.

## Step 5 — Write the GitOps manifests

Time for the fun part. Everything goes into the public homelab repo and Flux reconciles it.

### Namespace

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: opengist
  labels:
    app.kubernetes.io/name: opengist
```

### Helm repository

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: opengist
  namespace: flux-system
spec:
  interval: 1h
  url: https://helm.opengist.io
```

### CNPG Postgres cluster

Live data on `local-path` (NVMe on the node), backups to OMV MinIO via the Barman Cloud plugin:

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: opengist-db
  namespace: opengist
spec:
  instances: 1
  imageName: ghcr.io/cloudnative-pg/postgresql:18-minimal-trixie

  bootstrap:
    initdb:
      database: opengist
      owner: opengist
      secret:
        name: opengist-db-credentials

  storage:
    storageClass: local-path
    size: 10Gi

  plugins:
    - name: barman-cloud.cloudnative-pg.io
      isWALArchiver: true
      parameters:
        barmanObjectName: opengist-db-backups
        serverName: opengist-db

  backup:
    retentionPolicy: "30d"

  resources:
    requests:
      memory: "256Mi"
      cpu: "250m"
    limits:
      memory: "512Mi"
      cpu: "1000m"
```

### ObjectStore (backup target)

```yaml
apiVersion: barmancloud.cnpg.io/v1
kind: ObjectStore
metadata:
  name: opengist-db-backups
  namespace: opengist
spec:
  configuration:
    destinationPath: s3://cnpg-backups/opengist/
    endpointURL: http://nas.example.com:9000
    s3Credentials:
      accessKeyId:
        name: opengist-minio-backup-creds
        key: ACCESS_KEY_ID
      secretAccessKey:
        name: opengist-minio-backup-creds
        key: ACCESS_SECRET_KEY
    data:
      compression: gzip
    wal:
      compression: gzip
```

### Scheduled backup

Daily base backup at 3 AM:

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: ScheduledBackup
metadata:
  name: opengist-db-daily
  namespace: opengist
spec:
  schedule: "0 3 * * *"
  backupOwnerReference: self
  cluster:
    name: opengist-db
  method: plugin
  pluginConfiguration:
    name: barman-cloud.cloudnative-pg.io
  immediate: true
```

### NFS PersistentVolume + PVC

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: opengist-data
  namespace: opengist
spec:
  capacity:
    storage: 50Gi
  accessModes:
    - ReadWriteOnce
  nfs:
    server: nas.example.com
    path: /srv/dev-disk-by-uuid-REPLACE-WITH-YOUR-UUID/opengist/data
  storageClassName: ""
  persistentVolumeReclaimPolicy: Retain
  mountOptions:
    - hard
    - intr
    - nconnect=8
```

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: opengist-data
  namespace: opengist
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Gi
  storageClassName: ""
  volumeName: opengist-data
```

## Step 6 — The HelmRelease

Here's where I made my first real mistake 😅.

My initial HelmRelease used `service.main.ports.http.port: 80` and `targetPort: 6157`. That's the `bjw-s/common` chart pattern — the convention used by Karakeep and many other charts I'd already deployed. OpenGist's chart? It does NOT use `bjw-s/common`. It has its own keys.

I copy-pasted from Karakeep instead of reading the OpenGist chart's `values.yaml`. Classic.

{: .prompt-danger}
**Read the chart's own `values.yaml` before writing your HelmRelease values.** Do not assume all Helm charts use `bjw-s/common` conventions. The OpenGist chart uses `service.http.port`, `service.ssh.enabled`, `service.metrics.serviceMonitor.enabled` — completely different keys.

Here's the corrected HelmRelease from the real repo:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: opengist
  namespace: opengist
spec:
  interval: 1h
  chart:
    spec:
      chart: opengist
      version: "0.10.0"   # Helm chart version; appVersion is 1.14.0
      sourceRef:
        kind: HelmRepository
        name: opengist
        namespace: flux-system
      interval: 1h
  install:
    remediation:
      retries: 3
  upgrade:
    remediation:
      retries: 3
  values:
    configExistingSecret: opengist-config

    image:
      tag: "1.14.0"

    replicaCount: 1

    service:
      http:
        port: 6157
      ssh:
        enabled: false
      metrics:
        serviceMonitor:
          enabled: true
          labels:
            release: kube-prometheus-stack

    # OIDC credentials injected as env vars (config.yml can't reference Secrets)
    deployment:
      envFromSecrets:
        - name: OG_OIDC_SECRET
          secretName: opengist-oidc-client
          secretKey: client-secret
        - name: OG_OIDC_CLIENT_KEY
          secretName: opengist-oidc-client
          secretKey: client-id
        - name: OG_OIDC_DISCOVERY_URL
          secretName: opengist-oidc-client
          secretKey: discovery-url

    ingress:
      enabled: false

    persistence:
      enabled: true
      existingClaim: opengist-data

    config:
      metrics.enabled: true

    resources:
      requests:
        cpu: 50m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 512Mi
```

{: .prompt-info}
The `deployment.envFromSecrets` list is the chart's documented way to inject individual env vars from secret keys. We use it for OIDC because `config.yml` can only hold static config — it has no templating engine and can't reference Kubernetes Secrets. The chart template renders `env.valueFrom.secretKeyRef` entries from this list. Clean split: static config in the Secret-mounted `config.yml`, rotatable credentials in separate Secrets injected as env vars.

## Step 7 — Cloudflare Tunnel

No Kubernetes Ingress. No cert-manager. No router ports opened. Cloudflare Tunnel handles everything.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cloudflared-opengist
  namespace: opengist
  labels:
    app.kubernetes.io/name: cloudflared-opengist
    app.kubernetes.io/component: tunnel
spec:
  replicas: 2
  selector:
    matchLabels:
      app.kubernetes.io/name: cloudflared-opengist
  template:
    metadata:
      labels:
        app.kubernetes.io/name: cloudflared-opengist
    spec:
      containers:
        - name: cloudflared
          image: cloudflare/cloudflared:latest
          args:
            - tunnel
            - --no-autoupdate
            - run
            - --token
            - $(TUNNEL_TOKEN)
            - --url
            - http://opengist-http.opengist.svc.cluster.local:6157
          env:
            - name: TUNNEL_TOKEN
              valueFrom:
                secretKeyRef:
                  name: opengist-tunnel-token
                  key: token
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              cpu: 200m
              memory: 128Mi
```

{: .prompt-warning}
The OpenGist Helm chart creates the HTTP service as **`opengist-http`** on port `6157`, not `opengist` on `6157`. The Cloudflare Tunnel hostname rule must point to `http://opengist-http.opengist.svc.cluster.local:6157`. If you use `opengist.opengist.svc.cluster.local`, you'll get a 502 from the tunnel and spend 20 minutes wondering why 😅. The initial rule pointed to the non-existent `opengist.opengist.svc.cluster.local:6157` — corrected to `opengist-http.opengist.svc.cluster.local:6157` after the first failed request.

## Step 8 — Observability

No service is done until it's observable. This is the homelab religion. OpenGist gets:

1. **ServiceMonitor** — built into the Helm chart, we just enabled it
2. **PrometheusRule** — CPU and memory alert thresholds
3. **AlertmanagerConfig** — route alerts to Mattermost
4. **Loki rule** — alert on non-2xx HTTP responses in logs
5. **Grafana dashboard** — provisioned via ConfigMap

The Prometheus rule watches for CPU and memory above requests (warning) and above 90% of limits (critical):

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: opengist-resource-alerts
  namespace: opengist
  labels:
    release: kube-prometheus-stack
spec:
  groups:
    - name: opengist.resources
      interval: 30s
      rules:
        - alert: OpenGistCPUAboveRequest
          expr: |
            sum by (pod, container, namespace) (
              rate(container_cpu_usage_seconds_total{namespace="opengist", container!=""}[5m])
            ) >
            sum by (pod, container, namespace) (
              kube_pod_container_resource_requests{namespace="opengist", resource="cpu", container!=""}
            )
          for: 5m
          labels:
            severity: warning
            namespace: opengist
          annotations:
            summary: "opengist/{{ $labels.pod }} CPU above request"
```

The AlertmanagerConfig routes alerts to Mattermost via webhook:

```yaml
apiVersion: monitoring.coreos.com/v1alpha1
kind: AlertmanagerConfig
metadata:
  name: opengist-mattermost-alerts
  namespace: opengist
  labels:
    release: kube-prometheus-stack
spec:
  route:
    receiver: opengist-mattermost
    matchers:
      - name: namespace
        value: opengist
        matchType: "="
  receivers:
    - name: opengist-mattermost
      webhookConfigs:
        - urlSecret:
            name: opengist-mattermost-webhook-url
            key: url
          sendResolved: true
          maxAlerts: 10
```

And the Grafana dashboard is a ConfigMap with `grafana_dashboard: "1"` label — Grafana's sidecar auto-imports it:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: opengist-dashboard
  namespace: observability
  labels:
    grafana_dashboard: "1"
  annotations:
    grafana.folder: "opengist"
data:
  opengist-dashboard.json: |
    {
      "title": "OpenGist",
      "uid": "opengist-overview",
      "tags": ["opengist", "homelab"],
      "timezone": "Europe/Berlin",
      "schemaVersion": 36,
      "refresh": "30s",
      "panels": [
        {
          "id": 1,
          "title": "Pod CPU",
          "type": "timeseries",
          "targets": [
            {
              "expr": "sum by (pod) (rate(container_cpu_usage_seconds_total{namespace=\"opengist\", container!=\"\"}[5m]))",
              "legendFormat": "{{ pod }}"
            }
          ],
          "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
        },
        {
          "id": 2,
          "title": "Pod Memory",
          "type": "timeseries",
          "targets": [
            {
              "expr": "sum by (pod) (container_memory_working_set_bytes{namespace=\"opengist\", container!=\"\"})",
              "legendFormat": "{{ pod }}"
            }
          ],
          "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
        }
      ]
    }
```

![observability dashboard](./../assets/images/2026-07-29/observability.png)

## Step 9 — Wire everything into kustomization.yaml

All these files need to be listed in `apps/kustomization.yaml` so Flux picks them up:

```yaml
  # OpenGist namespace
  - opengist/namespace.yaml
  # Helm repository
  - opengist/opengist-helm-repository.yaml
  # SOPS-encrypted secrets
  - opengist/opengist-db-credentials.sops.yaml
  - opengist/opengist-minio-backup-creds.sops.yaml
  - opengist/opengist-oidc-client.sops.yaml
  - opengist/opengist-config.sops.yaml
  - opengist/opengist-tunnel-token.sops.yaml
  - opengist/opengist-mattermost-webhook-url.sops.yaml
  # CNPG cluster + backups
  - opengist/postgres-cluster.yaml
  - opengist/objectstore.yaml
  - opengist/scheduled-backup.yaml
  # OMV NFS storage for OpenGist data
  - opengist/opengist-data-pv.yaml
  - opengist/opengist-data-pvc.yaml
  # OpenGist HelmRelease
  - opengist/opengist-helm-release.yaml
  # Cloudflare Tunnel for gist.example.com
  - opengist/cloudflared-opengist-deployment.yaml
  - opengist/opengist-tunnel-ingress-configmap.yaml
  # Observability
  - opengist/opengist-prometheus-rules.yaml
  - opengist/opengist-alertmanager-config.yaml
  - opengist/opengist-loki-rule.yaml
  - opengist/opengist-dashboard-configmap.yaml
```

Then validate:

```bash
cd ~/Projects/homelab-2nd
kubectl kustomize apps > /tmp/rendered-apps.yaml
```

If that succeeds with no errors, you're good. Commit, push, and let Flux reconcile.

## The problems I hit (so you don't have to)

![debugging saga](./../assets/images/2026-07-29/debugging-saga.png)

### Problem 1: SOPS files not actually created

`kubectl kustomize apps` failed with `no such file or directory` for the SOPS secrets. A previous shell session reported it had copied the encrypted files into `apps/opengist/`, but only the Mattermost webhook secret actually landed. The `cp` step silently failed for the rest.

**Fix:** Re-generated the plaintext secrets, ran `sops --encrypt --in-place`, then copied with explicit verification. Ran a `grep '^sops:'` on every `*.sops.yaml` to confirm encryption metadata was present.

**Lesson:** Always verify file existence after a batch of `cp` operations, especially when the command runs inside a sandbox that may hide errors.

### Problem 2: Wrong HelmRelease values (the copy-paste tax)

I already told you about this one — I used `bjw-s/common` keys instead of the OpenGist chart's own keys. But let me drive the point home: **every Helm chart is different.** Some use `bjw-s/common` as a library chart. Some don't. The OpenGist chart has its own service/ingress/persistence structure. Read the chart's `values.yaml` before writing your overrides.

### Problem 3: Authentik RedirectURI dataclass

Covered above. `RedirectURI` dataclass instances, not strings. This pitfall was already documented in the homelab-gitops skill. I should have opened it earlier instead of debugging from scratch. Read your own docs, people 😅.

### Problem 4: Cloudflare Tunnel service name mismatch

The Helm chart creates the HTTP service as `opengist-http` (not `opengist`). The Cloudflare Tunnel rule initially pointed to `opengist.opengist.svc.cluster.local:6157` — which doesn't exist. 502 from the tunnel. Fixed to `opengist-http.opengist.svc.cluster.local:6157`.

### Problem 5: CrashLoopBackOff after reboot

After a full reboot of `homelab-2nd`, the `opengist` pod entered `CrashLoopBackOff` with 24+ restarts:

```
FATAL: password authentication failed for user "opengist" (SQLSTATE 28P01)
```

**Root cause:** The `db-uri` inside `apps/opengist/opengist-config.sops.yaml` had been replaced with a redacted placeholder (`postgres://opengist:***@...`) during an earlier manual edit, rather than the real password from `opengist-db-credentials.sops.yaml`. On first deployment it worked because CNPG created the user with the real password and the app had cached the working config. After the reboot, the pod re-read the broken Secret and could no longer authenticate.

**Fix:** Decrypted both SOPS secrets, rebuilt `opengist-config` with the real `secret-key` and `db-uri` using the password from `opengist-db-credentials`, re-encrypted, committed, let Flux reconcile. Deleted the pod to force a clean restart. Came up healthy.

**Lesson:** Never edit SOPS-encrypted config files by hand or let redacted placeholders slip into Git. Always regenerate from the canonical credential secret and re-encrypt. The blog security scanner is a safety net — but it can also quietly replace real values with `***` placeholders if you're not careful. Double-check after every scan.

{: .prompt-danger}
A redacted `***` in a SOPS-encrypted config file looks fine in a diff review — it's hidden behind encryption. But when the pod mounts that Secret and reads the value, it gets the literal string `***` as the password. That's a CrashLoopBackOff waiting to happen.

## Verification — how to know it's alive

After Flux reconciles everything, here's the verification checklist I ran:

```bash
# Flux reconciliation
gotk reconcile kustomization -n flux-system apps --with-source

# CNPG cluster healthy
kubectl -n opengist get cluster
kubectl -n opengist get pods

# HelmRelease
kubectl -n opengist get helmrelease opengist
kubectl -n opengist get pods

# NFS mount
kubectl -n opengist exec deploy/opengist -- df -h /opengist
kubectl -n opengist exec deploy/opengist -- ls -la /opengist

# Cloudflare Tunnel
kubectl -n opengist get pods -l app.kubernetes.io/name=cloudflared-opengist

# Public URL
curl -I https://gist.example.com

# SSO: hit the URL, click "Login with Authentik"
# Expected: redirect to auth.example.com, back to gist.example.com, logged in

# Metrics
kubectl -n opengist get servicemonitor
kubectl -n opengist exec deploy/opengist -- curl -s http://127.0.0.1:6158/metrics | head

# Backups
kubectl -n opengist get scheduledbackup
kubectl -n opengist get backups
```

![it works](./../assets/images/2026-07-29/it-works.png)

All green ✅. SSO login works for both `akadmin` (me) and the wife account. Gist creation works. Registration is disabled — only "Connect with Authentik account" button is visible.

One more thing: after the first OIDC login as admin, I disabled local signup and the local login form through the admin panel:

```sql
UPDATE admin_settings SET value='1' WHERE key='disable-signup';
UPDATE admin_settings SET value='1' WHERE key='disable-login-form';
```

{: .prompt-warning}
OpenGist's `disable-signup` and `disable-login-form` settings live in the Postgres `admin_settings` table, **not** in `config.yml`. This means a fresh install requires a one-time manual step. Not strictly GitOps, but documented honestly. If we ever rebuild the cluster, these two SQL commands need to run after the first admin login.

## What I learned

1. **A chart's `values.yaml` is the source of truth, not your previous HelmRelease.** The OpenGist chart uses upstream keys (`service.http.port`, `service.metrics.serviceMonitor`) — do not paste `bjw-s/common` patterns into it. Every chart is a snowflake 🧊.

2. **SOPS files must be verified after creation.** A batch copy inside a sandbox can silently fail. Always `ls` and `grep '^sops:'` before committing.

3. **Authentik `redirect_uris` are dataclass instances in 2026.5.x.** Strings will blow up with `TypeError: asdict() should be called on dataclass instances`. Read your own skill docs before debugging 😅.

4. **Static `config.yml` + dynamic env vars is a clean split.** Keep provider metadata in `config.yml`, put credentials in a separate Secret consumed by the chart's `envFromSecrets`. Rotatable without touching the config file.

5. **NFS for Git repositories is deliberate, not lazy.** Git wants POSIX semantics and a stable path. OMV NFS on a real disk gives us durability. `local-path` would be fast but not durable — and `homelab-2nd` is a laptop, not a server.

6. **CNPG + OMV MinIO is the homelab backup religion.** Every Postgres-backed service gets the same pattern: live data on `local-path`, backups/WAL to OMV MinIO via the Barman Cloud plugin. Copy-paste the ObjectStore + ScheduledBackup manifests, change the bucket name, done.

7. **No service is done until it is observable.** Prometheus rules, Alertmanager route, Loki rule, and Grafana dashboard all ship with the app — not as an afterthought. This is non-negotiable in the homelab.

8. **Never let redacted placeholders slip into SOPS-encrypted configs.** The `***` looks fine in a diff (it's encrypted) but the pod gets the literal `***` as a password. CrashLoopBackOff at the next reboot. Always regenerate from the canonical credential secret and re-encrypt.

## What's next

- Enable SSH Git access through a separate Cloudflare Tunnel (currently disabled)
- Add a CNPG init container or post-deploy Job that runs the `disable-signup` / `disable-login-form` SQL automatically, so a fresh install is fully GitOps-managed
- Maybe add a second OpenGist replica with NFS read-many if we ever need HA (we don't, but it's fun to think about)
- Continue the KubeCraft journey — I've been experimenting heavily with Kubernetes and I have more services to deploy 🎸

## ADR

I wrote [ADR-009](https://github.com/gulasz101/homelab-2nd/blob/main/docs/adr/adr-009-opengist-storage-ingress-sso.md) for this deployment. It covers the storage decision (NFS vs local-path vs S3), the ingress decision (Cloudflare Tunnel vs K8s Ingress), the SSO decision (Authentik OIDC vs local accounts), and the backup decision (CNPG + OMV MinIO). If you want the "why" behind the "what", that's where it lives.

Cheers! 🎸
