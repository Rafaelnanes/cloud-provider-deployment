# Cloud Provider Deployment

A learning project focused on deploying Java Spring Boot applications to a cloud provider.

## Table of Contents

- [Pending Checklist](#pending-checklist)
- [Goal](#goal)
- [Project Structure](#project-structure)
- [Learning Plan](#learning-plan)
    1. [Phase 1 — Containerize the Application](#phase-1--containerize-the-application)
    2. [Phase 2 — Deploy to Minikube](#phase-2--deploy-to-minikube-local-kubernetes)
    3. [Phase 3 — Package with Helm](#phase-3--package-with-helm)
    4. [Phase 4 — Secrets Management](#phase-4--secrets-management-with-kubernetes-secrets-and-vault)
    5. [Phase 5 — Service Mesh with Istio](#phase-5--service-mesh-with-istio)
    6. [Phase 6 — RBAC & IAM](#phase-6--rbac--iam)
    7. [Phase 7 — Provision Cloud Infrastructure](#phase-7--provision-cloud-infrastructure)
    8. [Phase 8 — Deploy to Cloud](#phase-8--deploy-to-cloud)
    9. [Phase 9 — GCP Gateway & Service Mesh](#phase-9--gcp-gateway--service-mesh)
    10. [Phase 10 — Google Secret Manager](#phase-10--google-secret-manager-gsm)
    11. [Phase 11 — Improvements](#phase-11--improvements-stretch-goals)
- [Tech Stack](#tech-stack)

## Pending Checklist

- [ ] config pipelines
- [ ] Create two different namespaces, try to do a request for an api for that to understand how network works from
  inside a namespace and from different namespaces

## Goal

Understand the end-to-end process of building, containerizing, and deploying a microservice to a cloud provider — from
local development to a running cloud environment.

## Project Structure

```
cloud-provider-deployment/
└── apps/
    └── products/        # Spring Boot REST API (Java 21, Gradle)
```

The `products` service exposes a simple `GET /products` endpoint and serves as the deployable unit throughout this
learning path.

## Learning Plan

### Phase 1 — Containerize the Application

1. Write a `Dockerfile` for the `products` Spring Boot app ✅
2. Build and run the container locally ✅
3. Understand multi-stage builds (build stage with Gradle, runtime stage with JRE) ✅
4. Push the image to a container registry (Docker Hub or cloud provider registry) ✅

### Phase 2 — Deploy to Minikube (Local Kubernetes)

1. Start a local Minikube cluster ✅
2. Write Kubernetes manifests (`Deployment`, `Service` - for the `products` app ✅
3. Build the image into Minikube's Docker daemon ✅
4. Apply manifests with `kubectl` and validate `GET /products` ✅

### Phase 3 — Package with Helm

1. Understand Helm concepts: charts, templates, values, releases ✅
2. Create a Helm chart for the `products` app (wrapping the existing manifests) ✅
3. Use `values.yaml` to parameterize image tag, replicas, and service config ✅
4. Install and upgrade the release locally on Minikube with `helm install/upgrade` ✅
5. Use `ConfigMap` to inject environment-specific config (e.g. log level, app properties) ✅

### Phase 4 — Secrets Management with Kubernetes Secrets and Vault

1. Understand the difference between `ConfigMap` and `Secret`
2. Create Kubernetes `Secret` resources for sensitive values (passwords, tokens, API keys)
3. Consume secrets as environment variables in the `Deployment`
4. Install HashiCorp Vault on Minikube
5. Understand Vault concepts: secrets engine, policies, AppRole authentication
6. Integrate Vault with Kubernetes using the Vault Agent Injector (sidecar)
7. Migrate sensitive config from Kubernetes `Secret` to Vault

### Phase 5 — Service Mesh with Istio

1. Install Istio on Minikube (`istioctl install`) ✅
2. Enable sidecar injection on the `products` namespace ✅
3. Understand core Istio resources: `VirtualService`, `DestinationRule`, `Gateway` ✅
4. Expose `GET /products` through an Istio `Gateway` + `VirtualService` ✅
5. Explore traffic management: retries, timeouts, and fault injection for testing
6. Test canary deployment using `DestinationRule` subsets and `VirtualService` traffic splitting
7. Observe traffic with Kiali, Jaeger (tracing), and Prometheus/Grafana (metrics)

### Phase 6 — RBAC & IAM

1. Create a `ServiceAccount` per app (`products`, `users`) and attach it to each `Deployment`
2. Define `Role` resources scoped to each namespace — allow only the verbs each app needs
3. Bind roles to service accounts with `RoleBinding`
4. Move `PRODUCTS_API_KEY` from `ConfigMap` to a `Secret`; restrict read access to `users` only
5. Verify `products` cannot access the `users` secret (test with `kubectl auth can-i`)
6. Confirm namespace isolation: roles in `dev` do not apply in `prod`
7. Apply a `default-deny-all` `NetworkPolicy` to enforce zero trust (requires `--cni=calico`)
8. Explicitly allow only `users` → `products` traffic via a targeted `NetworkPolicy`
9. Verify denied traffic (curl from `products` pod to `users` should be blocked)

### Phase 7 — Provision Cloud Infrastructure

1. Choose a cloud provider (AWS, GCP, or Azure) ✅
2. Provision a managed Kubernetes cluster (e.g., EKS, GKE, AKS) ✅
3. Set up a container registry on the chosen provider ✅
4. Configure IAM roles / service accounts with least-privilege access for deployments ✅

### Phase 8 — Deploy to Cloud

1. Push the image to the cloud registry ✅
2. Apply manifests/Helm chart to the cloud cluster ✅
3. Verify `GET /products` on the cloud ✅

### Phase 9 — GCP Gateway & Service Mesh

1. Replace the `LoadBalancer` service with a GKE Gateway (Kubernetes Gateway API)
2. Define `HTTPRoute` to route traffic to the `products` ClusterIP service
3. Understand the difference: Gateway API vs classic Ingress vs LoadBalancer
4. Configure the `HTTPRoute` to only accept requests with the `/rbn/` path prefix
5. Validate the `x-api-key` header at the Gateway level (via `HTTPRoute` filter or Istio `EnvoyFilter`)
6. Install Istio on GKE and enable sidecar injection
7. Expose `products` through an Istio `Gateway` + `VirtualService` on GKE
8. Apply an Istio `AuthorizationPolicy` to allow traffic to `products` only from the Istio ingress gateway (deny all other sources)
9. Test traffic management (retries, timeouts) in the cloud environment

### Phase 10 — Google Secret Manager (GSM)

1. Understand GSM vs Kubernetes `Secret` vs HashiCorp Vault
2. Store a secret (e.g. API key) in GSM via GCP Console and `gcloud`
3. Configure Workload Identity to link the K8s `ServiceAccount` → GCP `ServiceAccount`
4. Use the External Secrets Operator to inject GSM secrets into the pod
5. Verify the secret is available as an env var in the `products` container

### Phase 11 — Improvements (stretch goals)

1. Add health checks and rollback on failed deployments
2. Use Infrastructure as Code (Terraform) to provision GKE, registry, and IAM
3. Add a staging environment and promote builds from staging to production

## Tech Stack

| Layer            | Technology                           |
|------------------|--------------------------------------|
| Language         | Java 21                              |
| Framework        | Spring Boot 4                        |
| Build tool       | Gradle (Kotlin DSL)                  |
| Containerization | Docker                               |
| Local Kubernetes | Minikube                             |
| Package manager  | Helm                                 |
| Secrets manager  | Kubernetes Secrets + HashiCorp Vault + Google Secret Manager |
| Service mesh     | Istio                                |
| Cloud Kubernetes | TBD (EKS / GKE / AKS)                |
