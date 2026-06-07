.PHONY: validate-instance validate-docker-platform ensure-proxy-network proxy up open url build down logs psql sh reset ps

# --- Per-instance identity ---------------------------------------------------
# Default to a single clean instance: project `accrue-host`, stable URL
# http://accrue.localhost. Run a second checkout side by side without any
# collision by overriding INSTANCE:
#   make up INSTANCE=accrue-foo   -> http://accrue-foo.localhost
INSTANCE     ?= accrue-host
ACCRUE_HOST  ?= $(if $(filter accrue-host,$(INSTANCE)),accrue.localhost,$(INSTANCE).localhost)
export COMPOSE_PROJECT_NAME = $(INSTANCE)
export ACCRUE_HOST

validate-instance:
	@printf '%s\n' "$(INSTANCE)" | grep -Eq '^[a-z0-9]([a-z0-9-]*[a-z0-9])?$$' || { \
		echo "INSTANCE must be DNS-safe lowercase: [a-z0-9-], starting and ending with a letter/number."; \
		echo "Example: make up INSTANCE=accrue-foo"; \
		exit 2; \
	}

validate-docker-platform:
	@case "$$(uname -m):$${DOCKER_DEFAULT_PLATFORM:-}" in \
		arm64:*amd64*|aarch64:*amd64*) \
			echo "DOCKER_DEFAULT_PLATFORM=$${DOCKER_DEFAULT_PLATFORM} would force amd64 emulation on Apple Silicon."; \
			echo "Unset it for this demo; native arm64 is required for reliable BEAM/NIF builds."; \
			exit 2 ;; \
	esac

ensure-proxy-network:
	@docker network create proxy >/dev/null 2>&1 || true

proxy: validate-instance ensure-proxy-network ## one-time (shared by ALL lib demos): start the Traefik proxy + its network
	# Force project `dev_proxy` with -p so the shared proxy is the SAME container
	# no matter which lib (or which INSTANCE) runs this — our exported
	# COMPOSE_PROJECT_NAME would otherwise spawn a second Traefik that collides on :80.
	docker compose -p dev_proxy -f docker/traefik/compose.yml up -d
	@echo "Traefik dashboard: http://localhost:8080/dashboard/  (routes every *.localhost demo)"

up: validate-instance validate-docker-platform ensure-proxy-network ## daily: boot detached, print the launch banner, then follow web logs
	docker compose up -d --remove-orphans
	./bin/dev-banner.sh
	# Ctrl-C only detaches this log follow — the stack keeps running. Use `make down` to stop.
	docker compose logs -f web

open: validate-instance ## open the running demo in the browser at its stable URL
	open "$$(./bin/dev-banner.sh --url-only)"

url: validate-instance ## print this instance's stable URL + the ephemeral fallback
	@echo "Instance:  $(COMPOSE_PROJECT_NAME)"
	@echo "Stable:    http://$(ACCRUE_HOST)/admin  (needs \`make proxy\` once)"
	@echo "Fallback:  http://$$(docker compose port web 4000 2>/dev/null)/admin"

build: validate-instance validate-docker-platform ensure-proxy-network ## first run or when Dockerfile.dev / OS-level deps change
	docker compose up --build

down:   ## stop THIS demo's stack (never touches the shared proxy)
	docker compose down

logs:
	docker compose logs -f web

psql:
	docker compose exec db psql -U postgres accrue_host_dev

sh:
	docker compose exec web bash

reset: validate-instance validate-docker-platform ensure-proxy-network ## nuke volumes and reseed from scratch (seeds are idempotent)
	docker compose down --volumes
	docker compose up -d --build --remove-orphans
	./bin/dev-banner.sh
	# Ctrl-C only detaches this log follow — the stack keeps running. Use `make down` to stop.
	docker compose logs -f web

ps:
	docker compose ls
