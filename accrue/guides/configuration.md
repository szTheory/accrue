# Configuration

For a **pre-production checklist** that includes these keys plus webhooks, tenancy, and observability, see [Production readiness](production-readiness.md).

## Required runtime keys

Keep processor secrets in `config/runtime.exs` so release artifacts never bake them in:

```elixir
config :accrue,
  stripe_secret_key: System.fetch_env!("STRIPE_SECRET_KEY"),
  webhook_signing_secret: System.fetch_env!("STRIPE_WEBHOOK_SIGNING_SECRET")
```

The runtime-only keys you must supply for the Stripe processor are `:stripe_secret_key` and `:webhook_signing_secret`.

## Billing schema

By default, `mix accrue.install` configures Accrue-owned billing tables under a
Postgres schema named `billing` instead of placing them in `public`.

Keep this setting in `config/config.exs`, not `config/runtime.exs`: Ecto schema
prefixes are compile-time configuration.

```elixir
config :accrue, :billing_schema, "billing"
```

Set `"public"` explicitly only when you intentionally want Accrue tables in the
default schema:

```elixir
config :accrue, :billing_schema, "public"
```

Accrue migrations create the configured schema when needed and schema-qualify
Accrue-owned tables, indexes, foreign keys, and raw SQL helpers. Host-owned
tables such as users, organizations, Oban jobs, and your app tables remain under
your app's normal migration conventions.

## Optional adapters

Accrue keeps host integration points explicit. The most common optional adapters are:

- `:auth_adapter` for host-owned authentication and admin authorization.
- `:invoice_pdf_adapter` for invoice rendering through `Accrue.InvoiceRenderer`.
- `:pdf_adapter` for the lower-level HTML-to-PDF seam used by ChromicPDF and custom HTML renderers.
- `:mailer` for delivery behavior in development, test, or production.

For invoice rendering specifically, `:invoice_pdf_adapter` is the only switch.
Keep `:pdf_adapter` for advanced HTML-seam configuration only.

```elixir
config :accrue, :invoice_pdf_adapter, Accrue.InvoiceRenderer.Rendro
```

That is the default invoice renderer. Keep `:pdf_adapter` only when you need
to control the lower-level `Accrue.PDF` seam; see [PDF Rendering](pdf.md) for
the explicit Chromic compatibility path and migration posture.

These adapters can stay on Accrue defaults while you bootstrap, then move to host-owned modules as your app takes control of billing flows.

## Telemetry and OpenTelemetry

Accrue emits `:telemetry` events from the public surface by default. OpenTelemetry is optional: add the `:opentelemetry` dependency and your preferred reporters only when you want spans and trace export in the host app.

Keep telemetry handlers and OpenTelemetry setup in the host application, not inside Accrue package code.

## Deprecation policy

The supported v1.x API surface is the public facade layer documented in the package README. Public APIs are deprecated before removal rather than silently changed in place.

When a breaking change is necessary, Accrue marks the old API as deprecated first, documents the replacement path, and removes the deprecated surface in a later release according to the v1.x deprecation rule.
