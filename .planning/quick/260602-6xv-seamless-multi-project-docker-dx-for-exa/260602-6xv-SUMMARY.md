---
phase: 260602-6xv
plan: "01"
status: complete
subsystem: examples/accrue_host Docker DX
tags: [docker, dx, makefile, multi-project, port-conflict]
dependency_graph:
  requires: []
  provides: [seamless multi-project Docker DX for examples/accrue_host]
  affects: [examples/accrue_host]
tech_stack:
  added: []
  patterns: [per-checkout .env, docker-compose.override.yml opt-in, Makefile ergonomic targets]
key_files:
  created:
    - examples/accrue_host/.env.example
    - examples/accrue_host/docker-compose.override.yml.example
    - examples/accrue_host/.dockerignore
    - examples/accrue_host/Makefile
  modified:
    - examples/accrue_host/docker-compose.yml
    - examples/accrue_host/.gitignore
    - examples/accrue_host/README.md
decisions:
  - Remove db host port binding from docker-compose.yml (Postgres internal-only by default); opt-in via override.yml.example
  - Build context changed from ../.. to . (runtime bind mount ../..:/workspace unchanged)
  - ACCRUE_HOST_DOCKER_BIND=127.0.0.1 loopback default for web port (avoids LAN exposure)
  - per-checkout .env pattern (Docker Compose auto-loads) rather than inline env-var prefix on every command
metrics:
  duration: "~5 minutes"
  completed: "2026-06-02"
  tasks_completed: 2
  files_changed: 7
---

# Phase 260602-6xv Plan 01: Seamless Multi-Project Docker DX Summary

**One-liner:** Removed db host-port conflict source, shrunk build context from monorepo root to host dir, and added per-checkout .env + Makefile targets for zero-friction daily use.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Update docker-compose.yml, create .env.example, override.yml.example, .dockerignore, .gitignore, Makefile | fe139d7c | 6 files |
| 2 | Update README.md Docker guidance | 85477a1b | README.md |

## What Was Built

### Task 1: Core Docker DX infrastructure

**docker-compose.yml** — Three targeted changes, everything else preserved exactly:
- Removed `ports:` block from `db` service (Postgres internal-only, accessible to `web` via `PGHOST: db` over Docker network)
- Web `ports:` now uses `${ACCRUE_HOST_DOCKER_BIND:-127.0.0.1}:${ACCRUE_HOST_DOCKER_PORT:-4000}:4000` (loopback default, opt-in 0.0.0.0 for device testing)
- Build context changed from `../..` to `.`, dockerfile from `examples/accrue_host/Dockerfile.dev` to `Dockerfile.dev` (runtime bind mount `../..:/workspace` unchanged)

**.env.example** — Per-checkout mechanism; Docker Compose auto-loads `.env` from project directory. Contains `ACCRUE_HOST_DOCKER_PORT=4000`, `ACCRUE_HOST_COMPOSE_PROJECT=accrue-host`, commented BIND and PGPORT lines with cross-lib port convention comment (accrue: 4000, otherlib: 4010, thirdlib: 4020).

**docker-compose.override.yml.example** — Opt-in db host port binding: `127.0.0.1:${PGPORT:-5432}:5432`. Users copy to `docker-compose.override.yml` (gitignored, auto-merged by Compose) when a GUI DB client (psql, DBeaver, TablePlus) needs direct access.

**.dockerignore** — Build context is now `.` (host dir); excludes `deps/`, `_build/`, `assets/node_modules/`, `test-results/`, `playwright-report/`, `doc/`, `cover/`, `.env`, `*.log`, `node_modules/`, `.git`.

**.gitignore** — Appended `.env` and `docker-compose.override.yml` entries.

**Makefile** — 8 .PHONY tab-indented targets:
- `make up` — daily: reuses image + named-volume deps, no redownload
- `make build` — first run or Dockerfile.dev / OS-level dep change
- `make down` — stop the stack
- `make logs` — stream Phoenix logs from web container
- `make psql` — psql session in running db container
- `make sh` — bash shell in running web container
- `make reset` — nuke volumes and reseed from scratch
- `make ps` — list all Compose projects on the machine

### Task 2: README.md surgical updates

- **Start Here:** `make build` for first run, `make up` for daily (no --build footgun)
- **Makefile reference table** added (8 targets with when-to-use descriptions)
- **Multi-demo guidance:** `cp .env.example .env` workflow with cross-lib port convention
- **Optional Traefik escape hatch** mentioned as advanced doc-only note
- **Prerequisites:** Postgres described as internal-only by default; override.yml.example for GUI client opt-in; `make reset` replaces `docker compose down --volumes` examples
- **Proof and verification Explore bullet:** `make build (first run) / make up (daily)` replaces `docker compose up --build`
- **ACCRUE_HOST_DOCKER_PGPORT inline example removed** (moved to .env.example + override.yml.example)
- All non-Docker sections (mix verify, capsules, observability, VERIFY-01, proof matrix, visual walkthrough) unchanged

## Verification Results

- YAML valid: `python3 -c "import yaml; yaml.safe_load(open('docker-compose.yml'))"` passes
- db has no `ports:` block; web has exactly 1 ports entry with `ACCRUE_HOST_DOCKER_BIND`
- Build context: `context: .` / `dockerfile: Dockerfile.dev`
- Gitignore: `git check-ignore .env docker-compose.override.yml` lists both files
- Makefile: `make -n up` prints `docker compose up` (tab-indented syntax confirmed)
- README: `grep -c 'ACCRUE_HOST_DOCKER_PGPORT' README.md` = 0 (old example removed)
- Docker daemon unavailable in CI environment; YAML + structural checks used as fallback (noted per plan instructions)

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

No new security surface beyond what the plan's threat model covers:
- T-6xv-01 mitigated: `.env` gitignored, `.env.example` ships only safe defaults
- T-6xv-03 mitigated: `ACCRUE_HOST_DOCKER_BIND` defaults to `127.0.0.1`

## Self-Check: PASSED

- examples/accrue_host/docker-compose.yml: exists, YAML valid, db has no ports block
- examples/accrue_host/.env.example: exists
- examples/accrue_host/docker-compose.override.yml.example: exists
- examples/accrue_host/.dockerignore: exists
- examples/accrue_host/Makefile: exists, tab-indented recipes confirmed
- examples/accrue_host/.gitignore: .env and docker-compose.override.yml entries appended
- examples/accrue_host/README.md: make targets present, PGPORT example removed
- Commits fe139d7c and 85477a1b exist in git log
