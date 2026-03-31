# Apps

Three Spring Boot 4 / Java 21 apps. `products` is the primary REST API; `users` demonstrates inter-service communication; `batch` demonstrates Kubernetes Job and CronJob.

## Services

| App        | Base path   | Port | Description                              |
|------------|-------------|------|------------------------------------------|
| `products` | `/products` | 8080 | Product catalogue — standalone REST API  |
| `users`    | `/users`    | 8080 | User service — calls `products` for data |
| `batch`    | —           | —    | Batch runner — exits after task completes (no HTTP server) |

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

### batch

Runs one of two tasks selected via `TASK_TYPE` env var:

| `TASK_TYPE` | Description                          |
|-------------|--------------------------------------|
| `report`    | Processes N records and logs a summary |
| `cleanup`   | Simulates deletion of expired records |

`RECORD_COUNT` controls how many records are processed (default: `100`).

## Inter-service communication

`users` calls `products` via in-cluster DNS using `ProductsClient` (Spring `RestClient`).
The URL is injected through `config.productsUrl` in `helm/local/users/values.yaml`:

```
http://products-{namespace}:8080
```

## Build

```bash
# From apps/{service}/
./gradlew bootJar   # build JAR
./gradlew test      # run tests
```

Or via Makefile from the project root:

```bash
make build APP=products
make build APP=users
make build APP=batch
```
