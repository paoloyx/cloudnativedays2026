# ─────────────────────────────────────────────────────────────────────────────
# Tool overrides
# ─────────────────────────────────────────────────────────────────────────────
K3D    ?= k3d
KUBECTL ?= kubectl
CURL    ?= curl
DOCKER  ?= docker
CTR     ?= ctr
HELM    ?= helm

# ─────────────────────────────────────────────────────────────────────────────
# Cluster configuration
# ─────────────────────────────────────────────────────────────────────────────
CLUSTER_PREFIX           ?= cloudnativedays2026
CTRL_PLANE_CLUSTER_NAME  ?= $(CLUSTER_PREFIX)-ctrl-plane
WORKER_DEV_CLUSTER_NAME  ?= $(CLUSTER_PREFIX)-worker-dev
WORKER_PROD_CLUSTER_NAME ?= $(CLUSTER_PREFIX)-worker-prod

CTRL_PLANE_CONTEXT  ?= k3d-$(CTRL_PLANE_CLUSTER_NAME)
WORKER_DEV_CONTEXT  ?= k3d-$(WORKER_DEV_CLUSTER_NAME)
WORKER_PROD_CONTEXT ?= k3d-$(WORKER_PROD_CLUSTER_NAME)

K3D_SHARED_NETWORK ?= $(CLUSTER_PREFIX)-network

K3S_IMAGE_REPOSITORY ?= rancher/k3s
K3S_IMAGE_VERSION    ?= v1.35.3-k3s1
K3S_IMAGE ?= $(K3S_IMAGE_REPOSITORY):$(K3S_IMAGE_VERSION)
# Runtime image platform used when pulling third-party images.
# Auto-detected from host architecture, with manual override support.
# Examples:
#   make bootstrap
#   make IMAGE_PLATFORM=linux/arm64 bootstrap
#   make IMAGE_PLATFORM=linux/amd64 bootstrap
HOST_ARCH ?= $(shell uname -m 2>/dev/null)
IMAGE_PLATFORM_AUTO ?= $(if $(filter arm64 aarch64,$(HOST_ARCH)),linux/arm64,linux/amd64)
IMAGE_PLATFORM ?= $(IMAGE_PLATFORM_AUTO)

# Required: path on the host to a CA certificate mounted inside every cluster
# node so that TLS works behind a corporate proxy.
HOST_CA_CERT_PATH      ?=
CONTAINER_CA_CERT_PATH ?= /etc/ssl/certs/wk-zscaler-rootca.crt

K3D_INGRESS_HTTP_PORT  ?= 80
K3D_INGRESS_HTTPS_PORT ?= 443

# ─────────────────────────────────────────────────────────────────────────────
# cert-manager
# ─────────────────────────────────────────────────────────────────────────────
CERT_MANAGER_VERSION      ?= v1.20.0
CERT_MANAGER_MANIFEST_URL ?= https://github.com/cert-manager/cert-manager/releases/download/$(CERT_MANAGER_VERSION)/cert-manager.yaml

# ─────────────────────────────────────────────────────────────────────────────
# Kratix
# ─────────────────────────────────────────────────────────────────────────────
KRATIX_VERSION      ?= latest
KRATIX_MANIFEST_URL ?= https://github.com/syntasso/kratix/releases/$(KRATIX_VERSION)/download/kratix.yaml
# Optional image pin; if empty the image is resolved from the manifest.
KRATIX_UPSTREAM_IMAGE ?=
KRATIX_LOCAL_IMAGE    ?= kratix-platform:k3d-local
KRATIX_IMPORTED_IMAGE ?= docker.io/library/$(KRATIX_LOCAL_IMAGE)
CTRL_PLANE_SERVER_NODE ?= k3d-$(CTRL_PLANE_CLUSTER_NAME)-server-0
CTR_NAMESPACE          ?= k8s.io
K3D_IMAGE_IMPORT       ?= $(K3D) image import

# ─────────────────────────────────────────────────────────────────────────────
# Gitea
# ─────────────────────────────────────────────────────────────────────────────
GITEA_HELM_REPO_NAME    ?= gitea-charts
GITEA_HELM_REPO_URL     ?= https://dl.gitea.com/charts/
GITEA_RELEASE_NAME      ?= gitea
GITEA_CHART             ?= $(GITEA_HELM_REPO_NAME)/gitea
GITEA_CHART_VERSION     ?= v12.6.0
GITEA_UPSTREAM_IMAGE ?= docker.gitea.com/gitea:1.26-rootless
GITEA_LOCAL_IMAGE    ?= gitea:k3d-local
GITEA_IMPORTED_IMAGE ?= docker.io/library/$(GITEA_LOCAL_IMAGE)
# Ingress hostname — matches the k3d serverlb container name so that worker
# clusters can reach Gitea using the Host header over the shared Docker network.
CTRL_PLANE_SERVERLB_NODE ?= k3d-$(CTRL_PLANE_CLUSTER_NAME)-serverlb
GITEA_INGRESS_HOST       ?= $(CTRL_PLANE_SERVERLB_NODE)
GITEA_INGRESS_CLASS_NAME ?= traefik
GITEA_ADMIN_ACCOUNT  ?= admin
GITEA_ADMIN_PASSWORD ?= admin123!
GITEA_ADMIN_EMAIL    ?= admin@local
GITEA_REPO_NAME      ?= cloudnativedays2026
GIT_STATE_STORE_NAME ?= github-$(GITEA_REPO_NAME)-repo
FLUX_GIT_REPOSITORY_NAME ?= $(GITEA_REPO_NAME)-repo
KRATIX_GIT_AUTHOR_NAME ?= kratix
KRATIX_GIT_AUTHOR_EMAIL ?= kratix@cloudnativedays2026.it
GITEA_CONNECTIVITY_CHECK_IMAGE   ?= curlimages/curl
GITEA_CONNECTIVITY_MAX_ATTEMPTS  ?= 20
GITEA_CONNECTIVITY_RETRY_SECONDS ?= 10
GITEA_CONNECTIVITY_KUBECTL_TIMEOUT_SECONDS ?= 45
GITEA_CONNECTIVITY_CURL_TIMEOUT_SECONDS ?= 10
GITEA_CONNECTIVITY_CURL_CONNECT_TIMEOUT_SECONDS ?= 3
GITEA_HELM_SET_ARGS ?= \
	--set-string image.fullOverride=$(GITEA_UPSTREAM_IMAGE) \
	--set image.rootless=true \
	--set ingress.enabled=true \
	--set-string ingress.className=$(GITEA_INGRESS_CLASS_NAME) \
	--set-string ingress.hosts[0].host=$(GITEA_INGRESS_HOST) \
	--set-string ingress.hosts[0].paths[0].path=/ \
	--set-string gitea.admin.username=$(GITEA_ADMIN_ACCOUNT) \
	--set-string gitea.admin.password=$(GITEA_ADMIN_PASSWORD) \
	--set-string gitea.admin.email=$(GITEA_ADMIN_EMAIL) \
	--set-string gitea.admin.passwordMode=keepUpdated \
	--set-string gitea.config.server.ROOT_URL=http://$(GITEA_INGRESS_HOST)/

# ─────────────────────────────────────────────────────────────────────────────
# Flux
# ─────────────────────────────────────────────────────────────────────────────
FLUX_VERSION      ?= v2.8.7
FLUX_MANIFEST_URL ?= https://github.com/fluxcd/flux2/releases/download/$(FLUX_VERSION)/install.yaml

# ─────────────────────────────────────────────────────────────────────────────
# Promise workflow images
# ─────────────────────────────────────────────────────────────────────────────
PROMISE_V001_DIR ?= promise/v0.0.1
PROMISE_V002_DIR ?= promise/v0.0.2
PROMISE_V001_MANIFEST ?= $(PROMISE_V001_DIR)/promise.yaml
PROMISE_IMAGE_DEPS ?= cpng-database-promise-pipeline:v0.0.1
PROMISE_IMAGE_RESOURCE_V001 ?= cpng-database-resource-pipeline:v0.0.1
PROMISE_IMAGE_RESOURCE_V002 ?= cpng-database-resource-pipeline-ha:v0.0.1
PROMISE_DEPS_DOCKERFILE_DIR ?= $(PROMISE_V001_DIR)/workflows/promise/configure/dependencies/configure-deps
PROMISE_RESOURCE_V001_DOCKERFILE_DIR ?= $(PROMISE_V001_DIR)/workflows/resource/configure/database-configure/cpng-database-resource-pipeline
PROMISE_RESOURCE_V002_DOCKERFILE_DIR ?= $(PROMISE_V002_DIR)/workflows/resource/configure/database-configure-ha

# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────
# cluster-exists $(name) — exits 0 when the named k3d cluster already exists.
define cluster-exists
$(K3D) cluster list $(1) --no-headers 2>/dev/null | awk '{print $$1}' | grep -Fx "$(1)" >/dev/null
endef

.PHONY: bootstrap teardown apply-setup \
	_prereqs _network \
	_cluster-ctrl-plane _cluster-worker-dev _cluster-worker-prod \
	_cert-manager _kratix _gitea _gitea-connectivity _gitea-repo _flux _promise-workflow-images _install-promise-v001 _summary \
	_delete-ctrl-plane _delete-worker-dev _delete-worker-prod

# ─────────────────────────────────────────────────────────────────────────────
# Public targets
# ─────────────────────────────────────────────────────────────────────────────

## bootstrap: create all clusters and install all components.
bootstrap: _prereqs _network \
	_cluster-ctrl-plane _cluster-worker-dev _cluster-worker-prod \
	_cert-manager _kratix _gitea \
	_gitea-connectivity _gitea-repo _flux apply-setup _promise-workflow-images _install-promise-v001 _summary

## teardown: delete all clusters in reverse dependency order.
teardown: _delete-worker-prod _delete-worker-dev _delete-ctrl-plane

## apply-setup: apply post-bootstrap setup manifests in dependency order.
apply-setup:
	@set -e; \
	for file in setup/controlplane/state-stores/*.yaml; do \
		GITEA_INGRESS_HOST="$(GITEA_INGRESS_HOST)" \
		GITEA_ADMIN_ACCOUNT="$(GITEA_ADMIN_ACCOUNT)" \
		GITEA_ADMIN_PASSWORD="$(GITEA_ADMIN_PASSWORD)" \
		GITEA_REPO_NAME="$(GITEA_REPO_NAME)" \
		GIT_STATE_STORE_NAME="$(GIT_STATE_STORE_NAME)" \
		FLUX_GIT_REPOSITORY_NAME="$(FLUX_GIT_REPOSITORY_NAME)" \
		KRATIX_GIT_AUTHOR_NAME="$(KRATIX_GIT_AUTHOR_NAME)" \
		KRATIX_GIT_AUTHOR_EMAIL="$(KRATIX_GIT_AUTHOR_EMAIL)" \
		envsubst '$$GITEA_INGRESS_HOST $$GITEA_ADMIN_ACCOUNT $$GITEA_ADMIN_PASSWORD $$GITEA_REPO_NAME $$GIT_STATE_STORE_NAME $$FLUX_GIT_REPOSITORY_NAME $$KRATIX_GIT_AUTHOR_NAME $$KRATIX_GIT_AUTHOR_EMAIL' < "$$file" | \
		$(KUBECTL) --context $(CTRL_PLANE_CONTEXT) apply --filename -; \
	done
	@set -e; \
	for file in setup/controlplane/destinations/*.yaml; do \
		GITEA_INGRESS_HOST="$(GITEA_INGRESS_HOST)" \
		GITEA_ADMIN_ACCOUNT="$(GITEA_ADMIN_ACCOUNT)" \
		GITEA_ADMIN_PASSWORD="$(GITEA_ADMIN_PASSWORD)" \
		GITEA_REPO_NAME="$(GITEA_REPO_NAME)" \
		GIT_STATE_STORE_NAME="$(GIT_STATE_STORE_NAME)" \
		FLUX_GIT_REPOSITORY_NAME="$(FLUX_GIT_REPOSITORY_NAME)" \
		KRATIX_GIT_AUTHOR_NAME="$(KRATIX_GIT_AUTHOR_NAME)" \
		KRATIX_GIT_AUTHOR_EMAIL="$(KRATIX_GIT_AUTHOR_EMAIL)" \
		envsubst '$$GITEA_INGRESS_HOST $$GITEA_ADMIN_ACCOUNT $$GITEA_ADMIN_PASSWORD $$GITEA_REPO_NAME $$GIT_STATE_STORE_NAME $$FLUX_GIT_REPOSITORY_NAME $$KRATIX_GIT_AUTHOR_NAME $$KRATIX_GIT_AUTHOR_EMAIL' < "$$file" | \
		$(KUBECTL) --context $(CTRL_PLANE_CONTEXT) apply --filename -; \
	done
	@set -e; \
	for file in setup/workers/dev/*.yaml; do \
		GITEA_INGRESS_HOST="$(GITEA_INGRESS_HOST)" \
		GITEA_ADMIN_ACCOUNT="$(GITEA_ADMIN_ACCOUNT)" \
		GITEA_ADMIN_PASSWORD="$(GITEA_ADMIN_PASSWORD)" \
		GITEA_REPO_NAME="$(GITEA_REPO_NAME)" \
		GIT_STATE_STORE_NAME="$(GIT_STATE_STORE_NAME)" \
		FLUX_GIT_REPOSITORY_NAME="$(FLUX_GIT_REPOSITORY_NAME)" \
		KRATIX_GIT_AUTHOR_NAME="$(KRATIX_GIT_AUTHOR_NAME)" \
		KRATIX_GIT_AUTHOR_EMAIL="$(KRATIX_GIT_AUTHOR_EMAIL)" \
		envsubst '$$GITEA_INGRESS_HOST $$GITEA_ADMIN_ACCOUNT $$GITEA_ADMIN_PASSWORD $$GITEA_REPO_NAME $$GIT_STATE_STORE_NAME $$FLUX_GIT_REPOSITORY_NAME $$KRATIX_GIT_AUTHOR_NAME $$KRATIX_GIT_AUTHOR_EMAIL' < "$$file" | \
		$(KUBECTL) --context $(WORKER_DEV_CONTEXT) apply --filename -; \
	done
	@set -e; \
	for file in setup/workers/prod/*.yaml; do \
		GITEA_INGRESS_HOST="$(GITEA_INGRESS_HOST)" \
		GITEA_ADMIN_ACCOUNT="$(GITEA_ADMIN_ACCOUNT)" \
		GITEA_ADMIN_PASSWORD="$(GITEA_ADMIN_PASSWORD)" \
		GITEA_REPO_NAME="$(GITEA_REPO_NAME)" \
		GIT_STATE_STORE_NAME="$(GIT_STATE_STORE_NAME)" \
		FLUX_GIT_REPOSITORY_NAME="$(FLUX_GIT_REPOSITORY_NAME)" \
		KRATIX_GIT_AUTHOR_NAME="$(KRATIX_GIT_AUTHOR_NAME)" \
		KRATIX_GIT_AUTHOR_EMAIL="$(KRATIX_GIT_AUTHOR_EMAIL)" \
		envsubst '$$GITEA_INGRESS_HOST $$GITEA_ADMIN_ACCOUNT $$GITEA_ADMIN_PASSWORD $$GITEA_REPO_NAME $$GIT_STATE_STORE_NAME $$FLUX_GIT_REPOSITORY_NAME $$KRATIX_GIT_AUTHOR_NAME $$KRATIX_GIT_AUTHOR_EMAIL' < "$$file" | \
		$(KUBECTL) --context $(WORKER_PROD_CONTEXT) apply --filename -; \
	done

# ─────────────────────────────────────────────────────────────────────────────
# Bootstrap steps
# ─────────────────────────────────────────────────────────────────────────────

_prereqs:
	@command -v envsubst >/dev/null 2>&1 || { echo "envsubst is required (install gettext)"; exit 1; }

_network:
	@$(DOCKER) network inspect $(K3D_SHARED_NETWORK) >/dev/null 2>&1 || \
		$(DOCKER) network create $(K3D_SHARED_NETWORK)

_cluster-ctrl-plane:
	@if $(call cluster-exists,$(CTRL_PLANE_CLUSTER_NAME)); then \
		echo "Cluster $(CTRL_PLANE_CLUSTER_NAME) already exists, skipping"; \
	else \
		$(K3D) cluster create $(CTRL_PLANE_CLUSTER_NAME) \
			--network $(K3D_SHARED_NETWORK) \
			$(if $(HOST_CA_CERT_PATH),--volume $(HOST_CA_CERT_PATH):$(CONTAINER_CA_CERT_PATH)) \
			--port $(K3D_INGRESS_HTTP_PORT):80@loadbalancer \
			--port $(K3D_INGRESS_HTTPS_PORT):443@loadbalancer \
			--image $(K3S_IMAGE); \
	fi

_cluster-worker-dev:
	@if $(call cluster-exists,$(WORKER_DEV_CLUSTER_NAME)); then \
		echo "Cluster $(WORKER_DEV_CLUSTER_NAME) already exists, skipping"; \
	else \
		$(K3D) cluster create $(WORKER_DEV_CLUSTER_NAME) \
			--network $(K3D_SHARED_NETWORK) \
			$(if $(HOST_CA_CERT_PATH),--volume $(HOST_CA_CERT_PATH):$(CONTAINER_CA_CERT_PATH)) \
			--image $(K3S_IMAGE); \
	fi

_cluster-worker-prod:
	@if $(call cluster-exists,$(WORKER_PROD_CLUSTER_NAME)); then \
		echo "Cluster $(WORKER_PROD_CLUSTER_NAME) already exists, skipping"; \
	else \
		$(K3D) cluster create $(WORKER_PROD_CLUSTER_NAME) \
			--network $(K3D_SHARED_NETWORK) \
			$(if $(HOST_CA_CERT_PATH),--volume $(HOST_CA_CERT_PATH):$(CONTAINER_CA_CERT_PATH)) \
			--image $(K3S_IMAGE); \
	fi

_cert-manager:
	$(KUBECTL) --context $(CTRL_PLANE_CONTEXT) apply --filename $(CERT_MANAGER_MANIFEST_URL)
	$(KUBECTL) --context $(CTRL_PLANE_CONTEXT) \
		wait --for=condition=available deployment/cert-manager-webhook \
		-n cert-manager --timeout=240s

_kratix:
	@kratix_image="$(KRATIX_UPSTREAM_IMAGE)"; \
	if [ -z "$$kratix_image" ]; then \
		kratix_image="$$($(CURL) -fsSL $(KRATIX_MANIFEST_URL) | awk '/image:/ { print $$2; exit }')"; \
	fi; \
	test -n "$$kratix_image" || { echo "Unable to resolve Kratix image from $(KRATIX_MANIFEST_URL)"; exit 1; }; \
	$(DOCKER) pull --platform $(IMAGE_PLATFORM) "$$kratix_image"; \
	$(DOCKER) tag "$$kratix_image" $(KRATIX_LOCAL_IMAGE); \
	$(DOCKER) save $(KRATIX_LOCAL_IMAGE) | $(DOCKER) exec -i $(CTRL_PLANE_SERVER_NODE) $(CTR) -n $(CTR_NAMESPACE) image import -; \
	kratix_digest="$$($(DOCKER) exec $(CTRL_PLANE_SERVER_NODE) $(CTR) -n $(CTR_NAMESPACE) images ls -q | grep kratix-platform | head -1)"; \
	if [ -n "$$kratix_digest" ]; then \
		$(DOCKER) exec $(CTRL_PLANE_SERVER_NODE) $(CTR) -n $(CTR_NAMESPACE) images tag --force "$$kratix_digest" "$$kratix_image"; \
	fi
	$(KUBECTL) --context $(CTRL_PLANE_CONTEXT) apply --filename $(KRATIX_MANIFEST_URL)

_gitea:
	gitea_image="$(GITEA_UPSTREAM_IMAGE)"; \
	$(DOCKER) pull --platform $(IMAGE_PLATFORM) "$$gitea_image"; \
	$(DOCKER) tag "$$gitea_image" $(GITEA_LOCAL_IMAGE); \
	$(DOCKER) save $(GITEA_LOCAL_IMAGE) | $(DOCKER) exec -i $(CTRL_PLANE_SERVER_NODE) $(CTR) -n $(CTR_NAMESPACE) image import -; \
	gitea_digest="$$($(DOCKER) exec $(CTRL_PLANE_SERVER_NODE) $(CTR) -n $(CTR_NAMESPACE) images ls -q | grep gitea | head -1)"; \
	if [ -n "$$gitea_digest" ]; then \
		$(DOCKER) exec $(CTRL_PLANE_SERVER_NODE) $(CTR) -n $(CTR_NAMESPACE) images tag --force "$$gitea_digest" "$$gitea_image"; \
	fi
	$(HELM) repo add $(GITEA_HELM_REPO_NAME) $(GITEA_HELM_REPO_URL) --force-update
	$(HELM) --kube-context $(CTRL_PLANE_CONTEXT) upgrade --install $(GITEA_RELEASE_NAME) $(GITEA_CHART) --version $(GITEA_CHART_VERSION) $(GITEA_HELM_SET_ARGS)
	$(KUBECTL) --context $(CTRL_PLANE_CONTEXT) \
		wait --for=condition=ready pod -l app.kubernetes.io/name=gitea -n default --timeout=600s

_gitea-connectivity:
	@GITEA_INGRESS_IP="$$($(KUBECTL) --context $(CTRL_PLANE_CONTEXT) -n kube-system get svc traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"; \
	test -n "$$GITEA_INGRESS_IP" || { echo "Unable to resolve Traefik ingress IP"; exit 1; }; \
	timeout_cmd="$$($(SHELL) -c 'command -v timeout || command -v gtimeout || true')"; \
	for ctx in $(WORKER_DEV_CONTEXT) $(WORKER_PROD_CONTEXT); do \
		attempt=1; \
		while [ $$attempt -le $(GITEA_CONNECTIVITY_MAX_ATTEMPTS) ]; do \
			echo "  [$$ctx] connectivity check (attempt $$attempt/$(GITEA_CONNECTIVITY_MAX_ATTEMPTS))"; \
			$(KUBECTL) --context $$ctx delete pod gitea-check --ignore-not-found >/dev/null 2>&1 || true; \
			if [ -n "$$timeout_cmd" ]; then \
				$$timeout_cmd $(GITEA_CONNECTIVITY_KUBECTL_TIMEOUT_SECONDS) \
					$(KUBECTL) --context $$ctx --request-timeout=20s run gitea-check --attach=true --rm --restart=Never --image=$(GITEA_CONNECTIVITY_CHECK_IMAGE) --command -- \
					sh -ec 'code=$$(curl -sS --connect-timeout $(GITEA_CONNECTIVITY_CURL_CONNECT_TIMEOUT_SECONDS) --max-time $(GITEA_CONNECTIVITY_CURL_TIMEOUT_SECONDS) -o /dev/null -w "%{http_code}" -H "Host: $(GITEA_INGRESS_HOST)" "http://'"$$GITEA_INGRESS_IP"'/"); [ "$$code" = "200" ] || [ "$$code" = "302" ] || [ "$$code" = "401" ]' >/dev/null; \
				rc=$$?; \
			else \
				$(KUBECTL) --context $$ctx --request-timeout=20s run gitea-check --attach=true --rm --restart=Never --image=$(GITEA_CONNECTIVITY_CHECK_IMAGE) --command -- \
				sh -ec 'code=$$(curl -sS --connect-timeout $(GITEA_CONNECTIVITY_CURL_CONNECT_TIMEOUT_SECONDS) --max-time $(GITEA_CONNECTIVITY_CURL_TIMEOUT_SECONDS) -o /dev/null -w "%{http_code}" -H "Host: $(GITEA_INGRESS_HOST)" "http://'"$$GITEA_INGRESS_IP"'/"); [ "$$code" = "200" ] || [ "$$code" = "302" ] || [ "$$code" = "401" ]' >/dev/null; \
				rc=$$?; \
			fi; \
			if [ $$rc -eq 0 ]; then \
				break; \
			fi; \
			$(KUBECTL) --context $$ctx delete pod gitea-check --ignore-not-found >/dev/null 2>&1 || true; \
			[ $$attempt -lt $(GITEA_CONNECTIVITY_MAX_ATTEMPTS) ] || \
				{ echo "Connectivity check failed from $$ctx"; exit 1; }; \
			attempt=$$((attempt + 1)); \
			sleep $(GITEA_CONNECTIVITY_RETRY_SECONDS); \
		done; \
	done

# Repo setup uses localhost:$(K3D_INGRESS_HTTP_PORT) (k3d port mapping) with the Host header
# so Traefik routes the request to Gitea — no port-forward required.
_gitea-repo:
	@for attempt in $$(seq 1 30); do \
		code="$$($(CURL) -s -o /dev/null -w "%{http_code}" \
			-H "Host: $(GITEA_INGRESS_HOST)" \
			http://localhost:$(K3D_INGRESS_HTTP_PORT)/api/healthz)"; \
		[ "$$code" = "200" ] && break; \
		sleep 2; \
	done; \
	REPO_STATUS="$$($(CURL) -s \
		-u "$(GITEA_ADMIN_ACCOUNT):$(GITEA_ADMIN_PASSWORD)" \
		-H "Host: $(GITEA_INGRESS_HOST)" \
		-o /dev/null -w "%{http_code}" \
		http://localhost:$(K3D_INGRESS_HTTP_PORT)/api/v1/repos/$(GITEA_ADMIN_ACCOUNT)/$(GITEA_REPO_NAME))"; \
	if [ "$$REPO_STATUS" = "200" ]; then \
		echo "✓ Repository $(GITEA_REPO_NAME) already exists"; \
	else \
		$(CURL) -s \
			-u "$(GITEA_ADMIN_ACCOUNT):$(GITEA_ADMIN_PASSWORD)" \
			-H "Host: $(GITEA_INGRESS_HOST)" \
			-H "Content-Type: application/json" \
			-X POST http://localhost:$(K3D_INGRESS_HTTP_PORT)/api/v1/user/repos \
			-d "{\"name\": \"$(GITEA_REPO_NAME)\", \"description\": \"Cloud Native Days 2026 GitOps repository\", \"private\": false, \"auto_init\": true}" \
			>/dev/null && echo "✓ Repository $(GITEA_REPO_NAME) created" \
			|| { echo "Unable to create repository $(GITEA_REPO_NAME)"; exit 1; }; \
	fi

_flux:
	$(KUBECTL) --context $(WORKER_DEV_CONTEXT) apply --filename $(FLUX_MANIFEST_URL)
	$(KUBECTL) --context $(WORKER_PROD_CONTEXT) apply --filename $(FLUX_MANIFEST_URL)

_promise-workflow-images:
	$(DOCKER) build --tag $(PROMISE_IMAGE_DEPS) $(PROMISE_DEPS_DOCKERFILE_DIR)
	$(DOCKER) build --tag $(PROMISE_IMAGE_RESOURCE_V001) $(PROMISE_RESOURCE_V001_DOCKERFILE_DIR)
	$(DOCKER) build --tag $(PROMISE_IMAGE_RESOURCE_V002) $(PROMISE_RESOURCE_V002_DOCKERFILE_DIR)
	$(K3D_IMAGE_IMPORT) $(PROMISE_IMAGE_DEPS) -c $(CTRL_PLANE_CLUSTER_NAME)
	$(K3D_IMAGE_IMPORT) $(PROMISE_IMAGE_RESOURCE_V001) -c $(CTRL_PLANE_CLUSTER_NAME)
	$(K3D_IMAGE_IMPORT) $(PROMISE_IMAGE_RESOURCE_V002) -c $(CTRL_PLANE_CLUSTER_NAME)

_install-promise-v001:
	$(KUBECTL) --context $(CTRL_PLANE_CONTEXT) apply --filename $(PROMISE_V001_MANIFEST)

_summary:
	@GITEA_INGRESS_IP="$$($(KUBECTL) --context $(CTRL_PLANE_CONTEXT) -n kube-system \
		get svc traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"; \
	echo ""; \
	echo "Bootstrap complete"; \
	echo ""; \
	echo "Gitea"; \
	echo "  Host URL  : http://$(GITEA_INGRESS_HOST)/"; \
	echo "  Worker URL: http://$$GITEA_INGRESS_IP/  (Host: $(GITEA_INGRESS_HOST))"; \
	echo "  Repo      : http://$(GITEA_INGRESS_HOST)/$(GITEA_ADMIN_ACCOUNT)/$(GITEA_REPO_NAME)"; \
	echo "  Username  : $(GITEA_ADMIN_ACCOUNT)"; \
	echo "  Password  : $(GITEA_ADMIN_PASSWORD)"; \
	echo ""; \
	echo "Add to /etc/hosts on your machine to reach Gitea from a browser:"; \
	echo "  127.0.0.1   $(GITEA_INGRESS_HOST)"; \
	echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Teardown steps
# ─────────────────────────────────────────────────────────────────────────────

_delete-worker-prod:
	@if $(call cluster-exists,$(WORKER_PROD_CLUSTER_NAME)); then \
		$(K3D) cluster delete $(WORKER_PROD_CLUSTER_NAME); \
	else \
		echo "Cluster $(WORKER_PROD_CLUSTER_NAME) not found, skipping"; \
	fi

_delete-worker-dev:
	@if $(call cluster-exists,$(WORKER_DEV_CLUSTER_NAME)); then \
		$(K3D) cluster delete $(WORKER_DEV_CLUSTER_NAME); \
	else \
		echo "Cluster $(WORKER_DEV_CLUSTER_NAME) not found, skipping"; \
	fi

_delete-ctrl-plane:
	@if $(call cluster-exists,$(CTRL_PLANE_CLUSTER_NAME)); then \
		$(K3D) cluster delete $(CTRL_PLANE_CLUSTER_NAME); \
	else \
		echo "Cluster $(CTRL_PLANE_CLUSTER_NAME) not found, skipping"; \
	fi
