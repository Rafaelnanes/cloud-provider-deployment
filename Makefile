APP        := products
NAMESPACE  := dev
HELM_CHART := ./helm/$(APP)
VERIFY_URL := http://127.0.0.1:64537

.PHONY: build kind-load deploy rollback verify clean setup-namespaces setup-istio setup help

help:
	@echo "Usage: make <target> [APP=products|users] [NAMESPACE=dev|prod]"
	@echo ""
	@echo "Defaults: APP=$(APP)  NAMESPACE=$(NAMESPACE)"
	@echo ""
	@echo "Setup:"
	@echo "  setup              Run setup-istio then setup-namespaces"
	@echo "  setup-istio        Install Istio with ingress gateway"
	@echo "  setup-namespaces   Create and label dev/prod namespaces"
	@echo ""
	@echo "Build & Deploy:"
	@echo "  build              Build APP:jvm Docker image"
	@echo "  kind-load          Load APP:jvm image into kind cluster"
	@echo "  deploy             Build, load into kind, and deploy APP to NAMESPACE"
	@echo "  deploy-all         Build and deploy all apps to NAMESPACE"
	@echo ""
	@echo "Utilities:"
	@echo "  verify             Send test request to VERIFY_URL/rbn/APP"
	@echo "  rollback           Roll back APP release to previous revision"
	@echo "  clean              Uninstall APP release from NAMESPACE"
	@echo "  clean-all          Uninstall all releases from NAMESPACE"
	@echo ""
	@echo "Examples:"
	@echo "  make deploy APP=users NAMESPACE=dev"
	@echo "  make deploy-all NAMESPACE=prod"
	@echo "  make verify APP=products VERIFY_URL=http://127.0.0.1:<port>"

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

# Phase 2 - Build and deploy

build:
	@echo "==> [$(APP)] - Building $(APP):jvm image..."
	docker build -f ./apps/$(APP)/docker/Dockerfile-jvm -t $(APP):jvm ./apps/$(APP)

kind-load:
	@echo "==> [$(APP)] - Loading $(APP):jvm into kind cluster..."
	kind load docker-image $(APP):jvm

deploy: build kind-load
	@echo "==> [$(APP)] Deploying Helm release to namespace '$(NAMESPACE)'..."
	helm upgrade --install $(APP)-$(NAMESPACE) $(HELM_CHART) \
		-f $(HELM_CHART)/values.yaml \
		-f $(HELM_CHART)/values-$(NAMESPACE).yaml \
		-n $(NAMESPACE)
	@echo "==> Waiting for rollout to complete..."
	kubectl rollout status deployment/$(APP)-$(NAMESPACE) -n $(NAMESPACE)

deploy-all:
	$(MAKE) deploy APP=products NAMESPACE=$(NAMESPACE)
	$(MAKE) deploy APP=users NAMESPACE=$(NAMESPACE)

# Phase 3 - Utilities

verify:
	@echo "!! Make sure to run previously: minikube service istio-ingressgateway -n istio-system --url"
	@echo "==> [$(APP)] Sending test request to $(VERIFY_URL)/rbn/$(APP)..."
	curl -H "X-API-KEY: $(NAMESPACE)-secret-key" $(VERIFY_URL)/rbn/$(NAMESPACE)/$(APP)

rollback:
	@echo "==> [$(APP)] Rolling back $(APP)-$(NAMESPACE) in namespace '$(NAMESPACE)'..."
	helm rollback $(APP)-$(NAMESPACE) -n $(NAMESPACE)

clean:
	@echo "==> [$(APP)] Uninstalling $(APP)-$(NAMESPACE) from namespace '$(NAMESPACE)'..."
	helm uninstall $(APP)-$(NAMESPACE) -n $(NAMESPACE)

clean-all:
	$(MAKE) clean APP=products NAMESPACE=$(NAMESPACE)
	$(MAKE) clean APP=users NAMESPACE=$(NAMESPACE)
