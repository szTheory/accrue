.PHONY: up open build down logs psql sh reset ps

up:     ## daily: boot detached, print the launch banner, then follow web logs
	docker compose up -d --remove-orphans
	./bin/dev-banner.sh
	# Ctrl-C only detaches this log follow — the stack keeps running. Use `make down` to stop.
	docker compose logs -f web

open:   ## open the running demo in the browser at its live ephemeral URL
	open "$$(./bin/dev-banner.sh --url-only)"

build:  ## first run or when Dockerfile.dev / OS-level deps change
	docker compose up --build

down:
	docker compose down

logs:
	docker compose logs -f web

psql:
	docker compose exec db psql -U postgres accrue_host_dev

sh:
	docker compose exec web bash

reset:  ## nuke volumes and reseed from scratch (seeds are idempotent)
	docker compose down --volumes && docker compose up --build

ps:
	docker compose ls
