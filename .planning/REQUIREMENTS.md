# Requirements: Accrue — Milestone v1.39

**Defined:** 2026-05-22
**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain through v1.x.

## v1.39 — Entitlements / Plan-Gating

**Goal:** Close the last open step of the canonical SaaS loop — let a Phoenix dev *gate features and access on what a customer has paid for*, first-party, with the same provider-honest + telemetry + admin + docs rigor as the rest of Accrue. Entitlements is a thin derivation layer over subscription state Accrue already holds locally; it adds no new external dependency for the core, and ships **local-first across all providers** (Stripe native Entitlements API is not yet wrapped by `lattice_stripe`, and Stripe itself recommends persisting locally for fast auth checks).

**Source:** `research/JTBD-FRONTIER.md` ranks entitlements the **#1** remaining JTBD and the only gap inconsistent with Accrue's "more-complete-than-Pay/Cashier" positioning. Backed by **SEED-002 #4**. Research: `research/SUMMARY.md` (+ `STACK/FEATURES/ARCHITECTURE/PITFALLS.md`).

## v1 Requirements

Requirements for this milestone. Each maps to exactly one roadmap phase.

### Entitlement Model & Core Gate API

- [x] **ENT-01**: A host can declare a plan/price → feature (and optional seat/quota) mapping via `NimbleOptions`-validated config, as the canonical entitlement source across all providers.
- [x] **ENT-02**: A developer can call `Accrue.has_active_plan?(billable, plan)` and get a boolean derived from local subscription state, reusing the existing `Subscription.active?/1` lifecycle truth (never raw `.status`).
- [x] **ENT-03**: A developer can call `Accrue.entitled?(billable, feature)` and `features_for(billable)` with a **fail-closed** contract — the only path to `true` is an affirmative resolved match; errors, `nil`, unmapped plans, and exceptions all resolve to `false` (property-tested).
- [x] **ENT-04**: A developer can read a billable's entitled seat/quantity for a feature (`entitlement_quantity/2`), derived read-only from local subscription quantity. (Atomic seat enforcement stays host-owned and documented, not a core API.)
- [x] **ENT-05**: Entitlement checks emit `[:accrue, :entitlements, :check]` telemetry/OTel spans; deliberate grant/revoke/sync state changes are recorded in the immutable event ledger, while per-check decisions are **not** ledgered.

### Enforcement Surfaces

- [x] **ENT-06**: A developer can gate a Phoenix controller route with a Plug guard (`require_plan` / `require_feature`) that halts with a configurable fail response (redirect / 403) when not entitled.
- [x] **ENT-07**: A developer can gate a host LiveView with an `on_mount` guard, shipped via conditional compilation so core `accrue` stays runtime-LiveView-free; the billable-resolution key (e.g. `current_scope` / `current_user`) is host-configurable and adapter-thin (no required Sigra/Lockspire coupling).

### Provider Honesty & Lifecycle Truth

- [x] **ENT-08**: Entitlement resolution is provider-honest via a Resolver behaviour + capability-matrix rows — local plan→feature mapping behaves identically across Stripe, Braintree, and Fake, with a merge-blocking drift gate (mirroring the SCM-06 / PROC-24 support-contract pattern).
- [x] **ENT-09**: Entitlement truth maps explicitly to existing lifecycle states (trialing ✅, canceling/paid-through ✅, paused ✗, canceled ✗), with past-due grace as a fail-safe configurable knob reusing the dunning grace overlay, documented as an SSOT truth table.

### Optional Stripe-Native Sync (isolated final phase)

- [ ] **ENT-10**: When explicitly enabled (off by default), Accrue consumes Stripe's `entitlements.active_entitlement_summary.updated` webhook into a local cache used as an advisory overlay with monotonic ordering; local mapping remains the canonical default. Live Stripe entitlement API reads are deferred (depends on `lattice_stripe ≥ 1.2`).

### Admin & Docs

- [x] **ENT-11**: An operator can view a customer's currently-active entitlements/features in `accrue_admin` (read-only).
- [x] **ENT-12**: `guides/entitlements.md` documents the full story (gate API, Plug guard, LiveView guard, provider matrix, lifecycle truth table); the JTBD docs flip entitlements ⛔→✅ and the First Hour + README "Start here" spine reference it; package-doc verifiers stay green.

## Future Requirements

Deferred. Tracked but not in this milestone's roadmap.

- **Typed upstream Stripe Entitlements resources** — first-class `Feature`/`ProductFeature`/`ActiveEntitlement` modules + live API reads via `lattice_stripe ≥ 1.2` (candidate upstream contribution / SEED). v1.39 uses the generic webhook + raw-API escape hatch instead.
- **Dunning depth / notification journeys** (JTBD #2) — multi-step recovery via Chimeway + Mailglass (SEED-002 #1). Own milestone.
- **Admin search** across billing records (SEED-002 #5 / Scrypath) — intake-gated.

## Out of Scope

Explicitly excluded for v1.39. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Rich metered/tiered/range entitlement math (Chargebee Range/Custom types) | Boolean features + read-only seat count is the value; richer quota math is a different product surface. Revisit only on sourced demand. |
| Atomic seat enforcement / membership management | Accrue never owns the membership/user schema; the host owns atomic increment. Documented as a recipe, not a core API. |
| Feature-catalog / feature-flag management UI | Accrue is a billing library, not a feature-flag product. |
| Deep Sigra / Lockspire coupling | Entitlement guards stay adapter-thin over host identity; identity stays optional and host-owned. |
| Dunning notification journeys | Next-milestone candidate (JTBD #2); needs an external orchestration lib — heavier than entitlements. |
| FIN-03 finance exports · MRR/ARR analytics product · MoR processors · Hyperwallet | Standing non-goals with written boundaries. |

## Traceability

Which phases cover which requirements. Phases continue from v1.38 (ended at Phase 122) → v1.39 starts at Phase 123.

| Requirement | Phase | Status |
|-------------|-------|--------|
| ENT-01 | Phase 123 | Complete |
| ENT-02 | Phase 123 | Complete |
| ENT-03 | Phase 123 | Complete |
| ENT-04 | Phase 123 | Complete |
| ENT-05 | Phase 123 | Complete |
| ENT-06 | Phase 124 | Complete |
| ENT-07 | Phase 124 | Complete |
| ENT-08 | Phase 125 | Complete |
| ENT-09 | Phase 125 | Complete |
| ENT-10 | Phase 127 | Pending |
| ENT-11 | Phase 126 | Complete |
| ENT-12 | Phase 126 | Complete |

**Coverage:**

- v1.39 requirements: 12 total
- Mapped to phases: 12 ✓
- Unmapped: 0 ✓

**Phase map:**

- **Phase 123** — Config + Core Gate API Foundation: ENT-01, ENT-02, ENT-03, ENT-04, ENT-05
- **Phase 124** — Enforcement Surfaces (Plug + LiveView Guards): ENT-06, ENT-07
- **Phase 125** — Provider Honesty + Lifecycle Truth: ENT-08, ENT-09
- **Phase 126** — Admin Surface + Docs / JTBD Spine: ENT-11, ENT-12
- **Phase 127** — Optional Stripe-Native Sync (isolated, off by default): ENT-10

---
*Requirements defined: 2026-05-22*
*Last updated: 2026-05-22 — v1.39 roadmap created; ENT-01..12 mapped to Phases 123–127 (12/12, no orphans, no double-mapping)*
