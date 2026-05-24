---
gsd_state_version: 1.0
milestone: v1.39
milestone_name: — Entitlements / Plan-Gating
status: Awaiting next milestone
stopped_at: Phase 127 context gathered
last_updated: "2026-05-24T15:24:01.676Z"
last_activity: 2026-05-24 — Milestone v1.39 completed and archived
progress:
  total_phases: 5
  completed_phases: 5
  total_plans: 21
  completed_plans: 21
  percent: 100
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-24 after v1.39 milestone)

**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain through v1.x.

**Current focus:** Planning next milestone (post-v1.39). v1.39 — Entitlements / Plan-Gating shipped & archived 2026-05-24.

## Current Position

Phase: Milestone v1.39 complete
Plan: —
Status: Awaiting next milestone
Last activity: 2026-05-24 — Milestone v1.39 completed and archived

## Milestone Progress

**v1.39** (shipped & archived **2026-05-24**): 5 phases (**123–127**), 21 plans, ENT-01..12 (12/12). Headline JTBD — fail-closed local-first plan/feature gating with no new tables and no Stripe dependency — plus the isolated off-by-default Stripe-native advisory sync. Milestone audit `tech_debt` (DoD achieved, zero blockers). Archives: [milestones/v1.39-ROADMAP.md](milestones/v1.39-ROADMAP.md), [milestones/v1.39-REQUIREMENTS.md](milestones/v1.39-REQUIREMENTS.md); audit `.planning/v1.39-v1.39-MILESTONE-AUDIT.md`; planning tag `v1.39`.

**v1.38** (shipped **2026-05-08**): Phases **120–122** complete — linked `1.1.1` trio (`121-VERIFICATION.md`) + closeout (`122-VERIFICATION.md`).
**v1.37** (shipped **2026-05-07**): Phases **117–119** — SCM-01..06. **v1.36** (shipped **2026-05-07**): Phases **112–116** — PROC-21..24.

## Performance Metrics

**Velocity:**

- Total plans completed: 21 (v1.39)
- Average duration: —
- Total execution time: —

**By Phase (v1.39, archived):**

| Phase | Plans | Notes |
|-------|-------|-------|
| 123 Config + Core Gate API Foundation | 4 | fail-closed gate API, telemetry/ledger split |
| 124 Enforcement Surfaces (Plug + LiveView) | 6 | shared Guard engine, runtime-LiveView-free CI gate |
| 125 Provider Honesty + Lifecycle Truth | 3 | Resolver + capability matrix, entitling?/1 SSOT |
| 126 Admin Surface + Docs / JTBD Spine | 4 | admin tab, guides/entitlements.md, JTBD flip |
| 127 Optional Stripe-Native Sync (isolated) | 4 | off-by-default advisory cache, isolation gate |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md. Recent decisions affecting current work:

- **2026-05-22:** Open **v1.39 — Entitlements / Plan-Gating** as the #1 JTBD gap; entitlements is a thin local-state derivation layer, **no new required dependency** for the core.
- **2026-05-22:** Ship **local-first plan→feature mapping across all providers**; `lattice_stripe 1.1.0` has no Entitlements API (verified), so Stripe-native is an opt-in overlay only.
- **2026-05-22:** Bake the two highest-leverage correctness contracts into Phase 123 exit criteria — **fail-closed boolean** and **lifecycle-predicate reuse** (`Subscription.active?/1`, never raw `.status`) — so every downstream surface inherits them.
- **2026-05-22:** Split observability — per-check decisions → telemetry only; grant/revoke/sync → immutable event ledger.
- **2026-05-22:** Keep core runtime-LiveView-free; the `on_mount` guard ships conditionally compiled with a merge-blocking no-LiveView CI check (Phase 124).
- **2026-05-22:** Isolate optional Stripe-native sync to the final phase (127) so it cannot block the milestone's core value; flagged needs-deeper-research.
_v1.39 per-plan decision detail (Phases 123–127) is archived — full Key Decisions log lives in PROJECT.md, with per-plan rationale in each phase's SUMMARY.md / LEARNINGS.md and [milestones/v1.39-ROADMAP.md](milestones/v1.39-ROADMAP.md)._

### Pending Todos

None yet.

### Blockers/Concerns

None open. (v1.39 blockers resolved at ship: Phase 124 confirmed `accrue/mix.exs` keeps `{:phoenix_live_view, "~> 1.1"}` non-optional with core runtime-LiveView-free; Phase 127 research completed — eventual-consistency window, out-of-order monotonic ordering, and the 10-entitlement inline cap all handled and documented.)

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| scope | Rich metered/tiered/range entitlement math (beyond seat counts) | out of scope v1.39 | 2026-05-22 |
| scope | Atomic seat enforcement / membership management | host-owned; documented recipe, not core API | 2026-05-22 |
| scope | Typed upstream Stripe Entitlements resources + live API reads | deferred to `lattice_stripe ≥ 1.2` | 2026-05-22 |
| scope | Dunning depth / notification journeys (JTBD #2) | next-milestone candidate | 2026-05-22 |
| strategy_non_goal | FIN-03 finance exports · MRR/ARR product · MoR processors · Hyperwallet | explicit standing non-goals | carried |
| process_gap | Dedicated `v1.37` milestone audit artifact | accepted prior-milestone gap | carried |
| quick_task | `260413-jri-bump-lattice-stripe-to-1-0-and-unblock-p` | stale pre-v1.39 leftover; not v1.39 scope | 2026-05-24 (close) |
| quick_task | `260414-l9q-automate-phase-3-human-verification-item` | stale pre-v1.39 leftover; not v1.39 scope | 2026-05-24 (close) |
| todo | `2026-05-24-ent10-advisory-cache-followups.md` (webhooks) | Phase 127 advisory-cache follow-ups (WR-05 StaleEntryError → DB upsert, IN-01..04); non-fail-open, documented in milestone audit | 2026-05-24 (close) |
| seed | `SEED-002-ecosystem-integrations` | dormant; future-milestone candidate | 2026-05-24 (close) |
| nyquist | Partial Nyquist coverage on Phases 123–125 (VALIDATION.md draft) | goals fully verified by VERIFICATION.md + test suites; close retroactively via `/gsd:validate-phase 123\|124\|125` | 2026-05-24 (close) |

## Session Continuity

Last session: 2026-05-24T12:20:08.045Z
Stopped at: Phase 127 context gathered
Resume file: None

## Operator Next Steps

- Start the next milestone with /gsd:new-milestone
