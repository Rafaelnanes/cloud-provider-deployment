# Apps

Two independent Spring Boot 4 / Java 21 services. Both are deployable units in the learning path — `products` is the primary target; `users` exists to demonstrate inter-service communication.

## Services

| Service    | Base path   | Port | Description                              |
|------------|-------------|------|------------------------------------------|
| `products` | `/products` | 8080 | Product catalogue — standalone REST API  |
| `users`    | `/users`    | 8080 | User service — calls `products` for data |

## Endpoints

### products

| Method | Path                  | Description               |
|--------|-----------------------|---------------------------|
| GET    | `/products`           | List all products         |
| GET    | `/products/{id}`      | Get product by id         |
| GET    | `/products/env-info`  | Return injected `ENV_INFO` |

### users

| Method | Path                              | Description                              |
|--------|-----------------------------------|------------------------------------------|
| GET    | `/users`                          | List all users (resolves product names)  |
| POST   | `/users/{userId}/products/{productId}` | Add a product to a user             |
| GET    | `/users/env-info`                 | Return injected `ENV_INFO`               |

## Inter-service communication

`users` calls `products` via in-cluster DNS using `ProductsClient` (Spring `RestClient`).
The URL is injected through `config.productsUrl` in `helm/users/values.yaml`:

```
http://products-{namespace}:8080
```

## Build

```bash
# From apps/{service}/
./gradlew bootJar        # build JAR
./gradlew test           # run tests
./gradlew nativeCompile  # GraalVM native binary (slow, CI only)
```

Or via Makefile from the project root:

```bash
make build APP=products
make build APP=users
```

## Docker

Each app has two `Dockerfile` variants under `apps/{service}/docker/`:

| File             | Base image              | Use case            |
|------------------|-------------------------|---------------------|
| `Dockerfile-jvm` | `eclipse-temurin:21`    | Default, fast build |
| `Dockerfile-aot` | GraalVM → debian-slim   | Smaller image, slow build |

See `helm/K8S.md` for Docker build notes (layer caching, musl/scratch option).
