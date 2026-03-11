This application is just a simple one with a simple endpoint to be used to create a jar and later the docker image to
use in k8

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

## Deploying to Minikube

Kubernetes manifests live in `k8s/` — a `Deployment` and a `Service`.

Key decisions in the manifests:

- **`imagePullPolicy: Never`** — uses the locally built image instead of pulling from Docker Hub
- **`readinessProbe`** — Kubernetes waits for `GET /products` to succeed before routing traffic to the pod

### Deploy

**1. Point Docker to Minikube's daemon:**

```bash
 #Git Bash
 eval $(minikube docker-env)
 
 #Windows Power Shell
 minikube docker-env | Invoke-Expression
```

**2. Build the image inside Minikube:**

```bash
# From apps/products/
docker build -f ./docker/Dockerfile-jvm -t products:jvm .
```

**3. Apply the manifests:**

```bash
kubectl apply -f k8s/
```

**4. Wait for the pod to be ready:**

```bash
kubectl get pods -w
# Wait until STATUS = Running and READY = 1/1
```

**5. Access the service (port forwarding):**

```bash
minikube service products --url
curl http://<minikube-ip>:<port>/products
```

### Useful commands

```bash
kubectl get pods                  # list pods
kubectl logs <pod-name>           # app logs
kubectl describe pod <pod-name>   # debug a failing pod
kubectl delete -f k8s/            # tear everything down
```
