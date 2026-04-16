# Accrue

Billing state, modeled clearly.

Accrue is the billing library. Your Phoenix app owns the generated `MyApp.Billing`
facade, router mounts, runtime config, and auth/session boundary.

## Start Here

- [First Hour](guides/first_hour.md)
- [Troubleshooting](guides/troubleshooting.md)
- [Webhooks](guides/webhooks.md)
- [Upgrade](guides/upgrade.md)

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

Then follow the [First Hour guide](guides/first_hour.md) for the Phoenix-order
host setup path: runtime config, migrations, Oban, signed webhook ingest,
`accrue_admin "/billing"`, a first Fake-backed subscription, and focused host
tests.

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
- `Accrue.ConfigError` for setup failures

Breaking changes for that facade layer follow the deprecation cycle documented in `guides/upgrade.md`. Accrue deprecates public APIs before removal instead of silently changing behavior in place.

## Guides

- [Quickstart](guides/quickstart.md)
- [First Hour](guides/first_hour.md)
- [Troubleshooting](guides/troubleshooting.md)
- [Configuration](guides/configuration.md)
- [Testing](guides/testing.md)
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
