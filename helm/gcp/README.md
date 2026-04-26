# GCP Configuration

## Prerequisites

- `gcloud` CLI installed and authenticated
- Target project: `project-3cec667f-8135-4778-9b4`

---

## Cluster

### Option A — Autopilot (default, no GSM support)

Fully managed nodes. Use for simple deployments without Workload Identity or GSM.

```bash
make -f helm/gcp/Makefile cluster-create
```

| Flag | Value | Notes |
|------|-------|-------|
| `--region` | `us-central1` | Regional — nodes spread across zones |
| `--release-channel` | `regular` | Stable, auto-upgraded |
| `--cluster-ipv4-cidr` | `/17` | ~32k pod IPs |
| `--no-enable-google-cloud-access` | — | Pods cannot access GCP APIs directly |
| `--binauthz-evaluation-mode` | `DISABLED` | Binary Authorization off |

Connect:
```bash
gcloud container clusters get-credentials autopilot-cluster-1 \
  --region us-central1 \
  --project project-3cec667f-8135-4778-9b4
```

---

### Option B — Standard (GSM-ready)

1 node, `e2-standard-2` (2 vCPU / 8 GB RAM). Enables Workload Identity — required for GSM and External Secrets Operator.

```bash
make -f helm/gcp/Makefile cluster-create-standard
make -f helm/gcp/Makefile cluster-credentials
```

| Flag | Value | Notes |
|------|-------|-------|
| `--zone` | `us-central1-a` | Zonal — cheaper than regional |
| `--machine-type` | `e2-standard-2` | 2 vCPU / 8 GB — enough for ASM + 2 apps + ESO |
| `--num-nodes` | `1` | Single node for dev/learning |
| `--workload-pool` | `PROJECT_ID.svc.id.goog` | Enables Workload Identity (GSM prerequisite) |
| `--gateway-api` | `standard` | Keeps GKE Gateway API working |
| `--fleet-project` | `PROJECT_ID` | ASM managed mesh registration |
| `--enable-ip-alias` | — | VPC-native networking (required for GKE Gateway) |

---

## Products Chart (`helm/gcp/products/`)

Deploys the `products` Spring Boot service to GCP. Unlike the local Helm chart, this variant is designed for GKE with Workload Identity, Artifact Registry images, and GCP-native health check integration.

### Templates

| Template | Resource | Purpose |
|----------|----------|---------|
| `configmap.yaml` | `ConfigMap` | Injects `ENV_INFO`, `SERVER_PORT`, `LOG_LEVEL_ROOT`, `LOG_LEVEL_APP`, `SPRING_PROFILES_ACTIVE` as env vars |
| `deployment.yaml` | `Deployment` | Runs the app container; mounts the ConfigMap, sets resource limits, attaches the ServiceAccount for Workload Identity |
| `service.yaml` | `Service` (ClusterIP) | Exposes port 80 → targetPort 8080 inside the cluster |
| `serviceaccount.yaml` | `ServiceAccount` | Annotated with `iam.gke.io/gcp-service-account` to enable Workload Identity Federation |
| `gateway.yaml` | `HealthCheckPolicy` | Configures the GCP L7 load balancer health check cadence against `/actuator/health/readiness` |

### Key Design Decisions

- **Workload Identity** — the `ServiceAccount` is annotated so the pod can impersonate the GCP service account `products-sa@<PROJECT_ID>.iam.gserviceaccount.com` without storing credentials. Required for Secret Manager access.
- **QoS: Guaranteed** — CPU and memory `requests` equal `limits` (250m / 256Mi), preventing the pod from being throttled or evicted under node pressure. (to prevent extra costs)
- **Image** — pulled from Artifact Registry (`gcr.io/<PROJECT_ID>/products:jvm`) with `pullPolicy: Always`; built via Jib through the Makefile.

### Values Overview

| Key | Default | Dev override | Prod override |
|-----|---------|-------------|---------------|
| `replicaCount` | `1` | `1` | `2` |
| `config.envInfo` | `gcp` | `gcp-dev` | `gcp-prod` |
| `spring.profile` | `dev` | `dev` | `prod` |
| `readinessProbe.initialDelaySeconds` | `30` | — | — |
| `livenessProbe.initialDelaySeconds` | `60` | — | — |

### Deploy

```bash
# Dev
make -f helm/gcp/Makefile deploy APP=products NAMESPACE=dev

# Prod
make -f helm/gcp/Makefile deploy APP=products NAMESPACE=prod
```

### Dependencies

The products chart assumes the following are already deployed:

1. **`helm/gcp/infra`** — GKE Gateway + HTTPRoute that routes `/rbn/products` → `/products` on this service.
2. **`helm/gcp/istio`** — `AuthorizationPolicy` resources that enforce `x-api-key` header validation and restrict access to the `users` service account.
3. **`helm/gcp/iac`** (Terraform) — GCP IAM bindings that grant the `products-sa` service account `roles/secretmanager.secretAccessor` and the Workload Identity User role.
