---
gsd_state_version: 1.0
milestone: v1.39
milestone_name: — Entitlements / Plan-Gating
status: verifying
stopped_at: Completed 123-04-PLAN.md (phase 123 ready for verification)
last_updated: "2026-05-22T23:11:16.967Z"
last_activity: 2026-05-22
progress:
  total_phases: 5
  completed_phases: 1
  total_plans: 4
  completed_plans: 4
  percent: 20
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-08)

**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain through v1.x.

**Current focus:** Phase 123 — config-core-gate-api-foundation

## Current Position

Phase: 124
Plan: Not started
Status: Phase complete — ready for verification
Last activity: 2026-05-22

Progress: [██████████] 100% (phase 123 plans complete)

## Milestone Progress

**v1.39** (opened **2026-05-22**, roadmap created **2026-05-22**): 5 phases (**123–127**), continuing from v1.38's Phase 122. ENT-01..12 mapped 12/12, no orphans. Phases 123→124→125→126 deliver the headline JTBD with no new tables / no Stripe dependency; Phase 127 (optional Stripe-native sync) is isolated last and must not block core value.

- **123** — ENT-01..05 — Config + core gate API foundation (fail-closed contract, lifecycle-predicate reuse, telemetry/ledger split). Not started.
- **124** — ENT-06, ENT-07 — Plug guard + conditionally-compiled LiveView `on_mount` guard + merge-blocking "core stays runtime-LiveView-free" check. Not started.
- **125** — ENT-08, ENT-09 — Resolver behaviour + capability-matrix rows + drift gate; lifecycle entitlement truth-table SSOT. Not started.
- **126** — ENT-11, ENT-12 — Read-only admin entitlements view + `guides/entitlements.md` + JTBD ⛔→✅ flip + First Hour/README spine + green doc verifiers. Not started.
- **127** — ENT-10 — Optional Stripe-native webhook→cache advisory overlay, off by default, monotonic ordering. **Needs-deeper-research** (`/gsd:plan-phase --research-phase`). Not started.

**v1.38** (shipped **2026-05-08**): Phases **120–122** complete — linked `1.1.1` trio (`121-VERIFICATION.md`) + closeout (`122-VERIFICATION.md`).
**v1.37** (shipped **2026-05-07**): Phases **117–119** — SCM-01..06. **v1.36** (shipped **2026-05-07**): Phases **112–116** — PROC-21..24.

## Performance Metrics

**Velocity:**

- Total plans completed: 4 (v1.39)
- Average duration: —
- Total execution time: —

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 123 | 4 | - | - |

## Accumulated Context

| Phase 123 P01 | 4min | 2 tasks | 2 files |
| Phase 123 P02 | 1 | 1 tasks | 2 files |
| Phase 123 P03 | 5min | 3 tasks | 7 files |
| Phase 123 P04 | 4min | 3 tasks | 4 files |
| Phase 123 P04 | 4min | 3 tasks | 4 files |

### Decisions

Decisions are logged in PROJECT.md. Recent decisions affecting current work:

- **2026-05-22:** Open **v1.39 — Entitlements / Plan-Gating** as the #1 JTBD gap; entitlements is a thin local-state derivation layer, **no new required dependency** for the core.
- **2026-05-22:** Ship **local-first plan→feature mapping across all providers**; `lattice_stripe 1.1.0` has no Entitlements API (verified), so Stripe-native is an opt-in overlay only.
- **2026-05-22:** Bake the two highest-leverage correctness contracts into Phase 123 exit criteria — **fail-closed boolean** and **lifecycle-predicate reuse** (`Subscription.active?/1`, never raw `.status`) — so every downstream surface inherits them.
- **2026-05-22:** Split observability — per-check decisions → telemetry only; grant/revoke/sync → immutable event ledger.
- **2026-05-22:** Keep core runtime-LiveView-free; the `on_mount` guard ships conditionally compiled with a merge-blocking no-LiveView CI check (Phase 124).
- **2026-05-22:** Isolate optional Stripe-native sync to the final phase (127) so it cannot block the milestone's core value; flagged needs-deeper-research.
- [Phase 123]: ENT-01 :entitlements config schema landed — runtime-read (not compile_env!), boot-validated, with a cross-plan price_id-collision guard raising Accrue.ConfigError. limits typed as keyword_list with wildcard :pos_integer keys (NimbleOptions 1.1 has no {:keyword_list,value_type} form).
- [Phase 123 P02]: ENT-05 OTel half — @allowed_attributes extended with 6 D-19 entitlement keys (atom + accrue.* string forms). :result kept distinct from :status (no reuse). result:true crosses the bridge as "true" since sanitize_value/1 stringifies atoms (true/false are atoms); @prohibited_keys/PII rule untouched.
- [Phase 123 P03]: has_active_plan?/2 tests MapSet.member? on the active_plans SET (membership truth), never the representative :plan — multi-active-plan correct, consistent with entitled?/features_for UNION semantics (T-123-07b).
- [Phase 123 P03]: LocalMap folds local active-subs with zero processor calls (read-only customer lookup, Query.active/1, never raw .status); per-check decisions telemetry-only, zero accrue_events writes (D-21).
- [Phase 123 P04]: public gate API is 4 thin defdelegates on Accrue to Accrue.Entitlements (no re-implementation); the D-10 property test asserts through the public Accrue.* delegates so it proves delegate wiring AND the fail-closed contract in one pass.
- [Phase 123 P04]: D-16 reconcile — ROADMAP SC#5 + REQUIREMENTS ENT-05 changed singular [:accrue, :entitlement, :check] -> plural [:accrue, :entitlements, :check] (event-token only); D-14 one-way-dependency grep gate certified green.

### Pending Todos

None yet.

### Blockers/Concerns

- **Phase 124 (verify at planning):** STACK says core has no LiveView dep and would add `phoenix_live_view, optional: true`; ARCHITECTURE notes `accrue/mix.exs` already declares a non-optional `{:phoenix_live_view, "~> 1.1"}` (for `Phoenix.Component`/`~H`, with `:phoenix` optional). Resolve against the live `mix.exs` — either way the guard ships conditionally compiled and core stays runtime-LiveView-free.
- **Phase 127 (research):** Stripe summary eventual consistency, out-of-order summaries, and the 10-entitlement inline cap are the subtlest part of the milestone. Run `/gsd:plan-phase --research-phase`.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| scope | Rich metered/tiered/range entitlement math (beyond seat counts) | out of scope v1.39 | 2026-05-22 |
| scope | Atomic seat enforcement / membership management | host-owned; documented recipe, not core API | 2026-05-22 |
| scope | Typed upstream Stripe Entitlements resources + live API reads | deferred to `lattice_stripe ≥ 1.2` | 2026-05-22 |
| scope | Dunning depth / notification journeys (JTBD #2) | next-milestone candidate | 2026-05-22 |
| strategy_non_goal | FIN-03 finance exports · MRR/ARR product · MoR processors · Hyperwallet | explicit standing non-goals | carried |
| process_gap | Dedicated `v1.37` milestone audit artifact | accepted prior-milestone gap | carried |

## Session Continuity

Last session: 2026-05-22T22:53:11.368Z
Stopped at: Completed 123-04-PLAN.md (phase 123 ready for verification)
Resume file: None
