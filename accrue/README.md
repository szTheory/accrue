# Accrue

Billing state, modeled clearly.

Accrue is a Phoenix-era billing library: subscriptions, invoices, checkout, webhooks, and the rest of the Stripe-shaped surface as plain Elixir—not a pile of controllers you fork forever. You keep auth, routes, and product code; Accrue models money and lifecycle and ships a Fake processor so tests and CI stay offline.

If you ship a SaaS on Elixir and want documentation you can hand to a teammate, plus a straight path from “runs on my laptop” to “looks like how we run in prod,” you are in the right place.

## Start here

- [Organization billing (non-Sigra)](guides/organization_billing.md) — session→billable org path when the Stripe Customer should follow an organization, not only the signed-in user.
- [Testing](guides/testing.md) — Fake-first verification posture for host billing flows.
- [First Hour](guides/first_hour.md) — one sitting from deps to a working billing slice.
- [Production readiness](guides/production-readiness.md) — ordered checklist before promoting billing to production or live Stripe (webhooks, tenancy, observability, CI vs live lanes).
- [Maturity and maintenance](guides/maturity-and-maintenance.md) — when Accrue is “done enough” for the pre-1.0 line, how friction enters planning, and how Hex publishes trigger contract passes.
- [Troubleshooting](guides/troubleshooting.md) — when something already wired misbehaves.
- [Webhooks](guides/webhooks.md) — signing, retries, and operational notes.
- [Quickstart](guides/quickstart.md) — smallest possible skim.
- [Demo app README](https://github.com/szTheory/accrue/blob/main/examples/accrue_host/README.md) — command parity with Accrue’s CI host gate.
- [Release notes](guides/release-notes.md) and [Upgrade](guides/upgrade.md) — what changed, in plain language, then the formal contract.
- [HexDocs](https://hexdocs.pm/accrue/) — every guide and API page together; use the Guides section as the full index.

## Install

> **Hex vs `main`:** The `{:accrue, "~> …"}` line below tracks `accrue/mix.exs` `@version` on the branch you are reading (typically `main` on GitHub). [Hex.pm](https://hex.pm/packages/accrue) publishes that train after release; use [HexDocs](https://hexdocs.pm/accrue/) for API docs matched to the Hex version you resolved.

If you also pull **`accrue_admin`**, match its `~>` to the same train, and rely on a **resolved `mix.lock`** in production while Accrue is pre-1.0.

In `mix.exs`:

```elixir
defp deps do
  [
    {:accrue, "~> 1.0.0"}
  ]
end
```

Then:

```bash
mix deps.get
mix accrue.install
```

After install, pick up the walkthrough from **Start here** (First Hour) above—no need to duplicate those steps here.

Optional checks from the host app:

- `mix verify` — short “tutorial proof” suite
- `mix verify.full` — closer to what CI runs
- From the repo root: `bash scripts/ci/accrue_host_uat.sh` — full host integration gate

## What you get

- Billing domain: customers, subscriptions, invoices, charges, refunds, coupons, promotion codes, metered usage.
- Money paths: Checkout, billing portal, Connect helpers behind one processor contract (Stripe in production, Fake in test).
- Operations: webhook ingest, async dispatch, replay, event history, telemetry.
- Product polish: transactional email, invoice PDFs, installer tasks.

The LiveView dashboard ships as the sibling Hex package `accrue_admin`; pin it to the same version family as `accrue` when you add the operator UI.

## Stability

Your supported integration surface—generated `MyApp.Billing`, `use Accrue.Webhook.Handler`, `use Accrue.Test`, `AccrueAdmin.Router`, `Accrue.Auth`, `Accrue.ConfigError`—is spelled out in [Upgrade](guides/upgrade.md). Breaking changes on that surface go through **deprecation**, not silent reshuffles, including while public SemVer is still **`0.x`**. Internal schemas, workers, and demo helpers are not that contract. **`0.x`** may still ship additive work and proof tightening, but it does **not** promise an ever-growing feature roadmap—see [Maturity and maintenance](guides/maturity-and-maintenance.md). When you are ready to coordinate a **`1.0.0`** pair on Hex, maintainers follow repository root **`RELEASING.md`** (*Appendix: Same-day `1.0.0` bootstrap*).

Generated files are yours after install. Accrue only refreshes pristine stamped copies on installer reruns; it does not stomp files you have edited.

## Community

[Contributing](https://github.com/szTheory/accrue/blob/main/CONTRIBUTING.md) · [Code of Conduct](https://github.com/szTheory/accrue/blob/main/CODE_OF_CONDUCT.md) · [Security](https://github.com/szTheory/accrue/blob/main/SECURITY.md)

Keep Stripe credentials and webhook signing secrets in runtime configuration, not in the repo. Use Security for vulnerability reports.
