# Accrue Host Example

This example is the Phase 10 host-app dogfood harness for `accrue` and `accrue_admin`.

## Prerequisite

PostgreSQL 14+ must already be running before you execute setup or boot commands. By default the app connects to `localhost:5432`. Override that with `PGHOST`, `PGUSER`, and `PGPASSWORD` if your local database uses different values.

## Rebuild From A Clean Checkout

From `examples/accrue_host`:

```bash
mix deps.get
mix accrue.install --yes --billable AccrueHost.Accounts.User --billing-context AccrueHost.Billing --admin-mount /billing --webhook-path /webhooks/stripe
mix ecto.create
mix ecto.migrate
mix test
mix phx.server
```

## Local Defaults

- The default local setup uses `Accrue.Processor.Fake`, so the host proof path does not require live Stripe network access.
- The default webhook signing secret is `whsec_test_host`.
- Override the signing secret with `STRIPE_WEBHOOK_SECRET` if you need a different local value.

## What The App Proves

- Host-owned Phoenix auth and session state gate the mounted admin UI at `/billing`.
- Signed webhook ingestion runs through the installed `/webhooks/stripe` route.
- Admin replay actions leave persisted audit evidence in `accrue_events`.
