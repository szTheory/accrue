# Configuration

## Required runtime keys

Keep processor secrets in `config/runtime.exs` so release artifacts never bake them in:

```elixir
config :accrue,
  stripe_secret_key: System.fetch_env!("STRIPE_SECRET_KEY"),
  webhook_signing_secret: System.fetch_env!("STRIPE_WEBHOOK_SIGNING_SECRET")
```

The runtime-only keys you must supply for the Stripe processor are `:stripe_secret_key` and `:webhook_signing_secret`.

## Optional adapters

Accrue keeps host integration points explicit. The most common optional adapters are:

- `:auth_adapter` for host-owned authentication and admin authorization.
- `:pdf_adapter` for invoice rendering, including custom PDF backends.
- `:mailer` for delivery behavior in development, test, or production.

These adapters can stay on Accrue defaults while you bootstrap, then move to host-owned modules as your app takes control of billing flows.

## Telemetry and OpenTelemetry

Accrue emits `:telemetry` events from the public surface by default. OpenTelemetry is optional: add the `:opentelemetry` dependency and your preferred reporters only when you want spans and trace export in the host app.

Keep telemetry handlers and OpenTelemetry setup in the host application, not inside Accrue package code.

## Deprecation policy

The supported v1.x API surface is the public facade layer documented in the package README. Public APIs are deprecated before removal rather than silently changed in place.

When a breaking change is necessary, Accrue marks the old API as deprecated first, documents the replacement path, and removes the deprecated surface in a later release according to the v1.x deprecation rule.
