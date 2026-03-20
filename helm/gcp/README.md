# GCP Configuration

## Prerequisites

- `gcloud` CLI installed and authenticated
- Target project: `project-3cec667f-8135-4778-9b4`

---

## Cluster

### Create Autopilot Cluster

```bash
gcloud beta container \
  --project "project-3cec667f-8135-4778-9b4" \
  clusters create-auto "autopilot-cluster-1" \
  --region "us-central1" \
  --release-channel "regular" \
  --enable-dns-access \
  --enable-k8s-tokens-via-dns \
  --enable-k8s-certs-via-dns \
  --enable-ip-access \
  --no-enable-google-cloud-access \
  --network "projects/project-3cec667f-8135-4778-9b4/global/networks/default" \
  --subnetwork "projects/project-3cec667f-8135-4778-9b4/regions/us-central1/subnetworks/default" \
  --cluster-ipv4-cidr "/17" \
  --binauthz-evaluation-mode=DISABLED \
  --fleet-project=project-3cec667f-8135-4778-9b4
```

| Flag | Value | Notes |
|------|-------|-------|
| `--region` | `us-central1` | |
| `--release-channel` | `regular` | Stable, auto-upgraded |
| `--cluster-ipv4-cidr` | `/17` | ~32k pod IPs |
| `--binauthz-evaluation-mode` | `DISABLED` | Binary Authorization off |
| `--no-enable-google-cloud-access` | — | No external Google API access from nodes |

### Connect to Cluster

```bash
gcloud container clusters get-credentials autopilot-cluster-1 \
  --region us-central1 \
  --project project-3cec667f-8135-4778-9b4
```
