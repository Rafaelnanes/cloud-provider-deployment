APP        := products
NAMESPACE  := dev
HELM_CHART := ./helm/local/$(APP)

.PHONY: build deploy rollback verify verify-products verify-users verify-all verify-networkpolicy clean setup-namespaces setup-istio setup cluster-create setup-nginx setup-nginx-routing help

help:
	@echo "Usage: make <target> [APP=products|users] [NAMESPACE=dev|prod]"
	@echo ""
	@echo "Defaults: APP=$(APP)  NAMESPACE=$(NAMESPACE)"
	@echo ""
	@echo "Cluster:"
	@echo "  cluster-create     Start minikube cluster (run once)"
	@echo ""
	@echo "Setup:"
	@echo "  setup              Run all setup steps (istio + namespaces + nginx)"
	@echo "  setup-istio        Install Istio with ingress gateway"
	@echo "  setup-namespaces   Create and label dev/prod namespaces"
	@echo "  setup-nginx        Enable NGINX Ingress Controller addon in minikube"
	@echo "  setup-nginx-routing Deploy nginx-ingress Helm chart (ExternalName + Ingress)"
	@echo ""
	@echo "Build & Deploy:"
	@echo "  build              Build APP:jvm image directly inside minikube's Docker daemon"
	@echo "  deploy             Build and deploy APP to NAMESPACE"
	@echo "  deploy-all         Build and deploy all apps to NAMESPACE"
	@echo ""
	@echo "Utilities:"
	@echo "  verify             Send test request to http://localhost/rbn/NAMESPACE/APP"
	@echo "  verify-products    verify for products"
	@echo "  verify-users       verify for users"
	@echo "  verify-all         verify both apps"
	@echo "  rollback           Roll back APP release to previous revision"
	@echo "  clean              Uninstall APP release from NAMESPACE"
	@echo "  clean-all          Uninstall all releases from NAMESPACE"
	@echo ""
	@echo "Examples:"
	@echo "  make deploy APP=users NAMESPACE=dev"
	@echo "  make deploy-all NAMESPACE=prod"
	@echo "  make verify APP=products NAMESPACE=dev"

# Phase 1 - Install required components

cluster-create:
	@echo "==> Starting minikube cluster..."
	minikube start --driver=docker

setup-namespaces:
	@echo "==> Creating and labeling dev and prod namespaces..."
	kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -
	kubectl create namespace prod --dry-run=client -o yaml | kubectl apply -f -
	kubectl label namespace dev istio-injection=enabled --overwrite
	kubectl label namespace prod istio-injection=enabled --overwrite

setup-istio:
	@echo "==> Installing Istio with minimal profile and ingress gateway..."
	istioctl install --set profile=minimal --set components.ingressGateways[0].enabled=true --set components.ingressGateways[0].name=istio-ingressgateway -y

setup-nginx:
	@echo "==> Enabling NGINX Ingress Controller addon..."
	minikube addons enable ingress
	@echo "==> Waiting for NGINX controller to be ready..."
	kubectl wait --namespace ingress-nginx \
	  --for=condition=ready pod \
	  --selector=app.kubernetes.io/component=controller \
	  --timeout=120s

setup-nginx-routing:
	@echo "==> Deploying nginx-ingress Helm chart..."
	helm upgrade --install nginx-ingress ./helm/local/nginx-ingress -n ingress-nginx --create-namespace

setup: setup-istio setup-namespaces setup-nginx setup-nginx-routing
	@echo "==> Cluster is ready."

# Phase 2 - Build and deploy

build:
	@echo "==> [$(APP)] - Building $(APP):jvm image inside minikube..."
	eval $$(minikube docker-env) && docker build -f ./apps/$(APP)/docker/Dockerfile-jvm -t $(APP):jvm ./apps/$(APP)

deploy: build
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
	@echo "==> [$(APP)] Sending test request to http://localhost/rbn/$(NAMESPACE)/$(APP)..."
	@echo "    NOTE: requires 'minikube tunnel' running in a separate terminal."
	curl -H "X-API-KEY: $(NAMESPACE)-secret-key" http://localhost/rbn/$(NAMESPACE)/$(APP)

verify-products:
	$(MAKE) verify APP=products NAMESPACE=$(NAMESPACE)

verify-users:
	$(MAKE) verify APP=users NAMESPACE=$(NAMESPACE)

verify-all: verify-users verify-products

verify-networkpolicy:
	@echo "==> Verifying direct access to Istio IngressGateway is blocked by NetworkPolicy..."
	@echo "    Run in a separate terminal: kubectl port-forward -n istio-system svc/istio-ingressgateway 8888:80"
	@echo "    Then run: curl -v http://localhost:8888/rbn/$(NAMESPACE)/$(APP)"
	@echo "    Expected: connection refused or timeout (not HTTP 200)"
	@echo "    Traffic via NGINX (http://localhost/rbn/$(NAMESPACE)/$(APP)) must still return HTTP 200."

rollback:
	@echo "==> [$(APP)] Rolling back $(APP)-$(NAMESPACE) in namespace '$(NAMESPACE)'..."
	helm rollback $(APP)-$(NAMESPACE) -n $(NAMESPACE)

clean:
	@echo "==> [$(APP)] Uninstalling $(APP)-$(NAMESPACE) from namespace '$(NAMESPACE)'..."
	helm uninstall $(APP)-$(NAMESPACE) -n $(NAMESPACE)

clean-all:
	$(MAKE) clean APP=products NAMESPACE=$(NAMESPACE)
	$(MAKE) clean APP=users NAMESPACE=$(NAMESPACE)
