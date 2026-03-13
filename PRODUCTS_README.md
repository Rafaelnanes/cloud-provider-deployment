This application is just a simple one with a simple endpoint to be used to create a jar and later the docker image to
use in k8

## Table of Contents

- [Building the Docker Image](#building-the-docker-image)
  - [How it works](#how-it-works)
  - [Build and run](#build-and-run)
  - [Layer caching](#layer-caching)
  - [Going even smaller (optional)](#going-even-smaller-optional)
- [Deploying with Helm](#deploying-with-helm)
  - [Chart structure](#chart-structure)
  - [Install](#install)
  - [Verify](#verify)
  - [Upgrade](#upgrade)
  - [Rollback](#rollback)
  - [Uninstall](#uninstall)

## Building the Docker Image

The image is built using GraalVM Native Image, which AOT-compiles the application into a standalone native binary.
This removes the need for a JVM at runtime, resulting in a much smaller image (~80–100MB vs ~300MB+ for a JVM-based
image)
and significantly faster startup times.

### How it works

A multi-stage `Dockerfile` is used:

1. **Stage 1 (build)** — `ghcr.io/graalvm/native-image-community:21` compiles the app via `./gradlew nativeCompile`
2. **Stage 2 (runtime)** — `debian:bookworm-slim` (minimal glibc) runs the native binary — no JVM installed

The `org.graalvm.buildtools.native` Gradle plugin enables the `nativeCompile` task. Spring Boot's built-in AOT support
pre-processes beans and proxies at build time so the native compilation succeeds without extra configuration.

> **Note:** Build time is slow (~3–5 min) due to AOT compilation. This is expected and only happens in CI, not at
> runtime.

### Build and run

```bash
# From apps/products/
docker build -t products:latest .
#docker build -f ./docker/Dockerfile-jvm -t products:jvm .
#docker build -f ./docker/Dockerfile-aot -t products:aot .        

docker run -p 8080:8080 products:latest
```

```bash
# Verify
curl http://localhost:8080/products
```

### Layer caching

Gradle wrapper and dependency descriptors are copied before the source so Docker reuses the dependency resolution
layer on subsequent builds when only source code changes.

### Going even smaller (optional)

By default the native binary is dynamically linked against glibc. To use a `scratch` base image instead, add
`--static --libc=musl` to the native compile args and switch to a musl-based build image.

## Deploying with Helm

The Helm chart lives in `helm/products/` at the project root and wraps the same `Deployment` and `Service` as the raw manifests,
but parameterized via `values.yaml`.

Key concept — `{{ .Release.Name }}` is used for all resource names instead of hardcoding `products`.
This allows installing multiple instances of the same chart side by side (e.g. staging vs production).

### Chart structure

```
helm/products/
├── Chart.yaml              # chart metadata
├── values.yaml             # default values (image, replicas, service, probe, domainPrefix)
├── values-dev.yaml         # dev overrides (NodePort, 1 replica, local image)
├── values-prod.yaml        # prod overrides (LoadBalancer, 3 replicas, Always pull)
└── templates/
    ├── configmap.yaml      # injects env vars (e.g. ENV_INFO) per environment
    ├── deployment.yaml     # uses envFrom to consume the ConfigMap
    ├── gateway.yaml        # Istio Gateway + VirtualService, routes /rbn/products → /products
    └── service.yaml
```

`values.yaml` holds the base defaults. Environment files only override what changes —
Helm merges them in order, with later files taking precedence.

### Install

Install for dev (Minikube):

```bash
# From project root
helm install products-dev ./helm/products -f ./helm/products/values.yaml -f ./helm/products/values-dev.yaml -n dev
```

Install for prod (cloud cluster):

```bash
# From project root
helm install products-prod ./helm/products -f ./helm/products/values.yaml -f ./helm/products/values-prod.yaml -n prod
```

### Verify

```bash
helm list -n dev                                             # shows the active release
kubectl get pods -n dev                                      # pod should come up
kubectl port-forward deployment/products-dev 8080:8080 -n dev
curl http://localhost:8080/products

# Via Istio ingress
minikube service istio-ingressgateway -n istio-system --url
curl http://127.0.0.1:<http-port>/rbn/products
```

### Upgrade

```bash
# From project root

# Dev
helm upgrade products-dev ./helm/products -f ./helm/products/values.yaml -f ./helm/products/values-dev.yaml -n dev

# Prod
helm upgrade products-prod ./helm/products -f ./helm/products/values.yaml -f ./helm/products/values-prod.yaml -n dev

# Override a single value on the fly (e.g. bump the image tag)
helm upgrade products-dev ./helm/products -f ./helm/products/values.yaml -f ./helm/products/values-dev.yaml --set image.tag=1.1.0 -n dev
```

### Rollback

```bash
helm history products-dev -n dev          # list all revisions
helm rollback products-dev 1 -n dev       # roll back to revision 1
```

### Uninstall

```bash
helm uninstall products-dev -n dev
helm uninstall products-prod -n dev
```
