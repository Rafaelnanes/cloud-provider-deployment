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
    6. [Phase 6 — Provision Cloud Infrastructure](#phase-6--provision-cloud-infrastructure)
    7. [Phase 7 — Deploy to Cloud](#phase-7--deploy-to-cloud)
    8. [Phase 8 — Improvements](#phase-8--improvements-stretch-goals)
- [Tech Stack](#tech-stack)

## Pending Checklist

- [ ] config pipelines
- [ ] Create two different namespaces, try to do a request for an api for that to understand how network works from
  inside a namespace and from different namespaces

## Goal

Understand the end-to-end process of building, containerizing, and deploying a microservice to a cloud provider — from
local development to a running cloud environment.

## Makefile

A root `Makefile` automates all tasks for both apps. Run `make` to list available targets.

### Variables

| Variable    | Default    | Options             |
|-------------|------------|---------------------|
| `APP`       | `products` | `products`, `users` |
| `NAMESPACE` | `dev`      | `dev`, `prod`       |
| `VERIFY_URL`| *(set manually)* | HTTP URL from minikube tunnel |

### Targets

| Target            | Description                                              |
|-------------------|----------------------------------------------------------|
| `setup`           | Run `setup-istio` then `setup-namespaces`                |
| `setup-istio`     | Install Istio with ingress gateway                       |
| `setup-namespaces`| Create and label `dev`/`prod` namespaces                 |
| `build`           | Build `APP:jvm` Docker image inside Minikube             |
| `deploy`          | Build and deploy Helm release for `APP` to `NAMESPACE`   |
| `deploy-all`      | Deploy both `products` and `users` to `NAMESPACE`        |
| `verify`          | Send test request to `VERIFY_URL/rbn/APP`                |
| `rollback`        | Roll back the Helm release for `APP`                     |
| `clean`           | Uninstall the Helm release for `APP` from `NAMESPACE`    |
| `clean-all`       | Uninstall both `products` and `users` from `NAMESPACE`   |

### Examples

```bash
# First-time cluster setup
make setup

# Build and deploy a single app
make deploy APP=products NAMESPACE=dev
make deploy APP=users NAMESPACE=dev

# Deploy both apps at once
make deploy-all NAMESPACE=dev

# Verify (run minikube tunnel in a separate terminal first, then set VERIFY_URL)
make verify APP=products VERIFY_URL=http://127.0.0.1:<port>
make verify APP=users VERIFY_URL=http://127.0.0.1:<port>

# Rollback and cleanup
make rollback APP=users NAMESPACE=dev
make clean-all NAMESPACE=dev
```

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

1. Write a `Dockerfile` for the `products` Spring Boot app
2. Build and run the container locally
3. Understand multi-stage builds (build stage with Gradle, runtime stage with JRE)
4. Push the image to a container registry (Docker Hub or cloud provider registry)

### Phase 2 — Deploy to Minikube (Local Kubernetes)

1. Start a local Minikube cluster
2. Write Kubernetes manifests (`Deployment`, `Service`) for the `products` app
3. Build the image into Minikube's Docker daemon
4. Apply manifests with `kubectl` and validate `GET /products`

### Phase 3 — Package with Helm

1. Understand Helm concepts: charts, templates, values, releases
2. Create a Helm chart for the `products` app (wrapping the existing manifests)
3. Use `values.yaml` to parameterize image tag, replicas, and service config
4. Install and upgrade the release locally on Minikube with `helm install/upgrade`
5. Use `ConfigMap` to inject environment-specific config (e.g. log level, app properties)

### Phase 4 — Secrets Management with Kubernetes Secrets and Vault

1. Understand the difference between `ConfigMap` and `Secret`
2. Create Kubernetes `Secret` resources for sensitive values (passwords, tokens, API keys)
3. Consume secrets as environment variables in the `Deployment`
4. Install HashiCorp Vault on Minikube
5. Understand Vault concepts: secrets engine, policies, AppRole authentication
6. Integrate Vault with Kubernetes using the Vault Agent Injector (sidecar)
7. Migrate sensitive config from Kubernetes `Secret` to Vault

### Phase 5 — Service Mesh with Istio

1. Install Istio on Minikube (`istioctl install`)
2. Enable sidecar injection on the `products` namespace
3. Understand core Istio resources: `VirtualService`, `DestinationRule`, `Gateway`
4. Expose `GET /products` through an Istio `Gateway` + `VirtualService`
5. Explore traffic management: retries, timeouts, and fault injection for testing
6. Test canary deployment using `DestinationRule` subsets and `VirtualService` traffic splitting
7. Observe traffic with Kiali, Jaeger (tracing), and Prometheus/Grafana (metrics)

### Phase 6 — Provision Cloud Infrastructure

1. Choose a cloud provider (AWS, GCP, or Azure)
2. Provision a managed Kubernetes cluster (e.g., EKS, GKE, AKS)
3. Set up a container registry on the chosen provider
4. Configure IAM roles / service accounts with least-privilege access for deployments

### Phase 7 — Deploy to Cloud

1. Push the image to the cloud registry
2. Apply manifests/Helm chart to the cloud cluster
3. Verify `GET /products` on the cloud

### Phase 8 — Improvements (stretch goals)

1. Add health checks and rollback on failed deployments
2. Use Infrastructure as Code (Terraform or cloud-native IaC) to provision resources
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
| Secrets manager  | Kubernetes Secrets + HashiCorp Vault |
| Service mesh     | Istio                                |
| Cloud Kubernetes | TBD (EKS / GKE / AKS)                |
