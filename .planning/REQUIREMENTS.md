# Requirements: Accrue — Milestone v1.58 lattice_stripe 2.x Bump & Stripe-Native Entitlements Sync

**Defined:** 2026-07-30
**Core Value:** A Phoenix developer can install Accrue + its companion admin UI and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic Elixir DX, with zero breaking-change pain. This milestone keeps Accrue's Stripe wrapper current (major `lattice_stripe` 1.x → 2.x bump) and closes a prior explicitly-deferred capability (Phase 127's optional Stripe-native entitlements sync), without weakening the observational-only entitlements architecture.

**Milestone goal:** Move Accrue onto `lattice_stripe ~> 2.0`, reconcile the major-version deltas with all suites green, and adopt the new `LatticeStripe.Entitlements.*` surface as a client-backed advisory refresh path — closing the Phase 127 deferral while the local plan→feature map remains the sole canonical entitlement gate.

**Justification class (post-v1.48 pause rule):** maintenance / dependency currency **plus** closing a prior explicitly-deferred capability. Recorded in `PROJECT.md` `## Current State`.

**Authoritative sources:** `.planning/seeds/SEED-005-lattice-stripe-entitlements-bump.md` (the fired seed); `accrue/lib/accrue/entitlements/*` (existing observational-only seam — `stripe_sync.ex`, `resolver.ex`, `resolver/local_map.ex`, `guard.ex`, `admin.ex`); `accrue/lib/accrue/billing/entitlement_summary.ex`; `scripts/ci/verify_entitlement_sync_isolation.sh` (the gate→seam isolation guard); CLAUDE.md Technology Stack `:lattice_stripe` row + Version Compatibility Matrix; `guides/jobs_to_be_done.md` + `.planning/research/JTBD-FRONTIER.md` entitlements JTBD.

**Verified pre-open facts:** `lattice_stripe` 2.0.0 is on Hex (entitlements landed in 2.0.0; 2.1.0 is latest). Both 2.0.0 breaking vectors were checked low-risk for Accrue before opening — no direct fixture-builder (`*_json`) usage in Accrue lib/test, and no `LatticeStripe.Finch` pool wiring to reconcile. New modules: `LatticeStripe.Entitlements.{ActiveEntitlement, ActiveEntitlementSummary, Feature}`.

**Scope guardrails (binding / inviolable):**

- **Observational-only (D-01/D-11) is inviolable.** The Stripe-native sync is a *read seam* — its data is written to the advisory cache and surfaced for diagnostics only; it is **never** consulted for a grant/entitlement decision. The local plan→feature mapping (`resolver/local_map.ex`) remains the single canonical gate.
- `scripts/ci/verify_entitlement_sync_isolation.sh` (asserts no `gate → seam` edge) stays green and is **extended** to cover any new client-fetch surface added this milestone.
- Pin target is `~> 2.0` (permissive within major 2 for adopters), **not** `~> 2.1`.
- Stable-core rule: any processor-surface / support-matrix / public-behavior change updates behavior + docs + examples/verifiers + release notes **together**, in the same phase.
- No new required dependencies; no new nav rooms; no admin redesign work (that is SEED-004 M2/M3).

---

## v1 Requirements

Each maps to exactly one roadmap phase (assigned in ROADMAP.md).

### Dependency Bump & Reconciliation (BUMP)

- [x] **BUMP-01**: The `:lattice_stripe` pin in `accrue/mix.exs` is bumped `{:lattice_stripe, "~> 1.1"}` → `~> 2.0`, and `mix.lock` is refreshed to a resolved 2.x version across every project that resolves the dep — `accrue`, `accrue_admin`, `accrue_portal`, and `examples/accrue_host` — with all lockfiles committed. Any sibling package that independently pins `:lattice_stripe` is bumped in lockstep.
- [x] **BUMP-02**: Every `LatticeStripe.*` call site in Accrue (core lib, admin, portal, examples, and test support) compiles clean against 2.x with no deprecated-call warnings; the two verified 2.0.0 breaking vectors (fixture-builder `<object>_json` rename; optional/default-wired Finch pool) are confirmed to need no change, or are reconciled if the confirmation turns out false.
- [x] **BUMP-03**: The Three Zeros gate is green across all packages on the bumped deps — `mix test`, `mix dialyzer`, `mix credo --strict`, and coverage — with no new skips introduced to pass, and any dialyzer PLT churn from the bump absorbed.

### Stripe-Native Entitlements Sync Adoption (SYNC)

- [x] **SYNC-01**: A client-backed advisory refresh path fetches a customer's active Stripe entitlements via `LatticeStripe.Entitlements.{ActiveEntitlement, ActiveEntitlementSummary}` and writes them into the existing advisory cache (`Accrue.Entitlements.StripeSync` → `Accrue.Billing.EntitlementSummary` row) — i.e. a pull/refresh path, not webhook-payload-only — closing the Phase 127 "optional Stripe-native entitlements sync" deferral.
- [x] **SYNC-02**: The sync is **opt-in and observational-only** — gated behind the existing `stripe_native_sync: :advisory` config seam, off by default, and its output is consumed only by diagnostic/admin read surfaces. It is never read by the resolver/guard grant path; the local plan→feature map remains the canonical gate (D-01/D-11 preserved).
- [x] **SYNC-03**: `scripts/ci/verify_entitlement_sync_isolation.sh` stays green and is extended so the new client-fetch entry point is covered by the `gate → seam` isolation assertion (a future gate that reads the new path fails CI).
- [x] **SYNC-04**: The D-07 `fetch_entitled/2` question left open in `admin.ex` is resolved this milestone — either implemented as part of the advisory refresh surface (observational) or kept deferred with a one-line recorded reason in the code/docs; the milestone does not leave it ambiguous.
- [x] **SYNC-05**: The new sync path is covered by tests using the Fake/Test processor (no live Stripe, no Chrome, `async`-safe), asserting: cache is populated from `LatticeStripe.Entitlements.*` results; a grant decision is unchanged whether the advisory cache is empty, stale, or contradictory (proves it is never a gate); and the config default keeps it off.

### Docs & Truth (DOCS)

- [x] **DOCS-01**: `CLAUDE.md` is updated — the Technology Stack `:lattice_stripe` row (version + entitlements note) and the Version Compatibility Matrix `lattice_stripe` anchor pin now read `~> 2.0`, correcting the stale `~> 0.2` matrix cell in passing.
- [x] **DOCS-02**: The entitlements JTBD truth is updated — `guides/jobs_to_be_done.md` and `.planning/research/JTBD-FRONTIER.md` flip the Phase 127 "optional Stripe-native sync deferred" status to shipped/observational, without overstating (it stays advisory, never a gate).
- [x] **DOCS-03**: Per-package changelog / release notes record the major dep bump and the new advisory sync; new public functions carry `@since` annotations; and the adoption-proof / support-matrix / planning-mirror docs stay mutually consistent (POS-03 / stable-core rule).

---

## Standing Stable-Core Posture Anchors

These anchors remain active outside a feature milestone because CI uses them to keep the public docs and planning mirrors aligned:

- **POS-01**: Public docs and package READMEs describe Accrue as stable-core / demand-driven expansion.
- **POS-02**: Adopter-facing docs describe the supported SaaS billing loop, processor support boundaries, and package ownership boundaries.
- **POS-03**: Release notes, package docs, support matrix, adoption proof docs, and planning mirrors describe the same stable-core posture.

---

## Out of Scope (explicit exclusions this milestone)

- Making the Stripe-native entitlements data authoritative for any grant/gate decision — permanently out of scope by architecture (D-01/D-11), not just this milestone.
- Pinning to `~> 2.1` or chasing 2.1-only additions beyond entitlements — target is `~> 2.0`.
- Any `accrue_admin` redesign / new-room / IA work (SEED-004 M2/M3) beyond the minimal read surface needed to display advisory entitlement data.
- Adopting other, non-entitlements 2.x additions unless a call site forces reconciliation.
- New required dependencies; Tailwind migration; replacing the `ax-*` token SSOT.

---

## Future Requirements (deferred)

- SEED-004 **M2** (Why-blocked / causality diagnosis + core `accrue` diagnosis functions) and **M3** (new rooms + v1.56 ratchet re-freeze) remain the next admin candidates.
- Surfacing Stripe `Feature` catalog management (create/list Features) as an admin authoring surface — only if adopter demand appears; the read/advisory path this milestone ships is the floor.

---

## Traceability

Phase assignments are written by the roadmap step (ROADMAP.md). Continues phase numbering from 211 (v1.57's last phase) — v1.58 begins at Phase 212.

| Requirement | Phase | Status |
|-------------|-------|--------|
| BUMP-01 | Phase 212 — lattice_stripe 2.x bump & green reconciliation | Complete |
| BUMP-02 | Phase 212 — lattice_stripe 2.x bump & green reconciliation | Complete |
| BUMP-03 | Phase 212 — lattice_stripe 2.x bump & green reconciliation | Complete |
| SYNC-01 | Phase 213 — Stripe-native advisory entitlements sync (observational-only) | Complete |
| SYNC-02 | Phase 213 — Stripe-native advisory entitlements sync (observational-only) | Complete |
| SYNC-03 | Phase 213 — Stripe-native advisory entitlements sync (observational-only) | Complete |
| SYNC-04 | Phase 213 — Stripe-native advisory entitlements sync (observational-only) | Complete |
| SYNC-05 | Phase 213 — Stripe-native advisory entitlements sync (observational-only) | Complete |
| DOCS-01 | Phase 214 — Docs & truth reconciliation | Complete |
| DOCS-02 | Phase 214 — Docs & truth reconciliation | Complete |
| DOCS-03 | Phase 214 — Docs & truth reconciliation | Complete |

**Coverage:** 11/11 mapped, 0 orphans, 0 duplicates (validated at roadmap creation 2026-07-30).
