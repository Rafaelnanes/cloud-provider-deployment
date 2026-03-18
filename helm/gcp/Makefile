SHELL      = powershell.exe
.SHELLFLAGS = -NoProfile -Command

APP        := products
NAMESPACE  := dev
REGION     := us-central1
PROJECT_ID := project-3cec667f-8135-4778-9b4
REPO       := docker-main
IMAGE_TAG  := jvm
REGISTRY   := $(REGION)-docker.pkg.dev/$(PROJECT_ID)/$(REPO)
HELM_CHART := ./$(APP)

.PHONY: help gcp-auth build push deploy deploy-only rollback verify clean

help:
	@Write-Host "Usage: make -f helm/gcp/Makefile <target> [APP=products] [NAMESPACE=dev]"
	@Write-Host ""
	@Write-Host "Defaults: APP=$(APP)  NAMESPACE=$(NAMESPACE)"
	@Write-Host ""
	@Write-Host "Setup:"
	@Write-Host "  gcp-auth        Configure Docker to authenticate with Artifact Registry"
	@Write-Host ""
	@Write-Host "Build & Deploy:"
	@Write-Host "  build           Build APP:jvm Docker image locally"
	@Write-Host "  push            Tag and push image to Artifact Registry"
	@Write-Host "  deploy          push + helm upgrade --install to NAMESPACE"
	@Write-Host ""
	@Write-Host "Utilities:"
	@Write-Host "  verify          Send test request to the LoadBalancer external IP"
	@Write-Host "  rollback        Roll back APP Helm release to previous revision"
	@Write-Host "  clean           Uninstall APP Helm release from NAMESPACE"
	@Write-Host ""
	@Write-Host "Examples:"
	@Write-Host "  make -f helm/gcp/Makefile deploy APP=products NAMESPACE=dev"
	@Write-Host "  make -f helm/gcp/Makefile verify APP=products NAMESPACE=dev"

# ── Setup ────────────────────────────────────────────────────────────────────

gcp-auth:
	@Write-Host "==> Configuring Docker for Artifact Registry ($(REGION))..."
	gcloud auth configure-docker $(REGION)-docker.pkg.dev

# ── Build & Push ─────────────────────────────────────────────────────────────

build:
	@Write-Host "==> [$(APP)] Building $(APP):$(IMAGE_TAG) image..."
	docker build -f ../../apps/$(APP)/docker/Dockerfile-jvm -t $(APP):$(IMAGE_TAG) ../../apps/$(APP)

push: build
	@Write-Host "==> [$(APP)] Tagging and pushing to $(REGISTRY)..."
	docker tag $(APP):$(IMAGE_TAG) $(REGISTRY)/$(APP):$(IMAGE_TAG)
	docker push $(REGISTRY)/$(APP):$(IMAGE_TAG)

# ── Deploy ───────────────────────────────────────────────────────────────────

deploy-only:
	@Write-Host "==> [$(APP)] Deploying Helm release to namespace '$(NAMESPACE)' on GCP... IMAGE_TAG='$(IMAGE_TAG)' - image.name='$(REGISTRY)/$(APP)' "
	helm upgrade --install $(APP) $(HELM_CHART) -f $(HELM_CHART)/values.yaml --set image.name=$(REGISTRY)/$(APP) --set image.tag=$(IMAGE_TAG) -n $(NAMESPACE) --create-namespace
	@Write-Host "==> Waiting for rollout to complete..."
	kubectl rollout status deployment/$(APP) -n $(NAMESPACE)

deploy: push deploy-only

# ── Utilities ────────────────────────────────────────────────────────────────

verify:
	@Write-Host "==> [$(APP)] Fetching LoadBalancer external IP..."
	$$ip = kubectl get svc $(APP)-$(NAMESPACE) -n $(NAMESPACE) -o jsonpath='{.status.loadBalancer.ingress[0].ip}'; Write-Host "==> Sending request to http://$$ip/$(APP)..."; Invoke-WebRequest "http://$$ip/$(APP)" -UseBasicParsing

rollback:
	@Write-Host "==> [$(APP)] Rolling back $(APP)-$(NAMESPACE) in namespace '$(NAMESPACE)'..."
	helm rollback $(APP)-$(NAMESPACE) -n $(NAMESPACE)

clean:
	@Write-Host "==> [$(APP)] Uninstalling $(APP)-$(NAMESPACE) from namespace '$(NAMESPACE)'..."
	helm uninstall $(APP)-$(NAMESPACE) -n $(NAMESPACE)
