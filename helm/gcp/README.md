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
