# Accrue

Billing state, modeled clearly.

## Quickstart

Add Accrue to `deps/0`, point it at the Stripe processor, then run the installer:

```elixir
defp deps do
  [
    {:accrue, "~> 1.0.0"}
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

## What ships in v1.0.0

- Billing facades for customers, subscriptions, invoices, charges, refunds, coupons, promotion codes, and metered usage.
- Checkout, billing portal, and Connect helpers on top of the Stripe-backed processor contract.
- Webhook ingest, async dispatch, replay tooling, event-ledger history, and operational telemetry.
- Transactional email, invoice PDF rendering, installer tasks, and a Fake-first test surface.

## Public API stability

The supported v1.x surface is the public facade layer under `Accrue.Billing`, `Accrue.Checkout`, `Accrue.BillingPortal`, `Accrue.Connect`, `Accrue.Events`, and `Accrue.Test`.

Breaking changes for that facade layer follow the deprecation cycle documented in `guides/upgrade.md`. Accrue deprecates public APIs before removal instead of silently changing behavior in place.

## Guides

- [Quickstart](https://github.com/jon/accrue/blob/main/accrue/guides/quickstart.md)
- [Configuration](https://github.com/jon/accrue/blob/main/accrue/guides/configuration.md)
- [Testing](https://github.com/jon/accrue/blob/main/accrue/guides/testing.md)
- [Sigra integration](https://github.com/jon/accrue/blob/main/accrue/guides/sigra_integration.md)
- [Custom processors](https://github.com/jon/accrue/blob/main/accrue/guides/custom_processors.md)
- [Custom PDF adapter](https://github.com/jon/accrue/blob/main/accrue/guides/custom_pdf_adapter.md)
- [Branding](https://github.com/jon/accrue/blob/main/accrue/guides/branding.md)
- [Webhook gotchas](https://github.com/jon/accrue/blob/main/accrue/guides/webhook_gotchas.md)
- [Upgrade](https://github.com/jon/accrue/blob/main/accrue/guides/upgrade.md)

## Security

Use runtime-only secrets for Stripe credentials, keep webhook signing secrets out of source control, and review the repository `SECURITY.md` before production rollout or vulnerability reporting.

## Project policies

- [Contributing guide](../CONTRIBUTING.md)
- [Code of Conduct](../CODE_OF_CONDUCT.md)
- [Security policy](../SECURITY.md)
