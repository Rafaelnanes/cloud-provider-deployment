# Terraform — GKE Access Control

## Giving a user view-only access to a specific namespace

### Overview

```
ADMIN SIDE (GCP IAM)
─────────────────────────────────────────────────────
1. Grant user1@example.com → roles/container.clusterViewer
   (allows user1 to run `get-credentials`, nothing else)


ADMIN SIDE (Kubernetes RBAC — managed via Terraform or kubectl)
─────────────────────────────────────────────────────
2. Create Role in target namespace (e.g. `dev`)
   (verbs: get/list/watch on pods, deployments, services, etc.)

3. Create RoleBinding in target namespace
   (binds user1@example.com → that Role)


USER1 SIDE
─────────────────────────────────────────────────────
4. gcloud container clusters get-credentials CLUSTER --project PROJECT
   (authenticates to the cluster using their Google identity)

5. kubectl get pods -n dev      ✅ works
   kubectl get pods -n prod     ❌ forbidden
   kubectl get pods              ❌ forbidden (no cluster-wide access)
```

### Key principle

GCP IAM only opens the door to the cluster. Kubernetes RBAC controls what the user can see inside it.

- Use `roles/container.clusterViewer` (not `roles/container.viewer`) — the latter grants cluster-wide Kubernetes view access automatically.
- Bind to a **Google Group** rather than individual emails in production — access is then managed by group membership, not RBAC changes.
- Steps 2 and 3 should be managed via Terraform or a dedicated platform Helm chart, separate from application charts.
