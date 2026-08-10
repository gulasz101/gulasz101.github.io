---
# the default layout is 'page'
icon: fas fa-info-circle
order: 4
---

# About Me

## Wojciech Guła — DevOps / Infrastructure Engineer

**13+ years building production systems.** From introducing Docker to a Swiss SaaS company in 2013 to operating a self-hosted Kubernetes platform with 55+ workloads today.

Currently pivoting from Engineering Manager to IC role for hands-on infrastructure work. Based in Düsseldorf, Germany → relocating to Poland.

- 📧 [gula.wojciech@gmail.com](mailto:gula.wojciech@gmail.com)
- 🔗 [LinkedIn](https://www.linkedin.com/in/wojciech-guła-57797070/) · [GitHub](https://github.com/gulasz101) · [Homelab Repo](https://github.com/gulasz101/homelab-2nd)
- 🎸 Bass player · 🥦 Vegetarian · 📷 Amateur photographer at [insidepumpkin.com](https://insidepumpkin.com)

---

## What I Do

I build and operate infrastructure that stays quiet at 3 AM. My work spans three areas:

### DevOps & Platform Engineering

At METRO Markets GmbH, I led the transformation of a WMS platform serving **40%+ of company revenue** — the platform that 150 warehouse staff depend on to do their jobs.

- **Reduced deployment downtime from 30–45 min to zero-downtime rolling releases** (multiple deploys per day)
- **Zero production incidents** over the last 3 months (down from ~8/month)
- Rebuilt CI/CD from "build → push → festival of Sentry errors" to full guardrails: security scans, unit tests, Cypress E2E, Sonar, separate DB migration jobs
- Cut PostgreSQL query latency from tens of seconds to sub-second using `pg_stat_statements`, `pg_badger`, and Google Query Insights
- Grafana alerting, log-based metrics, K6 performance regression tests, rotating support hero role
- Team throughput improved ~6× over two years

### AI Infrastructure

Self-hosted AI platform on Kubernetes — not a managed API wrapper:

- **LiteLLM proxy** with 40+ model aliases, multi-provider routing (z.ai, Mistral, OpenRouter, Ollama, LM Studio), virtual keys, SSO admin UI
- **Open WebUI** with OIDC-only login, LiteLLM backend, pgvector RAG, Firecrawl web search
- **GPU inference** — Ollama serving nomic-embed-text on GTX 970M via NVIDIA Device Plugin + RuntimeClass
- **Firecrawl v2 self-hosted** — API + worker + Playwright scraper + Redis + RabbitMQ, LAN-only, observability wired
- Agentic coding harnesses (Hermes, OpenCode, Claude Code, GitHub Copilot) as daily driver

### Observability

OpenTelemetry from proof-of-concept to company-wide adoption at METRO:

- Extended an early OTel SDK draft into a production-grade PHP library (Composer-installable) covering PDO, Laravel, Symfony, Google Pub/Sub, and RabbitMQ tracing
- Built PHP base Docker images with OTel extension included by default
- Advocated adoption through demos, Tech Day talks, and education sessions
- **Speaker**, Platform Engineering Meet-Up Cologne, Mar 2025 — *"From Chaos to Clarity: How OpenTelemetry Makes Microservice Monitoring Effortless"*

---

## Self-Hosted Kubernetes Platform (Homelab)

> **Public repo:** [github.com/gulasz101/homelab-2nd](https://github.com/gulasz101/homelab-2nd) — 315+ commits, 240 YAML files, 67 SOPS-encrypted secrets, 10 ADRs
> **Tech blog:** [gulasz101.github.io](https://gulasz101.github.io) — documenting real infrastructure work

A single-node k3s cluster running ~55 Deployments/StatefulSets across 20 namespaces, all delivered via **Flux CD** from a public GitHub repo. **GitOps is law** — everything in a public repo, zero plaintext secrets.

| Layer | Stack |
|-------|-------|
| **Cluster** | k3s, Flux CD v2.8.8, SOPS/age secrets |
| **Database** | CloudNativePG — 8 Postgres clusters, WAL archiving to MinIO S3 |
| **Storage** | MinIO on OpenMediaVault NAS (S3 + NFS) |
| **Ingress** | 9 Cloudflare Tunnels — no router ports opened |
| **Auth** | Authentik — central OIDC/OAuth2 for all services |
| **Observability** | LGTM stack — Prometheus, Grafana, Loki, Tempo, OTel Collector DaemonSet |
| **GPU** | NVIDIA Device Plugin + RuntimeClass, Ollama embeddings |
| **Security** | Nightly scans: gitleaks, trivy, kubeconform, kube-score, pluto |

Cold boot recovery from full cluster outage with zero data loss. Rebuildable compute node from repo + backups. Every service is observable.

Member of [kubecraft.dev](https://www.kubecraft.dev/) community — following DevOpsOS, HomeLabOS, and JobMagnetOS courses.

---

## Technical Skills

| Category | Technologies |
|----------|-------------|
| **Kubernetes** | k3s, GKE (application-level), Flux CD, Helm, Kustomize, NVIDIA Device Plugin, k9s |
| **AI Infrastructure** | LiteLLM, Open WebUI, Ollama, pgvector, Firecrawl, GPU scheduling |
| **Observability** | Prometheus, Grafana, Tempo, K6, Loki, Alertmanager, OpenTelemetry, Sentry |
| **Databases** | PostgreSQL (CloudNativePG), MySQL, Redis, Elasticsearch, pgvector |
| **Security** | SOPS/age, Authentik OIDC, Cloudflare Tunnels, gitleaks, trivy, kubeconform |
| **CI/CD** | Flux GitOps, GitHub/GitLab CI, ArgoCD (review level), Cypress E2E, Sonar, TDD |
| **Languages** | Python, PHP 7/8, SQL, Bash, JavaScript/TypeScript |
| **Cloud** | GCP (application-level: Cloud SQL, Pub/Sub, GKE monitoring) |
| **Messaging** | RabbitMQ, Redis, Google Pub/Sub |

---

## Experience

### Engineering Manager / Technical Team Lead — WMS Platform
**METRO Markets GmbH** | Düsseldorf, Germany | *Jun 2023 – Present*

Led the turnaround of a warehouse management system serving 40%+ of company revenue. Built the team from 4 to 8 internal engineers (managing up to 11 concurrent reports including 3 external agencies). Rebuilt the entire delivery process from scratch — from Monday-only deployments with 30–45 min downtime to multiple zero-downtime releases per day with ~90% code coverage.

Planned and executed an 18-month Odoo Enterprise → Community Edition migration (v15 → v17), replacing the vendor mobile WMS app with in-house web apps. Designed push-only network topology for the migration, maintained rollback fallback throughout, rehearsed the cutover three times, and executed on release night with full rollback capability.

### Software Development Engineer — Developer Experience
**METRO Markets GmbH** | Düsseldorf, Germany | *Jan 2023 – Jun 2023*

Owned OpenTelemetry adoption from proof-of-concept to company-wide. Built the OTel SDK into a production-grade PHP library, drove cross-team Backstage adoption, and served as interim Team Lead for the Delivery Experience team (France warehouse launch).

### Software Development Engineer — Fulfilment & Delivery Experience
**METRO Markets GmbH** | Düsseldorf, Germany | *Feb 2021 – Jan 2023*

Backend engineer on microservices handling sale order flow, stock synchronisation, and carrier integrations across multiple countries. Co-founded the Delivery Experience team. Consistently rated high-performing (Level 4 High) on every review.

### PHP Developer → Senior Engineer / Informal Architect
**Lourens Systems GmbH** | Remote (Warsaw) | *Oct 2013 – Dec 2020*

Full ownership of two SaaS products: **Pingen** (physical letter delivery) and **smallinvoice** (invoicing/ERP). Introduced Docker, built REST APIs consumed by enterprise integrators (including SAP), authored a Composer SDK, migrated core from Lumen to Laravel, led Solr → Elasticsearch migration, and introduced TDD with 6000+ PHPUnit tests.

### PHP Developer
**Mint Media** | Poland | *Sep 2011 – Sep 2013*

Full-stack engineer building Facebook applications — quizzes, games, and interactive campaigns for external clients. Shipped under constant deadlines, always on time.

---

## Speaking & Publications

- **Platform Engineering Meet-Up, Cologne — Mar 2025:** *"From Chaos to Clarity: How OpenTelemetry Makes Microservice Monitoring Effortless"*
- **Metro Markets Tech Days, Oct 2023:** *"Introduction to OpenTelemetry"*
- **Metro Markets Tech Days, May 2022:** *"Test Driven Development and its benefits"*
- **Metro Markets Tech Talks, Sep 2021:** *"Mutagen — how to speed up local development when docker is so slow"*
- **Technical Blog:** [gulasz101.github.io](https://gulasz101.github.io) — Kubernetes, GitOps, observability, AI infrastructure
- **Public GitOps Repo:** [github.com/gulasz101/homelab-2nd](https://github.com/gulasz101/homelab-2nd)

---

## Education

**Information Technology** (4 years completed — degree not conferred)
Kielce University of Technology | Poland | 2004–2008

## Languages

- **Polish** — Native
- **English** — Full Professional Proficiency (working in English since 2013)