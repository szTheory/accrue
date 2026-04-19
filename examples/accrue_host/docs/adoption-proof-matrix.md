# Adoption proof matrix (`examples/accrue_host`)

This matrix answers: **what is proven, where, and against what kind of “realism”?**

Accrue intentionally splits proof into a **deterministic Fake-first lane** (blocking PR CI) and a **Stripe test-mode provider parity lane** (advisory, scheduled / manual). There is no in-repo “digital twin” of Stripe; `lattice_stripe` talks to Stripe when configured, and `Accrue.Processor.Fake` simulates processor-shaped behavior for speed and CI stability.

## Blocking: Fake-backed host + browser

| Concern | Proof | Where |
|--------|--------|--------|
| Installer + compile + bounded + full host ExUnit | `mix verify.full` (see `mix.exs` aliases) | `examples/accrue_host`, `scripts/ci/*.sh` |
| VERIFY-01 contract (README, seed, fixture schema, Playwright) | `host-integration` job + `verify_verify01_readme_contract.sh` | `.github/workflows/ci.yml`, `scripts/ci/` |
| Org-first billing LiveView (tax location, subscribe, cancel) | `subscription_flow_test.exs` | Bounded `mix verify` slice |
| User-as-billable **API** (B2C-shaped host facade) | `billing_facade_test.exs` (`Billing.subscribe(user, …)`, `owner_type == "User"`) | Bounded `mix verify` slice |
| Org access / denial, admin mount, webhooks | `org_billing_*`, `admin_*`, `webhook_ingest_test.exs` | Bounded + full suites |
| Mounted admin + trust / responsiveness | Playwright `@phase15-trust` + per-verify01 specs | `e2e/` |
| Visual screenshots (maintainers / evaluators) | `npm run e2e:visuals`, CI artifact `accrue-host-phase15-screenshots` | README VERIFY-01 + visuals section |

**Caveat:** `/app/billing` LiveView in this host is **organization-scoped** (active org, `subscribe_active_organization/3`). User-level billing is proven at the **generated `AccrueHost.Billing` facade + `Accrue.Billing`** layer in ExUnit — a realistic B2C SaaS would expose its own LiveViews or controllers on top of the same APIs.

## Advisory: Stripe test mode (network)

| Concern | Proof | Where |
|--------|--------|--------|
| 3DS / proration / Connect shapes vs real Stripe | `:live_stripe` modules, `mix test.live` | `accrue/test/live_stripe/`, `accrue/mix.exs` alias |
| CI schedule + manual dispatch | Job id `live-stripe` (display name references test-mode keys) | `.github/workflows/ci.yml`, `guides/testing-live-stripe.md` |

Requires repository secrets; failures do not block merge (`continue-on-error: true`).

## Evaluator narrative

For a human-recorded walkthrough (screen capture), follow [`evaluator-walkthrough-script.md`](evaluator-walkthrough-script.md).
