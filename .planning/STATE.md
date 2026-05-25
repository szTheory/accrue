---
gsd_state_version: 1.0
milestone: v1.40
milestone_name: — Dunning depth / notification journeys
status: verifying
stopped_at: Phase 130 context gathered
last_updated: "2026-05-25T14:30:26.692Z"
last_activity: 2026-05-25
progress:
  total_phases: 5
  completed_phases: 3
  total_plans: 14
  completed_plans: 14
  percent: 60
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-24 after v1.39 milestone)

**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain through v1.x.

**Current focus:** Phase 130 — provider-honesty-fake-lane-proof-example-host-wiring

## Current Position

Phase: 130 (provider-honesty-fake-lane-proof-example-host-wiring) — EXECUTING
Plan: 4 of 4
Status: Phase complete — ready for verification
Last activity: 2026-05-25

## Milestone Progress

**v1.40** (planning, opened **2026-05-24**): 5 phases (**128–132**), DUN-01..10 + PROOF-03 (11 requirements, 11/11 mapped). Multi-step dunning journey (campaign engine + idempotency must-fix → customer/operator surfaces + observability → provider honesty + Fake-lane proof + example-host wiring → optional Chimeway adapter, isolated → entitlements adopter-proof). Roadmap: [ROADMAP.md](ROADMAP.md); requirements: [REQUIREMENTS.md](REQUIREMENTS.md).

**v1.39** (shipped & archived **2026-05-24**): 5 phases (**123–127**), 21 plans, ENT-01..12 (12/12). Headline JTBD — fail-closed local-first plan/feature gating with no new tables and no Stripe dependency — plus the isolated off-by-default Stripe-native advisory sync. Milestone audit `tech_debt` (DoD achieved, zero blockers). Archives: [milestones/v1.39-ROADMAP.md](milestones/v1.39-ROADMAP.md), [milestones/v1.39-REQUIREMENTS.md](milestones/v1.39-REQUIREMENTS.md); audit `.planning/v1.39-v1.39-MILESTONE-AUDIT.md`; planning tag `v1.39`.

**v1.38** (shipped **2026-05-08**): Phases **120–122** complete — linked `1.1.1` trio (`121-VERIFICATION.md`) + closeout (`122-VERIFICATION.md`).
**v1.37** (shipped **2026-05-07**): Phases **117–119** — SCM-01..06. **v1.36** (shipped **2026-05-07**): Phases **112–116** — PROC-21..24.

## Performance Metrics

**Velocity:**

- Total plans completed: 31 (v1.39)
- Average duration: —
- Total execution time: —

**v1.40 phase map (planned):**

| Phase | Requirements | Notes |
|-------|--------------|-------|
| 128 Campaign Engine Foundation + Idempotency Must-Fix | DUN-01, DUN-02, DUN-04, DUN-05 | durable Oban campaign + config + de-dup must-fix + cancel-on-recovery keying |
| 129 Customer + Operator Surfaces + Observability | DUN-06, DUN-07, DUN-08 | portal banner, admin dunning state, ledger events + telemetry + recovered-vs-lost counter |
| 130 Provider Honesty + Fake-Lane Proof + Example-Host Wiring | DUN-09, DUN-10 | provider-honest docs + drift gate, deterministic Fake-lane gate, host wiring |
| 131 Optional Chimeway Engine Adapter (isolated) | DUN-03 | `Dunning.Engine` behaviour + off-by-default conditionally-compiled adapter |
| 132 Entitlements Adopter-Proof Demo | PROOF-03 | entitlement-gated route/page in example host + matrix row |

**By Phase (v1.39, archived):**

| Phase | Plans | Notes |
|-------|-------|-------|
| 123 Config + Core Gate API Foundation | 4 | fail-closed gate API, telemetry/ledger split |
| 124 Enforcement Surfaces (Plug + LiveView) | 6 | shared Guard engine, runtime-LiveView-free CI gate |
| 125 Provider Honesty + Lifecycle Truth | 3 | Resolver + capability matrix, entitling?/1 SSOT |
| 126 Admin Surface + Docs / JTBD Spine | 4 | admin tab, guides/entitlements.md, JTBD flip |
| 127 Optional Stripe-Native Sync (isolated) | 4 | off-by-default advisory cache, isolation gate |
| Phase 128 P01 | 3min | 2 tasks | 2 files |
| Phase 128 P02 | 2min | 2 tasks | 3 files |
| Phase 128 P03 | 3min | 2 tasks | 2 files |
| Phase 128 P04 | 6min | 3 tasks | 7 files |
| Phase 128 P05 | 3min | 1 tasks | 2 files |
| Phase 128 P06 | 10min | 2 tasks | 4 files |
| Phase 129 P03 | 6min | 1 tasks | 5 files |
| Phase 129 P04 | 14min | 2 tasks | 4 files |
| Phase 129 P02 | 3min | 1 tasks | 2 files |
| Phase 130 P01 | 8min | - tasks | - files |
| Phase 130 P02 | 3min | 2 tasks | 2 files |
| Phase 130 P03 | 7min | 2 tasks | 1 files |

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

**2026-05-24 — v1.40 roadmap created:**

- **5 phases (128–132), 11/11 requirements mapped** (DUN-01..10 + PROOF-03), phase numbering continued from v1.39 (no reset). Build order honors the pre-resolved research: (128) tightly-coupled correctness foundation — durable Oban campaign + config + `:invoice_payment_failed` idempotency must-fix + cancel-on-recovery keying; (129) customer/operator surfaces + observability; (130) provider honesty + deterministic Fake-lane merge-gate + example-host wiring; (131) optional Chimeway adapter isolated last (like v1.39 Phase 127) so it never blocks core dunning value; (132) entitlements adopter-proof in the example host (independent of dunning).
- **Three open questions carried into phase context (do not re-litigate):** pin the campaign key to the FIRST nil→past_due transition (not every `past_due_since` bump); validate `last_step.after_days <= grace_days` in the NimbleOptions schema so final notice precedes the sweeper's terminal action; verify Chimeway's published 1.0.0 public API before coding the adapter (guide vs code disagree).

_v1.39 per-plan decision detail (Phases 123–127) is archived — full Key Decisions log lives in PROJECT.md, with per-plan rationale in each phase's SUMMARY.md / LEARNINGS.md and [milestones/v1.39-ROADMAP.md](milestones/v1.39-ROADMAP.md)._

- [Phase ?]: 2026-05-24 (128-01): dunning campaign opt-out shorthand campaign:false normalized at all three raw read sites (boot grace validator, dunning_campaign/0 accessor, {:custom} validator) because validate_at_boot!/0 passes UN-normalized opts to maybe_validate_boot_setup!/1
- [Phase ?]: 2026-05-24 (128-02): dunning campaign anchor is a single nullable column dunning_campaign_started_at on accrue_subscriptions (column-add, NOT a new table, mirrors dunning_sweep_attempted_at); cast-for-CLEAR-path-only in @cast_fields (D-12 recovery clear) — START is a sibling update_all (D-09), never a cast, so it never contends with optimistic_lock(:lock_version); no index (deferred to Phase 129); Subscription.dunning_campaign_active?/1 true iff anchor is a non-nil DateTime
- [Phase ?]: 2026-05-24 (128-03): Accrue.Dunning.Campaign next_step/3 returns {:next, step, schedule_in} | :done; boundary is >= so day-0 returns the first step immediately (schedule_in 0) — must_have overrides the discretionary strict-> sketch; schedule_in clamped to max(0,...) (T-128-05); module grep-asserted side-effect-free (no DB/Oban/clock), keeping the Phase-131 engine seam clean
- [Phase ?]: 2026-05-24 (128-04): :invoice_payment_failed deduped at enqueue via Oban unique with invoice_id PROMOTED to a TOP-LEVEL arg (keys narrow to top-level only); period :infinity + :completed for week-2 Smart-Retry; dedup_unique/2 returns false for all other types (no regression)
- [Phase ?]: 2026-05-24 (128-04): routed :invoice_payment_failed to the Mailglass lane so the D-14 idempotency_key backstop fires; added maybe_attach_pdf_for_lane/3 to SKIP PDF for it (Rule 1 — lane otherwise renders an invoice PDF for any invoice_id)
- [Phase ?]: 2026-05-24 (128-05): Accrue.Workers.DunningStep chains via the pure resolver by deriving resolver now from anchor + current-step after_days + 1s (NOT raw Clock.utc_now/0) — raw wall-clock at elapsed approx boundary re-resolves to the current step (D-16-suppressed, chain never advances); D-16 unique keys [:subscription_id,:step_key,:campaign_started_at] period :infinity + :completed; cancel-guard FIRST returns {:cancel,:recovered} on not-past_due OR nil anchor; campaign_started_at carried/parsed as ISO8601 string (no atomization); no ledger/telemetry/engine-behaviour (scope-fenced to Phase 128)
- [Phase 129]: 2026-05-25 (129-03): DUN-06 portal recovery banner. Conditional `<section data-role="subscription-recovery-banner">` inserted before the first portal-card in `SubscriptionLive.render/1`, gated on `recovery_prompt?/1` = `Subscription.past_due?/1` OR `Subscription.dunning_campaign_active?/1` (D-10, canonical predicates — no template status-atom). `update_pm_path/2` dispatches on `subscription.processor` (2-clause, mirroring `cancel_subscription/1`): braintree → `Path.payment_methods_new/1` (`/payment-methods/new`); non-braintree → `Path.payment_methods/1` in-portal list (RESEARCH A4 safe default, never the Braintree-only hosted-fields form = T-129-10). Three jargon-free `AccruePortal.Copy.subscription_recovery_heading/body/cta` defs; CTA label "Update payment method" shared verbatim with the `card_expiring_soon` email. Neutral `.portal-card role=alert` tone (UI-SPEC), zero new CSS. Render tests assert decoded element content via `has_element?/3` (HTML-entity safe). Blocking fix: synced portal `mix.lock` rendro 0.1.0→0.3.0 to match `accrue` core (Rule 3).
- [Phase ?]: 2026-05-24 (128-06): campaign wired into the REAL webhook path. D-09 atomic update_all WHERE is_nil(anchor) in maybe_bump_past_due_since elects exactly ONE concurrent invoice.payment_failed winner (count==1 enqueues day-0 DunningStep; count==0 no-op; sibling update_all, never touches lock_version). D-12 cancel-on-recovery SPLITS the commit boundary: in-transaction force_status_changeset anchor-clear (durable, atomic with the status write) + POST-commit Oban.cancel_all_jobs keyed on subscription_id+campaign_started_at (run OUTSIDE any Repo.transact at the dispatch site, only on a committed {:ok,%Subscription{}}, handed off via a tightly-scoped process-dict stash). D-15 REPLACE skips the standalone :invoice_payment_failed email when the campaign owns day-0. Cancel-failure is logged via Logger.warning (NOT telemetry/ledger — Phase 129); per-step cancel-guard backstops uncancelled steps. iso_anchor captured from row BEFORE the clear so a stale recovery can't cancel a fresh re-lapse campaign. Stale standalone-dispatch test re-scoped to campaign-disabled (Rule 1).
- [Phase ?]: 2026-05-25 (129-04): DUN-07 admin read-only dunning-state ax-card. New <article data-role=subscription-dunning-state> cloned from related-billing in SubscriptionLive.render/1, ALWAYS rendered (state surface). next_action_summary/1 derives next action from the PURE Accrue.Dunning.Campaign.next_step/3 resolver (Config.dunning_campaign_steps + Clock.utc_now for Fake-lane determinism), rescuing failure to Copy.dunning_next_action_unavailable (T-129-14). dunning_badge_tone/1 amber (active) / slate (none). Strictly read-only (D-12): zero phx-click/phx-submit/button/form. All operator copy via dedicated AccrueAdmin.Copy.Dunning (D-13). Empty state renders body + Started/Next labels so copy-routing holds. No new CSS. 137 admin tests green.
- [Phase ?]: 2026-05-25 (129-02): DUN-08 SC#4 recovered-vs-lost counter. Accrue.Billing.Dunning.recovered_vs_lost/1 folds accrue_events into flat %{recovered: count(dunning.recovered), lost: count(dunning.exhausted)} — no new table (D-07), raw map only no rate field (D-08). Request-time terminal-action-request type structurally excluded so lost never double-counts (D-06, T-129-06); grep gate enforces the excluded string == 0. Optional since:/until: %DateTime{} window bound as Ecto params, no interpolation (T-129-05/V5). Mirrors Events bucket_query/1 type+since/until shape as a flat count (not the private bucket_query/1 nor bucket_by/2). DB-backed counter tests in a sibling RepoCase module beside the pure policy tests.
- [Phase ?]: 130-03-SUMMARY.md

### Pending Todos

None yet.

### Blockers/Concerns

**Surfaced by the 2026-05-24 assessment (none block shipping; inputs to this milestone):**

- **Latent bug (now scoped to Phase 128):** `:invoice_payment_failed` email has no idempotency key → duplicate sends on each Stripe retry. Fixed as the DUN-04 must-fix in Phase 128 (thread `dunning-depth-milestone-prep`).
- **Adopter-proof gap (now scoped to Phase 132):** the v1.39 headline JTBD (entitlements/plan-gating) has ZERO usage in `examples/accrue_host`; metered + checkout-session also unexercised there; recovery crons (`DunningSweeper`, `DetectExpiringCards`) ship dormant/host-unwired. PROOF-03 (Phase 132) closes the entitlements demo; the default campaign wiring (DUN-10, Phase 130) closes the dormant dunning cron. See thread `adopter-proof-gaps`.
- **Chimeway watch-item (scoped to Phase 131):** its guide and code disagree on the public API surface; only `1.0.0` is on Hex while the local repo's `mix.exs` version string is stale at `0.1.0`. Verify against published 1.0.0 before coding the adapter.
- **Graduation-candidate lesson (cross-phase):** "a fully green suite can hide a feature dead on the production path" — caught at code review in BOTH Phase 126 (CR-01) and 127 (CR-01). Already in `126-LEARNINGS.md`/`127-LEARNINGS.md`; flagged here as a cross-phase graduation candidate (test the production entry point, not just the unit handler). Directly relevant to Phase 128 (the campaign must fire on the real webhook path, not just unit-level) and Phase 130 (the Fake-lane gate must exercise the real entry point).

Prior status — None open. (v1.39 blockers resolved at ship: Phase 124 confirmed `accrue/mix.exs` keeps `{:phoenix_live_view, "~> 1.1"}` non-optional with core runtime-LiveView-free; Phase 127 research completed — eventual-consistency window, out-of-order monotonic ordering, and the 10-entitlement inline cap all handled and documented.)

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| scope | Rich metered/tiered/range entitlement math (beyond seat counts) | out of scope v1.39 | 2026-05-22 |
| scope | Atomic seat enforcement / membership management | host-owned; documented recipe, not core API | 2026-05-22 |
| scope | Typed upstream Stripe Entitlements resources + live API reads | deferred to `lattice_stripe ≥ 1.2` | 2026-05-22 |
| scope | Multi-channel (SMS/push/in-app) dunning | out of scope v1.40; Chimeway engine unlocks later | 2026-05-24 |
| scope | Full recovered-revenue analytics dashboard | out of scope v1.40; ledger counter + telemetry only | 2026-05-24 |
| scope | Braintree native smart-retry overlay | out of scope v1.40; Accrue-clock-driven only unless sourced need | 2026-05-24 |
| strategy_non_goal | FIN-03 finance exports · MRR/ARR product · MoR processors · Hyperwallet | explicit standing non-goals | carried |
| process_gap | Dedicated `v1.37` milestone audit artifact | accepted prior-milestone gap | carried |
| quick_task | `260413-jri-bump-lattice-stripe-to-1-0-and-unblock-p` | stale pre-v1.39 leftover; not v1.39 scope | 2026-05-24 (close) |
| quick_task | `260414-l9q-automate-phase-3-human-verification-item` | stale pre-v1.39 leftover; not v1.39 scope | 2026-05-24 (close) |
| todo | `2026-05-24-ent10-advisory-cache-followups.md` (webhooks) | Phase 127 advisory-cache follow-ups (WR-05 StaleEntryError → DB upsert, IN-01..04); non-fail-open, documented in milestone audit | 2026-05-24 (close) |
| seed | `SEED-002-ecosystem-integrations` | partially actioned by v1.40 (#1 Chimeway adapter, Phase 131); remainder dormant | 2026-05-24 (close) |
| nyquist | Partial Nyquist coverage on Phases 123–125 (VALIDATION.md draft) | goals fully verified by VERIFICATION.md + test suites; close retroactively via `/gsd:validate-phase 123\|124\|125` | 2026-05-24 (close) |

## Session Continuity

Last session: 2026-05-25T14:30:26.689Z
Stopped at: Phase 130 context gathered
Resume file: None

## Operator Next Steps

- **v1.40 roadmap created** — Phases **128–132** cover DUN-01..10 + PROOF-03 (11/11 mapped). See [ROADMAP.md](ROADMAP.md) and [REQUIREMENTS.md](REQUIREMENTS.md).
- **Plan the first phase:** `/gsd:plan-phase 128` (Campaign Engine Foundation + Idempotency Must-Fix — DUN-01, DUN-02, DUN-04, DUN-05). Carry the three open questions into planning (campaign-key-to-first-transition, `last_step.after_days <= grace_days` validation, Chimeway 1.0.0 API verification for Phase 131).
- **Research flag:** Phase 131 (Chimeway adapter) is the only externally-coupled slice — consider `/gsd:plan-phase 131 --research-phase` to verify Chimeway's published 1.0.0 public API before coding. Phases 128–130 and 132 clone existing Accrue patterns and need no external research.
- Pre-resolved research lives in threads `dunning-depth-milestone-prep` and `adopter-proof-gaps` (load with `/gsd-thread <slug>`).
