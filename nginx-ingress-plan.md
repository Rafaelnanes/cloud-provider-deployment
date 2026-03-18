# Plan: NGINX Ingress in Front of Istio IngressGateway

## Context

The project uses Istio IngressGateway as the sole entry point. The goal is to add NGINX Ingress Controller as a reverse
proxy in front of Istio, implemented in two phases:

- **Phase 1 (this plan):** Stand up NGINX Ingress and route all traffic through it to Istio
- **Phase 2 (next):** Lock down Istio IngressGateway so it only accepts traffic from NGINX

**Target traffic flow:**

```
curl (port 80) → NGINX Ingress Controller → Istio IngressGateway → VirtualService → Pod
```

---

## Key Challenges

**Cross-namespace routing:** `Ingress` resources can only reference `Service` objects in the same namespace. NGINX runs
in `ingress-nginx`; Istio IngressGateway is in `istio-system`. Solution: an `ExternalName` Service in `ingress-nginx`
acting as a DNS alias.

**kind port mapping:** kind doesn't expose node ports by default. Requires a `kind-config.yaml` mapping host port 80 →
node containerPort 80, plus `ingress-ready=true` label on the control-plane node. **Recreating the kind cluster is
required** (one-time, destructive).

---

## Phase 1 — NGINX Ingress

### Files to Create

#### `kind-config.yaml` (project root)

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
    extraPortMappings:
      - containerPort: 80
        hostPort: 80
        protocol: TCP
      - containerPort: 443
        hostPort: 443
        protocol: TCP
```

#### `helm/nginx-ingress/Chart.yaml`

```yaml
apiVersion: v2
name: nginx-ingress
description: NGINX Ingress routing to Istio IngressGateway
type: application
version: 0.1.0
```

#### `helm/nginx-ingress/values.yaml`

```yaml
istioGateway:
  namespace: istio-system
  serviceName: istio-ingressgateway

nginxNamespace: ingress-nginx

paths:
  - /rbn/dev/products
  - /rbn/prod/products
  - /rbn/dev/users
  - /rbn/prod/users
```

#### `helm/nginx-ingress/templates/externalname-service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: istio-ingressgateway-proxy
  namespace: { { .Values.nginxNamespace } }
spec:
  type: ExternalName
  externalName: { { .Values.istioGateway.serviceName } }.{{ .Values.istioGateway.namespace }}.svc.cluster.local
  ports:
      - port: 80
        targetPort: 80
```

#### `helm/nginx-ingress/templates/ingress.yaml`

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: istio-passthrough
  namespace: { { .Values.nginxNamespace } }
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
    nginx.ingress.kubernetes.io/proxy-pass-headers: "X-API-KEY"
spec:
  ingressClassName: nginx
  rules:
    - http:
        paths:
          { { - range .Values.paths } }
          - path: { { . } }
            pathType: Prefix
            backend:
              service:
                name: istio-ingressgateway-proxy
                port:
                  number: 80
          { { - end } }
```

No `rewrite-target` annotation — NGINX passes the URI unchanged so the Istio VirtualService can do its own matching (
`/rbn/dev/products`) and rewriting (`/products`).

---

### Files to Modify

#### `Makefile`

Add variable at top:

```makefile
NGINX_INGRESS_MANIFEST := https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/kind/deploy.yaml
```

Add targets:

```makefile
cluster-create:
	@echo "==> Creating kind cluster with port mappings for NGINX ingress..."
	kind create cluster --config kind-config.yaml --image kindest/node:v1.31.0

setup-nginx:
	@echo "==> Installing NGINX Ingress Controller (kind variant)..."
	kubectl apply -f $(NGINX_INGRESS_MANIFEST)
	@echo "==> Waiting for NGINX controller to be ready..."
	kubectl wait --namespace ingress-nginx \
	  --for=condition=ready pod \
	  --selector=app.kubernetes.io/component=controller \
	  --timeout=120s

setup-nginx-routing:
	@echo "==> Deploying nginx-ingress Helm chart..."
	helm upgrade --install nginx-ingress ./helm/nginx-ingress -n ingress-nginx --create-namespace
```

Update `setup`:

```makefile
setup: setup-istio setup-namespaces setup-nginx setup-nginx-routing
	@echo "==> Cluster is ready."
```

Update `verify` (port 80 is now mapped directly to host, no port-forward needed):

```makefile
verify:
	@echo "==> [$(APP)] Sending test request to http://localhost/rbn/$(NAMESPACE)/$(APP)..."
	curl -H "X-API-KEY: $(NAMESPACE)-secret-key" http://localhost/rbn/$(NAMESPACE)/$(APP)
```

Update `.PHONY` and `help` to include new targets.

---

### Execution Order (First-Time Setup)

```bash
kind delete cluster        # required if cluster exists without port mapping
make cluster-create        # recreate with kind-config.yaml
make setup                 # istio + namespaces + nginx + nginx-routing
make deploy-all NAMESPACE=dev
```

> `cluster-create` is intentionally separate from `setup` — recreating the cluster is destructive and should be an
> explicit action.

---

### Phase 1 Verification

```bash
kubectl get pods -n ingress-nginx                        # NGINX controller Running
kubectl get ingress -n ingress-nginx                     # istio-passthrough exists
make verify APP=products NAMESPACE=dev                   # HTTP 200
make verify APP=users NAMESPACE=dev                      # HTTP 200
```

---

## Phase 2 — Istio Source Restriction (Next Session)

Add a `NetworkPolicy` to `istio-system` that restricts the IngressGateway pod to only accept traffic from NGINX ingress
pods:

```yaml
# helm/nginx-ingress/templates/networkpolicy-ingressgateway.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-only-nginx-to-ingressgateway
  namespace: istio-system
spec:
  podSelector:
    matchLabels:
      app: istio-ingressgateway
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: ingress-nginx
          podSelector:
            matchLabels:
              app.kubernetes.io/name: ingress-nginx
              app.kubernetes.io/component: controller
      ports:
        - port: 8080   # pod port (Service port 80 maps to pod port 8080)
          protocol: TCP
```

Verification: `kubectl port-forward -n istio-system svc/istio-ingressgateway 8888:80` then direct curl should be
blocked.