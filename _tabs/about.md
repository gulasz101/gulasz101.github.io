---
# the default layout is 'page'
icon: fas fa-info-circle
order: 4
---

# About Me

## Wojciech Guła — DevOps / Infrastructure Engineer

**13+ years building production systems** — from introducing Docker to a Swiss SaaS company in 2013 to operating a self-hosted Kubernetes platform with 55+ workloads today. Working in IT since 2009; first software engineering position in 2011.

Currently pivoting from Engineering Manager to IC role for flexibility and hands-on infrastructure work. Based in Düsseldorf, Germany → relocating to Poland.

- 📧 [gula.wojciech@gmail.com](mailto:gula.wojciech@gmail.com)
- 🔗 [LinkedIn](https://www.linkedin.com/in/wojciech-guła-57797070/) · [GitHub](https://github.com/gulasz101) · [Homelab Repo](https://github.com/gulasz101/homelab-2nd)
- 🎸 Bass player · 🥦 Vegetarian · 📷 Amateur photographer at [insidepumpkin.com](https://insidepumpkin.com)

---

## Professional Summary

Infrastructure Engineer with 13+ years building production systems — from introducing Docker to Lourens Systems GmbH (Pingen and smallinvoice) to operating AI infrastructure on Kubernetes. Currently pivoting from Engineering Manager to IC role for flexibility and hands-on infrastructure work.

Led a WMS platform serving 40%+ of company revenue at METRO Markets, where downtime meant 150 warehouse staff unable to work. Reduced PostgreSQL query latency from tens of seconds to sub-second, rebuilt CI/CD pipelines from "build → push → festival of Sentry errors" to full guardrails, and planned an 18-month Odoo migration with push-only network topology and rollback fallback. Replacing Odoo EE barcode app with micro web apps supporting all the "on the floor" operations.

Operating a self-hosted GitOps-driven Kubernetes platform (k3s) with 55 workloads across 15 namespaces — including an AI gateway with 15+ model aliases, GPU inference, CloudNativePG with S3 backups, full LGTM observability, SOPS/age secrets, Authentik SSO, and Cloudflare Tunnels. Public repo: [github.com/gulasz101/homelab-2nd](https://github.com/gulasz101/homelab-2nd) (315+ commits, 240 YAML files, 10 ADRs).

**Target roles:** AI Infrastructure Engineer (priority 1), Cloud Engineer, DevOps Engineer. Remote-first, English-speaking, based in Poland.

---

## Professional Experience

### Engineering Manager / Technical Team Lead — WMS Platform
**METRO Markets GmbH** | Düsseldorf, Germany | *Jun 2023 – Present*

*Formally appointed Nov 2023; interim Team Lead Jun–Aug 2023 (Delivery Experience team, France warehouse launch)*

**Starting point — new domain, new team, new everything:**

Stepped into this role having to rapidly acquire deep knowledge of warehouse operations — from goods receipt and pick/pack flows to barcode scanning processes on the warehouse floor — while simultaneously diagnosing the state of the platform and rebuilding the team. The WMS (Odoo) had already been rolled out to three warehouses; the fourth — the largest warehouse in Germany — was pending. On joining: the team consisted of two internal and three external Odoo engineers, with no classical software engineering skills (no SQL knowledge, no Docker, no cloud fundamentals). The mobile apps were critically slow, production deployments happened only on Mondays to allow the full week to recover from incidents, and there was zero observability.

A first visit to the most mature warehouse confirmed the severity: the system was nearly unusable, and operations staff were compensating with enormous amounts of manual work. Initial diagnosis: the team needed proper software engineers alongside Odoo specialists, the entire delivery process needed to be rebuilt from scratch, and deep collaboration with warehouse operations needed to start immediately — even when those early conversations were hostile due to years of poor software quality.

This role also demanded leading across significant cultural and background diversity: the team included engineers and agency contractors from multiple countries and professional backgrounds (Odoo specialists, classical software engineers, frontend engineers) — each requiring a different management approach, communication style, and growth path. Building trust and cohesion across this mix, under sustained delivery pressure, was as much of a leadership challenge as the technical turnaround.

**Delivery & Operational Excellence (DevOps / Infrastructure focus):**

*Before:* ~8 production incidents/month, Monday-only deployments with 30–45 min warehouse downtime, zero test coverage, no observability, "works on my laptop" as the release standard. CI/CD pipeline was build → push to low env → push to prod with no quality gates — the first sign of trouble was a festival of Sentry errors in production. Root causes included unindexed database queries causing full table scans, and a caching implementation sending 25–50 MB of uncompressed JSON per request.

*After:*
- Zero production incidents over the last 3 months
- Multiple zero-downtime rolling releases per day
- ~90% code coverage; Cypress E2E automated test suite before every deployment; Grafana K6 performance regression tests
- Full CI/CD guardrails: security scans, extensive unit testing, Cypress E2E, separate DB migration jobs, Sonar analysis
- Grafana alerting with templated Slack notifications, and log-based metrics providing proactive signal on system health — covering both technical health and business process monitoring
- Introduced a rotating "support hero" role (bi-weekly) — kept the rest of the team focused on delivery instead of firefighting
- Team throughput improved approximately 6× over two years; sprint reviews regularly exceed 45 minutes due to volume of shipped work

**PostgreSQL performance:**
- Used pg_stat_statements, pg_badger for daily query log analysis with automated reports, and Google Query Insights (GCP Cloud SQL) to systematically identify slowest queries across critical warehouse operations; applied targeted indexing strategies and rewrote inefficient query patterns — reduced execution times from tens of seconds to sub-second or low-second ranges for high-frequency paths
- Performed this work while managing full EM responsibilities including team delivery, stakeholder communication, and operational continuity — treated as an individual contributor responsibility when no other engineer on the team had SQL expertise

**Odoo Enterprise → Community Edition migration:**
- Planned and executed an 18-month migration from Odoo Enterprise to Community Edition (v15 → v17), replacing the vendor mobile WMS app with a suite of fully in-house web apps — one per warehouse process
- Designed push-only network topology for the migration: GCP Compute jump VM managed remote DB migration against Odoo factory servers — no inbound connections from Odoo servers to METRO infrastructure
- Isolated RabbitMQ consumers (XML-RPC order transformers) during migration windows by scaling them down — stopped order flow into Odoo without losing messages
- Kept Odoo v15 Enterprise running as rollback fallback throughout the migration; maintained ability to redeploy v15 EE if warning signs appeared during cutover
- Prioritised migration order by operational criticality; collaborated with a UX designer on each application, delivering UX and performance improvements alongside the technical migration
- Ran two parallel main branches for an extended period; collaborated with infra to provision a production-like environment for K6 stress testing and Cypress E2E validation
- Rehearsed the full cutover scenario three times; executed a detailed live-tracked checklist on release night with full rollback capability maintained until the final go/no-go
- Critical rollout executed within first 6 months with the team. Provided trainings to warehouse stakeholders and rolled out the new system; approximately 3 months were required to recover from unforeseen issues before shifting focus to rebuilding the team
- After recovery from the German warehouse rollout, spent the following ~2 years replacing Odoo proprietary barcode apps one by one with in-house alternatives — a deliberate, sustainable pace that avoided burnout and ensured quality
- Collaborated with cloud infra team on GCP/Kubernetes resource planning, read replica scaling, and cost optimisation via observability data
- Managed vendor relationships and contributed to technology budget decisions, balancing cost, risk, and delivery needs
- Drove Grafana monitoring, Slack alerting, GitOps, and ADR process adoption across the team
- Speaker, Platform Engineering Meet-Up Cologne, Mar 2025 — *"From Chaos to Clarity: How OpenTelemetry Makes Microservice Monitoring Effortless"*

**Kubernetes & GCP at METRO (honest scope):**
- Read-level access to GKE across 5 GCP projects; used k9s for debugging pods, monitoring compute usage, and tuning resource requests/limits
- Reviewed and occasionally wrote Helm charts and Kustomize manifests — primarily reviewed infra team's work
- Application-level incidents only, not cluster-level on-call
- ArgoCD/Kargo GitOps migration led by infra team — supported engineers when stuck
- Built PHP wrapper for Google Pub/Sub with full emulator test suite and OpenTelemetry instrumentation
- Used Google Query Insights (Cloud SQL) for PostgreSQL performance analysis

**AI and developer experience enablement:**
- Enabled team to work with GitLab Duo and agentic coding harnesses (OpenCode / Claude Code) for the team — enabled faster refactors, safer migrations, and better onboarding; positioned as developer experience work rather than infrastructure building. Later we switched to GitHub Copilot.
- Ran workshops on effective use of these tools; monitored adoption and usage via Grafana dashboards to iterate on workflows and keep momentum going
- Built a RAG-like helper during a 2026 hackathon: pulls Sentry issues, indexes the codebase using Vertex Gemini 2.5 Flash, and suggests fixes via markdown. Pragmatic hackathon helper, not a full AI infrastructure platform.

**People Leadership & Talent Development:**
- Built WMS team from scratch — grew from 4 to 8 internal engineers, managed up to 11 concurrent reports including engineers from 3 external agencies
- Ran a structured 1:1 programme with every team member: weekly cadence, growth-focused agendas, individual development tracking — people management was the core of this role
- Designed and led onboarding from scratch — experienced engineers productive within 3 weeks, 12+ onboardings total
- Proactively sought mentorship from the People Partner (bi-weekly sessions) to develop people management skills: facilitation, conflict resolution, difficult conversations; applied this learning directly to the team
- Drove conflict resolution and team cohesion under sustained delivery pressure across a mixed internal/external structure

**Performance Management:**
- Ran 2 full PIPs with independent decision-making authority
- PIP design: 3-month plans with concrete, measurable tasks in software engineering, performance topics, and cloud infrastructure; weekly follow-up with structured progress reviews
- Invited a peer team lead to co-review PIP progress sessions — ensured transparency, credibility, and a clean paper trail with the People team
- One outcome: engineer took the PIP seriously, grew significantly, and is now considered a potential future team lead candidate
- Second outcome: termination — triggered an accelerated exit procedure due to the engineer holding high cloud infrastructure privileges, mitigating risk to the platform; worked closely with the People team to execute cleanly and professionally
- Conducted PIP processes while managing significant personal circumstances, maintaining full professionalism and team continuity throughout

**Recruitment & Hiring:**
- Led end-to-end hiring for own team: authored job specs, conducted technical and cultural interviews, made hiring decisions independently
- Actively supported the People team as an interviewer across multiple hiring processes — contributed to several successful hires still with the company
- Applied consistent assessment frameworks to raise team quality and reduce onboarding friction

---

### Software Development Engineer — Developer Experience
**METRO Markets GmbH** | Düsseldorf, Germany | *Jan 2023 – Jun 2023*

Cross-team platform ownership role — embedded across engineering, infrastructure, and product domains to improve shared developer tooling. Only engineer based in Düsseldorf while the rest of the team was in Palma de Majorca; used the geographic isolation productively to build company-wide connections that later proved valuable as a team lead.

**OpenTelemetry — from proof of concept to company-wide adoption:**
- Joined an early, incomplete OTel SDK draft (basic HTTP trace/span correlation only); extended it into a production-grade, developer-friendly library installable via Composer across both the monorepo marketplace backend and independent microservices
- Added instrumentation support for PDO, Laravel, Symfony, Google Pub/Sub, and RabbitMQ tracing via Symfony Messenger — covering the full breadth of the company's PHP communication patterns
- Collaborated with the infrastructure team to build new PHP base Docker images with the OTel extension included by default, reducing team onboarding friction
- Advocated for adoption through demos, proof of concepts, and education sessions; presented on the main stage at an internal company Tech Day
- Left the initiative in good hands — another engineer took ownership after the role ended; multiple teams now collect a baseline set of OTel signals across their backends

**Backstage (internal developer portal):**
- Contributed to deployment infrastructure: built Docker images for local development and production deployment of the Backstage instance
- Drove cross-team adoption of Backstage's YAML service catalogue configuration — reached out to teams across the organisation to ensure correct service and team indexing, including onboarding the ERP domain

**Interim Team Lead — Delivery Experience (Jun–Aug 2023):**
- Stepped in as interim team lead when the permanent lead went on extended leave — planned as one month, extended to three months due to scope
- Delivered France carrier integrations under extreme pressure, including undocumented APIs, while acting as temporary Team Lead for the Delivery Management team — ensured on-time launch and full ownership despite tight timelines and incomplete specs
- Led the team through the France warehouse launch: managed carrier integrations for a new market, coordinated directly with external carriers, maintained delivery under pressure
- Made independent decisions on engineer probation outcomes during this period
- This interim period confirmed the fit for formal leadership and led directly to the WMS Engineering Manager application

---

### Software Development Engineer — Fulfilment Team & Delivery Experience Team
**METRO Markets GmbH** | Düsseldorf, Germany | *Feb 2021 – Jan 2023*

Joined a team of 5–7 backend engineers responsible for a suite of microservices forming the integration layer between the internal ERP, two warehouse management systems, and external carriers. No dedicated QA — engineers owned full test coverage. Hired at mid-level; consistently rated high-performing (Level 4 High) on every performance review.

**Domain & systems:**
- Maintained and extended ~4 PHP/Symfony microservices handling sale order flow, supply order sync, stock synchronisation with the customer-facing e-commerce frontend, and carrier integrations
- Services communicated via RabbitMQ and REST APIs; stack included Redis and MySQL
- Responsible for keeping stock in sync across internal ERP, WMS, and marketplace frontend as the business scaled to multiple countries

**Carrier integrations & tracking:**
- Built and maintained a unified shipping label generation gateway — integrated DHL, DPD, and several country-specific carriers
- Carrier selection logic was rules-based: driven by destination country, order volume, and business criteria — grew in complexity as METRO Markets expanded geographically
- Implemented return label generation alongside outbound shipping
- Contributed to a parcel tracking service; for dropshipper carriers, applied a KPI-driven prioritisation model (sales volume × shipment share per country) to decide which carriers to integrate — scraping only after legal review and effort estimation confirmed viability

**Delivery Experience team formation:**
- As the domain matured, shipment label and tracking services were extracted into a new dedicated team — the Delivery Experience team
- Co-founded this team alongside one other engineer, operating with full autonomy under a junior project manager and no formal team lead — a self-directed unit that continued to deliver effectively

**People & growth:**
- Informally mentored a colleague transitioning from customer service into software engineering — progressed from zero to PHP developer, securing a position at Check24
- Consistently exceeded expectations on performance reviews throughout the role
- Moved into Developer Experience role motivated by desire for broader company impact and a strong personal interest in observability and developer tooling

---

### PHP Developer → Senior Engineer / Informal Architect
**Lourens Systems GmbH** | Remote (Warsaw) | *Oct 2013 – Dec 2020*

Started as an outsourced backend engineer on an external client project (watson.ch — a Swiss digital newspaper built on CakePHP, MySQL, Cassandra, and HHVM), then transitioned into full ownership of two in-house SaaS products: **Pingen** (physical letter delivery via PDF upload, operating in Switzerland and Germany) and **smallinvoice** (invoicing and lightweight ERP software). Team peaked at ~12 engineers reporting directly to the CTO, working across backend, frontend (React SPA), and native mobile (iOS/Android).

**watson.ch (first year):**
- Backend engineer providing APIs for an Angular frontend for a Swiss digital newspaper
- Stack: CakePHP, MySQL, Cassandra, HHVM (Facebook's high-performance PHP runtime)

**Pingen & smallinvoice — engineering and architecture:**
- Joined legacy PHP codebases (no framework) and progressively modernised them: introduced framework adoption, improved security posture, integrated Solr (later migrated to Elasticsearch) as a search engine
- Introduced Docker to the company — built container images and drove containerization culture across both products; the company later adopted Docker Swarm on VPS infrastructure in Switzerland based on this foundation
- Designed and built REST APIs (JSONAPI, OAuth2 with scopes, Swagger documentation) consumed by enterprise integrators (including SAP), web SPAs, and native mobile apps — targeting a "15-minute developer experience" for new integrators
- Authored and shipped a Composer SDK enabling customers to integrate with Pingen and smallinvoice APIs with minimal setup
- Migrated core application from Lumen to full Laravel after identifying performance and maintainability limits — led the migration independently
- Contributed to the rearchitecture of Pingen's backend using Laravel and Laravel Horizon for async queue processing
- Led technical discovery and rollout for the Solr → Elasticsearch migration
- Enforced Test-Driven Development (TDD) as a team practice when building new APIs at smallinvoice.ch and pingen.ch — all new endpoints shipped with tests first, using PHPUnit; established patterns that reduced regression risk during large-scale refactors
- Introduced the PHPUnit testing suite to legacy codebases and grew it to over 6000 unit tests across both products; coordinated with teammates on test design and review cycles so quality improvements were shared rather than isolated
- Acted as a technical coach for peers transitioning into backend work: reviewed test designs, helped refactor brittle integration tests into focused PHPUnit suites, and advocated for writing tests before features — kept the team moving while raising overall code quality

**Growth and independence:**
- Evolved from outsourced junior to one of the most trusted engineers in the company — full autonomy on features, technical direction, and onboarding of new engineers
- Acted as informal architect: evaluated frameworks, proposed tooling, designed APIs, set coding standards — without a formal title
- Co-designed the team's testing philosophy, including deliberate test reduction after over-testing became a maintenance burden

---

### PHP Developer
**Mint Media** | Poland | *Sep 2011 – Sep 2013*

Marketing agency building Facebook applications — quizzes, small games, and interactive campaigns for external clients.

- Full-stack engineer on a team of ~5; started as junior, quickly earned full end-to-end delivery ownership
- Built backend services and APIs consumed by Flash/ActionScript frontends for browser games, and full-stack jQuery/HTML applications for lighter campaigns
- Handled the full delivery cycle independently: database schema setup, backend logic, CSS styling from designer-cut slices, test environment setup, and production deployment
- Operated under constant high-pressure client deadlines — including overnight refactors of entire application modules driven by last-minute client pivots; always shipped on time
- Stack: PHP 5, Zend Framework 1, PostgreSQL, Subversion

---

## Self-Hosted Kubernetes Platform (Homelab)

> **Public repo:** [github.com/gulasz101/homelab-2nd](https://github.com/gulasz101/homelab-2nd) — 315+ commits, 240 YAML files, 67 SOPS-encrypted secrets, 10 ADRs
> **Tech blog:** [gulasz101.github.io](https://gulasz101.github.io) — documenting real infrastructure work

A single-node k3s cluster running ~55 Deployments/StatefulSets across 20 namespaces, all delivered via Flux CD from a public GitHub repo. Durable data lives on an OpenMediaVault NAS running MinIO S3 + NFS. Public services use dedicated Cloudflare Tunnels — no router ports opened. PostgreSQL is always CloudNativePG with S3 backups. Secrets are SOPS/age. Observability is LGTM + OpenTelemetry.

### Platform overview

| Layer | Stack |
|-------|-------|
| **Cluster** | k3s v1.35.5+k3s1, single-node control-plane, 8 vCPU, 31 GB RAM, GTX 970M GPU |
| **GitOps** | Flux CD v2.8.8, bootstrapped on main, SOPS decryption wired |
| **Database** | CNPG operator v0.29.0 — 8 healthy Postgres clusters, WAL archiving to OMV MinIO S3 |
| **Storage** | MinIO on OMV — buckets for backups, files, uploads, S3 primary storage |
| **Ingress** | 9 Cloudflare Tunnels — no router ports opened |
| **Auth** | Authentik 2026.5.4 — central OIDC/OAuth2 for Grafana, Open WebUI, Nextcloud, Karakeep, OpenGist, LiteLLM |
| **Observability** | LGTM: kube-prometheus-stack v88.2.0, Grafana v12.7.1, Loki v18.1.1, Tempo v2.2.3, OTel Collector v0.169.0 DaemonSet |
| **GPU** | NVIDIA Device Plugin v0.17.1 + RuntimeClass, Ollama embeddings on GTX 970M |

### AI/ML infrastructure

- **LiteLLM proxy** (chart v1.85.7): ~40 model aliases, virtual keys, multi-provider routing (z.ai, Mistral, OpenRouter, Ollama, LM Studio), SSO Admin UI via Authentik, CronJob key provisioner
- **Open WebUI** (chart v16.0.0): OIDC-only login, LiteLLM backend for all models, pgvector RAG on own CNPG cluster, Firecrawl web search, OpenTelemetry metrics/traces/logs
- **Firecrawl v2 self-hosted**: API + worker + Playwright scraper + Redis + RabbitMQ, LAN-only, observability wired
- **GPU embeddings**: Ollama serving nomic-embed-text on GTX 970M, NVIDIA RuntimeClass, used by docs-mcp-server
- **Honcho** (memory platform): fork of plastic-labs/honcho, built to GHCR, CNPG Postgres + Redis, LiteLLM integration

### Security & secrets

- 67 SOPS-encrypted Kubernetes Secret resources (age encryption)
- Public repo contains zero plaintext credentials
- Cloudflare Tunnels keep origin IPs hidden
- Authentik central SSO; local login forms disabled on migrated services
- Nightly security scanning: gitleaks, trivy, kubeconform, kube-score, pluto

### Reliability & DR

- Cold boot recovery from full cluster outage with zero data loss — CNPG WAL archiving to MinIO S3
- Rebuildable compute node from repo + backups; OMV is the only durable store
- Per-namespace observability: Grafana dashboards, Prometheus rules, Loki log alerts, Alertmanager → Mattermost

### KubeCraft community

- Paid member of [kubecraft.dev](https://www.kubecraft.dev/) — following DevOpsOS, HomeLabOS, and JobMagnetOS courses on Skool
- Concurrently starting advanced Linux course

---

## Technical Skills

| Category | Technologies |
|----------|-------------|
| **Kubernetes** | k3s, GKE (application-level), Flux CD, Helm, Kustomize, NVIDIA Device Plugin, k9s |
| **AI Infrastructure** | LiteLLM, Open WebUI, Ollama, pgvector, Firecrawl, GPU scheduling |
| **AI Tooling** | Agentic harnesses (Hermes, OpenCode, Claude Code, GitLab Duo, GitHub Copilot) — daily driver |
| **Observability** | Prometheus, Grafana, Grafana Tempo, Grafana K6, Loki, Alertmanager, OpenTelemetry, Sentry, incidents.io |
| **Databases** | PostgreSQL (CloudNativePG), MySQL, Redis, Elasticsearch, pgvector |
| **Security** | SOPS/age, Authentik OIDC, Cloudflare Tunnels, gitleaks, trivy, kubeconform |
| **CI/CD & Quality** | Flux GitOps, GitHub/GitLab CI, ArgoCD (review level), Cypress E2E, Sonar, zero-downtime deployments, TDD (PHPUnit/Pest) |
| **Languages** | Python, PHP 7/8, SQL, Bash, JavaScript/TypeScript |
| **Cloud** | GCP (application-level: Cloud SQL, Pub/Sub, GKE monitoring, Compute jump VM) |
| **Developer Tooling** | Neovim/LazyVim, k9s, tmux, terminal-first workflow |
| **Messaging & Data** | RabbitMQ, Redis, Google Pub/Sub, MySQL, MariaDB, Cassandra |
| **Platforms** | Linux (Debian/Fedora), macOS, Docker, self-hosted infrastructure |

---

## Speaking & Publications

- **Platform Engineering Meet-Up, Cologne — Mar 2025:** *"From Chaos to Clarity: How OpenTelemetry Makes Microservice Monitoring Effortless"*
- **Metro Markets Tech Days, Düsseldorf — October 2023:** *"Introduction to OpenTelemetry"*
- **Metro Markets Tech Days, Düsseldorf — May 2022:** *"Test Driven Development and its benefits"*
- **Metro Markets Tech Talks, Düsseldorf — September 2021:** *"Mutagen — how to speed up local development when docker is so slow"*
- **Technical Blog:** [gulasz101.github.io](https://gulasz101.github.io) — posts on Kubernetes, GitOps, observability, AI infrastructure, OpenTelemetry with Odoo, LazyVim, infrastructure tooling
- **Public GitOps Repo:** [github.com/gulasz101/homelab-2nd](https://github.com/gulasz101/homelab-2nd) — 315+ commits, 240 YAML files, 67 SOPS-encrypted secrets, 10 ADRs

---

## Education

**Information Technology** *(4 years completed — degree not conferred)*
Kielce University of Technology | Kielce, Poland | 2004–2008

## Languages

- **Polish** — Native
- **English** — Full Professional Proficiency (working in English since 2013)