# Cloud Provider Deployment

A learning project focused on deploying Java Spring Boot applications to a cloud provider.

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

- Write a `Dockerfile` for the `products` Spring Boot app
- Build and run the container locally
- Understand multi-stage builds (build stage with Gradle, runtime stage with JRE)
- Push the image to a container registry (Docker Hub or cloud provider registry)

### Phase 2 — Deploy to Minikube (Local Kubernetes)

- Start a local Minikube cluster
- Write Kubernetes manifests (`Deployment`, `Service`) for the `products` app
- Build the image into Minikube's Docker daemon
- Apply manifests with `kubectl` and validate `GET /products`

### Phase 3 — Package with Helm

- Understand Helm concepts: charts, templates, values, releases
- Create a Helm chart for the `products` app (wrapping the existing manifests)
- Use `values.yaml` to parameterize image tag, replicas, and service config
- Install and upgrade the release locally on Minikube with `helm install/upgrade`

### Phase 4 — Service Mesh with Istio

- Install Istio on Minikube (`istioctl install`)
- Enable sidecar injection on the `products` namespace
- Understand core Istio resources: `VirtualService`, `DestinationRule`, `Gateway`
- Expose `GET /products` through an Istio `Gateway` + `VirtualService`
- Explore traffic management: retries, timeouts, and fault injection for testing
- Observe traffic with Kiali, Jaeger (tracing), and Prometheus/Grafana (metrics)

### Phase 5 — Provision Cloud Infrastructure

- Choose a cloud provider (AWS, GCP, or Azure)
- Provision a managed Kubernetes cluster (e.g., EKS, GKE, AKS)
- Set up a container registry on the chosen provider
- Configure IAM roles / service accounts with least-privilege access for deployments

### Phase 6 — Deploy to Cloud

- Push the image to the cloud registry
- Apply manifests/Helm chart to the cloud cluster
- Verify `GET /products` on the cloud

### Phase 7 — Improvements (stretch goals)

- Add health checks and rollback on failed deployments
- Use Infrastructure as Code (Terraform or cloud-native IaC) to provision resources
- Add a staging environment and promote builds from staging to production

## Tech Stack

| Layer            | Technology            |
|------------------|-----------------------|
| Language         | Java 21               |
| Framework        | Spring Boot 4         |
| Build tool       | Gradle (Kotlin DSL)   |
| Containerization | Docker                |
| Local Kubernetes | Minikube              |
| Package manager  | Helm                  |
| Service mesh     | Istio                 |
| Cloud Kubernetes | TBD (EKS / GKE / AKS) |
