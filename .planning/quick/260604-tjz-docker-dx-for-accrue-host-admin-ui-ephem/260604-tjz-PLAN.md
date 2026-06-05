---
phase: quick-260604-tjz
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - examples/accrue_host/docker-compose.yml
  - examples/accrue_host/.env.example
  - examples/accrue_host/bin/dev-banner.sh
  - examples/accrue_host/bin/dev-entrypoint.sh
  - examples/accrue_host/Dockerfile.dev
  - examples/accrue_host/Makefile
  - examples/accrue_host/README.md
  - accrue_admin/guides/local_demo.md
  - accrue_admin/mix.exs
autonomous: true
requirements: [DX-DOCKER-EPHEMERAL, DX-DOCKER-BANNER, DX-DOCKER-CACHE, DX-DOCKER-DOCS]

must_haves:
  truths:
    - "Every `make up` binds the web container to a free ephemeral host port — two demos never collide without any port-picking config"
    - "After `make up`, a banner prints the live base URL, the real mounted routes, and the real seeded demo logins + password"
    - "`make open` opens the running demo in the browser at the live ephemeral URL"
    - "Daily `make up` does not re-run the full `mix setup` sledgehammer; warm volumes skip npm install and first-paint asset build"
    - "`make reset` re-links hex/mix/npm from the host-bind cache instead of re-downloading over the network"
    - "`cd accrue_admin && mix docs` builds with the new local_demo guide under the Guides group and resolves its cross-links"
    - "Prod/test boot is untouched: no new runtime deps; the entrypoint is Docker-only and the optional native banner is gated off under Docker"
  artifacts:
    - path: "examples/accrue_host/bin/dev-banner.sh"
      provides: "Host-side launch banner: resolves live port, polls health, prints URL/routes/creds; --url-only flag"
      min_lines: 40
    - path: "examples/accrue_host/bin/dev-entrypoint.sh"
      provides: "Lean idempotent container boot replacing `mix setup && mix phx.server`"
      min_lines: 15
    - path: "accrue_admin/guides/local_demo.md"
      provides: "Evaluator/operator-persona 'see the admin UI without wiring Stripe' guide"
      min_lines: 30
  key_links:
    - from: "examples/accrue_host/Makefile"
      to: "examples/accrue_host/bin/dev-banner.sh"
      via: "up + open targets invoke the script"
      pattern: "dev-banner.sh"
    - from: "examples/accrue_host/Dockerfile.dev"
      to: "examples/accrue_host/bin/dev-entrypoint.sh"
      via: "ENTRYPOINT/CMD runs the copied script"
      pattern: "dev-entrypoint.sh"
    - from: "accrue_admin/mix.exs"
      to: "accrue_admin/guides/local_demo.md"
      via: "registered in extras + Guides group"
      pattern: "guides/local_demo.md"
---

<objective>
Close the four remaining Docker-DX gaps in `examples/accrue_host/` so the admin-UI
demo is hands-off, collision-proof, and well-documented. The approved plan
(`/Users/jon/.claude/plans/gsd-autonomous-cheerful-pike.md`) is LOCKED — this plan
transcribes it into executable tasks. The key decision (ephemeral host ports, no
Traefik) is final.

Purpose: The user runs many OSS Elixir admin-UI demos at once and keeps hitting
port conflicts; they also want zero wasted rebuilds and a copy-pasteable launch
summary of URLs/routes/creds.

Output:
- Ephemeral host port in compose + reworded `.env.example`.
- New `bin/dev-banner.sh` (live URL + real routes + real creds; `--url-only`).
- New `bin/dev-entrypoint.sh` (lean idempotent boot) + Dockerfile + host-bind caches.
- Rewritten README "Start Here" + new `accrue_admin/guides/local_demo.md` registered in docs.

Four atomic commits: (1) ephemeral ports, (2) launch banner, (3) caching/entrypoint, (4) docs.

CONSTRAINTS:
- No new runtime deps. Dev-tooling + docs only. Prod/test boot untouched.
- KEEP the existing named volumes (`mix_deps`/`mix_build`/`assets_node_modules`) — they are
  correct for macOS/NIF. Do NOT add the `COPY mix.exs && mix deps.get` layer trick.
- Use ONLY routes/creds confirmed below from router.ex + seeds. No placeholders.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@./CLAUDE.md

# Approved spec (authoritative — transcribe faithfully, do not redesign)
@/Users/jon/.claude/plans/gsd-autonomous-cheerful-pike.md

# Files being modified
@examples/accrue_host/docker-compose.yml
@examples/accrue_host/Dockerfile.dev
@examples/accrue_host/Makefile
@examples/accrue_host/.env.example
@examples/accrue_host/README.md
@accrue_admin/mix.exs

# Voice/style references for the new guide (match this tone)
@accrue_admin/guides/admin_ui.md
@accrue/guides/first_hour.md

<confirmed_facts>
<!-- CONFIRMED from examples/accrue_host/lib/accrue_host_web/router.ex and the seed files.
     The executor MUST use these exact values in the banner and the guide. -->

Real mounted routes (all from router.ex — every route the approved plan guessed DOES exist):
- `/`                      home (PageController :home)
- `/admin`                 mounted Accrue Admin UI (accrue_admin)
- `/billing`               mounted Accrue Portal (accrue_portal)
- `/app/billing`           host-owned billing screen (SubscriptionLive)
- `/app/reports/advanced`  entitlement-gated advanced reports (AdvancedReportsLive)
- `/users/log-in`          login (UserLive.Login)
- `/users/register`        registration (UserLive.Registration)
- `/users/settings`        user settings (UserLive.Settings)
- `/dev/mailbox`           Swoosh mailbox preview (dev_routes only; present in dev)

Seeded demo logins (from priv/repo/seeds/hero_accounts.exs) — all share ONE password:
- healthy@example.com      subscribed, healthy (no dunning banner)
- past-due@example.com     subscribed → past_due, dunning campaign active
- canceled@example.com     canceled subscription
- enterprise@example.com   premium plan + JPY invoice showcase
- trialing@example.com     trialing subscription
- Password (ALL demo users): accrue-demo-password
  (source of truth: AccrueHost.Seeds.Helpers.demo_password/0 in priv/repo/seeds.exs)

Boot facts:
- Phoenix listens on container port 4000 (Dockerfile EXPOSE 4000; compose maps -> 4000).
- In Docker, dev.exs binds endpoint IP to {0,0,0,0} when PGHOST == "db" (set by compose);
  native dev binds {127,0,0,1}. dev_routes: true in dev.
- Seeds are idempotent and run via `mix run priv/repo/seeds.exs` (eval_file chain:
  hero_accounts → background_data → showcase → edge_states).
</confirmed_facts>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Ephemeral host ports (commit 1)</name>
  <files>examples/accrue_host/docker-compose.yml, examples/accrue_host/.env.example</files>
  <action>
COMMIT 1 — make port collisions structurally impossible with zero config.

In `examples/accrue_host/docker-compose.yml`, change ONLY the `web` service `ports:` entry
(currently `"${ACCRUE_HOST_DOCKER_BIND:-127.0.0.1}:${ACCRUE_HOST_DOCKER_PORT:-4000}:4000"`).
Drop the `4000` default on the host-port segment so it defaults to EMPTY (ephemeral):
`"${ACCRUE_HOST_DOCKER_BIND:-127.0.0.1}:${ACCRUE_HOST_DOCKER_PORT:-}:4000"`.
Add a 2-line YAML comment above it: empty host port ⇒ Docker assigns a free ephemeral port
(no collisions, ever); pin a fixed port by setting ACCRUE_HOST_DOCKER_PORT in .env (e.g. for
OAuth callbacks). When unset this expands to `127.0.0.1::4000` (ephemeral); when set,
`127.0.0.1:4010:4000` (pinned). Do NOT touch any other compose lines in this commit
(named volumes and host-bind caches are commit 3).

In `examples/accrue_host/.env.example`, replace the manual port-block convention (the
`accrue: web 4000 / otherlib: web 4010 / thirdlib: web 4020` table and the
`ACCRUE_HOST_DOCKER_PORT=4000` line). New wording: by default each `make up` auto-picks a
free port and the banner prints the URL — no port-picking needed; set
`ACCRUE_HOST_DOCKER_PORT` ONLY if you want a stable URL (e.g. OAuth callbacks). Keep
`ACCRUE_HOST_COMPOSE_PROJECT=accrue-host` (still needed to run two checkouts of THIS same
lib), keep the commented `ACCRUE_HOST_DOCKER_BIND` note, and keep the commented `PGPORT` note.
Show `ACCRUE_HOST_DOCKER_PORT` only as a COMMENTED-OUT opt-in example, not an active default.

Stage and commit these two files: `git commit -m "feat(host-docker): ephemeral host port by default (no manual port picking)"`.
  </action>
  <verify>
    <automated>cd /Users/jon/projects/accrue/examples/accrue_host && grep -q 'ACCRUE_HOST_DOCKER_PORT:-}:4000' docker-compose.yml && ! grep -Eq '^ACCRUE_HOST_DOCKER_PORT=4000' .env.example && grep -q 'ACCRUE_HOST_COMPOSE_PROJECT' .env.example && echo OK</automated>
  </verify>
  <done>Compose `web` port maps `${...PORT:-}:4000` (empty default = ephemeral); `.env.example` no longer hard-sets port 4000 and explains the ephemeral default + opt-in pin; commit 1 made.</done>
</task>

<task type="auto">
  <name>Task 2: Launch banner + Makefile up/open (commit 2)</name>
  <files>examples/accrue_host/bin/dev-banner.sh, examples/accrue_host/Makefile</files>
  <action>
COMMIT 2 — host-side launch banner using the REAL routes/creds from &lt;confirmed_facts&gt;.

Create `examples/accrue_host/bin/dev-banner.sh` (bash, `set -euo pipefail`, host-side):
1. Resolve the live host port: run `docker compose port web 4000`, parse the trailing `:PORT`
   (the address may be `0.0.0.0:NNNN` or `127.0.0.1:NNNN`). If empty/unresolved, print a
   friendly "web container not up yet — run `make up` first" message and exit non-zero.
2. BASE_URL = `http://127.0.0.1:$PORT` (always advertise 127.0.0.1 for the browser, even when
   the container bound 0.0.0.0).
3. Support `--url-only`: if `$1 == --url-only`, print ONLY `$BASE_URL` and exit 0
   (resolve the port first; do NOT poll/print the banner in this mode — used by `make open`
   and scripting).
4. Otherwise poll `GET $BASE_URL/` with a short per-attempt timeout (curl `-sf -o /dev/null
   --max-time 2`), ~30 attempts with a 1s sleep, printing friendly "starting…" dots; stop
   polling once it returns (any HTTP response is fine — `-f` may 4xx on `/`, so treat a
   completed connection as "up": prefer checking `--max-time` connect success rather than
   strict 2xx, e.g. `curl -s -o /dev/null --max-time 2 "$BASE_URL/"` returning 0).
5. Print a clean copy-pasteable block:
   - "Accrue admin-UI demo is up:" then `  $BASE_URL`
   - Key routes (use EXACTLY these real paths):
     `/admin` (mounted Accrue Admin UI), `/billing` (mounted billing portal),
     `/app/billing` (host billing screen), `/app/reports/advanced` (entitlement-gated reports),
     `/users/log-in` (sign in), `/dev/mailbox` (sent-email preview).
   - Seeded demo logins — print all five with their password (ALL use `accrue-demo-password`):
     healthy@example.com, past-due@example.com, canceled@example.com,
     enterprise@example.com, trialing@example.com. Note healthy@ = clean, past-due@ = dunning.
   - Handy commands: `make open`, `make logs`, `make psql`, `make sh`, `make down`.
   Keep it ASCII, scannable, framed (e.g. a simple `=====` rule). No emojis.

`chmod +x examples/accrue_host/bin/dev-banner.sh` (and ensure git records the exec bit).

In `examples/accrue_host/Makefile`, rework `up` and add `open` (keep all other targets):
- `up`: `docker compose up -d --remove-orphans` then `./bin/dev-banner.sh` then
  `docker compose logs -f web`. Add the comment that Ctrl-C only detaches the log follow —
  the stack keeps running; use `make down` to stop.
- `open`: `open "$$(./bin/dev-banner.sh --url-only)"` (note the doubled `$$` for Make).
- Add both new targets to the `.PHONY` line. Keep the `## ...` help comments style.

Commit: `git commit -m "feat(host-docker): launch banner prints live URL, routes, and demo logins"`.
  </action>
  <verify>
    <automated>cd /Users/jon/projects/accrue/examples/accrue_host && bash -n bin/dev-banner.sh && test -x bin/dev-banner.sh && grep -q 'accrue-demo-password' bin/dev-banner.sh && grep -q '/app/reports/advanced' bin/dev-banner.sh && grep -q -- '--url-only' bin/dev-banner.sh && grep -Eq '^open:' Makefile && grep -q 'dev-banner.sh' Makefile && echo OK</automated>
  </verify>
  <done>`dev-banner.sh` is executable, passes `bash -n`, resolves the live port, supports `--url-only`, and prints the real routes + all five demo logins with the real password; Makefile `up` runs detached→banner→logs and `open` launches the browser; commit 2 made.</done>
</task>

<task type="auto">
  <name>Task 3: Lean entrypoint + host-bind caches (commit 3)</name>
  <files>examples/accrue_host/bin/dev-entrypoint.sh, examples/accrue_host/Dockerfile.dev, examples/accrue_host/docker-compose.yml</files>
  <action>
COMMIT 3 — trim the per-boot `mix setup` sledgehammer and make `make reset` re-link from cache.

Create `examples/accrue_host/bin/dev-entrypoint.sh` (bash, `set -euo pipefail`), run from the
`/workspace/examples/accrue_host` workdir, in this idempotent order:
1. `[ -d assets/node_modules/.bin ] || mix assets.setup`  (skip npm install when volume warm)
2. `mix deps.get`  (cheap when warm; correct when a hex dep is added)
3. `mix ecto.create --quiet`
4. `mix ecto.migrate`
5. `mix run priv/repo/seeds.exs`  (idempotent seeds — eval_file chain)
6. `[ -d priv/static/assets ] || mix assets.build`  (first-paint only; watchers own rebuilds after)
7. `exec mix phx.server`
Echo a short one-line status before steps so logs are readable. `chmod +x` it (record exec bit).

In `examples/accrue_host/Dockerfile.dev`:
- Add `# syntax=docker/dockerfile:1` as the VERY FIRST line.
- Add `COPY bin/ /workspace/examples/accrue_host/bin/` (after WORKDIR; ensure the script is
  inside the image and executable — add `RUN chmod +x bin/dev-entrypoint.sh bin/dev-banner.sh`
  if needed for safety).
- Replace `CMD ["bash", "-c", "mix setup && mix phx.server"]` with
  `ENTRYPOINT ["bin/dev-entrypoint.sh"]` (the entrypoint already execs phx.server; no CMD args
  required). Keep `EXPOSE 4000`.

In `examples/accrue_host/docker-compose.yml`, ADD host-bind cache mounts to the `web` service
`volumes:` list (KEEP the existing `../..:/workspace`, `mix_deps`, `mix_build`,
`assets_node_modules` named volumes exactly as-is):
  - `${HOME}/.cache/accrue-docker/hex:/root/.hex`
  - `${HOME}/.cache/accrue-docker/mix:/root/.mix`
  - `${HOME}/.cache/accrue-docker/npm:/root/.npm`
These survive `docker compose down --volumes`, so `make reset` re-links instead of re-downloads.
Do NOT convert the named volumes to bind mounts and do NOT add BuildKit `--mount=type=cache`
(build-time only; fetches here happen at runtime).

Commit: `git commit -m "perf(host-docker): lean idempotent entrypoint + host-bind hex/mix/npm caches"`.
  </action>
  <verify>
    <automated>cd /Users/jon/projects/accrue/examples/accrue_host && bash -n bin/dev-entrypoint.sh && test -x bin/dev-entrypoint.sh && grep -q 'exec mix phx.server' bin/dev-entrypoint.sh && grep -q 'priv/static/assets' bin/dev-entrypoint.sh && head -1 Dockerfile.dev | grep -q 'syntax=docker/dockerfile:1' && grep -q 'dev-entrypoint.sh' Dockerfile.dev && grep -q '/root/.hex' docker-compose.yml && grep -q 'mix_deps:/workspace' docker-compose.yml && echo OK</automated>
  </verify>
  <done>`dev-entrypoint.sh` is executable, idempotent (guards npm + first-paint asset build), and execs phx.server; Dockerfile has the syntax header, COPYs bin/, and uses the entrypoint instead of `mix setup`; compose adds the three host-bind caches while keeping all named volumes; commit 3 made.</done>
</task>

<task type="auto">
  <name>Task 4: README "Start Here" rewrite + new guide registered in docs (commit 4)</name>
  <files>examples/accrue_host/README.md, accrue_admin/guides/local_demo.md, accrue_admin/mix.exs</files>
  <action>
COMMIT 4 — persona-framed docs (not shoehorned). Match the existing voice in admin_ui.md and
first_hour.md (gameplan/TL;DR at top → numbered spine → "what you'll see").

(a) Rewrite the "Start Here" section of `examples/accrue_host/README.md` ONLY (leave the rest
of the README intact). New structure, gameplan summary FIRST:
   - 3-line happy path: `make build` once → `make up` → read the banner.
   - "No port picking — every `make up` auto-grabs a free port and prints the URL." Multi-demo
     note: just run `make up` in each lib; they can't collide (ephemeral host ports).
   - The banner explained: it prints the live URL, the key routes (`/admin`, `/billing`,
     `/app/billing`, `/app/reports/advanced`, `/users/log-in`, `/dev/mailbox`), and the seeded
     demo logins (all five) with password `accrue-demo-password`. `make open` jumps straight there.
   - Caching mental model: what's instant (`.heex`/CSS/JS hot-reload), what's a few seconds
     (`make up` — deps.get + migrate + boot), what's a full rebuild (`make build` / `make reset`)
     and why (named volumes vs host-bind caches; reset re-LINKS from `~/.cache/accrue-docker/*`).
   - Brief troubleshooting: pin a port via `ACCRUE_HOST_DOCKER_PORT` for OAuth; `make down` vs
     Ctrl-C (Ctrl-C only detaches logs; `make down` stops the stack); `make reset` to reseed.
   - Update the Makefile command table to add the new `make open` row and keep `make up`/`make
     down`/`make logs`/`make psql`/`make sh`/`make reset`/`make ps`/`make build`. The old "pick a
     port block 4000/4010/4020" guidance and the manual `.env` copy-to-pick-a-port instructions
     must be removed/reworded to match the ephemeral default. The Traefik "Advanced (optional)"
     block may be DROPPED (the ephemeral approach replaces it) — removing it is fine.

(b) Create `accrue_admin/guides/local_demo.md` for the EVALUATOR/OPERATOR persona ("I want to
SEE the admin UI operators get, without wiring Stripe"). NOT a README duplicate — narrative.
   - TL;DR at top (3-5 lines: clone → `cd examples/accrue_host` → `make build` → `make up` →
     open the banner URL → sign in as healthy@example.com / accrue-demo-password → visit `/admin`).
   - Numbered spine: (1) start it, (2) read the banner, (3) sign in (list the five demo accounts
     and what each shows: healthy = clean, past-due = dunning banner, canceled, enterprise = JPY,
     trialing), (4) walk `/admin` (customers, subscriptions, invoices, webhook/replay, audit),
     (5) "what you'll see" — Fake-backed billing, no live Stripe keys needed.
   - Cross-link, do not duplicate: the README (`../../examples/accrue_host/README.md`) for the
     full command reference; `../../accrue/guides/first_hour.md` for the package install story;
     `admin_ui.md` for host wiring. Use the same relative-path style as other admin guides.

(c) Register the guide in `accrue_admin/mix.exs` `docs/0`:
   - Add `"guides/local_demo.md"` to the `extras:` list.
   - Add `"guides/local_demo.md"` to the `Guides:` list under `groups_for_extras:`.
   - Because local_demo.md cross-references repo-relative paths outside the package tarball
     (the example README), ADD `"guides/local_demo.md"` to `skip_undefined_reference_warnings_on:`
     so `mix docs --warnings-as-errors`-style builds stay clean (mirrors the existing entries).

Commit: `git commit -m "docs(host-docker): rewrite Start Here + add local_demo evaluator guide"`.
  </action>
  <verify>
    <automated>cd /Users/jon/projects/accrue && test -f accrue_admin/guides/local_demo.md && grep -q 'guides/local_demo.md' accrue_admin/mix.exs && grep -c 'guides/local_demo.md' accrue_admin/mix.exs | grep -qE '^[23]$' && grep -q 'make open' examples/accrue_host/README.md && ! grep -q 'otherlib web 4010, thirdlib web 4020' examples/accrue_host/README.md && (cd accrue_admin && mix docs >/tmp/axdocs.log 2>&1); grep -qi 'local_demo' /tmp/axdocs.log || ls accrue_admin/doc/local_demo.html >/dev/null 2>&1 && echo OK</automated>
  </verify>
  <done>README "Start Here" leads with the gameplan summary and the ephemeral/banner/caching story (no 4000/4010/4020 block, `make open` documented); `accrue_admin/guides/local_demo.md` exists as a persona-framed narrative and is registered in `extras:`, the `Guides:` group, and `skip_undefined_reference_warnings_on:`; `mix docs` builds clean with the guide; commit 4 made.</done>
</task>

<task type="auto">
  <name>Task 5 (OPTIONAL — only if low-risk): native-dev banner</name>
  <files>examples/accrue_host/lib/accrue_host_web/dev_banner.ex, examples/accrue_host/lib/accrue_host/application.ex</files>
  <action>
OPTIONAL native-dev nicety. Include ONLY if it is genuinely low-risk after reading
`lib/accrue_host/application.ex`; otherwise SKIP and note it as deferred in the SUMMARY
(the host-side Docker banner already covers the primary use case).

If included: add a tiny `AccrueHost.DevBanner` module with a `print/0` that logs the same
routes + demo creds block as `dev-banner.sh` but for native dev (`http://localhost:4000`).
Call it from `AccrueHost.Application.start/2` AFTER `Supervisor.start_link/2` succeeds, gated
on BOTH:
  - `Application.get_env(:accrue_host, :dev_routes)` is truthy (dev only), AND
  - `System.get_env("PGHOST") != "db"` (suppress inside Docker — the host-side banner already
    runs there and binds 0.0.0.0/ephemeral, so `localhost:4000` would be wrong).
Must NOT raise if printing fails (wrap in a best-effort try/catch); must NOT affect prod/test
boot. If touching application.ex feels risky, DEFER — do not force it.

If included, commit: `git commit -m "feat(host-docker): native-dev banner (dev-only, suppressed under Docker)"`.
If deferred, make no commit and record the deferral in the SUMMARY.
  </action>
  <verify>
    <automated>cd /Users/jon/projects/accrue/examples/accrue_host && { test -f lib/accrue_host_web/dev_banner.ex && grep -q 'PGHOST' lib/accrue_host_web/dev_banner.ex && grep -q 'dev_routes' lib/accrue_host/application.ex && MIX_ENV=test mix compile --warnings-as-errors >/tmp/axcompile.log 2>&1 && echo INCLUDED-OK; } || echo "DEFERRED-OK (note in SUMMARY)"</automated>
  </verify>
  <done>EITHER: a dev-only, Docker-suppressed native banner compiles clean under warnings-as-errors and does not touch prod/test boot — OR the task is deferred with a one-line note in the SUMMARY. Both outcomes are acceptable.</done>
</task>

</tasks>

<verification>
End-to-end (manual / on a Docker host — the automated `<verify>` gates above are the
merge-blocking checks; these are the human acceptance walkthrough from the approved plan):
1. `cd examples/accrue_host && make build` then `make up` → server boots, banner prints a
   `127.0.0.1:<random-port>` URL with the real routes + the five demo logins; open it, sign in
   as `healthy@example.com` / `accrue-demo-password`, reach `/admin`.
2. With the first stack up, start a SECOND copy with a different `ACCRUE_HOST_COMPOSE_PROJECT`
   → it gets a DIFFERENT ephemeral port and both run (multi-lib collision stand-in).
3. `make open` launches the browser at the live URL.
4. Edit a `.heex` and a CSS file while running → hot-reload, no rebuild. `make up` after a
   no-op change → no npm install, no full asset rebuild. Add a throwaway hex dep → only
   `deps.get` runs.
5. `make reset` after warming `~/.cache/accrue-docker/*` → deps/npm re-link from cache, not
   re-downloaded.
6. `cd accrue_admin && mix docs` builds with local_demo under "Guides"; links resolve.
7. No regressions: prod/test boot untouched (entrypoint Docker-only; native banner — if added —
   gated on :dev_routes and suppressed under Docker; no new runtime deps).
</verification>

<success_criteria>
- Four atomic commits made (ephemeral ports, banner, caching/entrypoint, docs); optional 5th
  commit only if the native banner was included.
- `web` host port is ephemeral by default; pinnable via `ACCRUE_HOST_DOCKER_PORT`.
- `bin/dev-banner.sh` (executable) prints live URL + REAL routes + REAL five demo logins +
  `accrue-demo-password`; `--url-only` works; Makefile `up`/`open` wired.
- `bin/dev-entrypoint.sh` (executable) replaces `mix setup`; Dockerfile syntax header + COPY
  bin/ + ENTRYPOINT; compose adds host-bind caches and KEEPS named volumes.
- README "Start Here" rewritten gameplan-first; `accrue_admin/guides/local_demo.md` created and
  registered (extras + Guides group + skip_undefined_reference_warnings_on); `mix docs` clean.
- No new runtime deps; prod/test boot untouched.
</success_criteria>

<output>
Create `.planning/quick/260604-tjz-docker-dx-for-accrue-host-admin-ui-ephem/260604-tjz-SUMMARY.md` when done.
Record in the SUMMARY whether Task 5 (native-dev banner) was INCLUDED or DEFERRED.
</output>
