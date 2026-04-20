# Accrue

**Billing state, modeled clearly.**

Accrue helps you ship **real subscription billing** in a **Phoenix** app without rebuilding the same Stripe-shaped domain for the tenth time. You keep ownership of auth, routes, and product code; Accrue gives you a clear billing layer—customers, subscriptions, invoices, coupons, checkout, webhooks, PDFs, email, and tests that run against a **Fake** Stripe stand-in so CI stays fast and boring.

---

## Who this is for

You are building (or already run) a **B2B or B2C SaaS** on Elixir/Phoenix and want:

- something that feels **maintained and intentional**, not a pile of copy-pasted controllers
- **HexDocs and guides** you can send a teammate without a sales call
- a path from **“hello world”** to **production-shaped** setup that does not hide the sharp edges (webhooks, secrets, Connect)

If that is you, you are in the right place.

---

## Where to go next (pick one)

| If you want to… | Start here |
|-----------------|------------|
| **Get running in one sitting** | [First Hour](guides/first_hour.md) |
| **Skim the smallest path** | [Quickstart](guides/quickstart.md) |
| **Understand what changed between versions** | [Release notes (plain language)](guides/release-notes.md) → then [Upgrade](guides/upgrade.md) |
| **Configure Stripe, PDFs, email, branding** | [Configuration](guides/configuration.md), [Webhooks](guides/webhooks.md), [Branding](guides/branding.md) |
| **Prove it locally the same way CI does** | Checked-in demo app [`examples/accrue_host`](https://github.com/szTheory/accrue/tree/main/examples/accrue_host) and its [README](https://github.com/szTheory/accrue/blob/main/examples/accrue_host/README.md) |
| **Read API and guide HTML** | [HexDocs: accrue](https://hexdocs.pm/accrue/) (generated from this README + `guides/`) |

The **guides** are the long-form source of truth. This README is the map.

---

## Install

In `mix.exs`:

```elixir
defp deps do
  [
    {:accrue, "~> 0.2.0"}
  ]
end
```

Then:

```bash
mix deps.get
mix accrue.install
```

Use **[First Hour](guides/first_hour.md)** for the full narrative (Oban, migrations, `use Accrue.Webhook.Handler`, mounting **`accrue_admin`**). The demo app above is useful when you want command-for-command parity with maintainers.

**Quick verification** (optional, from the host app):

- `mix verify` — shorter “tutorial proof” suite  
- `mix verify.full` — closer to what CI runs  
- From the **repo root**: `bash scripts/ci/accrue_host_uat.sh` — full host integration gate used in CI  

---

## What you get

- **Billing** — customers, subscriptions, invoices, charges, refunds, coupons, promotion codes, metered usage.  
- **Money paths** — Checkout, billing portal, Connect helpers; all behind a **processor contract** (Stripe in production, Fake in test).  
- **Operations** — Webhook ingest, async handling, replay, append-only style history, telemetry.  
- **Product polish** — Transactional email, invoice PDFs, installer tasks, and tests that do not need live Stripe.

**Admin UI** ships as the sibling Hex package **`accrue_admin`** (same version family as `accrue`). Install both when you want the LiveView dashboard.

---

## Public surface (stability)

The supported “first integration” surface is documented in **[Upgrade](guides/upgrade.md)** and includes your generated **`MyApp.Billing`**, **`use Accrue.Webhook.Handler`**, **`use Accrue.Test`**, **`AccrueAdmin.Router`**, **`Accrue.Auth`**, and **`Accrue.ConfigError`**. Breaking changes there go through deprecation, not silent reshuffles.

Everything else—internal schemas, workers, demo-only helpers—is subject to change. Generated files are **yours** after install; Accrue will not silently overwrite your edits.

---

## Guides (full list)

**Getting productive:** [Quickstart](guides/quickstart.md) · [First Hour](guides/first_hour.md) · [Troubleshooting](guides/troubleshooting.md) · [Testing](guides/testing.md) · [Upgrade](guides/upgrade.md) · [Release notes](guides/release-notes.md)

**Running in production:** [Configuration](guides/configuration.md) · [Webhooks](guides/webhooks.md) · [Webhook gotchas](guides/webhook_gotchas.md) · [Telemetry](guides/telemetry.md) · [Security (repo)](https://github.com/szTheory/accrue/blob/main/SECURITY.md)

**Stripe-shaped features:** [Connect](guides/connect.md) · [Checkout / portal checklist](guides/portal_configuration_checklist.md) · [Email](guides/email.md) · [PDF](guides/pdf.md) · [Branding](guides/branding.md)

**Auth and customization:** [Auth adapters](guides/auth_adapters.md) · [Sigra](guides/sigra_integration.md) · [Custom processors](guides/custom_processors.md) · [Custom PDF adapter](guides/custom_pdf_adapter.md)

**Finance / ops:** [Finance handoff](guides/finance-handoff.md)

---

## Community and policies

- [Contributing](https://github.com/szTheory/accrue/blob/main/CONTRIBUTING.md)  
- [Code of Conduct](https://github.com/szTheory/accrue/blob/main/CODE_OF_CONDUCT.md)  
- [Security](https://github.com/szTheory/accrue/blob/main/SECURITY.md)  

Use **runtime-only** secrets for Stripe; never commit webhook signing secrets. When you are ready to report a vulnerability, follow **SECURITY.md**.
