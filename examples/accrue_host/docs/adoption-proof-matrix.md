# Adoption proof matrix (`examples/accrue_host`)

This matrix answers: **what is proven, where, and against what kind of “realism”?**

Accrue intentionally splits proof into a **deterministic Fake-first lane** (blocking PR CI) and live provider parity lanes (advisory, scheduled / manual). There is no in-repo “digital twin” of Stripe or Braintree; `lattice_stripe` talks to Stripe when configured, `Accrue.Processor.Fake` simulates processor-shaped behavior for speed and CI stability. Stripe remains the default first-user path, and Braintree is official only for the `gateway subscription core` slice. The billing facade stays provider-honest: Stripe returns upstream hosted checkout and billing-portal URLs, while Braintree returns mounted local checkout and portal URLs. The official active-subscription-change contract is `swap_plan/3` plus `preview_upcoming_invoice/2`: preview is the canonical path where supported before commit, `swap_plan/3` is bounded first-party on Braintree when the host configures `:plan_resolver`, and `preview_upcoming_invoice/2` stays unsupported on Braintree. The misuse-prevention semantics here stay intentionally small: `update_customer/2` is bounded and provider-neutral, `cancel/2` is the shared immediate path, and `cancel_at_period_end/2` is not a first-party Braintree path. The Braintree proof lane in `examples/accrue_host` is advisory while Fake remains the merge-blocking SSOT.
This matrix is refreshed for the linked `1.0.0` pair: the same merge-blocking host/docs proof still attests the coordinated `accrue` + `accrue_admin` release surface after the first public major.

## Public guides handoff

This matrix is a proof mirror. Canonical support-boundary semantics and stable-core policy live in the public guides, especially [`../../../accrue/guides/first_hour.md`](../../../accrue/guides/first_hour.md), [`../../../accrue/guides/jobs_to_be_done.md#scope-and-maturity`](../../../accrue/guides/jobs_to_be_done.md#scope-and-maturity), and [`../../../accrue/guides/maturity-and-maintenance.md`](../../../accrue/guides/maturity-and-maintenance.md). Use this file for adoption-proof coverage and lane realism, not as the policy authority.

## v1.59 first-adopter path

For the additive multi-rail and offline contract, use one route from setup to
incident response:

1. Adopt this anonymized reference host and run `mix verify` from
   `examples/accrue_host`.
2. Run `cd accrue && mix accrue.entitlements.reference_scenarios --check` from
   the repository root for the deterministic semantic contract.
3. Consult the generated
   [`capability and limits matrix`](capability-limits-matrix.md) for exact
   support and privacy cells; do not copy those cells into host policy.
4. Follow the canonical
   [`multi-rail/offline release guide`](../../../accrue/guides/multi-rail-offline-release.md)
   for App Review, privacy/security limits, and release-checklist procedure.
   This host documentation intentionally has no duplicate release guide.
5. Record the failing stable scenario ID and follow the matching
   [v1.59 operator runbook](../../../accrue/guides/operator-runbooks.md#v159-multi-rail-and-offline-runbooks).

The deterministic lane proves Apple-to-web and Stripe-to-iOS account-projection
convergence. It is merge-blocking semantic evidence, not Crosswake mobile
runtime evidence. The tracer remains `feasibility_blocked` until its exact
bridge and physical-device evidence exists. Advisory provider parity and
browser rendering are useful complementary evidence, but neither promotes a
runtime-capability claim or replaces the semantic contract.

## Layering note (local proof vs merge-blocking CI)

**Layer B (local Fake-backed proof):** running `mix verify` or `mix verify.full` inside `examples/accrue_host` exercises the host proof aliases (bounded vs full stack).

**Layer C (merge-blocking `docs-contracts-shift-left` + `host-integration`):** job `docs-contracts-shift-left` is the CI home for the support-contract bundle. The exact bundle membership lives in `scripts/ci/README.md` and `.github/workflows/ci.yml`; the host-facing checks this matrix depends on are `verify_package_docs.sh`, `verify_v1_17_friction_research_contract.sh`, `verify_verify01_readme_contract.sh`, `verify_adoption_proof_matrix.sh`, and `verify_core_admin_invoice_verify_ids.sh`. Job `host-integration` runs `bash scripts/ci/accrue_host_uat.sh` (which delegates to `mix verify.full`) and may run `bash scripts/ci/accrue_host_hex_smoke.sh` on eligible workflow events. Local `mix verify.full` is the core host stack but **not** the entire merge contract unless you also run the same shift-left scripts from the repository root.

**Advisory Stripe-native entitlement sync proof:** the merge-blocking proof is
deterministic docs/isolation coverage, not a live Stripe run.
`verify_package_docs.sh` pins the public wording that local plan→feature mapping
is the grant authority and the Stripe cache is optional/default-off diagnostics.
`verify_entitlement_sync_isolation.sh` proves the advisory cache, client fetch
seam, and shared reconcile writer cannot enter resolver, plug, or LiveView guard
paths. Live Stripe parity remains advisory evidence only.

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
| Dunning campaign wiring — `accrue_dunning` queue + `Oban.Plugins.Cron` DunningSweeper in host config; Fake-backed failed-payment → campaign-step → recovery loop through the real webhook entry point | `dunning_wiring_test.exs` (host wiring smoke) + `dunning_full_journey_test.exs` (accrue package full journey) | `examples/accrue_host/test/accrue_host/dunning_wiring_test.exs` + `accrue/test/accrue/dunning/dunning_full_journey_test.exs` |
| Recovery wiring (PROOF-06) — base `config/config.exs` proof validates `Oban` config, requires queues `accrue_webhooks`, `accrue_mailers`, `accrue_dunning`, `accrue_meters`, `accrue_scheduled`, and requires `Oban.Plugins.Cron` workers `DunningSweeper`, `DetectExpiringCards`, `MeterEventsReconciler`, `MeteredRenewalReconciler`; see canonical append-merge teaching in `config/config.exs` (`append-merge` comment) | `recovery_wiring_test.exs` (host wiring smoke) | `examples/accrue_host/test/accrue_host/recovery_wiring_test.exs` |
| Apple V2 ingress — dedicated `/webhooks/apple` boundary, durable intake/quarantine, backpressure classes, duplicate/concurrent convergence, and recovery wakeup | Fake-backed `apple_notification_ingest_test.exs`, `apple_rate_policy_test.exs`, `recovery_wiring_test.exs`, and source contract in `mix verify` | Merge-blocking bounded host proof |
| Entitlement gating (`Accrue.Live.Entitlements`) | Gated `/app/reports/advanced` with `{:require_feature, :advanced_reports}` ; `entitlements_guard_test.exs` | `examples/accrue_host` router + `Accrue.Config.entitlements()` configuration |
| Stripe-native advisory entitlement sync boundary | `verify_package_docs.sh` pins default-off/advisory/local-grant wording; `verify_entitlement_sync_isolation.sh` blocks gate-path references to the advisory cache/client-fetch/reconcile seam | `scripts/ci/verify_package_docs.sh`, `scripts/ci/verify_entitlement_sync_isolation.sh`, `accrue/guides/entitlements.md`, `.planning/processor-support-matrix.md` |
| Recovered Revenue Dashboard | Deterministic seeds and UI rendering proof (`recovery_analytics_test.exs`) | [`priv/repo/seeds.exs`](../priv/repo/seeds.exs), `/admin/analytics/recovery`, `test-results/recovery-dashboard.png` |
| In-app dunning banner (BAN-04) — shows for a past-due org and is absent for a healthy org, side-by-side via seeded `healthy@example.com` vs `past-due@example.com` | `dunning_banner_live_test.exs` (banner-on + banner-off) + `AccrueAdmin.Components.DunningBanner` mounted zero-config at the top of `Layouts.app` | [`test/accrue_host_web/live/dunning_banner_live_test.exs`](../test/accrue_host_web/live/dunning_banner_live_test.exs) + [`priv/repo/seeds.exs`](../priv/repo/seeds.exs) |

**Caveat:** `/app/billing` LiveView in this host is **organization-scoped** (active org, `subscribe_active_organization/3`). User-level billing is proven at the **generated `AccrueHost.Billing` facade + `Accrue.Billing`** layer in ExUnit — a realistic B2C SaaS would expose its own LiveViews or controllers on top of the same APIs.

## Organization billing proof (ORG-09)

**Non-Sigra** here means the contracts you prove for identity and billable resolution—`Accrue.Auth`, `Accrue.Billable`, and the host billing façade described in the organization billing guide—not a blanket claim that every host in the repo is Sigra-free. The **example `accrue_host`** may still use **Sigra** as a **demo** or **implementation detail** for some flows; read that as host wiring, not as ORG-09 redefining the merge-blocking mainline.

### Primary archetype (merge-blocking)

| Concern | Proof | Where |
|--------|--------|--------|
| **non-Sigra** mainline: **`phx.gen.auth`** + membership-gated **`Organization`** with **`use Accrue.Billable`** (ORG-05/ORG-06 alignment) | `scripts/ci/verify_adoption_proof_matrix.sh` (runs in **`docs-contracts-shift-left`**) | [`../../../accrue/guides/organization_billing.md`](../../../accrue/guides/organization_billing.md) |

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

## Advisory: Apple deployment delivery

App Store Request a Test Notification and notification-status evidence are advisory
deployment checks. They can confirm a deployed endpoint is reachable, but do not
replace the Fake-backed router proof or `mix verify` as merge authority. They also
do not establish Crosswake bridge/device evidence or external Alpha integration
evidence; those remain separately owned non-claims.

### Trust and versioning (v1.15+)

- **Hex (`hex.pm`):** Published SemVer in each package’s `mix.exs` is the authoritative pin for dependency upgrades — not informal references to unreleased `main`.
- **Planning labels:** Milestone tags like **`v1.16`** under **`.planning/`** are planning artifacts only; they do not substitute for install pins or resolver output.
- **Demo / optional adapters:** **Sigra** (or similar) in this checked-in host is **host wiring**, not a global production requirement — stay aligned with **`non-Sigra`** ORG-09 framing elsewhere in this file.
- **Advisory Stripe:** Stripe test mode and scheduled **`live-stripe`**-class jobs remain **advisory** per **`## Advisory: Stripe test mode`** — not merge-blocking for contributors.
- **First-hour SSOT:** Longer install + verification ordering narrative lives in [`../../../accrue/guides/first_hour.md`](../../../accrue/guides/first_hour.md).
- **Host SSOT:** Example host setup and VERIFY-01 detail live in [`../README.md`](../README.md).

## Evaluator narrative

For a human-recorded walkthrough (screen capture), follow [`evaluator-walkthrough-script.md`](evaluator-walkthrough-script.md).
