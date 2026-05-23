# Roadmap: Accrue

## Active Milestone

🚧 **v1.39 — Entitlements / Plan-Gating** (opened **2026-05-22**) — Phases **123–127**.

**Milestone goal:** Close the last open step of the canonical SaaS loop — let a Phoenix dev *gate features and access on what a customer has paid for*, first-party, with the same provider-honest + telemetry + admin + docs rigor as the rest of Accrue. Entitlements is a thin derivation layer over local subscription state Accrue already holds; the headline JTBD ships with **no new tables and no Stripe dependency**, and the optional Stripe-native sync is isolated to the final phase so it never blocks the core value.

**Phase numbering:** continues from v1.38 (ended at Phase 122) → starts at **Phase 123**. Not reset.

## Overview

Entitlements is an **integration design over Accrue's already-feature-complete billing core**, not a new domain. The build is dependency-ordered: a fail-closed config + core gate API foundation (Phase 123) that everything else inherits its correctness contracts from, two enforcement surfaces that gate controllers and host LiveViews while keeping core runtime-LiveView-free (Phase 124), provider-honest resolution plus a lifecycle entitlement truth-table SSOT mirroring the SCM-06 / PROC-24 contract pattern (Phase 125), operator visibility and the on-brand docs/JTBD spine (Phase 126), and finally the optional, off-by-default Stripe-native webhook→cache overlay (Phase 127) — the riskiest, needs-deeper-research slice, deliberately isolated last so the milestone's core value lands before any Stripe-specific work.

## Phases

**Phase Numbering:**

- Integer phases (123, 124, …): Planned milestone work
- Decimal phases (124.1, …): Urgent insertions (marked INSERTED)

- [x] **Phase 123: Config + Core Gate API Foundation** - Host plan→feature/quota config plus fail-closed `has_active_plan?` / `entitled?` / `features_for` / `entitlement_quantity` over local subscription state, with telemetry/ledger split (completed 2026-05-22)
- [x] **Phase 124: Enforcement Surfaces — Plug + LiveView Guards** - Controller Plug guard and conditionally-compiled LiveView `on_mount` guard, with a merge-blocking "core stays runtime-LiveView-free" check (completed 2026-05-23)
- [ ] **Phase 125: Provider Honesty + Lifecycle Truth** - Resolver behaviour + capability-matrix rows + merge-blocking drift gate, plus the lifecycle→entitlement truth-table SSOT
- [ ] **Phase 126: Admin Surface + Docs / JTBD Spine** - Read-only entitlements view in `accrue_admin`, `guides/entitlements.md`, the JTBD ⛔→✅ flip, First Hour/README spine, and green package-doc verifiers
- [ ] **Phase 127: Optional Stripe-Native Sync (isolated, off by default)** - Webhook→cache advisory overlay with monotonic ordering, behind a flag, that must not block the milestone's core value

## Phase Details

### Phase 123: Config + Core Gate API Foundation

**Goal**: A Phoenix developer can declare a plan→feature/quota map and gate code on what a customer has paid for, resolved entirely from local subscription state with a fail-closed contract — the headline JTBD, with no new tables and no Stripe dependency.
**Depends on**: Nothing (first phase of this milestone; builds on shipped billing core)
**Requirements**: ENT-01, ENT-02, ENT-03, ENT-04, ENT-05
**Success Criteria** (what must be TRUE):

  1. A host can declare a `NimbleOptions`-validated plan/price→feature (and optional seat/quota) map; an invalid or unmapped configuration fails loudly at boot rather than silently allowing access.
  2. `Accrue.has_active_plan?(billable, plan)` returns a boolean derived from the existing `Subscription.active?/1` lifecycle truth (never raw `.status`), and `Accrue.entitled?(billable, feature)` / `features_for(billable)` resolve from local subscription state with zero processor API calls.
  3. The fail-closed contract holds under property tests: the only path to `true` is an affirmative resolved match — errors, `nil` billables, unmapped plans, and exceptions all resolve to `false`.
  4. `Accrue.entitlement_quantity/2` returns a read-only entitled seat/quantity derived from local subscription quantity, with atomic seat enforcement documented as host-owned (not a core API).
  5. Entitlement checks emit `[:accrue, :entitlements, :check]` telemetry/OTel spans; per-check decisions are NOT written to the immutable event ledger.

**Plans**: 4 plans

  - [x] 123-01-PLAN.md — :entitlements config schema + entitlements/0 accessor + boot price_id-collision guard (ENT-01)
  - [x] 123-02-PLAN.md — OTel @allowed_attributes: add the 6 entitlement keys so check spans retain attributes (ENT-05)
  - [x] 123-03-PLAN.md — Accrue.Entitlements context tree: Plan struct + Resolver behaviour + LocalMap + 4 fail-closed gate fns w/ telemetry (ENT-02..05)
  - [x] 123-04-PLAN.md — 4 Accrue defdelegates + load-bearing fail-closed property test + D-14 dependency gate + plural-event doc reconcile (ENT-02..05)

### Phase 124: Enforcement Surfaces — Plug + LiveView Guards

**Goal**: A developer can gate both controller routes and host LiveViews on entitlement, with the same fail-closed contract, while core `accrue` remains runtime-LiveView-free for headless/API hosts.
**Depends on**: Phase 123
**Requirements**: ENT-06, ENT-07
**Success Criteria** (what must be TRUE):

  1. A developer can gate a Phoenix controller route with a Plug guard (`require_plan` / `require_feature`) that halts with a configurable fail response (redirect or 403) when the billable is not entitled.
  2. A developer can gate a host LiveView with an `on_mount` guard whose billable-resolution key (e.g. `current_scope` / `current_user`) is host-configurable and adapter-thin, with no required Sigra/Lockspire coupling.
  3. The LiveView guard is shipped via conditional compilation, and a merge-blocking CI check proves no always-compiled core module references the LiveView socket runtime (Phoenix.LiveView / on_mount / Socket) — core `accrue` stays runtime-LiveView-free even though `phoenix_live_view` is a required core dep.
  4. Both guards resolve entitlement once per request/mount and reuse the Phase 123 fail-closed contract — a guard whose check cannot resolve denies rather than allows.

**Plans**: 6 plans

  - [x] 124-01-PLAN.md — Contract extension: :entitlements billable/on_deny/deny_path config + :surface OTel allowlist + additive surface: opts on the gate predicates (ENT-06/07)
  - [x] 124-02-PLAN.md — Shared Accrue.Entitlements.Guard engine (billable resolution + resolve-once + fail-closed delegation + tiered on_deny + ctx) + guard/telemetry tests (ENT-06/07)
  - [x] 124-03-PLAN.md — Plug surface: Accrue.Plug.RequireEntitlement + require_feature/require_plan router macros + plug/router tests (ENT-06)
  - [x] 124-04-PLAN.md — LiveView surface: cond-compiled Accrue.Live.Entitlements on_mount guard + source-assertion/on_mount test (ENT-07)
  - [x] 124-05-PLAN.md — D-06 LiveView-runtime-free doc reconciliation (CLAUDE.md / ROADMAP SC#3 / PITFALLS.md / oban middleware / mix.exs comment) (ENT-07)
  - [x] 124-06-PLAN.md — Merge-blocking static LiveView-runtime-free CI gate + ci.yml wiring + cross-surface fail-closed property test (ENT-06/07)

**UI hint**: yes

### Phase 125: Provider Honesty + Lifecycle Truth

**Goal**: Entitlement resolution behaves identically across Stripe, Braintree, and Fake via a documented provider-honest contract, and entitlement-vs-lifecycle truth is pinned as a single source of truth — both protected by merge-blocking drift gates.
**Depends on**: Phase 123
**Requirements**: ENT-08, ENT-09
**Success Criteria** (what must be TRUE):

  1. A Resolver behaviour plus `entitlements:` capability-matrix rows make local plan→feature mapping behave identically across Stripe, Braintree, and Fake, with the Fake lane as a deterministic merge-blocking proof.
  2. Drift between the runtime capability labels and the published support-matrix doc fails the build before merge, mirroring the SCM-06 / PROC-24 support-contract pattern.
  3. Entitlement truth maps explicitly to existing lifecycle states (trialing ✅, canceling/paid-through ✅, paused ✗, canceled ✗) as a documented SSOT truth table, with past-due grace as a fail-safe configurable knob reusing the dunning grace overlay.
  4. An operator/developer can read one canonical truth table and know exactly which lifecycle states grant entitlement and how the past-due grace knob behaves.

**Plans**: 3 plans

  - [ ] 125-01-PLAN.md — Provider-honesty capability surface: `entitlements:` Capabilities group + 3 adapter `capabilities/0` rows + matrix-doc + drift-gate (positive + negative divergence guard) + Fake-lane proof (ENT-08, Wave 1)
  - [ ] 125-02-PLAN.md — Lifecycle-truth SSOT: `Subscription.entitling?/1` + `Query.entitling/1` twin + retarget `fold_active/1` (closes paused fail-OPEN gap) + truth-table guide entry + 8-status pin + twin-invariant test (ENT-09, Wave 1)
  - [ ] 125-03-PLAN.md — Past-due grace knob: `past_due_grace` config + `PastDueGrace.within_grace?/2` + conditional fold-widening + `:grace_plans` resolved field + `:past_due_grace`/`:past_due_expired` telemetry + truth-table footnote (ENT-09, Wave 2, depends on 125-02)

### Phase 126: Admin Surface + Docs / JTBD Spine

**Goal**: An operator can see a customer's resolved entitlements in the admin UI, and the entitlements story is documented end-to-end with the JTBD gap closed and the doc-contract verifiers green.
**Depends on**: Phase 123 (read API), Phase 125 (provider matrix + truth table to document)
**Requirements**: ENT-11, ENT-12
**Success Criteria** (what must be TRUE):

  1. An operator can view a customer's currently-active entitlements/features in `accrue_admin` (read-only), surfacing unmapped-plan drift by eye.
  2. `guides/entitlements.md` documents the full story: the gate API, Plug guard, LiveView guard, provider matrix, and lifecycle truth table.
  3. The JTBD docs flip entitlements ⛔→✅, and the First Hour + README "Start here" spine reference the entitlements guide.
  4. Package-doc verifiers stay green after the docs and admin changes land.

**Plans**: TBD
**UI hint**: yes

### Phase 127: Optional Stripe-Native Sync (isolated, off by default)

**Goal**: A Stripe shop can optionally let Stripe's native entitlement summaries reconcile a local advisory cache, without that path being able to block or regress the milestone's local-first core value.
**Depends on**: Phase 123 (read API + resolver seam), Phase 125 (provider matrix). Final and isolated.
**Requirements**: ENT-10
**Success Criteria** (what must be TRUE):

  1. When explicitly enabled (off by default), Accrue consumes Stripe's `entitlements.active_entitlement_summary.updated` webhook into a local cache used as an advisory overlay, while local mapping remains the canonical default.
  2. Cache writes apply monotonic event-ts/id ordering so out-of-order or replayed summaries cannot regress the cache, mirroring the existing `last_stripe_event_ts`/`_id` pattern.
  3. With sync disabled (the default), the entire entitlements surface behaves exactly as after Phase 126 — no Stripe dependency on the core gate path.
  4. The eventual-consistency window and the 10-entitlement inline-summary cap are documented, with full paginated reads recorded as a deferred follow-up (depends on `lattice_stripe ≥ 1.2`).

**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 123 → 124 → 125 → 126 → 127

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 123. Config + Core Gate API Foundation | v1.39 | 4/4 | Complete    | 2026-05-22 |
| 124. Enforcement Surfaces — Plug + LiveView Guards | v1.39 | 6/6 | Complete    | 2026-05-23 |
| 125. Provider Honesty + Lifecycle Truth | v1.39 | 0/3 | Not started | - |
| 126. Admin Surface + Docs / JTBD Spine | v1.39 | 0/TBD | Not started | - |
| 127. Optional Stripe-Native Sync (isolated) | v1.39 | 0/TBD | Not started | - |

## Notes

- **Critical-path isolation:** Phases 123→124→125→126 deliver the headline JTBD ("gate a feature on a paid subscription") with no new tables and no Stripe dependency. Phase 127 is the optional Stripe-native depth and must not block the milestone's core value — it is the natural slip-point.
- **Research flag:** Phase 127 (Stripe-native sync) is flagged needs-deeper-research by both ARCHITECTURE and PITFALLS (eventual consistency, out-of-order summaries, the 10-entitlement cap). Run `/gsd:plan-phase --research-phase` for it. Phases 123–126 clone existing Accrue patterns (telemetry span, `Events.record`, `nimble_options` schema, `Processor.Capabilities` matrix, conditional-compile à la `Integrations.Sigra`, `accrue_admin` Copy/VERIFY-01 discipline) and need no external research.
- **LiveView-runtime-free constraint:** the `on_mount` guard (Phase 124) ships conditionally-compiled, with a merge-blocking static CI check proving **no always-compiled core module references the LiveView socket runtime** (Phoenix.LiveView / on_mount / Socket). `phoenix_live_view` is a **required core dep** (it ships `Phoenix.Component`/`~H` for the email + invoice render spine), so "runtime-LiveView-free" means core must not require a host to run LiveView nor couple its public APIs to the LiveView socket lifecycle — it does **not** mean the package is absent. (`accrue/mix.exs` posture verified at Phase 124 planning time: `{:phoenix_live_view, "~> 1.1"}` is correctly non-optional.)
- **Standing non-goals (unchanged):** rich metered/tiered entitlement math beyond seat counts; atomic seat enforcement / membership management; feature-catalog authoring UI; deep Sigra/Lockspire coupling; dunning notification journeys (next-milestone candidate); FIN-03, MRR/ARR product, MoR processors, Hyperwallet.

## Recent Milestones

- ✅ **v1.38 Linked Release Truth** — Phases **120–122** shipped **2026-05-08**. Locked the three-package release contract, published the linked `1.1.1` trio with canonical proof in `121-VERIFICATION.md`, and finalized the maintainer-facing planning closeout plus `INV-08` certification in `122-VERIFICATION.md`.
- ✅ **v1.37 Subscription Change Management** — Phases **117–119** shipped **2026-05-07**. Promoted official swap/preview semantics, shipped admin and portal change flows, and finalized bounded Braintree `:plan_resolver` support plus drift gates. Archives: [milestones/v1.37-ROADMAP.md](/Users/jon/projects/accrue/.planning/milestones/v1.37-ROADMAP.md), [milestones/v1.37-REQUIREMENTS.md](/Users/jon/projects/accrue/.planning/milestones/v1.37-REQUIREMENTS.md).
- ✅ **v1.36 Dual-Provider Core Completion** — Phases **112–116** shipped **2026-05-07**. Promoted bounded first-party customer update, normalized provider-honest cancellation semantics, locked the support-contract verifier bundle, and restored the audit-required verification chain. Archives: [milestones/v1.36-ROADMAP.md](/Users/jon/projects/accrue/.planning/milestones/v1.36-ROADMAP.md), [milestones/v1.36-REQUIREMENTS.md](/Users/jon/projects/accrue/.planning/milestones/v1.36-REQUIREMENTS.md).
- ✅ **v1.35 Dual-Provider Supportability Closure** — Phases **109–111** shipped **2026-05-07**. Provider-honest support contract mirrors, lifecycle semantics SSOT, and Braintree webhook/operator recovery proof. Archives: [milestones/v1.35-ROADMAP.md](/Users/jon/projects/accrue/.planning/milestones/v1.35-ROADMAP.md), [milestones/v1.35-REQUIREMENTS.md](/Users/jon/projects/accrue/.planning/milestones/v1.35-REQUIREMENTS.md).

---
*Last updated: 2026-05-23 — Phase 125 planned (3 plans, 2 waves); ENT-08 + ENT-09 covered. v1.39 roadmap created 2026-05-22; Phases 123–127 cover ENT-01..12 (12/12 mapped).*
