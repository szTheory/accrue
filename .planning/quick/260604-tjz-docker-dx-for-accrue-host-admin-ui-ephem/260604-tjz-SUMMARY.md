---
phase: quick-260604-tjz
plan: 01
status: complete
subsystem: examples/accrue_host (Docker DX) + accrue_admin (docs)
tags: [docker, dx, ephemeral-ports, launch-banner, caching, docs]
requires: []
provides:
  - "Ephemeral host port by default for the accrue_host Docker demo"
  - "Host-side launch banner (live URL + real routes + real demo logins)"
  - "Lean idempotent container entrypoint + host-bind hex/mix/npm caches"
  - "Persona-framed local_demo evaluator guide registered in accrue_admin docs"
  - "Optional native-dev banner (dev-only, Docker-suppressed)"
affects:
  - examples/accrue_host/docker-compose.yml
  - examples/accrue_host/.env.example
  - examples/accrue_host/Makefile
  - examples/accrue_host/Dockerfile.dev
  - accrue_admin/mix.exs
tech-stack:
  added: []
  patterns:
    - "Docker ephemeral host port via empty host-port segment (127.0.0.1::4000)"
    - "Idempotent entrypoint guards (warm-volume skip for npm install + first-paint asset build)"
    - "Host-bind caches survive `docker compose down --volumes` so `make reset` re-links"
key-files:
  created:
    - examples/accrue_host/bin/dev-banner.sh
    - examples/accrue_host/bin/dev-entrypoint.sh
    - accrue_admin/guides/local_demo.md
    - examples/accrue_host/lib/accrue_host_web/dev_banner.ex
  modified:
    - examples/accrue_host/docker-compose.yml
    - examples/accrue_host/.env.example
    - examples/accrue_host/Makefile
    - examples/accrue_host/Dockerfile.dev
    - examples/accrue_host/README.md
    - examples/accrue_host/lib/accrue_host/application.ex
    - accrue_admin/mix.exs
decisions:
  - "Task 5 (native-dev banner) INCLUDED — application.ex change was low-risk (gated, best-effort, returns the start_link tuple unchanged)"
metrics:
  duration: ~12m
  completed: 2026-06-04
---

# Quick Task 260604-tjz: Docker DX for accrue_host (ephemeral ports, banner, caching, docs) Summary

Closed the four remaining Docker-DX gaps in `examples/accrue_host/` so the admin-UI demo is hands-off and collision-proof: ephemeral host ports by default, a host-side launch banner that prints the live URL + real routes + real seeded logins, a lean idempotent entrypoint backed by host-bind caches, and persona-framed docs — plus an optional native-dev banner.

## What was built

**Task 1 — Ephemeral host ports (commit `48ddbf55`)**
- `docker-compose.yml` `web` host port now defaults to empty (`${ACCRUE_HOST_DOCKER_PORT:-}:4000`) so Docker assigns a free ephemeral port; added a 2-line explanatory comment. No other compose lines touched in this commit.
- `.env.example` reworded: ephemeral-by-default messaging, `ACCRUE_HOST_DOCKER_PORT` shown only as a commented-out opt-in pin; kept `ACCRUE_HOST_COMPOSE_PROJECT`, the `ACCRUE_HOST_DOCKER_BIND` note, and the `PGPORT` note.

**Task 2 — Launch banner + Makefile up/open (commit `e44f1c77`)**
- `bin/dev-banner.sh` (executable, `bash -n` clean): resolves the live port via `docker compose port web 4000`, polls `GET $BASE_URL/` (treats a completed connection as up, no `-f`), and prints a framed ASCII block with the live `http://127.0.0.1:<port>` URL, the real routes (`/admin`, `/billing`, `/app/billing`, `/app/reports/advanced`, `/users/log-in`, `/dev/mailbox`), and all five demo logins with `accrue-demo-password`. `--url-only` short-circuits to just the URL.
- `Makefile`: `up` now boots detached (`-d --remove-orphans`) → runs the banner → follows web logs (with the Ctrl-C-only-detaches note); new `open` target launches the browser via `$$(./bin/dev-banner.sh --url-only)`; both added to `.PHONY`.

**Task 3 — Lean entrypoint + host-bind caches (commit `f08c9f04`)**
- `bin/dev-entrypoint.sh` (executable, `bash -n` clean): idempotent boot — guarded `assets.setup` (warm-volume skip) → `deps.get` → `ecto.create` → `ecto.migrate` → seeds → guarded first-paint `assets.build` → `exec mix phx.server`, with one-line status echoes.
- `Dockerfile.dev`: added `# syntax=docker/dockerfile:1` header, `COPY bin/` + `chmod +x`, and replaced the `mix setup && mix phx.server` CMD with `ENTRYPOINT ["bin/dev-entrypoint.sh"]`. `EXPOSE 4000` kept.
- `docker-compose.yml`: added three host-bind caches (`~/.cache/accrue-docker/{hex,mix,npm}` → `/root/.{hex,mix,npm}`) while keeping the `../..:/workspace` bind and all three named volumes (`mix_deps`/`mix_build`/`assets_node_modules`) exactly as-is.

**Task 4 — README rewrite + new guide registered in docs (commit `c8881e17`)**
- `README.md` "Start Here" rewritten gameplan-first: 3-step happy path, ephemeral/no-port-picking story, banner explained, instant-vs-seconds-vs-rebuild caching mental model, troubleshooting (pin port / Ctrl-C vs down / reset), and an updated command table including `make open`. The old 4000/4010/4020 block and the Traefik "Advanced (optional)" block were dropped; the lingering cross-lib convention line in Prerequisites was reworded.
- `accrue_admin/guides/local_demo.md` created — evaluator/operator-persona narrative (TL;DR + numbered spine: start → read banner → sign in → walk `/admin` → "what you'll see"), cross-linking the README, first_hour.md, and admin_ui.md rather than duplicating them.
- `accrue_admin/mix.exs`: registered `guides/local_demo.md` in `extras:`, the `Guides:` group, and `skip_undefined_reference_warnings_on:`. `mix docs` builds clean (exit 0, generates `doc/local_demo.html`).

**Task 5 — Native-dev banner (INCLUDED, commit `ac384440`)**
- `lib/accrue_host_web/dev_banner.ex`: `AccrueHostWeb.DevBanner.maybe_print/0` logs the same routes + creds block for native dev (`http://localhost:4000`), gated on BOTH `:dev_routes` truthy AND `PGHOST != "db"`, wrapped in best-effort `try/catch` so it can never affect boot.
- `lib/accrue_host/application.ex`: calls `maybe_print/0` only on a successful `Supervisor.start_link/2`, returning the `{:ok, _pid}` tuple unchanged; non-`:ok` results pass through untouched. `mix compile --force --warnings-as-errors` is clean (exit 0) for `accrue_host`.

## Deviations from Plan

None for Tasks 1–4 — executed exactly as written.

**Task 5 disposition:** INCLUDED. `application.ex` was a clean, minimal `start/2`; the added change is gated, best-effort, and returns the supervisor tuple unchanged, so the risk bar in the plan ("only if genuinely low-risk") was met.

## Verification

All automated `<verify>` gates passed (Tasks 1–5):
- Task 1: compose ephemeral default + `.env.example` no longer hard-sets 4000 — OK
- Task 2: `dev-banner.sh` executable, `bash -n` clean, `accrue-demo-password` + `/app/reports/advanced` + `--url-only` present, Makefile `open` wired — OK
- Task 3: `dev-entrypoint.sh` executable + `bash -n` clean + `exec mix phx.server` + first-paint guard, Dockerfile syntax header + entrypoint, compose host-bind caches + named volumes intact — OK
- Task 4: guide exists + registered 3× in mix.exs + README `make open` + old port block removed + `mix docs` builds clean (`doc/local_demo.html` generated) — OK
- Task 5: `dev_banner.ex` with `PGHOST` gate + `application.ex` `dev_routes`, `mix compile --warnings-as-errors` clean for accrue_host — OK

Exec bits recorded in git index as `100755` for both new shell scripts.

Pre-existing/unrelated: `accrue_admin` emits a `tabs/4 is unused` warning during compile — that is a dependency warning predating this task and does not break the host compile (out of scope; not fixed).

## Pending human UAT (no Docker daemon here)

The full Docker walkthrough (`make build` / `make up` / two-stack ephemeral-collision proof / `make open` / hot-reload + warm-volume skip / `make reset` cache re-link) is a human acceptance pass — it could not run in this environment (no live Docker daemon). The static gates above (syntax checks, exec bits, grep assertions, and a real `mix docs` + `mix compile --warnings-as-errors`) are the merge-blocking checks that did run. The end-to-end Docker walkthrough remains a pending human UAT.

## Self-Check: PASSED
- FOUND: examples/accrue_host/bin/dev-banner.sh (100755)
- FOUND: examples/accrue_host/bin/dev-entrypoint.sh (100755)
- FOUND: accrue_admin/guides/local_demo.md
- FOUND: examples/accrue_host/lib/accrue_host_web/dev_banner.ex
- FOUND commit 48ddbf55 (Task 1)
- FOUND commit e44f1c77 (Task 2)
- FOUND commit f08c9f04 (Task 3)
- FOUND commit c8881e17 (Task 4)
- FOUND commit ac384440 (Task 5)

## Cold-boot fixes

Two correctness bugs surfaced only on a COLD cache (fresh `make build` / post-`make reset`); static `bash -n` gates passed because both are runtime ordering/mount issues. Fixed atomically in commit `9f435936`.

1. **Entrypoint step order** (`bin/dev-entrypoint.sh`): `mix assets.setup` ran before `mix deps.get`, but `assets.setup` calls `tailwind.install` / `esbuild.install` — Mix tasks supplied by the `:tailwind` / `:esbuild` deps, which don't exist until deps are fetched. Cold boot failed with "task tailwind.install could not be found". Reordered so `deps.get` runs first, then the `assets.setup` guard, then ecto/seeds/`assets.build`/`phx.server` — matching the canonical `setup` alias order in `mix.exs`. All guards and echo lines preserved.

2. **Dropped `/root/.mix` cache mount** (`docker-compose.yml`): the `web` service bind-mounted an empty host dir over `/root/.mix`, shadowing the Hex/rebar archives baked in by the Dockerfile's `mix local.hex --force` / `mix local.rebar --force`. With no Hex present and no TTY (detached `up -d`), `mix deps.get` couldn't interactively self-install Hex and boot failed on a cold cache. Removed only that mount; kept `/root/.hex` (the dep download cache that keeps `make reset` fast) and `/root/.npm`. The Hex/rebar *tool* archives stay baked into the image; only the package *download* cache needs persisting, and that lives in `/root/.hex`.
