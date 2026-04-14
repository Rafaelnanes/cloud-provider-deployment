# Terraform — GKE Access Control

This directory contains Terraform IaC that provisions the GCP IAM bindings required for the `products` service to authenticate with GCP via Workload Identity.

## What it provisions

Two IAM resources in `main.tf`:

| Resource | Role | Purpose |
|---|---|---|
| `google_project_iam_member` | `roles/secretmanager.secretAccessor` | Grants the GCP service account read access to Secret Manager secrets |
| `google_service_account_iam_member` | `roles/iam.workloadIdentityUser` | Allows the Kubernetes service account (`products` in the target namespace) to impersonate the GCP service account via Workload Identity Federation |

The Workload Identity binding links:
- **GCP side:** `products-sa@<project>.iam.gserviceaccount.com`
- **K8s side:** `serviceAccount:<project>.svc.id.goog[<namespace>/products]`

This is what allows the pod to call GCP APIs without storing a credentials JSON file.

## Variables (`terraform.tfvars`)

| Variable | Description |
|---|---|
| `project_id` | GCP project ID |
| `gcp_sa_email` | GCP service account email to bind |
| `k8s_namespace` | Namespace where the workload runs (default: `dev`) |
| `k8s_sa_name` | Kubernetes service account name (default: `products`) |

## Commands

```bash
terraform init                  # download provider plugins (run once, or after adding providers)
terraform validate              # check config syntax/validity
terraform fmt                   # auto-format .tf files
terraform plan                  # preview changes — no side effects
terraform apply                 # apply with interactive confirmation prompt
terraform apply -auto-approve   # apply without prompt
terraform destroy               # tear down resources, with confirmation
terraform destroy -auto-approve # tear down without prompt
```

### Typical workflow

```bash
terraform init
terraform plan
terraform apply
```

> **Note:** `-auto-approve` skips the confirmation prompt. Use `apply`/`destroy` without it in production to avoid accidental changes.
