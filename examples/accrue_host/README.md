# Accrue Host Example

This checked-in Phoenix app is the canonical local evaluation path for `accrue`
and `accrue_admin`. The primary story stays Fake-backed: start one
subscription, post one signed webhook through the real endpoint, inspect the
result in the mounted admin UI, then run the focused proof command.

## Prerequisites

- PostgreSQL 14+ must already be running.
- By default the app connects to `localhost:5432`.
- Override `PGHOST`, `PGPORT`, `PGUSER`, or `PGPASSWORD` if your local database
  uses different values.

The default local setup uses `Accrue.Processor.Fake` and the local webhook
signing secret `whsec_test_host`. You can exercise the full path without live
Stripe credentials.

**Sigra:** the example host depends on Sigra (not on Hex yet). `mix deps.get`
pulls it from [szTheory/sigra](https://github.com/szTheory/sigra) by default so
CI and fresh clones work. To compile against a sibling checkout instead, set
`ACCRUE_SIGRA_PATH=../../../sigra` (relative to this directory) before
`mix deps.get`.

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

## Verification modes

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

## VERIFY-01 (Phase 21)

Canonical local gate for org-scoped host billing proofs and Playwright VERIFY-01
specs. Paths are **Fake-backed** by default; no live Stripe keys are required.
Treat live Stripe as optional and advisory only — do not put `sk_live` in `.env`
for this checklist.

On every pull request, the GitHub Actions job `host-integration` runs the same
contract as `cd examples/accrue_host && mix verify.full` (see
`.github/workflows/ci.yml`).

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

3. Playwright (after `npm ci` in `examples/accrue_host` if dependencies are not
   installed yet):

   ```bash
   cd examples/accrue_host
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

To **see** the mounted admin + host billing story as full-page screenshots (no live
Stripe), use the release-blocking **`@phase15-trust`** Playwright spec. It seeds the
same Fake fixture as the rest of the browser suite (scrubs prior `sub_fake_%` host rows
so Fake ids cannot collide), saves a tax location, then writes PNGs under:

`examples/accrue_host/test-results/phase15-trust/<project>/`  
(for example `chromium-desktop/` and `chromium-mobile/`).

The repo ships a real **`accrue_admin` `priv/static` bundle** (Phoenix + LiveView client). If you change admin JavaScript or CSS sources, rebuild with `cd accrue_admin && mix accrue_admin.assets.build` and commit the updated `priv/static` files.

**One command (after `npm ci` and `npm run e2e:install`):**

```bash
cd examples/accrue_host
npm run e2e:visuals
```

**Playwright video (local, larger artifacts):** records a `.webm` per test under `test-results/` (still gitignored). Use when you want motion for a demo clip instead of still PNGs only:

```bash
cd examples/accrue_host
npm run e2e:visuals:video
```

(`ACCRUE_HOST_PLAYWRIGHT_VIDEO=1` is set by that script; CI does not enable it.)

Equivalent manual invocation:

```bash
cd examples/accrue_host
npx playwright test e2e/phase13-canonical-demo.spec.js --grep @phase15-trust
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

**Video:** not enabled in CI (size/noise). For a scripted evaluator capture path,
see [`docs/evaluator-walkthrough-script.md`](docs/evaluator-walkthrough-script.md).
For ad-hoc debug recordings, use Playwright’s `video` option in a headed session only.

## What this app proves

- Host-owned auth and session state gate the mounted admin UI at `/billing`.
- Signed webhook ingest runs through the installed `/webhooks/stripe` route.
- Replay actions and billing changes leave persisted audit history.
- Fake, test, and live Stripe remain distinct modes, but the canonical local
  path is Fake-backed and credential-free.
