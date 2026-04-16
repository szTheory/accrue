# Accrue

Billing state, modeled clearly.

## Quickstart

Add Accrue to `deps/0`, configure the Stripe processor, then run the installer:

```elixir
defp deps do
  [
    {:accrue, "~> 0.1.2"}
  ]
end
```

```elixir
config :accrue, :processor, Accrue.Processor.Stripe
```

```bash
mix deps.get
mix accrue.install
```

From there, configure your runtime Stripe secrets, mount the generated routes, and call your host billing facade for checkout, subscriptions, invoices, and customer self-service.

## What ships

- Billing facades for customers, subscriptions, invoices, charges, refunds, coupons, promotion codes, and metered usage.
- Checkout, billing portal, and Connect helpers on top of the Stripe-backed processor contract.
- Webhook ingest, async dispatch, replay tooling, event-ledger history, and operational telemetry.
- Transactional email, invoice PDF rendering, installer tasks, and a Fake-first test surface.

## Public API stability

The supported public surface is the facade layer under `Accrue.Billing`, `Accrue.Checkout`, `Accrue.BillingPortal`, `Accrue.Connect`, `Accrue.Events`, and `Accrue.Test`.

Breaking changes for that facade layer follow the deprecation cycle documented in `guides/upgrade.md`. Accrue deprecates public APIs before removal instead of silently changing behavior in place.

## Guides

- [Quickstart](guides/quickstart.md)
- [Configuration](guides/configuration.md)
- [Testing](guides/testing.md)
- [Sigra integration](guides/sigra_integration.md)
- [Custom processors](guides/custom_processors.md)
- [Custom PDF adapter](guides/custom_pdf_adapter.md)
- [Branding](guides/branding.md)
- [Webhook gotchas](guides/webhook_gotchas.md)
- [Upgrade](guides/upgrade.md)

## Security

Use runtime-only secrets for Stripe credentials, keep webhook signing secrets out of source control, and review the repository `SECURITY.md` before production rollout or vulnerability reporting.

## Project policies

- [Contributing guide](https://github.com/szTheory/accrue/blob/main/CONTRIBUTING.md)
- [Code of Conduct](https://github.com/szTheory/accrue/blob/main/CODE_OF_CONDUCT.md)
- [Security policy](https://github.com/szTheory/accrue/blob/main/SECURITY.md)
