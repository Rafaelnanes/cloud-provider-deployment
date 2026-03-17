# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Build & Deploy
```bash
make setup                               # First-time: install Istio + create namespaces
make build APP=products                  # Build Docker image (products:jvm)
make kind-load APP=products              # Load image into kind cluster
make deploy APP=products NAMESPACE=dev   # Build + load + helm upgrade --install
make deploy-all NAMESPACE=prod           # Deploy both products and users
make rollback APP=products NAMESPACE=dev
make clean APP=products NAMESPACE=dev
```

### App Build (Gradle)
```bash
cd apps/products
./gradlew bootJar          # Build JAR
./gradlew test             # Run tests
./gradlew nativeCompile    # GraalVM native image
```

### Verify Deployment
```bash
make verify APP=products VERIFY_URL=http://127.0.0.1:<PORT>
# Sends: GET http://<VERIFY_URL>/rbn/products with X-API-KEY header
```

### Helm (manual)
```bash
helm upgrade --install products ./helm/products \
  -f ./helm/products/values-dev.yaml -n dev

helm upgrade --install products ./helm/products \
  -f ./helm/products/values-prod.yaml -n prod
```

## Architecture

Two independent Spring Boot 4 / Java 21 services (`apps/products`, `apps/users`) deployed to a local kind cluster via Helm with Istio service mesh.

### Request Flow
```
curl → Istio IngressGateway (port 80)
     → VirtualService (match: /rbn/{env}/products → rewrite: /products)
     → ClusterIP Service
     → Pod (sidecar-injected)
```

### Helm Chart Layout
Each service has its own chart under `helm/{app}/`:
- `values.yaml` — base defaults (1 replica, `pullPolicy: Never`, ClusterIP)
- `values-dev.yaml` — dev overrides (`domainPrefix: rbn/dev`, 1 replica)
- `values-prod.yaml` — prod overrides (3 replicas, `security.networkPolicy: true`, `security.rbacIam: true`)

Security features (`NetworkPolicy`, `ServiceAccount`/`Role`/`RoleBinding`) are **feature-flagged** via `security.rbacIam` and `security.networkPolicy` — only active in prod.

### Config Injection
`ConfigMap` → `envFrom` in Deployment → Spring Boot binds env vars:
- `ENV_INFO` → `service.envInfo`
- `SERVER_PORT`, `LOG_LEVEL_ROOT`, `LOG_LEVEL_APP`

### Users → Products Communication
`users` calls `products` via in-cluster DNS: `http://products-{namespace}:8080`, configured in `helm/users/values.yaml` as `config.productsUrl`.

### Image Strategy
- Local dev: `imagePullPolicy: Never` — images must be loaded into kind with `make kind-load`
- Two Dockerfile variants in `docker/`: `Dockerfile-jvm` (default), `Dockerfile-aot` (GraalVM native)

## Key Files
- `Makefile` — primary orchestration entrypoint
- `helm/{app}/templates/gateway.yaml` — Istio Gateway + VirtualService + DestinationRule
- `helm/{app}/templates/rbac/` — conditionally rendered RBAC resources
- `apps/products/src/main/resources/application.yaml` — env var bindings + actuator config
