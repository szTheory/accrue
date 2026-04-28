# Adoption proof matrix (`examples/accrue_host`)

This matrix answers: **what is proven, where, and against what kind of “realism”?**

Accrue intentionally splits proof into a **deterministic Fake-first lane** (blocking PR CI) and a **Stripe test-mode provider parity lane** (advisory, scheduled / manual). There is no in-repo “digital twin” of Stripe; `lattice_stripe` talks to Stripe when configured, and `Accrue.Processor.Fake` simulates processor-shaped behavior for speed and CI stability.
This matrix is refreshed for the linked `1.0.0` pair: the same merge-blocking host/docs proof still attests the coordinated `accrue` + `accrue_admin` release surface after the first public major.

## Layering note (local proof vs merge-blocking CI)

**Layer B (local Fake-backed proof):** running `mix verify` or `mix verify.full` inside `examples/accrue_host` exercises the host proof aliases (bounded vs full stack).

**Layer C (merge-blocking `docs-contracts-shift-left` + `host-integration`):** job `docs-contracts-shift-left` runs `verify_package_docs.sh`, `verify_v1_17_friction_research_contract.sh`, `verify_verify01_readme_contract.sh`, `verify_adoption_proof_matrix.sh`, and `verify_core_admin_invoice_verify_ids.sh` from the repository root. Job `host-integration` runs `bash scripts/ci/accrue_host_uat.sh` (which delegates to `mix verify.full`) and may run `bash scripts/ci/accrue_host_hex_smoke.sh` on eligible workflow events. Local `mix verify.full` is the core host stack but **not** the entire merge contract unless you also run the same shift-left scripts from the repository root.

## Blocking: Fake-backed host + browser

| Concern | Proof | Where |
|--------|--------|--------|
| Billing **`Accrue.Billing.create_checkout_session/2`** facade + **`[:accrue, :billing, :checkout_session, :create]`** telemetry contract | `checkout_session_facade_test.exs` + First Hour / `guides/telemetry.md` | `accrue` package |
| Billing **`Accrue.Billing.create_billing_portal_session/2`** facade + **`[:accrue, :billing, :billing_portal, :create]`** telemetry contract | `billing_portal_session_facade_test.exs` + First Hour / `guides/telemetry.md` | `accrue` package |
| Installer + compile + bounded + full host ExUnit | `mix verify.full` (see `mix.exs` aliases) | `examples/accrue_host`, `scripts/ci/*.sh` |
| VERIFY-01 contract (README, seed, fixture schema, Playwright) | `docs-contracts-shift-left` + `host-integration` jobs; bash gates + Playwright | `.github/workflows/ci.yml`, `scripts/ci/` |
| Org-first billing LiveView (tax location, subscribe, cancel) | `subscription_flow_test.exs` | Bounded `mix verify` slice |
| User-as-billable **API** (B2C-shaped host facade) | `billing_facade_test.exs` (`Billing.subscribe(user, …)`, `owner_type == "User"`) | Bounded `mix verify` slice |
| Org access / denial, admin mount, webhooks | `org_billing_*`, `admin_*`, `webhook_ingest_test.exs` | Bounded + full suites |
| Mounted admin + trust / responsiveness + a11y (axe) | Playwright `@phase15-trust`, per-verify01 specs, `e2e/verify01-admin-a11y.spec.js` | `e2e/` |
| Visual screenshots (maintainers / evaluators) | `npm run e2e:visuals`, CI artifact `accrue-host-phase15-screenshots` | README VERIFY-01 + visuals section |

**Caveat:** `/app/billing` LiveView in this host is **organization-scoped** (active org, `subscribe_active_organization/3`). User-level billing is proven at the **generated `AccrueHost.Billing` facade + `Accrue.Billing`** layer in ExUnit — a realistic B2C SaaS would expose its own LiveViews or controllers on top of the same APIs.

## Organization billing proof (ORG-09)

**Non-Sigra** here means the contracts you prove for identity and billable resolution—`Accrue.Auth`, `Accrue.Billable`, and the host billing façade described in the organization billing guide—not a blanket claim that every host in the repo is Sigra-free. The **example `accrue_host`** may still use **Sigra** as a **demo** or **implementation detail** for some flows; read that as host wiring, not as ORG-09 redefining the merge-blocking mainline.

### Primary archetype (merge-blocking)

| Concern | Proof | Where |
|--------|--------|--------|
| **non-Sigra** mainline: **`phx.gen.auth`** + membership-gated **`Organization`** with **`use Accrue.Billable`** (ORG-05/ORG-06 alignment) | `scripts/ci/verify_adoption_proof_matrix.sh` (runs in **`docs-contracts-shift-left`**) | [`../../../../accrue/guides/organization_billing.md`](../../../../accrue/guides/organization_billing.md) |

### Recipe lanes (advisory by default)

| Concern | Proof | Where |
|--------|--------|--------|
| **Pow (ORG-07)** — identity via Pow; same membership-gated org + `use Accrue.Billable` pattern | Advisory checklist + bounded host tests; **not** merge-blocking unless a future phase adds a new gate | Same guide; **ORG-07** row stays **advisory** and does **not** add a parallel VERIFY-01 Playwright lane |
| **Custom organization (ORG-08)** — tenancy signals (subdomain, headers, jobs) collapse to membership-verified **`Organization`** | Advisory checklist + bounded host tests; **not** merge-blocking unless a future phase adds a new gate | Same guide; **ORG-08** row stays **advisory** and does **not** add a parallel VERIFY-01 Playwright lane |

## Advisory: Stripe test mode (network)

| Concern | Proof | Where |
|--------|--------|--------|
| 3DS / proration / Connect shapes vs real Stripe | `:live_stripe` modules, `mix test.live` | `accrue/test/live_stripe/`, `accrue/mix.exs` alias |
| CI schedule + manual dispatch | Job id `live-stripe` (display name references test-mode keys) | `.github/workflows/ci.yml`, `guides/testing-live-stripe.md` |

Requires repository secrets; failures do not block merge (`continue-on-error: true`).

### Trust and versioning (v1.15+)

- **Hex (`hex.pm`):** Published SemVer in each package’s `mix.exs` is the authoritative pin for dependency upgrades — not informal references to unreleased `main`.
- **Planning labels:** Milestone tags like **`v1.16`** under **`.planning/`** are planning artifacts only; they do not substitute for install pins or resolver output.
- **Demo / optional adapters:** **Sigra** (or similar) in this checked-in host is **host wiring**, not a global production requirement — stay aligned with **`non-Sigra`** ORG-09 framing elsewhere in this file.
- **Advisory Stripe:** Stripe test mode and scheduled **`live-stripe`**-class jobs remain **advisory** per **`## Advisory: Stripe test mode`** — not merge-blocking for contributors.
- **First-hour SSOT:** Longer install + verification ordering narrative lives in [`../../../../accrue/guides/first_hour.md`](../../../../accrue/guides/first_hour.md).
- **Host SSOT:** Example host setup and VERIFY-01 detail live in [`../README.md`](../README.md).

## Evaluator narrative

For a human-recorded walkthrough (screen capture), follow [`evaluator-walkthrough-script.md`](evaluator-walkthrough-script.md).
