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
#docker build -f Dockerfile-jvm -t products:jvm .
#docker build -f Dockerfile-aot -t products:aot .        

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
