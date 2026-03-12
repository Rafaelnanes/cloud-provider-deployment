HELM_CHART := ./helm/products
NAMESPACE  := dev
VERIFY_URL := http://127.0.0.1:64537

.PHONY: build deploy rollback verify clean setup-namespaces setup-istio setup help

help:
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@echo "  setup            Run setup-istio then setup-namespaces"
	@echo "  setup-istio      Install Istio with ingress gateway"
	@echo "  setup-namespaces Create and label dev/prod namespaces"
	@echo "  build            Build products:jvm Docker image in Minikube"
	@echo "  deploy           Build and deploy Helm release to NAMESPACE (default: dev)"
	@echo "  verify           Send test request to the ingress gateway"
	@echo "  rollback         Roll back the Helm release to the previous revision"
	@echo "  clean            Uninstall the Helm release from NAMESPACE"

# Phase 1 - Install required components

setup-namespaces:
	@echo "==> Creating and labeling dev and prod namespaces..."
	kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -
	kubectl create namespace prod --dry-run=client -o yaml | kubectl apply -f -
	kubectl label namespace dev istio-injection=enabled --overwrite
	kubectl label namespace prod istio-injection=enabled --overwrite

setup-istio:
	@echo "==> Installing Istio with minimal profile and ingress gateway..."
	istioctl install --set profile=minimal --set components.ingressGateways[0].enabled=true --set components.ingressGateways[0].name=istio-ingressgateway -y

setup: setup-istio setup-namespaces
	@echo "==> Cluster is ready."

# Phase 2 - Build product application

build:
	@echo "==> Env: '$(NAMESPACE)' -> Pointing Docker to Minikube daemon and building products:jvm image..."
	@eval $(minikube docker-env) && docker build -f ./apps/products/docker/Dockerfile-jvm -t products:jvm ./apps/products

deploy: build
	@echo "==> Deploying Helm release to namespace '$(NAMESPACE)'..."
	helm upgrade --install products-$(NAMESPACE) $(HELM_CHART) \
		-f $(HELM_CHART)/values.yaml \
		-f $(HELM_CHART)/values-$(NAMESPACE).yaml \
		-n $(NAMESPACE)
	@echo "==> Waiting for rollout to complete..."
	kubectl rollout status deployment/products-$(NAMESPACE) -n $(NAMESPACE)

## Phase 3 - Utilities

verify:
	echo "!! Make sure to run previously: minikube service istio-ingressgateway -n istio-system --url"; \
	echo "==> Sending test request to $VERIFY_URL/rbn/products..."; \
	curl -H "X-API-KEY: $(NAMESPACE)-secret-key" $(VERIFY_URL)/rbn/products

rollback:
	@echo "==> Rolling back products-$(NAMESPACE) to previous revision in namespace '$(NAMESPACE)'..."
	helm rollback products-$(NAMESPACE) -n $(NAMESPACE)

clean:
	@echo "==> Uninstalling products-dev from namespace '$(NAMESPACE)'..."
	helm uninstall products-$(NAMESPACE) -n $(NAMESPACE)
