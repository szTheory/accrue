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

For maintainers who want the repo-root wrapper after the tutorial story:

```bash
bash scripts/ci/accrue_host_uat.sh
```

## What this app proves

- Host-owned auth and session state gate the mounted admin UI at `/billing`.
- Signed webhook ingest runs through the installed `/webhooks/stripe` route.
- Replay actions and billing changes leave persisted audit history.
- Fake, test, and live Stripe remain distinct modes, but the canonical local
  path is Fake-backed and credential-free.
