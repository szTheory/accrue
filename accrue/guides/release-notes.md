# Release notes (plain-language)

This page is the **story** of what shipped—not a commit list. For every line item and hash, see the package changelogs and GitHub releases:

- [`accrue/CHANGELOG.md`](https://github.com/szTheory/accrue/blob/main/accrue/CHANGELOG.md) — machine-precise history for the core library
- [`accrue_admin/CHANGELOG.md`](https://github.com/szTheory/accrue/blob/main/accrue_admin/CHANGELOG.md) — same for the admin UI package
- [`accrue_portal/CHANGELOG.md`](https://github.com/szTheory/accrue/blob/main/accrue_portal/CHANGELOG.md) — same for the customer portal package
- [GitHub releases](https://github.com/szTheory/accrue/releases) — tags and generated notes (more technical)

`accrue`, `accrue_admin`, and `accrue_portal` live in one repo and are usually bumped together so your host app never depends on mismatched versions.

---

## Stable-core posture

Accrue follows a **stable-core / demand-driven expansion** posture. Release notes are a change story, not the static support contract. For canonical posture and boundaries, use [`maturity-and-maintenance.md`](maturity-and-maintenance.md), [`first_hour.md`](first_hour.md), and [`jobs_to_be_done.md`](jobs_to_be_done.md#scope-and-maturity).

## v1.59 release contract

v1.59 documents an additive multi-rail and offline-study contract around the
existing billing surface. Legacy hosts remain compatible. Apple subscriptions
remain externally managed, and Accrue does not transfer, merge, migrate, refund,
cancel, or prorate lifecycle state across rails. A stale offline lease preserves
downloaded study and local progress only; expansion waits for reconnect.

The exact support and privacy facts live in the generated
[capability and limits matrix](https://github.com/szTheory/accrue/blob/main/examples/accrue_host/docs/capability-limits-matrix.md).
The first-adopter procedure, App Review boundary, threat review, and release
checklist live in the [v1.59 multi-rail and offline release guide](multi-rail-offline-release.md).
Deterministic account-projection conformance is merge-blocking. Crosswake mobile
runtime feasibility remains `feasibility_blocked` until its bridge and physical
device evidence exists; browser and advisory evidence do not promote that claim.

Release evidence and support records use bounded diagnostics and safe
correlations. They never include raw transaction data, signed proof material,
tokens, credentials, provider payloads, or PII.

## accrue

### 1.5.1

**Phoenix 1.8 compatibility and a smaller API-only entitlement setup.**

`1.5.1` resolves clean Phoenix 1.8 / Ecto 3.14 hosts on Decimal 3 while retaining `lattice_stripe 2.x`. Read-only entitlement consumers can boot without mail branding, plan `limits` now populate snapshot quantities, ambiguous installer runs still copy the required migrations, and provider-free host fixtures cover the common Stripe and Apple render states.

`accrue_admin` and `accrue_portal` move in lockstep for dependency compatibility only; the core `accrue` package owns the fixes.

### 1.5.0

**lattice_stripe 2.x plus observational Stripe-native entitlement sync.**

`1.5.0` is the next linked feature release. The core `accrue` package moves to `lattice_stripe ~> 2.0` and adds an optional, default-off Stripe-native entitlement refresh for diagnostics and admin read surfaces. The local plan-to-feature map remains the only Accrue grant gate, so Stripe-native advisory data never changes `entitled?/2`, plugs, or LiveView guards.

`accrue_admin` and `accrue_portal` ship compatibility-only updates in the same linked version family; they do not add package-owned workflows or authorization behavior for this slice.

### 1.4.0

**Phase 162 Linked Release Proof.**

`1.4.0` completes the linked release readiness and proof closure for v1.48, making the stable-core posture explicit and ensuring full artifact alignment across all packages.

### 1.3.0

**Dunning analytics, recovered-revenue dashboard, in-app dunning banners, ENT-10 webhook scoping fix, and dependency maintenance.**

`1.3.0` ships the v1.46 feature batch. The recovered-revenue analytics API is now complete: `recovered_vs_lost_mrr/1`, `recovery_rate/1`, `funnel/1`, `at_risk_subscriptions/1`, `campaign_timeline/2`, `campaign_timeline_grouped/2`, and `invoices_for_campaign/2` are all documented, spec-annotated, and tagged `(since 1.3.0)` in ExDoc. The `/billing/analytics/recovery` LiveView integrates these into an operator-facing recovery funnel dashboard. In-app dunning banners ship in the `accrue_admin` package via the `DunningBanner` component, so operators can surface recovery prompts directly in the admin UI. The ENT-10 webhook scoping bug is fixed: the webhook cache is now per-entity, not global, eliminating cross-entity contamination for multi-tenant setups. Dependency maintenance: `accrue`, `accrue_admin`, and `accrue_portal` are all current on their upstream package floors.

### 1.2.0

**Idempotency foundations, Phase 128-142 rollout, and cross-currency analytics.**

`1.2.0` introduces the full dunning campaign engine, robust idempotency controls, and recovered-revenue analytics that correctly support multi-currency MRR aggregations. Includes major additions to the admin UI and structural foundations for offline proof paths.

### 1.1.2

**Patch release for linked release-contract alignment and CI stability.**

`1.1.2` is a small follow-up to the `1.1.1` linked publish line. It keeps the same public billing surface, then tightens the release contract around it: package docs, release notes, and CI now agree on the same three-package `accrue` / `accrue_admin` / `accrue_portal` version family.

### 1.1.1

**Linked-release recovery and public release-truth cleanup.**

`1.1.1` keeps the active-subscription-change and three-package release story from `1.1.0`, then tightens the public release contract after the first linked publish attempt. The shipped line, package docs, and recovery workflow now describe the same `accrue` / `accrue_admin` / `accrue_portal` version family more clearly.

### 1.1.0

**Official subscription-change flows, clearer release truth, same-version three-package publishing.**

This release makes **active subscription changes** feel first-party instead of implied. `swap_plan/3` and `preview_upcoming_invoice/2` are now part of the explicit public story, with provider-honest boundaries across Stripe, Fake, and the bounded Braintree path.

The operator and self-serve surfaces moved with the same contract: admin and portal flows now describe the same preview-before-commit story as the core library. The release process was also tightened so `accrue`, `accrue_admin`, and `accrue_portal` publish together with one clearer public version line, changelog, and install story.

### 1.0.0

**Stable public baseline for the core billing surface.**

`1.0.0` is the point where Accrue stopped reading like a promising pre-1.0 library and started reading like a deliberate public contract. The core checkout, billing portal, webhook, invoice, admin, docs, and proof surfaces were locked into a stable release line with clearer upgrade and maintenance expectations.

### 0.2.0

**Stripe Tax–ready billing, calmer installs, stronger CI trust.**

You can turn on **automatic tax** for subscriptions and checkout in a first-class way, with billing state and observability columns to match. The **Fake** processor understands the same shapes, so tests stay deterministic.

Install and boot got **clearer diagnostics**: preflight checks, webhook route awareness, and migration inspection errors surface as ordinary setup hints instead of mystery crashes. Docs and the **checked-in host demo** stay aligned so “what CI proves” and “what you run locally” mean the same thing.

Under the hood: Connect, webhooks, telemetry, and config refinements; release gates and package-doc checks got stricter so regressions are caught before they reach Hex.

### 0.1.2

Patch release focused on **HexDocs** and README polish so published docs match what you see on GitHub.

### 0.1.1

Early **CI and release pipeline** stabilization so public automation and docs publishing behave predictably.

---

## accrue_admin

The admin package is the **LiveView dashboard** that mounts into your Phoenix router. It tracks `accrue` closely—install the same version family for both.

### 1.5.1

Matches **accrue 1.5.1** for linked dependency compatibility. The API-only entitlement and Decimal 3 fixes live in core; this package adds no operator workflow or authorization behavior.

### 1.5.0

Matches **accrue 1.5.0** for linked dependency compatibility. Stripe-native entitlement refresh remains observational and core-owned; this package adds no grant authority.

### 1.4.0

Matches **accrue 1.4.0**: Stays aligned with the linked release proof and stable-core positioning updates.

### 1.3.0

Matches **accrue 1.3.0**: Ships the `FunnelChart` LiveComponent, the recovery dashboard LiveView at `/admin/analytics/recovery`, and the `AccrueAdmin.Components.DunningBanner` component for embedding context-aware in-app dunning notices in operator and portal surfaces. Also includes the `@since 1.3.0` annotation cleanup — all dunning and funnel functions now render `(since 1.3.0)` badges correctly in ExDoc.

### 1.2.0

Matches **accrue 1.2.0**: Ships the full Recovered Revenue Analytics dashboard, campaign timelines, and drill-down views, along with global admin search and dunning campaign visibility.

### 1.1.2

Matches **accrue 1.1.2**: the admin package stays on the same linked three-package release line, with public release notes and CI checks updated so the published version story stays consistent across the core, admin, and portal packages.

### 1.1.1

Matches **accrue 1.1.1**: the admin package stays on the linked three-package release line and picks up the same release-truth and recovery-path cleanup as the core package.

### 1.1.0

Matches **accrue 1.1.0**: the admin UI now documents and exercises the same active-subscription-change story as the core library, while staying aligned with the linked three-package publish flow.

### 1.0.0

Matches **accrue 1.0.0**: the admin package shipped as part of the stable public baseline, with the mounted operator dashboard and docs treated as a first-class part of the release contract.

### 0.2.0

Matches **accrue 0.2.0**: same tax and billing surface assumptions, asset and docs drift fixes alongside the core release.

### 0.1.x

Initial public releases with the admin UI, asset pipeline, and docs wired for the same Stripe-backed flows as the core library.

---

## How we version

- **Patch** — safe fixes, docs, and internal quality.
- **Minor** — additive capabilities you can adopt incrementally; read the changelog before upgrading production.
- **Major** — breaking changes, shipped only after a deprecation cycle.

When in doubt, read **[Upgrade](upgrade.md)** and run your usual test and staging passes.
