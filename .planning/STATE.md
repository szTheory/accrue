---
gsd_state_version: 1.0
milestone: v1.40
milestone_name: Dunning depth
status: planning
last_updated: "2026-05-24T16:26:32.736Z"
last_activity: 2026-05-24
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-24 after v1.39 milestone)

**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain through v1.x.

**Current focus:** v1.40 — Dunning depth / notification journeys (defining requirements; phases begin at 128). Research pre-resolved in `.planning/threads/dunning-depth-milestone-prep.md`.

## Current Position

Phase: Not started (defining requirements)
Plan: —
Status: Defining requirements
Last activity: 2026-05-24 — Milestone v1.40 started

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

**2026-05-24 — post-v1.39 next-step assessment:**

- **Selected next milestone = Dunning depth / multi-step notification journeys** (JTBD #2). It is the only 🟡-bounded item on the canonical revenue loop and the project's #1 ranked candidate. Assessment puts the lib at ~90–95% done for its stated scope (canonical 6/6 loop shipped; original Elixir-Stripe-gap wedge fully closed). Full research in thread `dunning-depth-milestone-prep`.
- **Chimeway = optional integration, NOT a hard dependency.** Ship a thin built-in `Accrue.Dunning.Campaign` (Oban-driven, no new heavy deps) as the always-on default + a conditional-compiled off-by-default `Accrue.Integrations.Chimeway` adapter behind an `Accrue.Dunning.Engine` behaviour. Rationale: Chimeway is only `1.0.0`-on-Hex (2026-05-08, churn risk vs zero-breaking-change promise), pulls its own schema/migrations + Oban, and dunning is not on the critical install path. (Mailglass/lattice_stripe are hard deps because they ARE.)
- **Must-fix folded into the dunning milestone:** `:invoice_payment_failed` email has no idempotency key (`workers/mailer.ex:292,314`) → re-sends on every Stripe retry. Fix via `Mailer.idempotency_key/2` coverage + Oban `unique`.
- **Did NOT change `workflow.research`/quality-gate config** (per shift-left ask-first rule). Did NOT auto-run new-milestone (per assessment instruction).

_v1.39 per-plan decision detail (Phases 123–127) is archived — full Key Decisions log lives in PROJECT.md, with per-plan rationale in each phase's SUMMARY.md / LEARNINGS.md and [milestones/v1.39-ROADMAP.md](milestones/v1.39-ROADMAP.md)._

### Pending Todos

None yet.

### Blockers/Concerns

**Surfaced by the 2026-05-24 assessment (none block shipping; inputs to the next milestone):**

- **Latent bug:** `:invoice_payment_failed` email has no idempotency key → duplicate sends on each Stripe retry. Fix in the dunning milestone (thread `dunning-depth-milestone-prep`).
- **Adopter-proof gap:** the v1.39 headline JTBD (entitlements/plan-gating) has ZERO usage in `examples/accrue_host`; metered + checkout-session also unexercised there; recovery crons (`DunningSweeper`, `DetectExpiringCards`) ship dormant/host-unwired. See thread `adopter-proof-gaps`.
- **Chimeway watch-item:** its guide and code disagree on the public API surface; only `1.0.0` is on Hex while the local repo's `mix.exs` version string is stale at `0.1.0`. Verify against published 1.0.0 before coding the adapter.
- **Graduation-candidate lesson (cross-phase):** "a fully green suite can hide a feature dead on the production path" — caught at code review in BOTH Phase 126 (CR-01) and 127 (CR-01). Already in `126-LEARNINGS.md`/`127-LEARNINGS.md`; flagged here as a cross-phase graduation candidate (test the production entry point, not just the unit handler).

Prior status — None open. (v1.39 blockers resolved at ship: Phase 124 confirmed `accrue/mix.exs` keeps `{:phoenix_live_view, "~> 1.1"}` non-optional with core runtime-LiveView-free; Phase 127 research completed — eventual-consistency window, out-of-order monotonic ordering, and the 10-entitlement inline cap all handled and documented.)

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

- **Next milestone selected: Dunning depth / notification journeys.** Research is pre-resolved in thread `dunning-depth-milestone-prep` (run `/gsd-thread dunning-depth-milestone-prep` to load it).
- Kick off when ready: `/gsd-new-milestone "v1.40 Dunning depth"` (assessment intentionally did NOT auto-start it).
- Consider the `adopter-proof-gaps` thread (entitlements not proven in example host) — fold into the dunning milestone's example-host work or take as a small dedicated phase.
