# Cadence Example Host

This checked-in Phoenix app is the canonical local evaluation path for `accrue`
and `accrue_admin`. It presents a fictional team project-tracking SaaS called **Cadence** so
the customer-facing app feels like a real Phoenix product using Accrue, while the
operator surface remains **Accrue Admin**.

## Start Here

The whole happy path is three steps:

```bash
cd examples/accrue_host
make proxy      # ONCE per machine — starts the shared Traefik proxy (skip if it's already up)
make up         # every time after that — builds on first run, then read the banner
```

Then open **http://accrue.localhost/**. That URL is stable — bookmark it. Start
from the Cadence home page to choose pricing, customer billing, or the Accrue
Admin operator path. You must be logged in as `admin@example.com` (password
`accrue-demo-password`) to access `/admin`; customer logins are for
tenant-facing billing flows only.

Operator deep link: **http://accrue.localhost/admin** opens the mounted Accrue
Admin UI after sign-in.

`make up` creates the shared Docker `proxy` network if it is missing, so a fresh
machine fails less mysteriously. `make proxy` is still the step that starts Traefik
and makes the stable `*.localhost` URL route; without it, the banner prints the
automatic `http://127.0.0.1:<port>/admin` fallback.

**One stable URL, zero port juggling.** `make proxy` starts a small shared Traefik
reverse proxy (once, fleet-wide). Every demo that joins it gets its own
`*.localhost` name on port 80 — so this lib lives at `http://accrue.localhost` while
your other lib demos sit at `http://scoria.localhost`, `http://parapet.localhost`,
and so on. **They can never collide**, and you never pick or remember a port. See
[docs/docker-dx.md](docs/docker-dx.md) for the why and the fleet picture.

> **Running alongside your other lib demos?** The proxy is shared infrastructure.
> Run `make proxy` from *any* one repo and they all route through it — `make down`
> only stops *this* demo, never the proxy. `*.localhost` resolves automatically in
> Chrome/Firefox; on Safari/curl use the fallback URL the banner prints.

**Read the banner.** After `make up`, `bin/dev-banner.sh` waits for the server, then
prints a copy-pasteable block with:

- the stable URL (`http://accrue.localhost/`) — plus an ephemeral
  `http://127.0.0.1:<port>` **fallback** for when the proxy isn't running,
- the key routes — `/` (Cadence app home), `/pricing` (Cadence plans),
  `/billing` (Cadence customer portal), `/app/billing` (workspace billing),
  `/admin` (mounted Accrue Admin UI), `/app/reports/advanced`
  (entitlement-gated reports), `/users/log-in` (sign in), `/dev/mailbox`
  (sent-email preview), and
- the seeded demo logins — `admin@example.com` (billing-admin operator — required to
  open `/admin`), and the 5 customer personas (tenant-facing billing flows only, not
  admin-capable): `healthy@example.com`, `past-due@example.com`, `canceled@example.com`,
  `enterprise@example.com`, `trialing@example.com`, all with password **`accrue-demo-password`**.
  Use `healthy@example.com` for the happy-path `/billing` portal walkthrough; it
  has a seeded user-owned subscription, default card, and paid invoice.

`make open` jumps straight to the running demo in your browser; `make url` reprints
the stable + fallback URLs without the full banner. No live Stripe keys are required
for any of this — billing is `Accrue.Processor.Fake`-backed.

**What's instant vs. what costs a moment.**

- *Instant:* editing `.heex`, CSS, or JS hot-reloads with no restart (live_reload +
  Tailwind/esbuild watchers run inside the container).
- *A few seconds:* `make up` runs the lean entrypoint — `mix deps.get` + migrate +
  seed + boot — skipping npm install and the first-paint asset build when the named
  volumes are already warm. Adding a hex dep just re-runs `deps.get`.
- *A full rebuild:* `make build` (image changed) or `make reset` (wipe volumes and
  reseed). `make reset` re-**links** Hex/npm from the host-bind caches under
  `~/.cache/accrue-docker/*` instead of re-downloading over the network — those
  caches survive `docker compose down --volumes`.

**Troubleshooting.**

- `accrue.localhost` won't load? Either the shared proxy isn't running (`make proxy`)
  or your browser won't resolve `*.localhost` (Safari, `curl`) — use the
  `http://127.0.0.1:<port>` fallback the banner prints. The Traefik dashboard at
  http://localhost:8080/dashboard/ shows exactly what's routed where.
- Running two checkouts of *this same* lib? `make up INSTANCE=accrue-foo` gives the
  second one its own route at `http://accrue-foo.localhost` and isolated volumes.
  `INSTANCE` must be DNS-safe lowercase: letters, numbers, and hyphens only.
- On Apple Silicon, unset `DOCKER_DEFAULT_PLATFORM=linux/amd64` before using this
  demo. Forced amd64 emulation is known to corrupt BEAM/NIF builds here; the image
  builds native arm64 and compiles the HarfBuzz NIF from Rust source.
- `make up` follows the web logs; **Ctrl-C only detaches the log follow** — the stack
  keeps running. Use `make down` to actually stop it (the shared proxy stays up).
- Want a clean slate? `make reset` nukes the volumes and reseeds (seeds are
  idempotent).

| Command | When to use |
|---------|-------------|
| `make proxy` | Once per machine — start the shared Traefik proxy (skip if already up) |
| `make up` | Every day — builds on first run, prints the banner, follows logs |
| `make open` | Open the running demo in your browser |
| `make url` | Reprint the stable + fallback URLs |
| `make build` | Force a rebuild after changing `Dockerfile.dev` / OS-level deps |
| `make down` | Stop *this* demo's stack (leaves the shared proxy running) |
| `make logs` | Stream Phoenix logs |
| `make psql` | Open a psql session in the running db container |
| `make sh` | Open a bash shell in the running web container |
| `make reset` | Nuke volumes and reseed from scratch (seeds are idempotent) |
| `make ps` | List all Compose projects running on this machine |

Run the focused proof after the walkthrough:

```bash
cd examples/accrue_host
mix verify
```

## Apple notification ingress

Cadence exposes the production-only Apple V2 endpoint at `POST /webhooks/apple`.
It is a dedicated JSON/raw-body boundary, separate from the Stripe webhook route:
the exact request body is limited to **262,144 bytes** before the host delegates
to Accrue's Apple notification ingress.

Production supplies these six runtime inputs by name, with deployment values kept
outside this repository: `APPLE_TRUST_ROOTS_PEM_PATH`, `APPLE_BUNDLE_ID`,
`APPLE_APP_ID`, `APPLE_VERIFIER_CONFIG_VERSION`,
`APPLE_SERVER_API_BEARER_TOKEN`, and `APPLE_PRODUCT_MAP_JSON`. The host pins the
trust-root/config-version identity to a production verifier configuration and
shares that same configuration with Apple admission and reconciliation. This
recipe does not describe a sandbox route; a future sandbox endpoint needs its own
configuration and proof.

The host adds Apple intake to the existing reconciliation queue and sweeper. A
`200` means the notification reached a durable verified, no-op, or quarantined
terminal outcome; it does not mean the request directly changed an entitlement.
`400` is malformed input, `413` is an oversized body, `429` is temporary
backpressure, and `503` means a required capture, configuration, verification, or
persistence dependency could not complete. PostgreSQL constraints and locks own
duplicate and concurrent-delivery correctness. The local direct-peer rate policy
is a single-node backstop only; deployment edge or shared infrastructure is the
authority for multi-node and internet-scale limits.

For a safe first response, compare response-class trends first, then quarantine
growth, reconciliation age/backlog, and `needs_repair` in the authenticated
diagnostic. Confirm the named queue and sweeper are running, let bounded
reconciliation work converge, and escalate a growing backlog, repeated `429`, or
`needs_repair` rather than attempting a manual entitlement change. Record only a
safe correlation and the next action.

Run the credential-free host proof exactly as follows:

```bash
cd examples/accrue_host
mix verify
```

For native Phoenix contributor work, use the same app without Docker:

```bash
cd examples/accrue_host
mix setup
mix phx.server
```

> **Accrue does not require Sigra.** Production integrations use your host’s
> **`Accrue.Auth`** adapter. This demo app uses Sigra so the checked-in story can
> show reproducible signed-in organization billing. If you are not using Sigra,
> follow **[First Hour](../../accrue/guides/first_hour.md)** plus
> **[Organization billing (non-Sigra)](../../accrue/guides/organization_billing.md)**
> in your own Phoenix app.

## Prerequisites

For Docker evaluation, you need Docker with Compose. You do **not** need a host
Postgres server: Compose sets `PGHOST=db`, keeps Postgres internal-only by default,
and the web container reaches it over the private Compose network.

If you need a GUI client such as DBeaver or TablePlus, copy
`docker-compose.override.yml.example` to `docker-compose.override.yml` (gitignored,
auto-merged). By default Docker assigns a free loopback DB port; run
`docker compose port db 5432` to see it. Set `PGPORT=55432` only when your GUI needs
a stable port for this one instance.

Host ports are ephemeral by default, so concurrent demos never collide — no port
picking needed. Copy `.env.example` to `.env` only to pin a fixed fallback port
(`ACCRUE_HOST_DOCKER_PORT`, e.g. for OAuth callbacks) or to override
`COMPOSE_PROJECT_NAME` / `ACCRUE_HOST` directly. For normal side-by-side checkouts,
prefer `make up INSTANCE=accrue-foo`.

Docker uses named volumes for `deps`, `_build`, and `assets/node_modules`.
`make up` reuses them every run — no dep redownload. Use `make reset` only when you
want to nuke volumes and reseed from scratch; the Hex/npm download caches under
`~/.cache/accrue-docker/*` survive the reset.

For native Phoenix contributor work (`mix setup && mix phx.server`), run your own
Postgres and override `PGHOST`, `PGPORT`, `PGUSER`, or `PGPASSWORD` if your local
database uses non-default values.

The default local setup uses `Accrue.Processor.Fake` and the local webhook
signing secret `whsec_test_host`. You can exercise the full path without live
Stripe credentials. Stripe remains the default first-user path, and Braintree
is official only for the `gateway subscription core` slice. The shared billing
facade stays provider-honest: Stripe returns upstream hosted checkout and
billing-portal URLs, while Braintree returns mounted local checkout and portal
URLs owned by the host app. The Braintree proof lane in `examples/accrue_host`
is fully hermetic and uses checked-in mocks/fixtures to exercise the generic
billing facade without network access. Any future real-provider Braintree smoke
is advisory only while Fake remains the merge-blocking SSOT.
At this host layer, the semantics stay intentionally thin: `update_customer/2`
remains a bounded provider-neutral helper, `cancel/2` is the shared immediate
path, and the official active-subscription-change contract is
`swap_plan/3` plus `preview_upcoming_invoice/2`. Preview is the canonical path where supported before commit; Braintree keeps a bounded first-party
`swap_plan/3` path when the host configures `:plan_resolver`, but
`preview_upcoming_invoice/2` stays explicitly unsupported there. `cancel_at_period_end/2`
is not a first-party Braintree path. The full contract still lives in the canonical
[`processor-support-matrix.md`](../../.planning/processor-support-matrix.md).

**Sigra:** the example host depends on Sigra (not on Hex yet). `mix deps.get`
pulls it from [szTheory/sigra](https://github.com/szTheory/sigra) by default so
CI and fresh clones work. To compile against a sibling checkout instead, set
`ACCRUE_SIGRA_PATH=../../../sigra` (relative to this directory) before
`mix deps.get`.

## How to enter this example

This README is the **host-facing** telling of the same ordered spine as
[`../../accrue/guides/first_hour.md`](../../accrue/guides/first_hour.md) (deps → install/setup → runtime → migrations → Oban → webhooks → admin → proof). Pick a capsule, then follow **§ First run** below.

### Capsule H — Hex consumer

Integrate Accrue into your **own** Phoenix app: follow package steps in **First Hour** (`mix accrue.install`, `config/runtime.exs`, migrations, Oban, webhook pipeline, admin mount, and the mounted Braintree portal contract when needed), then use this demo only for proof vocabulary if needed.

### Capsule M — Monorepo clone

You are in the Accrue repo: stay in **`examples/accrue_host`**, run **`mix setup`** and **`mix phx.server`**, then walk the numbered story (subscription → signed `/webhooks/stripe` → `/billing` → `mix verify`) — the canonical Fake-backed loop.

### Capsule R — Evaluate / read-only

Clone once, `cd examples/accrue_host`, run **`mix verify`**. When VERIFY-01 / Playwright depth or the CI-equivalent host stack matters, jump to [**#proof-and-verification**](#proof-and-verification) instead of duplicating those commands here.

## First run

From the repository root:

```bash
cd examples/accrue_host
mix setup
mix phx.server
```

Then walk the public Cadence story in this order:

1. Sign in, open workspace billing, and choose the Launch plan
   on `/app/billing` to create one Fake-backed subscription through
   `AccrueHost.Billing`.
2. Post one signed webhook through the real `/webhooks/stripe` endpoint. The
   focused proof suite uses `customer.subscription.created` for this step.
   If ingest fails, see [`../../accrue/guides/troubleshooting.md`](../../accrue/guides/troubleshooting.md#accrue-dx-webhook-raw-body) (**`ACCRUE-DX-WEBHOOK-RAW-BODY`**) and [`../../accrue/guides/troubleshooting.md#accrue-dx-webhook-secret-missing`](../../accrue/guides/troubleshooting.md#accrue-dx-webhook-secret-missing) (**`ACCRUE-DX-WEBHOOK-SECRET-MISSING`**) for stable fix paths — VERIFY-01 authority stays under [**#proof-and-verification**](#proof-and-verification).
3. Visit `/billing` as `healthy@example.com` to confirm the Cadence-branded
   customer portal shows subscription, invoice, and payment method state.
   `/app/billing` is workspace/org billing; `/billing` is the signed-in user's
   customer portal. Visit `/admin` as the operator to inspect billing state,
   webhook ingest, and replay visibility.
4. Run the focused proof suite after you have walked the story yourself:

```bash
cd examples/accrue_host
mix verify
```

Package-facing docs mirror the same order in
[`../../accrue/guides/first_hour.md`](../../accrue/guides/first_hour.md).

## Seeded history

`Seeded history` is the deterministic evaluation path for replay/history and
browser smoke. It is not the public teaching path.

```bash
cd examples/accrue_host
mix setup
mix verify.full
```

Use this when you want replay-ready webhook history, browser coverage, or other
pre-seeded admin states that would be awkward to create in a short walkthrough.
Keep cancellation and other secondary proofs here instead of in the main story.

## Proof and verification

Use the smallest proof that answers your question:

- **Explore:** `make build` (first run) / `make up` (daily) runs the demo app and
  Postgres locally so you can inspect the Fake-backed `/app/billing` to `/billing`
  loop in a browser.
- **Focused proof:** `mix verify` is the bounded Fake-backed proof for installer
  boundary, subscription flow, signed `/webhooks/stripe` ingest, mounted
  `/billing` inspection, and replay visibility.
- **Full local gate:** `mix verify.full` is the CI-equivalent local host gate. It
  layers compile, asset-build, dev-boot, regression, and browser smoke on top of
  `mix verify`.
- **CI wrapper:** `bash scripts/ci/accrue_host_uat.sh` is the repo-root wrapper
  used by GitHub Actions job `host-integration` for the full host stack.
- **Maintainer contracts:** `scripts/ci/README.md` owns maintainer triage and the
  support-contract bundle map; this README only names the host-facing checks it
  directly depends on.
- **Provider parity:** live Stripe parity is scheduled/manual provider drift
  detection. It is not required for local evaluation or Start Here.

Pull requests are merge-blocked on GitHub Actions jobs
`docs-contracts-shift-left` and `host-integration` (see
`.github/workflows/ci.yml`). This README directly depends on
`bash scripts/ci/verify_adoption_proof_matrix.sh` for the adoption-proof
contract and on `bash scripts/ci/accrue_host_uat.sh` for the full host stack
(`cd examples/accrue_host && mix verify.full`). For exact CI bundle membership
and triage ownership, use `scripts/ci/README.md` with `.github/workflows/ci.yml`.
This checked-in proof surface is the linked `accrue` / `accrue_admin` `1.0.0`
release slice: the same host README, shift-left scripts, and wrapper UAT prove
the public pair before and after publish.

For **`Accrue.Billing.create_checkout_session/2`** and
**`Accrue.Billing.create_billing_portal_session/2`**, the teaching path and
telemetry tuples live in [**First Hour**](../../accrue/guides/first_hour.md);
span anchors and ExUnit SSOT paths are under [**#observability**](#observability).

### Verification modes

- `mix verify` is the focused local proof suite for installer boundary,
  Fake-backed subscription flow, signed `/webhooks/stripe` ingest, mounted
  `/billing` inspection, and replay visibility.
- `mix verify.full` is the CI-equivalent local gate. It layers compile,
  asset-build, dev-boot, regression, and browser smoke on top of `mix verify`.
- `bash scripts/ci/accrue_host_uat.sh` is the thin repo-root wrapper around the
  same full contract.
- `bash scripts/ci/accrue_host_hex_smoke.sh` is Hex smoke. Keep it separate
  from the canonical checked-in host tutorial.
- `mix accrue.install` is production setup inside your own Phoenix app, not the
  shortcut for this demo app.

## Observability

- **Cross-domain host subscription** (append `Accrue.Telemetry.Metrics.defaults/0`, attach once to `[:accrue, :ops, :webhook_dlq, :dead_lettered]`) is documented in [`../../accrue/guides/telemetry.md`](../../accrue/guides/telemetry.md#cross-domain-host-subscription). The compile-checked mirror in this app is `AccrueHost.AccrueOpsTelemetry`.
- **Billing checkout facade:** `Accrue.Billing.create_checkout_session/2` emits **`[:accrue, :billing, :checkout_session, :create]`**; span metadata and Fake vs live processor notes live under [`../../accrue/guides/telemetry.md#billing-checkout-session-create`](../../accrue/guides/telemetry.md#billing-checkout-session-create) (ExUnit SSOT: `accrue/test/accrue/billing/checkout_session_facade_test.exs`).
- **Billing portal facade:** `Accrue.Billing.create_billing_portal_session/2` emits **`[:accrue, :billing, :billing_portal, :create]`**; span notes live under [`../../accrue/guides/telemetry.md#billing-billing-portal-create`](../../accrue/guides/telemetry.md#billing-billing-portal-create) (ExUnit SSOT: `accrue/test/accrue/billing/billing_portal_session_facade_test.exs`).
- **Recovery & Maintenance:** Background jobs like `Accrue.Jobs.DetectExpiringCards` and `Accrue.Jobs.MeterEventsReconciler` are wired into the host Oban crontab to demonstrate production-grade failure recovery and automated maintenance. Proof of wiring lives in `test/accrue_host/recovery_wiring_test.exs`.

## Production readiness

Before promoting billing to a live Stripe account, use the package checklist [`../../accrue/guides/production-readiness.md`](../../accrue/guides/production-readiness.md). It is the same host-owned story as **First Hour**, ordered for **ship** rather than **evaluate**.

## Public guides handoff

This host README stays proof-lane focused. Canonical semantics, support boundaries, and stable-core posture live in public guides: [First Hour](../../accrue/guides/first_hour.md), [Jobs to Be Done](../../accrue/guides/jobs_to_be_done.md#scope-and-maturity), and [Maturity and maintenance](../../accrue/guides/maturity-and-maintenance.md). Treat this file as adoption proof vocabulary, not policy authority.

### VERIFY-01 (Phase 21)

Canonical local gate for org-scoped host billing proofs and Playwright VERIFY-01
specs. Paths are **Fake-backed** by default; no live Stripe keys are required.
Treat live Stripe as optional and advisory only — do not put `sk_live` in `.env`
for this checklist.

The VERIFY-01 browser lane under `host-integration` runs the **full** Playwright suite,
including **`e2e/verify01-admin-a11y.spec.js`** (Phase 28: `@axe-core/playwright`,
serious + critical violations, forced light then dark on desktop; mobile projects
skip this file). Focused local run after the usual seed + server: `npm run e2e:a11y`.
For the mobile shell lane on **`chromium-mobile`**, **`npm run e2e:mobile`** runs **`e2e/verify01-admin-mobile.spec.js`** after the same seed + server setup.
The payment-method route in this suite stays intentionally narrow: operators can
review projected inventory, **Sync payment methods**, set a new default, and hit
guarded delete warnings, while **Replace payment method** remains a host-owned
handoff outside admin.

**Copy anti-drift (Phase 50 / D-23):** VERIFY-01 specs read operator strings from
**`e2e/generated/copy_strings.json`**, produced by
**`mix accrue_admin.export_copy_strings --out e2e/generated/copy_strings.json`**
(run from **`accrue_admin/`**; path is relative to the host package checkout). CI
regenerates this file on every **`accrue_host_verify_browser.sh`** run before
**`npm run e2e`**; update the Mix task allowlist when adding new keys.

The `npm run e2e:*` scripts use **`env -u NO_COLOR`** (POSIX-oriented); Windows contributors may run `npx playwright test …` directly when `env -u` is awkward.

#### Mounted admin — mobile shell

When Accrue Admin is mounted under `/billing`, treat the **App shell** as the single
scroll owner on narrow viewports: primary content scrolls inside **`.ax-shell-main`**
so it does not fight the host page chrome.

- **Narrow width:** primary destinations (Dashboard, Customers, Subscriptions, …)
  live behind the **Menu** control (`getByRole("button", { name: "Menu" })`) until the
  drawer opens. Do not rely on **hover-only** primary navigation for mobile layout
  proofs.
- **`?org=`:** shell `nav_href` links preserve the active organization the same way as
  desktop; keep org query params coherent when deep-linking customer routes.
- **Touch targets:** dense tables on Pixel-class viewports may need
  `scrollIntoViewIfNeeded` before clicks in Playwright so hit targets are reachable.
- **Host embedding cautions:** watch for **double chrome** (host nav + admin topbar),
  **`overflow: hidden`** on host wrappers clipping the LiveView tree, and **z-index**
  stacking that can hide the mobile drawer behind host overlays (patterns from
  Filament/ActiveAdmin-style mounts).

Automated checks for this contract live in **`e2e/verify01-admin-mobile.spec.js`**,
which runs substantive assertions on **`chromium-mobile`** only. The
**`chromium-mobile-tagged`** project is for tag discovery, not responsive layout
parity.

Run each step from the repository root using `cd examples/accrue_host` first:

1. Create a temp fixture file and seed the test database (required for browser
   specs that read `ACCRUE_HOST_E2E_FIXTURE`):

   ```bash
   cd examples/accrue_host
   fixture_file="$(mktemp)"
   ACCRUE_HOST_E2E_FIXTURE="$fixture_file" MIX_ENV=test mix run ../../scripts/ci/accrue_host_seed_e2e.exs
   ```

2. Host integration tests (warnings as errors):

   ```bash
   cd examples/accrue_host
   MIX_ENV=test mix test --warnings-as-errors
   ```

3. Playwright phase gate (after deterministic JS bootstrap in
   `examples/accrue_host`):

   ```bash
   cd examples/accrue_host
   npm ci
   npm run e2e:install
   npm run e2e:a11y
   ```

4. Full host browser suite, if you need more than the merge-blocking admin a11y lane:

   ```bash
   cd examples/accrue_host
   npm ci
   npm run e2e:install
   npx playwright test
   ```

For maintainers who want the repo-root wrapper after the tutorial story:

```bash
bash scripts/ci/accrue_host_uat.sh
```

## Adoption realism & proof matrix

For **what is proven where** (Fake CI vs Stripe test-mode advisory vs B2C-shaped API
tests vs org-first LiveView), see
[`docs/adoption-proof-matrix.md`](docs/adoption-proof-matrix.md).

For a **human screen-recording checklist** (evaluators / stakeholders), see
[`docs/evaluator-walkthrough-script.md`](docs/evaluator-walkthrough-script.md).

## Visual walkthrough (Fake-backed)

To **see** the Cadence + Accrue Admin story (no live Stripe), use the
**`@phase15-trust`** Playwright spec. This lane is **trust/demo visuals only**; it
does not substitute for the VERIFY-01 merge-blocking checklist under
[Proof and verification](#proof-and-verification) above. It uses the same Fake-backed
fixture as the rest of the browser suite (scrubs prior `sub_fake_%` host rows so
Fake ids cannot collide): Cadence workspace billing and customer portal first,
then mounted **Accrue Admin** for webhook detail, replay, and audit.

**Artifacts (local, gitignored under `test-results/`):**

- **PNG stills (full page):** `examples/accrue_host/test-results/phase15-trust/<project>/`
  (e.g. `chromium-desktop/`, `chromium-mobile/`).
- **Session videos (Playwright `.webm`):** `npm run e2e:visuals` records one clip per
  browser project. After each run, the walkthrough is also copied to a stable path:
  `examples/accrue_host/test-results/phase15-trust-videos/<project>/admin-billing-walkthrough.webm`
  so you do not have to hunt Playwright’s hashed `test-results/.../video.webm` folders.

The repo ships a real **`accrue_admin` `priv/static` bundle** (Phoenix + LiveView client). If you change admin JavaScript or CSS sources, rebuild with `cd accrue_admin && mix accrue_admin.assets.build` and commit the updated `priv/static` files.

**One command (after `npm ci` and `npm run e2e:install`):** screenshots **and** video (1280×720 encode; mobile uses the Pixel 5 viewport from the project).

```bash
cd examples/accrue_host
npm run e2e:visuals
```

**PNG only (faster, no `.webm`):**

```bash
cd examples/accrue_host
npm run e2e:visuals:png-only
```

CI and `npm run e2e` / `mix verify.full` do **not** set `ACCRUE_HOST_PLAYWRIGHT_VIDEO`, so
they stay screenshot/trace-only unless you opt in.

Equivalent manual invocation (with video):

```bash
cd examples/accrue_host
ACCRUE_HOST_PLAYWRIGHT_VIDEO=1 npx playwright test e2e/phase13-canonical-demo.spec.js --grep @phase15-trust
```

**HTML report (optional):** run a normal `npx playwright test` locally, then open the
generated report (Playwright default: `npx playwright show-report` from this
directory when the HTML reporter produced `playwright-report/`).

**On CI:** every `host-integration` run uploads artifact **`accrue-host-phase15-screenshots`**
(`examples/accrue_host/test-results/phase15-trust`, upload step `if: always()` in
`.github/workflows/ci.yml`). Download it from the GitHub Actions run summary, or with the GitHub CLI (after `gh auth login`) once you have a run `RUN_ID` from the **host-integration** job:

```bash
gh run download RUN_ID --repo szTheory/accrue -n accrue-host-phase15-screenshots -D /path/to/output-dir
```

**Video on CI:** workflows still upload **PNGs** only (`accrue-host-phase15-screenshots`).
For a human screen-recording checklist (OBS / QuickTime), see
[`docs/evaluator-walkthrough-script.md`](docs/evaluator-walkthrough-script.md).

## What this app proves

- Host-owned auth and session state gate the mounted admin UI at `/billing`.
- Signed webhook ingest runs through the installed `/webhooks/stripe` route.
- Replay actions and billing changes leave persisted audit history.
- Recovery and reconciliation jobs (`DetectExpiringCards`, `MeterEventsReconciler`) run automatically via Oban crontab.
- Fake, test, and live Stripe remain distinct modes, but the canonical local
  path is Fake-backed and credential-free.
