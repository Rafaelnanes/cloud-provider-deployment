SHELL      = powershell.exe
.SHELLFLAGS = -NoProfile -Command

APP          := products
NAMESPACE    := dev
REGION       := us-central1-a
PROJECT_ID   := project-3cec667f-8135-4778-9b4
CLUSTER_NAME := gke-cluster
REPO         := docker-main
IMAGE_TAG  := 0.0.1-SNAPSHOT-gsm
REGISTRY   := us-central1-docker.pkg.dev/$(PROJECT_ID)/$(REPO)
HELM_CHART    := ./$(APP)
INFRA_CHART   := ./infra
ISTIO_CHART   := ./istio
DOMAIN_PREFIX := rbn
GATEWAY_NAME  := rbn-gateway

.PHONY: help gcp-auth build push deploy-all deploy deploy-infra deploy-istio rollback verify clean clean-infra \
        asm-inject-ns asm-mtls asm-authz asm-status asm-verify \
        cluster-create cluster-create-standard cluster-credentials

help:
	@Write-Host "Usage: make -f helm/gcp/Makefile <target> [APP=products] [NAMESPACE=dev]"
	@Write-Host ""
	@Write-Host "Defaults: APP=$(APP)  NAMESPACE=$(NAMESPACE)"
	@Write-Host ""
	@Write-Host "Cluster:"
	@Write-Host "  cluster-create          Create GKE Autopilot cluster (default, no node management)"
	@Write-Host "  cluster-create-standard Create GKE Standard cluster (supports Workload Identity + GSM)"
	@Write-Host "  cluster-credentials     Fetch kubeconfig for the Standard cluster"
	@Write-Host ""
	@Write-Host "Setup:"
	@Write-Host "  gcp-auth        Configure Docker to authenticate with Artifact Registry"
	@Write-Host ""
	@Write-Host "Build & Deploy:"
	@Write-Host "  build           Build and push APP:jvm to Artifact Registry via Jib"
	@Write-Host "  deploy-infra    Deploy shared infra chart (GKE Gateway) to NAMESPACE"
	@Write-Host "  deploy-istio    Deploy Istio policies chart to NAMESPACE (uses values-NAMESPACE.yaml)"
	@Write-Host "  deploy-all         push + helm upgrade --install to NAMESPACE"
	@Write-Host "  deploy          helm upgrade --install to NAMESPACE"
	@Write-Host ""
	@Write-Host "ASM (Anthos Service Mesh):"
	@Write-Host "  asm-inject-ns   Label NAMESPACE for sidecar injection"
	@Write-Host "  asm-mtls        Apply PeerAuthentication (STRICT mTLS) to NAMESPACE (Step 9)"
	@Write-Host "  asm-authz       Apply AuthorizationPolicy to NAMESPACE (Step 10)"
	@Write-Host "  asm-status      Show ASM mesh status for the cluster (Step 11)"
	@Write-Host "  asm-verify      Show sidecar proxy status for all pods in NAMESPACE (Step 11)"
	@Write-Host ""
	@Write-Host "Utilities:"
	@Write-Host "  verify          Send test request to the GKE Gateway external IP"
	@Write-Host "  rollback        Roll back APP Helm release to previous revision"
	@Write-Host "  clean           Uninstall APP Helm release from NAMESPACE"
	@Write-Host "  clean-infra     Uninstall infra (Gateway + HTTPRoute) from NAMESPACE"
	@Write-Host ""
	@Write-Host "Examples:"
	@Write-Host "  make -f helm/gcp/Makefile deploy APP=products NAMESPACE=dev"
	@Write-Host "  make -f helm/gcp/Makefile verify APP=products NAMESPACE=dev"
	@Write-Host "  make -f helm/gcp/Makefile asm-inject-ns NAMESPACE=dev"

# ── Cluster ──────────────────────────────────────────────────────────────────

# Default: Autopilot — fully managed nodes, no Workload Identity for pods, no GSM support
cluster-create:
	@Write-Host "==> Creating GKE Autopilot cluster 'autopilot-cluster-1'..."
	gcloud beta container --project "$(PROJECT_ID)" clusters create-auto "autopilot-cluster-1" --region "$(REGION)" --release-channel "regular" --enable-dns-access --enable-k8s-tokens-via-dns --enable-k8s-certs-via-dns --enable-ip-access --no-enable-google-cloud-access --network "projects/$(PROJECT_ID)/global/networks/default" --subnetwork "projects/$(PROJECT_ID)/regions/$(REGION)/subnetworks/default" --cluster-ipv4-cidr "/17" --binauthz-evaluation-mode=DISABLED --fleet-project=$(PROJECT_ID)

# Standard: 1 node e2-standard-2, Workload Identity enabled — required for GSM + External Secrets Operator
cluster-create-standard:
	@Write-Host "==> Creating GKE Standard cluster '$(CLUSTER_NAME)' in zone $(REGION)-a..."
	gcloud container clusters create "$(CLUSTER_NAME)" --project "$(PROJECT_ID)" --zone "$(REGION)-a" --release-channel "regular" --machine-type "e2-standard-2" --num-nodes 1 --workload-pool="$(PROJECT_ID).svc.id.goog" --gateway-api=standard --fleet-project="$(PROJECT_ID)" --enable-ip-alias --enable-autoupgrade --enable-autorepair --binauthz-evaluation-mode=DISABLED

cluster-credentials:
	@Write-Host "==> Fetching credentials for Standard cluster '$(CLUSTER_NAME)'..."
	gcloud container clusters get-credentials "$(CLUSTER_NAME)" --zone "$(REGION)-a" --project "$(PROJECT_ID)"

# ── Setup ────────────────────────────────────────────────────────────────────

gcp-auth:
	@Write-Host "==> Configuring Docker for Artifact Registry ($(REGION))..."
	gcloud auth configure-docker $(REGION)-docker.pkg.dev

# ── Build & Push ─────────────────────────────────────────────────────────────

build:
	@Write-Host "==> [$(APP)] Building and pushing $(APP):$(IMAGE_TAG) to $(REGISTRY) via Jib..."
	cd ../../apps/$(APP); ./gradlew jib -Pgcp

# ── Deploy ───────────────────────────────────────────────────────────────────

deploy-infra:
	@Write-Host "==> Deploying shared infra chart to namespace '$(NAMESPACE)'..."
	helm upgrade --install infra $(INFRA_CHART) -n $(NAMESPACE) --create-namespace

deploy-istio:
	@Write-Host "==> Deploying Istio policies chart to namespace '$(NAMESPACE)'..."
	helm upgrade --install istio-policies $(ISTIO_CHART) -f $(ISTIO_CHART)/values-$(NAMESPACE).yaml -n $(NAMESPACE) --create-namespace

deploy:
	@Write-Host "==> [$(APP)] Deploying Helm release to namespace '$(NAMESPACE)' on GCP... IMAGE_TAG='$(IMAGE_TAG)' - image.name='$(REGISTRY)/$(APP)' "
	helm upgrade --install $(APP) $(HELM_CHART) -f $(HELM_CHART)/values.yaml -f $(HELM_CHART)/values-$(NAMESPACE).yaml --set image.name=$(REGISTRY)/$(APP) --set image.tag=$(IMAGE_TAG) -n $(NAMESPACE) --create-namespace
	@Write-Host "==> Waiting for rollout to complete..."
	kubectl rollout status deployment/$(APP) -n $(NAMESPACE)

deploy-full: build deploy

# ── Utilities ────────────────────────────────────────────────────────────────

verify:
	@Write-Host "==> [$(APP)] Fetching Gateway external IP..."
	$$ip = kubectl get gateway $(GATEWAY_NAME) -n $(NAMESPACE) -o jsonpath='{.status.addresses[0].value}'; Write-Host "==> Sending request to http://$$ip/$(DOMAIN_PREFIX)/$(APP)..."; Invoke-WebRequest "http://$$ip/$(DOMAIN_PREFIX)/$(APP)" -UseBasicParsing

rollback:
	@Write-Host "==> [$(APP)] Rolling back $(APP)-$(NAMESPACE) in namespace '$(NAMESPACE)'..."
	helm rollback $(APP)-$(NAMESPACE) -n $(NAMESPACE)

clean:
	@Write-Host "==> [$(APP)] Uninstalling $(APP)-$(NAMESPACE) from namespace '$(NAMESPACE)'..."
	helm uninstall $(APP) -n $(NAMESPACE)

clean-infra:
	@Write-Host "==> Uninstalling infra chart from namespace '$(NAMESPACE)'..."
	helm uninstall infra -n $(NAMESPACE)

# ── ASM (Anthos Service Mesh) ─────────────────────────────────────────────────

asm-inject-ns:
	@Write-Host "==> [Step 8] Labelling namespace '$(NAMESPACE)' for Istio sidecar injection..."
	kubectl label namespace $(NAMESPACE) istio.io/rev=asm-managed --overwrite
	kubectl get namespace $(NAMESPACE) --show-labels

asm-mtls:
	@Write-Host "==> [Step 9] Applying STRICT mTLS PeerAuthentication to namespace '$(NAMESPACE)'..."
	kubectl apply -f ./istio/peer-authentication.yaml -n $(NAMESPACE)
	kubectl get peerauthentication -n $(NAMESPACE)

asm-authz:
	@Write-Host "==> [Step 10] Deploying Istio AuthorizationPolicies to namespace '$(NAMESPACE)'..."
	$(MAKE) -f helm/gcp/Makefile deploy-istio NAMESPACE=$(NAMESPACE)
	kubectl get authorizationpolicy -n $(NAMESPACE)

asm-status:
	@Write-Host "==> [Step 11] Checking ASM mesh status for cluster '$(CLUSTER_NAME)'..."
	gcloud container fleet mesh describe --project $(PROJECT_ID)

asm-verify:
	@Write-Host "==> [Step 11] Checking pod/sidecar status for namespace '$(NAMESPACE)'..."
	kubectl get pods -n $(NAMESPACE) -o wide
	kubectl get pods -n $(NAMESPACE) -o jsonpath="{range .items[*]}{.metadata.name}{'\t'}{range .spec.containers[*]}{.name}{' '}{end}{'\n'}{end}"
