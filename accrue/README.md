# Accrue

Billing state, modeled clearly.

Accrue is the billing library. Your Phoenix app owns the generated `MyApp.Billing`
facade, router mounts, runtime config, and auth/session boundary. Start with the
host-first [First Hour](guides/first_hour.md) guide, then keep the checked-in
[`examples/accrue_host`](https://github.com/szTheory/accrue/tree/main/examples/accrue_host) demo nearby for command parity
and the canonical local proof path.

## Start Here

- [First Hour](guides/first_hour.md)
- [Troubleshooting](guides/troubleshooting.md)
- [Webhooks](guides/webhooks.md)
- [Testing](guides/testing.md)
- [Finance handoff](guides/finance-handoff.md) (Stripe RR, Sigma, Data Pipeline)
- [Upgrade](guides/upgrade.md)
- [Canonical local demo](https://github.com/szTheory/accrue/blob/main/examples/accrue_host/README.md)

The compact adoption path is:

1. Install `accrue` in your Phoenix app.
2. Follow the [First Hour](guides/first_hour.md) guide for runtime config,
   migrations, Oban, `use Accrue.Webhook.Handler`, and
   `accrue_admin "/billing"`.
3. Compare that setup with the checked-in
   [`examples/accrue_host`](https://github.com/szTheory/accrue/tree/main/examples/accrue_host) demo path.

## Install

Add Accrue to `deps/0` and fetch dependencies:

```elixir
defp deps do
  [
    {:accrue, "~> 0.1.2"}
  ]
end
```

```bash
mix deps.get
mix accrue.install
```

Use the [First Hour](guides/first_hour.md) guide for the full tutorial story.
Keep the checked-in `examples/accrue_host` app nearby when you want the
canonical local demo path and command parity.

The canonical verification labels are:

- `mix verify` for the focused tutorial proof suite
- `mix verify.full` for the CI-equivalent local gate
- `bash scripts/ci/accrue_host_uat.sh` for the repo-root wrapper around that full gate

## What ships

- Billing facades for customers, subscriptions, invoices, charges, refunds, coupons, promotion codes, and metered usage.
- Checkout, billing portal, and Connect helpers on top of the Stripe-backed processor contract.
- Webhook ingest, async dispatch, replay tooling, event-ledger history, and operational telemetry.
- Transactional email, invoice PDF rendering, installer tasks, and a Fake-first test surface.

## Public API stability

The supported public setup surface for first-time integration is:

- your generated `MyApp.Billing`
- `use Accrue.Webhook.Handler`
- `use Accrue.Test`
- `AccrueAdmin.Router.accrue_admin/2`
- `Accrue.Auth`
- `Accrue.ConfigError` for setup failures

Breaking changes for that facade layer follow the deprecation cycle documented in `guides/upgrade.md`. Accrue deprecates public APIs before removal instead of silently changing behavior in place.

Generated files are host-owned after install. Accrue may refresh pristine
stamped files on installer reruns, but user-edited generated files are not
silently managed. Internal schemas, webhook/event structs, reducer modules,
worker internals, and demo-only helpers are not first-time integration APIs.

## Guides

- [Quickstart](guides/quickstart.md)
- [First Hour](guides/first_hour.md)
- [Troubleshooting](guides/troubleshooting.md)
- [Configuration](guides/configuration.md)
- [Testing](guides/testing.md)
- [Finance handoff](guides/finance-handoff.md)
- [Sigra integration](guides/sigra_integration.md)
- [Custom processors](guides/custom_processors.md)
- [Custom PDF adapter](guides/custom_pdf_adapter.md)
- [Branding](guides/branding.md)
- [Webhooks](guides/webhooks.md)
- [Upgrade](guides/upgrade.md)

## Security

Use runtime-only secrets for Stripe credentials, keep webhook signing secrets out of source control, and review the repository `SECURITY.md` before production rollout or vulnerability reporting.

## Project policies

- [Contributing guide](https://github.com/szTheory/accrue/blob/main/CONTRIBUTING.md)
- [Code of Conduct](https://github.com/szTheory/accrue/blob/main/CODE_OF_CONDUCT.md)
- [Security policy](https://github.com/szTheory/accrue/blob/main/SECURITY.md)
