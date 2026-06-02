.PHONY: up build down logs psql sh reset ps

up:     ## daily: reuses image and named-volume deps, no redownload
	docker compose up

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
