# Accrue admin-UI demo — Docker DX: join the shared Traefik proxy

## Context (why this change)

The accrue admin-UI demo (`examples/accrue_host/`) runs on Docker. The previous session
made it collision-proof with **ephemeral host ports + a launch banner**, but that leaves
the URL changing on every boot (you must re-read the banner, can't bookmark, breaks
OAuth/`PHX_HOST` stability). The user runs **~6 Elixir OSS lib demos on Docker at once**
(parapet, rulestead, scoria, scrypath, threadline, accrue) and port juggling is a constant
pain.

Decisive finding from exploring the user's own fleet: a **shared Traefik reverse proxy is
already running** on this machine — the `dev_proxy` stack from `scoria`
(`/Users/jon/projects/scoria/docker/traefik/compose.yml`), on an external `proxy` network.
Scoria's own docs position it as *the reference standard*. Several sibling repos converged
on weaker variants (parapet's hash-seeded port ranges, threadline's CLI port-scanner,
rulestead/scrypath's fixed-port `.env` lanes) — all inferior to the proxy at ~6 apps
because the proxy gives **stable, bookmarkable URLs with zero published host ports**.

**User decision (confirmed):** make accrue **join that same shared proxy**. Every lib then
lives at a stable name on port 80 — `http://accrue.localhost/admin`, `http://scoria.localhost/scoria`,
etc. — with no port collisions ever. Keep the ephemeral port + banner as an automatic
fallback for when the proxy is down. This also makes accrue **consistent with the fleet the
user already built**.

**Outcome:** `make proxy` once (shared across all libs, idempotent) → `make up` → open
`http://accrue.localhost/admin`. Hands-off, stable, collision-proof, and the same muscle
memory as scoria.

### Secondary concern — caching (verified, already solid; just needs accurate docs)
The user worried that "small style changes rebuild/re-download deps." They don't:
- `Dockerfile.dev` only `COPY`s `bin/` — source is **bind-mounted** (`../..:/workspace`),
  deps/_build/node_modules live in **named volumes**, hex/npm in **host-bind caches**
  (`~/.cache/accrue-docker/*`). The image layer cache only invalidates on `bin/` changes.
- A `.heex`/CSS/JS edit **hot-reloads via the esbuild/tailwind watchers + live_reload** —
  no rebuild, no `mix deps.get`, no asset rebuild.
- `make up` warm boot skips `npm install` and first-paint `assets.build` (guarded in
  `bin/dev-entrypoint.sh`). Only `make build`/`make reset` does full work.
- BuildKit `--mount=type=cache` layering (scoria's trick) does **not apply** here because
  accrue never COPYs source or runs `mix` at build time — runtime host-bind caches already
  cover it. No Dockerfile change needed for caching.

So caching needs **no code change** — only an accurate mental-model paragraph in the docs.

---

## The approach

Mirror scoria's proxy pattern **exactly** (same external `proxy` network, same `dev_proxy`
Traefik project, `traefik:v3.7.1`) so accrue *joins* the running proxy rather than fighting
it — bringing the proxy up from accrue is a no-op when scoria's is already running, and both
apps coexist on the one Traefik.

### Files to change — `examples/accrue_host/`

**1. `docker/traefik/compose.yml`  (NEW)** — copy scoria's verbatim
(`/Users/jon/projects/scoria/docker/traefik/compose.yml`): `name: dev_proxy`, external
`proxy` network, `traefik:v3.7.1`, binds `127.0.0.1:80:80` + `127.0.0.1:8080:8080`,
`--providers.docker.exposedbydefault=false`, mounts the docker socket read-only. Shipping
our own copy makes the demo self-contained for a fresh user (no scoria checkout required);
same project name = idempotent when scoria's is already up.

**2. `docker-compose.yml`  (EDIT)** — add the proxy join to the `web` service, keep
ephemeral as fallback (reuse scoria's `web` block as the template, lines 45–75 of
`scoria/compose.yml`):
- `environment:` add `PHX_HOST: ${ACCRUE_HOST:-accrue.localhost}` and
  `COMPOSE_PROJECT_NAME: ${COMPOSE_PROJECT_NAME:-accrue-host}` (keep existing `PGHOST: db`).
- `networks: [default, proxy]`.
- `labels:` —
  - `traefik.enable=true`
  - `traefik.docker.network=proxy`
  - `traefik.http.routers.${COMPOSE_PROJECT_NAME:-accrue-host}.rule=Host(\`${ACCRUE_HOST:-accrue.localhost}\`)`
  - `traefik.http.services.${COMPOSE_PROJECT_NAME:-accrue-host}.loadbalancer.server.port=4000`
- Keep `ports: ["127.0.0.1::4000"]` (ephemeral loopback fallback — current
  `${ACCRUE_HOST_DOCKER_BIND:-127.0.0.1}:${ACCRUE_HOST_DOCKER_PORT:-}:4000` already does
  this; keep the pin-via-env affordance).
- Add top-level `networks:` block: `proxy: {external: true}` and `default:`.
- Keep all existing volumes + host-bind caches unchanged. `db` stays unpublished (only via
  `docker-compose.override.yml.example`). Drop the redundant top-level
  `name: ${ACCRUE_HOST_COMPOSE_PROJECT:-accrue-host}` in favor of `COMPOSE_PROJECT_NAME`
  (exported by the Makefile; env overrides win over `name:` per Compose precedence) — or
  keep it as the raw-`docker compose` default; either is fine, document the chosen one.

**3. `Makefile`  (EDIT)** — adopt scoria's identity + targets (template:
`scoria/Makefile` lines 1–55):
- Derive identity: default `INSTANCE ?= accrue-host`, `ACCRUE_HOST ?= accrue.localhost`
  (clean single-checkout name the user was shown). `export COMPOSE_PROJECT_NAME = $(INSTANCE)`
  and `export ACCRUE_HOST`. For a second checkout side-by-side: `make up INSTANCE=accrue-foo`
  → routes at `accrue-foo.localhost` (document this).
- New `proxy:` target — `-docker network create proxy` (the `-` ignores "already exists")
  then `docker compose -f docker/traefik/compose.yml up -d`; echo the dashboard URL. Run once.
- `up:` keep boot-detached → `bin/dev-banner.sh` → `logs -f web` (banner now shows the
  stable URL).
- `open:` open `http://$(ACCRUE_HOST)/admin` (via banner `--url-only`).
- New `url:` target — print Instance, Traefik URL, and ephemeral fallback (scoria-style).
- Keep `build`/`down`/`logs`/`psql`/`sh`/`reset`/`ps`.

**4. `bin/dev-banner.sh`  (EDIT)** — advertise the **stable URL as primary**, ephemeral as
fallback. Keep the readiness poll against the ephemeral loopback (always resolvable, even
without `*.localhost` DNS), but print `http://${ACCRUE_HOST:-accrue.localhost}/admin` as the
headline URL plus a `Fallback (proxy down): http://127.0.0.1:<ephemeral>` line. `--url-only`
returns the stable URL (used by `make open`). Keep the routes + 5 seeded logins block.
Add a one-line Safari/`curl` caveat pointing at the fallback.

**5. `.env.example`  (EDIT)** — document `ACCRUE_HOST` (stable hostname, default
`accrue.localhost`) and `INSTANCE`/`COMPOSE_PROJECT_NAME` (for side-by-side checkouts);
keep `ACCRUE_HOST_DOCKER_PORT` as the optional fixed-port pin for the fallback. Reframe the
header around the shared-proxy model.

**6. `config/dev.exs`  (EDIT, small/optional)** — add `url: [host: System.get_env("PHX_HOST") || "localhost"]`
to the endpoint so absolute URLs/links render `accrue.localhost` under Traefik.
`check_origin: false` is **already set** (line 23) so LiveView websockets already work
through the proxy — no origin change needed. This is cosmetic (absolute-URL generation is
rare in the demo); include it or note it as deferred.

### Docs (respect persona / JTBD voice — gameplan-first, digestible)

**7. `README.md` "Start Here"  (EDIT)** — re-lead the 3-step happy path:
`make proxy` (once, shared) → `make up` → `http://accrue.localhost/admin`. Add a short
"**Running alongside your other lib demos**" paragraph (every lib at its own `*.localhost`,
zero collisions). Keep the (accurate) caching mental-model section. Update the Makefile
command table (`proxy`, `url`, `open`). Troubleshooting: `*.localhost` resolves in
Chrome/Firefox automatically; Safari/curl → use the printed fallback URL or add a dnsmasq
wildcard; proxy down → fallback URL.

**8. `accrue_admin/guides/local_demo.md`  (EDIT)** — evaluator/operator persona guide.
Update the start spine to the stable URL + one-time `make proxy`, keep the TL;DR-first
voice and cross-links (don't duplicate the README). It's ExDoc-published (registered in
`accrue_admin/mix.exs` `extras:`) — keep `mix docs` warning-free.

**9. `examples/accrue_host/docs/docker-dx.md`  (NEW)** — the comprehensive deep-dive that
keeps the README lean. Gameplan summary at top, then digestible sections: *why a shared
proxy* (vs ephemeral/fixed-port/CLI-scanner — the fleet comparison), *the one-time setup*,
*running N libs at once*, *the caching mental model* (what's instant vs warm vs full
rebuild), and *footguns* (Safari `*.localhost`, never mount over `/root/.mix`,
`--remove-orphans` on rename, the `dev_proxy` is shared so don't `down` it from one lib).
Mirrors scoria's `docs/docker_dev_dx.md` in spirit, accrue-flavored. Link it from the README.

---

## Verification (live — Docker daemon is up)

1. **Proxy:** `make proxy` → `docker compose ls` shows `dev_proxy` running; dashboard
   reachable at `http://localhost:8080`. (No-op/idempotent if scoria's already up.)
2. **Boot:** `make up` → entrypoint completes (deps.get/ecto/seeds/phx.server), banner prints
   the stable URL.
3. **Stable route:** `curl -s -o /dev/null -w '%{http_code}' -H 'Host: accrue.localhost' http://127.0.0.1/admin`
   returns a non-5xx (200/302). Also hit the ephemeral fallback via `docker compose port web 4000`.
4. **Coexistence:** confirm `scoria.localhost` still routes while `accrue.localhost` routes —
   both through the one Traefik (Host-header curl for each).
5. **Hot-reload / no churn:** edit a `.heex` and a CSS file → page live-reloads;
   `docker compose logs web` shows **no** `mix deps.get` / `assets.build` re-run.
6. **Reset cache:** `make down` then `make reset` re-links deps from
   `~/.cache/accrue-docker/*` (watch logs for re-link, not re-download).
7. **Docs gates:** in `accrue_admin/`, `mix docs` and `mix compile --warnings-as-errors`
   stay green (the existing PdfTest flake is unrelated — dodge with `--seed 0`).

## Notes / guardrails
- Runs under **gsd-quick**; group into atomic commits: (a) traefik compose + compose join +
  networks, (b) Makefile + banner + .env, (c) optional dev.exs url host, (d) docs. Planning
  artifacts under `.planning/quick/` + STATE.md as the final commit.
- Don't touch the ~23 pre-existing dirty files or the untracked `.planning/ui-reviews/`.
- The shared `dev_proxy` is **fleet infrastructure** — `make down` only stops accrue's stack,
  never the proxy; document that explicitly so no one tears down everyone's routing.
