---
phase: quick-260605-dkx
plan: 01
subsystem: examples/accrue_host (Docker DX) + accrue_admin (docs)
tags: [docker, dx, traefik, reverse-proxy, port-conflicts, apple-silicon, harfbuzz, rust-nif, caching, docs]
requires: []
provides:
  - "accrue_host demo joins the shared Traefik dev_proxy → stable http://accrue.localhost (zero port conflicts across all sibling lib demos)"
  - "Demo actually boots in Docker on Apple Silicon (native arch + Rust-built HarfBuzz NIF)"
  - "make proxy / make url targets; launch banner advertises stable URL + ephemeral fallback"
  - "Comprehensive Docker DX deep-dive guide (docs/docker-dx.md) + reframed README Start Here + evaluator guide"
affects:
  - examples/accrue_host/docker-compose.yml
  - examples/accrue_host/Dockerfile.dev
  - examples/accrue_host/Makefile
  - examples/accrue_host/bin/dev-banner.sh
  - examples/accrue_host/.env.example
  - examples/accrue_host/config/dev.exs
  - examples/accrue_host/README.md
  - accrue_admin/guides/local_demo.md
tech-stack:
  added:
    - "Traefik v3.7.1 shared reverse proxy (external `proxy` network, project `dev_proxy`) — shared with sibling lib demos (scoria et al.)"
    - "Rust toolchain (rustup stable) in Dockerfile.dev to build the harfbuzz_ex NIF from source"
  patterns:
    - "Shared external `proxy` network + per-service Traefik labels (Host(`accrue.localhost`)); no published host ports for the primary path"
    - "Ephemeral loopback (127.0.0.1::4000) kept as automatic fallback when the proxy is down"
    - "Named-volume shadows for path-dep siblings' deps/_build so host-native artifacts never poison the container"
    - "Force-build rustler NIF via RUSTLER_PRECOMPILATION_EXAMPLE_BUILD=1 (harfbuzz_ex uses pure-Rust rustybuzz → no system libs)"
key-files:
  created:
    - examples/accrue_host/docker/traefik/compose.yml
    - examples/accrue_host/docs/docker-dx.md
  modified:
    - examples/accrue_host/docker-compose.yml
    - examples/accrue_host/Dockerfile.dev
    - examples/accrue_host/Makefile
    - examples/accrue_host/bin/dev-banner.sh
    - examples/accrue_host/.env.example
    - examples/accrue_host/config/dev.exs
    - examples/accrue_host/README.md
    - accrue_admin/guides/local_demo.md
decisions:
  - "Join the EXISTING shared dev_proxy (from scoria) rather than ship a competing proxy — same external network + project name, so `make proxy` is idempotent fleet-wide. User-confirmed direction (reverses the prior session's ephemeral-only simplification)."
  - "`make proxy` forces `-p dev_proxy` so the exported COMPOSE_PROJECT_NAME (instance identity) can't spawn a second Traefik that collides on :80. (Caught live.)"
  - "Demo runs NATIVE arch, NOT amd64. amd64 emulation (Rosetta/QEMU) corrupts the BEAM compiler on Apple Silicon (3 distinct crashes: prim_tty NIF / 'module already compiled' / ets:lookup_element badarg). Native + force-build the one missing NIF is the only stable path."
  - "harfbuzz_ex (text shaping for rendro, the default invoice-PDF renderer) has no aarch64-linux precompiled NIF → build from source. It uses pure-Rust rustybuzz, so only a Rust toolchain is needed (no system HarfBuzz/Chrome)."
  - "Image bumped 1.17→1.19 to match the host toolchain (native, stable)."
  - "rendro left at 0.3.0 (already the latest published + already pinned `~> 0.3.0`)."
verification:
  - "make proxy idempotent against the running dev_proxy (no second Traefik, dashboard 8080 reachable)."
  - "make up builds native (elixir:1.19 + rust) and boots: 'Running AccrueHostWeb.Endpoint ... Access at http://accrue.localhost'. Seeds ran (JPY invoice). ~3 min entrypoint compile incl. Rust NIF."
  - "Stable routes via Traefik: /admin /billing /app/billing → 302 (auth-gated), /users/log-in /dev/mailbox → 200."
  - "Ephemeral fallback (127.0.0.1:<port>/admin) → 302."
  - "Coexistence: both accrue-host@docker AND scoria@docker registered on the one Traefik; both route."
  - "accrue_admin `mix docs` clean (local_demo guide renders, no undefined refs); `mix compile --warnings-as-errors` has only the PRE-EXISTING `tabs/4 unused` warning in customer_live.ex (untouched)."
follow-ups:
  - "Drift-on-boot: the container's `mix deps.get` rewrites the bind-mounted mix.lock (host uses path-sigra, container uses hex-sigra → different resolution). Reverted from this commit; flagged as a minor wart. A deliberate `mix deps.update` could refresh the lock if desired."
  - "harfbuzz_ex upstream lacks an aarch64-linux precompiled NIF — could be contributed upstream to drop the in-image Rust build later."
  - "Pre-existing `tabs/4 is unused` warning in accrue_admin/lib/.../customer_live.ex:584 (out of scope)."
---

# Quick Task 260605-dkx — Native Docker boot + shared Traefik proxy DX

See `260605-dkx-PLAN.md` for the approved plan. Net effect: the accrue_host admin-UI
demo now boots in Docker on Apple Silicon and is reachable at a stable
`http://accrue.localhost` via the shared `dev_proxy` Traefik — zero port conflicts with
the other Elixir lib demos, with an automatic ephemeral fallback and an accurate
caching model. Fully documented in `docs/docker-dx.md`.
