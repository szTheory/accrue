# Accrue Host Example

This checked-in Phoenix app is the canonical local evaluation path for `accrue`
and `accrue_admin`: a realistic B2B devtool SaaS host with seeded accounts,
`Accrue.Processor.Fake` billing, signed webhook ingest, and mounted admin
inspection.

## Start Here

Use Docker for the fastest evaluator path:

```bash
cd examples/accrue_host
docker compose up --build
```

Open [`http://localhost:4000`](http://localhost:4000). Sign in, visit
`/app/billing`, start a Fake-backed subscription through `AccrueHost.Billing`,
then inspect `/billing` to see billing state, webhook ingest, replay visibility,
and the mounted admin UI. No live Stripe keys are required for this path.

Run the focused proof after the walkthrough:

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

- PostgreSQL 14+ must already be running.
- By default the app connects to `localhost:5432`.
- Override `PGHOST`, `PGPORT`, `PGUSER`, or `PGPASSWORD` if your local database
  uses different values.
- Docker Compose sets `PGHOST=db` for the web container and publishes
  `5432:5432`; stop any local Postgres already using that port before running
  the Docker path.
- Docker uses named volumes for container `deps`, `_build`, and
  `assets/node_modules`, so container dependencies stay isolated from native
  development.
- Use `docker compose down --volumes` only when you want to reset Docker data and
  dependency volumes, not as the normal stop command.

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

Then walk the public host story in this order:

1. Sign in, open the host-owned billing screen, and use `Start subscription`
   on `/app/billing` to create one Fake-backed subscription through
   `AccrueHost.Billing`.
2. Post one signed webhook through the real `/webhooks/stripe` endpoint. The
   focused proof suite uses `customer.subscription.created` for this step.
   If ingest fails, see [`../../accrue/guides/troubleshooting.md`](../../accrue/guides/troubleshooting.md#accrue-dx-webhook-raw-body) (**`ACCRUE-DX-WEBHOOK-RAW-BODY`**) and [`../../accrue/guides/troubleshooting.md#accrue-dx-webhook-secret-missing`](../../accrue/guides/troubleshooting.md#accrue-dx-webhook-secret-missing) (**`ACCRUE-DX-WEBHOOK-SECRET-MISSING`**) for stable fix paths — VERIFY-01 authority stays under [**#proof-and-verification**](#proof-and-verification).
3. Visit `/billing` as a billing admin and confirm the mounted admin UI shows
   the billing state, webhook ingest, and replay visibility.
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

- **Explore:** `docker compose up --build` runs the demo app and Postgres
  locally so you can inspect the Fake-backed `/app/billing` to `/billing` loop
  in a browser.
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

To **see** the mounted admin + host billing story (no live Stripe), use the
**`@phase15-trust`** Playwright spec. This lane is **trust/demo visuals only**; it
does not substitute for the VERIFY-01 merge-blocking checklist under
[Proof and verification](#proof-and-verification) above. It uses the same Fake-backed
fixture as the rest of the browser suite (scrubs prior `sub_fake_%` host rows so Fake
ids cannot collide): org billing on the host app, then mounted **admin** at `/billing`
(webhook detail, replay, audit).

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
