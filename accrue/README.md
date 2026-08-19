# Accrue

Billing state, modeled clearly.

Accrue is a Phoenix-era billing library: subscriptions, invoices, checkout, webhooks, and the rest of the Stripe-shaped surface as plain Elixir—not a pile of controllers you fork forever. You keep auth, routes, and product code; Accrue models money and lifecycle and ships a Fake processor so tests and CI stay offline.

If you ship a SaaS on Elixir and want documentation you can hand to a teammate, plus a straight path from “runs on my laptop” to “looks like how we run in prod,” you are in the right place.

## Start here

- [Architecture](guides/architecture.md) — the outside-in model of host ownership, processor authority, local projections, webhooks, entitlements, Admin, and Portal.
- [Code walkthrough](guides/code-walkthrough.md) — the same direct-subscribe and webhook route through representative current source.
- [Jobs to Be Done](guides/jobs_to_be_done.md) — a ~15-minute tour of what you can build, organized by the life of a paying customer; the best first read for understanding Accrue's surface.
- [Organization billing (non-Sigra)](guides/organization_billing.md) — session→billable org path when the Stripe Customer should follow an organization, not only the signed-in user.
- [Testing](guides/testing.md) — Fake-first verification posture for host billing flows.
- [First Hour](guides/first_hour.md) — one sitting from deps to a working billing slice.
- [Production readiness](guides/production-readiness.md) — ordered checklist before promoting billing to production or live Stripe (webhooks, tenancy, observability, CI vs live lanes).
- [Maturity and maintenance](guides/maturity-and-maintenance.md) — when Accrue is “done enough” for the `1.0.x` line, how friction enters planning, and how Hex publishes trigger contract passes.
- [Troubleshooting](guides/troubleshooting.md) — when something already wired misbehaves.
- [Webhooks](guides/webhooks.md) — signing, retries, and operational notes.
- [Entitlements](guides/entitlements.md) — gate features on what they paid for; the next read when you need to lock paid surfaces.
- [Quickstart](guides/quickstart.md) — smallest possible skim.
- [Demo app README](https://github.com/szTheory/accrue/blob/main/examples/accrue_host/README.md) — command parity with Accrue’s CI host gate.
- [Release notes](guides/release-notes.md) and [Upgrade](guides/upgrade.md) — what changed, in plain language, then the formal contract.
- [HexDocs](https://hexdocs.pm/accrue/) — every guide and API page together; use the Guides section as the full index.

## Install

> **Hex vs `main`:** The `{:accrue, "~> …"}` line below tracks `accrue/mix.exs` `@version` on the branch you are reading (typically `main` on GitHub). [Hex.pm](https://hex.pm/packages/accrue) publishes that train after release; use [HexDocs](https://hexdocs.pm/accrue/) for API docs matched to the Hex version you resolved.

If you also pull **`accrue_admin`**, match its `~>` to the same train, and rely on a **resolved `mix.lock`** in production while you are tracking a single `~>` line.

In `mix.exs`:

```elixir
defp deps do
  [
    {:accrue, "~> 1.5.0"}
  ]
end
```

Then:

```bash
mix deps.get
mix accrue.install
```

After install, pick up the walkthrough from **Start here** (First Hour) above—no need to duplicate those steps here.

Invoice PDFs are Rendro-first by default, so the normal path no longer
requires Chrome or ChromicPDF on the host. If you need the explicit
Chromic compatibility path or the `:invoice_pdf_adapter` / `:pdf_adapter`
split, see [PDF Rendering](guides/pdf.md).

Optional checks from the host app:

- `mix verify` — short “tutorial proof” suite
- `mix verify.full` — closer to what CI runs
- From the repo root: `bash scripts/ci/accrue_host_uat.sh` — full host integration gate

## What you get

- Billing domain: customers, subscriptions, invoices, charges, refunds, coupons, promotion codes, metered usage.
- Money paths: Checkout, billing portal, and Connect helpers stay behind one processor contract. `Accrue.Billing.create_checkout_session/2` and `Accrue.Billing.create_billing_portal_session/2` are first-party on both Stripe and Braintree, with provider-honest behavior: Stripe returns upstream hosted URLs; Braintree returns mounted first-party local checkout and portal URLs. `Accrue.Billing.swap_plan/3`, `Accrue.Billing.preview_upcoming_invoice/2`, `Accrue.Billing.update_quantity/3`, `Accrue.Billing.add_item/3`, `Accrue.Billing.remove_item/2`, and `Accrue.Billing.update_item_quantity/3` form the official active-subscription-change bundle. `preview_upcoming_invoice/2` is the canonical path where supported before commit. Stripe is native across that bundle, Fake is the testing/local-only proof lane, and Braintree stays explicitly bounded to swap-only when the host configures `:plan_resolver` for app-facing `price_id` translation. Braintree does not get first-party preview, quantity, or subscription-item support. Stripe remains the default first-user path in production (Fake in test), while Braintree is official only for the `gateway subscription core` slice. The required Braintree proof stays hermetic and Fake/mock-backed; any real-provider Braintree smoke is advisory only. For the full processor support matrix, see [First Hour](guides/first_hour.md) and [Maturity and maintenance](guides/maturity-and-maintenance.md).
- Operations: webhook ingest, async dispatch, replay, event history, telemetry.
- Product polish: transactional email, invoice PDFs, installer tasks.

The LiveView dashboard ships as the sibling Hex package `accrue_admin`; pin it to the same version family as `accrue` when you add the operator UI.

## Stability

Your supported integration surface—generated `MyApp.Billing`, `use Accrue.Webhook.Handler`, `use Accrue.Test`, `AccrueAdmin.Router`, `Accrue.Auth`, `Accrue.ConfigError`—is spelled out in [Upgrade](guides/upgrade.md). Accrue is done enough for the **`1.0.x`** line because the documented facade is the contract: breaking changes on the documented surface go through deprecation, not silent reshuffles, even within the `1.0.x` series. That is the public stability boundary for a **stable-core / demand-driven expansion** posture.

The canonical SaaS billing loop is complete for this scope. We only reopen broad expansion when evidence is concrete and adopter-facing: a **concrete adopter failure mode** that shows up as a **correctness/security/data-loss risk**, a **repeated support issue**, an **operational failure**, or an **explicit strategy change**. Internal schemas, workers, and demo helpers are not part of the facade contract. See [Maturity and maintenance](guides/maturity-and-maintenance.md) for doctrine, and use [Jobs to Be Done — Scope and maturity](guides/jobs_to_be_done.md#scope-and-maturity) for the scoped narrative.

Generated files are yours after install. Accrue only refreshes pristine stamped copies on installer reruns; it does not stomp files you have edited.

## Community

[Contributing](https://github.com/szTheory/accrue/blob/main/CONTRIBUTING.md) · [Code of Conduct](https://github.com/szTheory/accrue/blob/main/CODE_OF_CONDUCT.md) · [Security](https://github.com/szTheory/accrue/blob/main/SECURITY.md)

Keep Stripe credentials and webhook signing secrets in runtime configuration, not in the repo. Use Security for vulnerability reports.
