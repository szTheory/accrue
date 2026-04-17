# Accrue Host Example

This example is the Phase 10 host-app dogfood harness for `accrue` and `accrue_admin`.

## Prerequisite

PostgreSQL 14+ must already be running before you execute setup or boot commands. By default the app connects to `localhost:5432`. Override that with `PGHOST`, `PGUSER`, and `PGPASSWORD` if your local database uses different values.

## First run

From the repository root:

```bash
cd examples/accrue_host
mix setup
mix phx.server
```

Then follow the public host path the example proves:

- Start one Fake-backed subscription through `AccrueHost.Billing` or the mounted billing UI.
- Post one signed `/webhooks/stripe` event.
- Inspect the resulting billing state and replay visibility at `/billing`.
- Run `mix verify` once you have walked through the story yourself.

The package docs mirror the same `First run` order:

- `../../accrue/guides/first_hour.md`
- `../../accrue/guides/troubleshooting.md`
- `../../accrue/guides/webhooks.md`
- `../../accrue_admin/guides/admin_ui.md`

## Seeded history

Use this only for deterministic replay/history evaluation and browser smoke, not as the first teaching path:

```bash
cd examples/accrue_host
mix setup
mix verify.full
```

`Seeded history` exists for evaluation states that are awkward to create during a short walkthrough, such as replay-ready webhook history for browser smoke.

## Verification modes

- `mix verify` is the focused tutorial proof suite.
- `mix verify.full` is the CI-equivalent local gate.
- `bash scripts/ci/accrue_host_uat.sh` is the thin repo-root wrapper around the same full contract.
- `bash scripts/ci/accrue_host_hex_smoke.sh` is Hex smoke, not part of `First run`.
- `mix accrue.install` remains the production setup step inside a real host app, not the demo shortcut.

For the maintainer-facing repo-root wrapper:

```bash
bash scripts/ci/accrue_host_uat.sh
```

## Local Defaults

- The default local setup uses `Accrue.Processor.Fake`, so the host proof path does not require live Stripe network access.
- The default webhook signing secret is `whsec_test_host`.
- Override the signing secret with `STRIPE_WEBHOOK_SECRET` if you need a different local value.

## What The App Proves

- Host-owned Phoenix auth and session state gate the mounted admin UI at `/billing`.
- Signed webhook ingestion runs through the installed `/webhooks/stripe` route.
- Admin replay actions leave persisted audit evidence in `accrue_events`.
