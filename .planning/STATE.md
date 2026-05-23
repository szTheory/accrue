---
gsd_state_version: 1.0
milestone: v1.39
milestone_name: — Entitlements / Plan-Gating
status: verifying
stopped_at: Completed 126-01-PLAN.md
last_updated: "2026-05-23T21:21:38.454Z"
last_activity: 2026-05-23
progress:
  total_phases: 5
  completed_phases: 4
  total_plans: 17
  completed_plans: 17
  percent: 80
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-08)

**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain through v1.x.

**Current focus:** Phase 126 — admin-surface-docs-jtbd-spine

## Current Position

Phase: 127
Plan: Not started
Status: Phase complete — ready for verification
Last activity: 2026-05-23

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

- Total plans completed: 17 (v1.39)
- Average duration: —
- Total execution time: —

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 123 | 4 | - | - |
| Phase 124 P01 | 3min | 3 tasks | 5 files |
| Phase 124 P05 | 3min | 2 tasks | 5 files |
| Phase 124 P02 | 3min | 3 tasks | 3 files |
| Phase 124 P03 | 2min | 2 tasks | 4 files |
| Phase 124 P04 | 1min | 2 tasks | 2 files |
| Phase 124 P06 | 2min | 3 tasks | 3 files |
| 124 | 6 | - | - |
| Phase 125 P01 | 5min | 3 tasks | 7 files |
| Phase 125 P02 | 6min | 3 tasks | 7 files |
| Phase 125 P03 | 11min | 3 tasks | 11 files |
| 125 | 3 | - | - |
| Phase 126 P01 | 2min | 3 tasks | 3 files |
| Phase 126 P3 | 10min | 3 tasks | 7 files |
| Phase 126 P02 | 11min | 3 tasks | 6 files |
| Phase 126 P04 | 6min | 2 tasks | 2 files |
| 126 | 4 | - | - |

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
- [Phase ?]: [Phase 124 P01]: guard config (billable/on_deny/deny_path) lives under :entitlements, boot-validated free via validate_at_boot!; on_deny uses a custom validate_on_deny/1 (fail loud at boot, T-124-01) not type: :any
- [Phase ?]: [Phase 124 P01]: billable uses {:or, [nil, {:fun, 1}]} — NimbleOptions 1.1.1 supports both subtypes (verified in deps), no :any fallback needed; entitlements/0 surfaces the 3 guard-key defaults via Keyword.put_new (raw :plans read unchanged, resolver unaffected)
- [Phase ?]: [Phase 124 P01]: surface: is an additive opt on internal entitled?/3 + has_active_plan?/3 merged onto the existing :check span (:surface OTel-allowlisted atom+string); public Accrue facade delegates stay arity 2 (D-18, T-124-03 non-breaking, fail-closed property test green)
- [Phase ?]: [Phase 124 P05]: D-06 lockstep — reconciled CLAUDE.md/ROADMAP SC#3/PITFALLS#8/oban middleware/mix.exs comment from 'core LiveView-FREE / no LiveView present' to 'core stays LiveView-runtime-free'; SC#3 now points at the static merge-gate invariant (no always-compiled core module references the LiveView socket runtime). REQUIREMENTS ENT-07 already runtime-LiveView-free, untouched; mix.exs dep kept non-optional (D-02).
- [Phase ?]: [Phase 124 P02]: Accrue.Entitlements.Guard is the always-compiled LiveView-runtime-free shared decision engine both surfaces call — check/3 resolves billable once (per-guard opt > config global > current_scope.user/current_user probe), delegates fail-closed to entitled?/3 + has_active_plan?/3 with surface:, tiered on_deny (D-11), bounded no-PII ctx (D-12)
- [Phase ?]: [Phase 124 P02]: ctx.reason is coarse-by-design (:no_active_subscription if no billable resolved else :not_entitled); precise Phase 123 reason atom lives in the :check span, not ctx (one gate call, D-08/D-17). deny_plug/4 is pure-Plug opaque content-negotiated 403/redirect/status-body/fn/MFA (no Phoenix.Controller)
- [Phase 124]: [Phase 124 P03]: Accrue.Plug.RequireEntitlement (ENT-06) is a thin Plug adapter — init/1 raises ArgumentError on ambiguous feature:/plan: intent (T-124-08), call/2 delegates allow/deny to Accrue.Entitlements.Guard.check/3 + deny_plug/4; pure Plug, zero Phoenix.Controller coupling
- [Phase 124]: [Phase 124 P03]: require_feature/1 + require_plan/1 router macros are single-arg sugar expanding to plug(Accrue.Plug.RequireEntitlement, feature:/plan: …); status:/on_deny:/billable: overrides route through the explicit plug form (documented split)
- [Phase ?]: [Phase 124 P04]: Accrue.Live.Entitlements (ENT-07) is the cond-compiled on_mount/4 LiveView surface — {:require_feature,x}/{:require_plan,y} clauses delegate to Guard.check(:live,…) and only surface-translate the deny enum ({:redirect,path}->redirect; :forbidden/{status,body} degradation->put_flash+redirect(deny_path)); resolve-once billable-only assign_new(:accrue_billable). The ONLY core file with LiveView refs, all inside Code.ensure_loaded?(Phoenix.LiveView) (D-04); merge gate (Plan 06) excludes /accrue/live/
- [Phase ?]: [Phase 124 P06]: runtime-LiveView-free is now machine-enforced — scripts/ci/verify_core_liveview_runtime_free.sh (D-05) static grep gate scans accrue/lib for real socket-runtime refs (import/alias Phoenix.LiveView/Socket, def on_mount), ^[^#]* allowlists doc comments, grep -v /accrue/live/ exempts the cond-compiled on_mount guard; wired merge-blocking in docs-contracts-shift-left. SC#4 cross-surface fail-closed property drives Guard.check/3 on :plug AND :live: nil/garbage/raising/no-active-sub DENY, allow pinned to the sole affirmative-resolved-match path
- [Phase ?]: [Phase 125 P01]: ENT-08 provider-honesty surface — additive entitlements: capability group (support label 'all first-party'; the matrix's first CONVERGENCE lane 'local-identical' across fake/stripe/braintree, contrasting every existing divergence lane). Mirrored byte-for-byte across code labels + processor-support-matrix doc + verify_processor_support_matrix.sh drift gate (same-PR SSOT co-update, D-09). Negative divergence guard rejects any native/unsupported/bounded entitlements label; widened its regex to scan ALL provider columns (planner regex only checked the Fake column). provider_honesty_test proves LocalMap.resolve/2 is == across all three processors with zero processor calls (telemetry-never-fired guard).
- [Phase 125 P02]: ENT-09 lifecycle->entitlement SSOT — Subscription.entitling?/1 (composes active?/paused?/canceled?, never raw .status) + its Query.entitling/1 Ecto twin (active/trialing + is_nil(pause_collection) + is_nil(ended_at), NOT the legacy :paused OR-clause since active/1 already excludes :paused). LocalMap.fold_active/1 retargeted to Query.entitling/1, closing the D-11 paused fail-OPEN broken-access-control gap (status:active + pause_collection no longer grants). Query.active/1 left untouched (status-only semantics for dunning/projections). Pinned merge-blocking: 8-status truth table, predicate<->fragment twin invariant (per-row DB cross-check), end-to-end paused-gap closure. Truth table documented in lifecycle_semantics.md; :past_due row is a knob placeholder for Plan 03.
- [Phase ?]: [Phase 125 P03]: ENT-09 past-due grace knob — past_due_grace config key ({:or,[{:in,[:dunning,:none]},:pos_integer]}, default :none, boot-validated) + pure clock-driven PastDueGrace.within_grace?/2 (fail-closed on nil past_due_since) + Query.entitling_with_grace_candidates/1 (adds :past_due only, never :unpaid). LocalMap.fold_active/1 conditionally widens (zero query/compute when :none, D-18), gates per-row via Subscription.dunning_sweepable?/1 (Credo-clean), drops out-of-window rows, tags additive :grace_plans/:grace_features/:expired_grace_plans. entitled?/3 + has_active_plan?/3 surface additive :past_due_grace/:past_due_expired reasons on the existing :check span (no new event, no Ops.emit, D-19/D-21). Grace is always an affirmative resolved configured decision — never fail-open (D-15).
- [Phase 126]: [Phase 126 P01]: ENT-11 admin read seam — Accrue.Entitlements.Admin.resolve_for_customer/1 returns {resolved, unmapped_price_ids}; fold_for_customer/1 literally calls fold_active/1 (single SSOT fold, zero copy, T-126-02); unmapped list re-derived independently via catalog()/active_items() since the resolver discards unmapped under :deny (D-04 candidate iii).
- [Phase 126]: [Phase 126 P01]: no new public Accrue.* gate API (entitlements.ex unchanged, 4 public defs); two LocalMap helpers @doc false; one-way dependency admin -> billing verified (no reverse ref); fetch_entitled/2 (D-07) stays deferred; Admin hard-codes LocalMap (A2 limitation, documented in moduledoc).
- [Phase 126 P03]: ENT-12 docs — guides/entitlements.md (fail-closed-first, summarize-and-link to lifecycle_semantics.md + Processor.Capabilities; 3 needles: entitled?, Accrue.Plug.RequireEntitlement, [:accrue, :entitlements, :check]); JTBD ⛔→✅ flip in public jobs_to_be_done.md (now committed/tracked) + internal JTBD-FRONTIER.md (6 of 6 shipped); README + quickstart spine pointers; PROJECT.md 'gateway subscription core' parity fix clears verify_package_docs.sh:220 RED holdout. Pinned post-flip shipped marker for Plan 04 needle 5a (byte-for-byte): "entitlements ✅ shipped" (in the dated 2026-05-23 jobs_to_be_done.md Update-log line). Public file had no entitlements ⛔ table row — prose flip + new body section cover it; the ⛔→✅ table-row flips live only in JTBD-FRONTIER.md.
- [Phase ?]: [Phase 126 P02]: ENT-11 admin entitlements tab — read-only entitlements tab on CustomerLive (/customers/:id?tab=entitlements) renders resolved plans/features/quantities/grace first, then a Plan-mapping drift card badging unmapped price_ids amber with a self-explaining hint (D-02/D-03). Calls Accrue.Entitlements.Admin.resolve_for_customer/1 once via entitlements_view/1 (one-way admin->core), dodges the JsonViewer MapSet trap via entitlements_display_map/1, omits tab_counts :entitlements key (D-01, no badge). No new route/auth surface (T-126-04).
- [Phase ?]: [Phase 126 P02]: VERIFY-01 three-part copy contract held — Copy.Entitlements (13 @doc false fns incl. fail-closed error copy) -> 13 Copy.entitlements_* defdelegates -> 13 export-allowlist entries (export now 54 strings); zero hardcoded template strings. Rule 3 fix: synced accrue_admin/mix.lock to reconcile rendro ~> 0.3.0 so accrue_admin compiles.
- [Phase ?]: [Phase 126 P04]: ENT-12 SC#4 closed — verify_package_docs.sh entitlements-spine block (D-14): README link, 3 entitlements.md needles (entitled?/Accrue.Plug.RequireEntitlement/[:accrue, :entitlements, :check]), JTBD shipped marker 'entitlements ✅ shipped' (byte-for-byte, U+2705 literal), scoped flip-guard 'on the table** is **entitlements' (NOT 'headline gap'), quickstart pointer. No gateway-subscription-core line added (already :220; the subscribe/3 second masked needle was restored by orchestrator 5635d77).
- [Phase ?]: [Phase 126 P04]: D-15 seed co-update — package_docs_verifier_test.exs seeds entitlements.md + jobs_to_be_done.md so negative-drift fixtures don't fail 'No such file'. 3-command phase gate GREEN: verifier exit 0 + verifier-test 8/0 + mix docs builds entitlements.html (35KB). Full accrue seed-0 1462/0; accrue_admin 131/0; default-seed lone failure is the known-flaky PdfTest (no regression).

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

Last session: 2026-05-23T21:00:38.494Z
Stopped at: Completed 126-01-PLAN.md
Resume file: None
