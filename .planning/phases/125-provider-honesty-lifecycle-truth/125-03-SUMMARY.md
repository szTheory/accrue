---
phase: 125-provider-honesty-lifecycle-truth
plan: 03
subsystem: entitlements
tags: [entitlements, past-due, grace, dunning, config, telemetry, clock, fail-closed, ecto]

# Dependency graph
requires:
  - phase: 125-02-lifecycle-entitlement-truth-ssot
    provides: "Query.entitling/1 (:none base fetch), Subscription.entitling?/1, the retargeted LocalMap.fold_active/1, and the documented lifecycle truth table to footnote"
  - phase: 123-config-core-gate-api
    provides: ":entitlements config schema + LocalMap resolver + fail-closed gate API + OTel-allowlisted :reason metadata"
provides:
  - "Accrue.Config.past_due_grace/0 + the past_due_grace :entitlements schema key ({:or, [{:in, [:dunning, :none]}, :pos_integer]}, default :none, boot-validated)"
  - "Accrue.Entitlements.PastDueGrace.within_grace?/2 — pure, clock-driven, fail-closed grace-window check"
  - "Accrue.Billing.Query.entitling_with_grace_candidates/1 — :past_due-widened entitlement fragment (never :unpaid)"
  - "LocalMap.fold_active/1 conditional grace widening (zero query/compute when :none) + additive :grace_plans / :grace_features / :expired_grace_plans resolved fields"
  - "Additive :past_due_grace / :past_due_expired telemetry reasons on the existing [:accrue, :entitlements, :check] span"
  - "lifecycle_semantics.md past_due footnote documenting the knob (window, clock, reasons, :unpaid exclusion, zero-cost :none)"
affects: [126-admin-entitlements-view, entitlements, lifecycle-semantics, telemetry]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Cost-aware conditional query widening: common (:none) case keeps the lean fetch with zero change; the overlay widens + filters per-row in Elixir only when enabled"
    - "Affirmative-resolved-configured grace grant (never fail-open): default :none preserves the shipped fail-closed contract; grace is always an opt-in resolved decision"
    - "Additive/optional resolved-map signal fields drive distinct telemetry reasons without a new event or a re-query"

key-files:
  created:
    - accrue/lib/accrue/entitlements/past_due_grace.ex
    - accrue/test/accrue/entitlements/past_due_grace_test.exs
  modified:
    - accrue/lib/accrue/config.ex
    - accrue/lib/accrue/billing/query.ex
    - accrue/lib/accrue/entitlements/resolver.ex
    - accrue/lib/accrue/entitlements/resolver/local_map.ex
    - accrue/lib/accrue/entitlements.ex
    - accrue/guides/lifecycle_semantics.md
    - accrue/test/accrue/config_entitlements_test.exs
    - accrue/test/accrue/entitlements/local_map_test.exs
    - accrue/test/accrue/entitlements/resolver_test.exs

key-decisions:
  - "Grace is layered conditionally in the resolver: past_due_grace == :none keeps the exact Query.entitling/1 lean fetch (zero query/compute change, D-18); only when enabled does fold_active/1 widen to Query.entitling_with_grace_candidates/1 and run within_grace?/2 per :past_due row in Elixir"
  - "Per-row grace-candidate check routes through Subscription.dunning_sweepable?/1 (strict :past_due, Credo-clean) — never a raw sub.status == :past_due, which would trip NoRawStatusAccess in the non-exempt entitlements layer"
  - "Out-of-window :past_due rows are marked :expired (recorded in expired_grace_plans) rather than silently dropped, so Accrue.Entitlements can surface the distinct :past_due_expired deny reason vs the generic :no_active_subscription"
  - "grace_features is the EXCLUSIVE set (subtracts every feature a non-grace plan also grants, computed order-independently via an internal non_grace_features accumulator stripped before return) so a feature held by both a grace and a normal active plan reports :entitled, not :past_due_grace"
  - "The three grace fields on @type resolved are optional/additive — a resolver that does not implement the overlay may omit them, and Accrue.Entitlements treats absent grace fields as empty (no spurious grace reason)"

patterns-established:
  - "Knob default :none is the fail-closed resting position; enabling grace is a one-line opt-in (past_due_grace: :dunning) that reuses the existing dunning grace window"
  - "Additive telemetry reason atoms (no new event, no ops-ledger emission) carry the per-check decision detail; the :check span :reason is the single home for denied-vs-couldn't-check distinctions"

requirements-completed: [ENT-09]

# Metrics
duration: 11min
completed: 2026-05-23
---

# Phase 125 Plan 03: Past-Due Grace Knob Summary

**Delivered the fail-safe `past_due_grace` knob (ENT-09 SC#3/#4): a boot-validated `:entitlements` config key (default fail-closed `:none`), a pure clock-driven `PastDueGrace.within_grace?/2` helper, a cost-aware conditional fold-widening in `LocalMap` (zero query change when `:none`, `:past_due`-widen + per-row clock filter when enabled), additive `:grace_plans` / `:grace_features` / `:expired_grace_plans` resolved signals, the additive `:past_due_grace` / `:past_due_expired` telemetry reasons, and the truth-table footnote — so a `:past_due` subscription within a configured window grants entitlement as an affirmative, resolved decision while `:unpaid` never does and the default preserves the shipped fail-closed contract.**

## Performance

- **Duration:** ~11 min
- **Tasks:** 3
- **Files created:** 2 / **modified:** 9

## Accomplishments

- `Accrue.Config.past_due_grace/0` + the `past_due_grace` schema key under `:entitlements`: `type: {:or, [{:in, [:dunning, :none]}, :pos_integer]}`, `default: :none`. Boot-validated natively by the existing `validate_at_boot!/0` (no custom validator) — `:bogus`, `0`, and `-3` all raise at boot.
- `Accrue.Entitlements.PastDueGrace.within_grace?/2` — a pure, multi-head, fail-closed module: nil/non-DateTime `past_due_since` and non-positive `grace_days` return `false`; the in-window check is `since >= now - grace_days*86_400` via `Accrue.Clock` (the testable clock), mirroring the dunning sweeper's cutoff math inverted.
- `Accrue.Billing.Query.entitling_with_grace_candidates/1` — the grace-widen twin of `entitling/1`: status set `[:active, :trialing, :past_due]` (adds `:past_due` ONLY, never `:unpaid`), keeps both `is_nil(pause_collection)` and `is_nil(ended_at)` guards; the clock cutoff stays in Elixir.
- `LocalMap.fold_active/1` conditional widening: `:none` keeps the lean `{price_id, quantity}` select (zero query/compute change vs Plan 02); enabled widens, evaluates `within_grace?/2` per `:past_due` candidate (gated by `Subscription.dunning_sweepable?/1`), drops out-of-window rows before folding, and tags kept-via-grace plans/features. `:dunning` resolves to `Config.dunning()[:grace_days]`; integer N used directly.
- Additive resolved-map signals: `:grace_plans` (subset of `:active_plans`), `:grace_features` (exclusive — features no non-grace plan also grants), `:expired_grace_plans` (lapsed-window plans, for the distinct deny reason).
- `Accrue.Entitlements.entitled?/3` + `has_active_plan?/3` select `:past_due_grace` on a grace-decided grant and `:past_due_expired` on a lapsed-window deny (distinct from `:no_active_subscription`), reading the additive resolved fields — no re-query, no new event, no ops-ledger emission. Non-grace paths (`:entitled` / `:not_entitled` / `:no_active_subscription` / `:error`) are unchanged.
- `lifecycle_semantics.md` past_due footnote details the knob: window measured from `past_due_since` via `Accrue.Clock`, `:dunning`/N policies, `:past_due_grace` / `:past_due_expired` reasons, `:unpaid` exclusion, and the zero-cost `:none` default.

## Task Commits

1. **Task 1: past_due_grace config knob + pure within_grace?/2 helper** — `e666c35` (feat)
2. **Task 2: grace-widen fragment + conditional fold widening + :grace_plans** — `89aa139` (feat)
3. **Task 3: grace telemetry reasons + truth-table footnote + e2e coverage** — `c3e240b` (feat)

## Files Created/Modified

- `accrue/lib/accrue/config.ex` — `past_due_grace` schema key + `past_due_grace/0` accessor (`:none` default via `Keyword.get`)
- `accrue/lib/accrue/entitlements/past_due_grace.ex` (NEW) — pure clock-driven `within_grace?/2`, fail-closed heads
- `accrue/lib/accrue/billing/query.ex` — `entitling_with_grace_candidates/1` (`:past_due` widen, never `:unpaid`)
- `accrue/lib/accrue/entitlements/resolver.ex` — `@type resolved` gains optional `:grace_plans` / `:grace_features` / `:expired_grace_plans`; typedoc updated
- `accrue/lib/accrue/entitlements/resolver/local_map.ex` — conditional `active_items/1` (none vs grace lane), `grace_row/4`, `fold_item/5`, exclusive `grace_features` finalization; `@empty`/`@fold_seed` extended
- `accrue/lib/accrue/entitlements.ex` — `:past_due_grace` / `:past_due_expired` reason selection in `entitled?/3` + `has_active_plan?/3`; safe optional grace-field readers
- `accrue/guides/lifecycle_semantics.md` — detailed D-20 past_due footnote
- `accrue/test/accrue/config_entitlements_test.exs` — `past_due_grace` boot-validation cases (accepts `:none`/`:dunning`/N, rejects `:bogus`/`0`/`-3`)
- `accrue/test/accrue/entitlements/past_due_grace_test.exs` (NEW) — `within_grace?/2` window/fail-closed cases driven by the Fake clock
- `accrue/test/accrue/entitlements/local_map_test.exs` — grace-lane behavioral cases + end-to-end telemetry-reason captures
- `accrue/test/accrue/entitlements/resolver_test.exs` — `:grace_plans` additive-field presence on the default resolve

## Decisions Made

- **Cost-aware widening (D-18):** the `:none` lane is byte-for-byte the Plan 02 fetch — zero query/compute change for the common case. Only the enabled lane carries the richer select + per-row Elixir clock filter.
- **Credo-clean per-row check (Pitfall 4):** grace candidacy goes through `Subscription.dunning_sweepable?/1` (strict `:past_due`), not a raw `.status` comparison, which would trip `NoRawStatusAccess` in the non-exempt entitlements layer.
- **Distinct lapsed-window reason:** out-of-window `:past_due` rows are recorded in `:expired_grace_plans` (not silently dropped) so `:past_due_expired` is distinguishable from `:no_active_subscription`.
- **Exclusive `grace_features`:** computed order-independently via an internal `non_grace_features` accumulator (stripped before return) so a feature also granted by a normal active plan reports `:entitled`, not `:past_due_grace`.
- **Optional grace fields:** the additive resolved fields are `optional(...)` on `@type resolved`; `Accrue.Entitlements` reads them via `Map.get(..., MapSet.new())`, so alternate resolvers that omit them never produce a spurious grace reason.

## Deviations from Plan

### Auto-added Functionality

**1. [Rule 2 - Missing critical functionality] Added `:grace_features` + `:expired_grace_plans` resolved fields (beyond the planned `:grace_plans`)**
- **Found during:** Task 3
- **Issue:** The plan's must_haves require `reason: :past_due_grace` on a grace-decided *feature* grant and the distinct `reason: :past_due_expired` on a *lapsed-window* deny. The single `:grace_plans` field added in Task 2 is sufficient for the plan-level `has_active_plan?/3` reason, but `entitled?/3` works at the feature level (features are a UNION across plans), and a lapsed-window deny is indistinguishable from `:no_active_subscription` once out-of-window rows are dropped.
- **Fix:** Added two additive, optional resolved-map fields — `:grace_features` (the exclusive set of features granted only via grace) and `:expired_grace_plans` (plans whose window lapsed) — both populated only in the grace lane and treated as empty when absent. This is fully consistent with D-19 ("the resolved map gains a small additive field … so Accrue.Entitlements can select the reason"); D-19 named `:grace_plans` as an example, and these are the minimal additional signals required to satisfy the two reason must_haves without a re-query or a new event.
- **Files modified:** `accrue/lib/accrue/entitlements/resolver.ex`, `accrue/lib/accrue/entitlements/resolver/local_map.ex`, `accrue/lib/accrue/entitlements.ex`
- **Commit:** `c3e240b`

### Comment-tightening to satisfy a merge-blocking grep gate

The Task 3 acceptance criterion `grep -c 'Telemetry.Ops.emit' accrue/lib/accrue/entitlements.ex introduces no new call` initially registered 1 because an explanatory comment used the literal token `Telemetry.Ops.emit`. The comment was rephrased ("no ops-ledger emission") to keep the meaning without the literal token. No behavioral change — there is and was zero actual `Telemetry.Ops.emit` call (baseline `HEAD~2` count was 0; D-21 holds). Same posture as Plan 02's `Query.active` comment tightening.

## Issues Encountered

- The `past_due_subscription/1` factory does not set `past_due_since`, so the behavioral grace tests set it explicitly via a `Subscription.changeset/2` update — and one test asserts that a `:past_due` sub with a nil `past_due_since` is fail-closed (dropped) even with grace enabled, pinning the `PastDueGrace` nil head end-to-end.
- The acceptance behavior command `mix run -e ':none = Accrue.Config.past_due_grace()'` only boots cleanly under `MIX_ENV=test` (dev lacks the required `:repo` config the supervisor validates). Verified the default reads `:none` under `MIX_ENV=test mix run` (exit 0) — same environmental note Plan 02 recorded; no code impact.

## Verification

- Plan test set (`config_entitlements_test.exs` + `past_due_grace_test.exs` + `local_map_test.exs` + `resolver_test.exs` + `guard_telemetry_test.exs`, `--warnings-as-errors`): **72 tests, 0 failures**.
- `mix compile --warnings-as-errors` — clean.
- `mix credo --strict` — green (3502 mods/funs, no issues; no raw `.status` in the entitlements layer; `PastDueGrace` references `Accrue.Clock.utc_now`, not `DateTime.utc_now`).
- Full release-gate `mix test --warnings-as-errors` — **49 properties, 1456 tests, 6 failures**. The 6 are the pre-existing `Accrue.Docs.PackageDocsVerifierTest` baseline (PROJECT.md missing the "gateway subscription core" needle since 2026-05-08, unrelated to this plan); the flaky `Accrue.Billing.PdfTest` passed this run. **No new failures introduced.**
- Acceptance greps: `entitling_with_grace_candidates/1` has no `:unpaid`; `@type resolved` carries `grace_plans:`; `@empty` carries `grace_plans: MapSet.new()`; `fold_active/1` branches on `Accrue.Config.past_due_grace()` and references `PastDueGrace.within_grace?` + `Subscription.dunning_sweepable?`; no raw `status == :past_due` in `local_map.ex`; `entitlements.ex` references both reasons + `grace_plans` and has zero `Telemetry.Ops.emit`; the footnote mentions `past_due_since`, `Accrue.Clock`, and both reasons; the public `guides/entitlements.md` is untouched (it does not exist yet — Phase 126 owns it, D-07).

## Threat Model Outcomes

- **T-125-08 (config-union tampering):** mitigated. `{:or, [{:in, [:dunning, :none]}, :pos_integer]}` boot-validated by NimbleOptions via `validate_at_boot!/0` (fail-loud); tests assert `:bogus`/`0`/`-3` raise at boot.
- **T-125-09 (clock-skew / wall-clock dependence):** mitigated. `within_grace?/2` routes through `Accrue.Clock.utc_now/0` (no `DateTime.utc_now` reference); tests drive the Fake clock deterministically (including a clock-advance test that flips an in-window row to out-of-window).
- **T-125-10 (nil past_due_since fail-open):** mitigated. Explicit fail-closed head + catch-all `false`; pinned both as a unit test and end-to-end (nil-since `:past_due` sub denied even with grace enabled).
- **T-125-11 (grace mis-applied to :unpaid):** mitigated. Widen status set excludes `:unpaid`; per-row check is `dunning_sweepable?/1` (strict `:past_due`); end-to-end test asserts `:unpaid` never grants even with grace enabled and a fresh `past_due_since`.
- **T-125-12 (grace as fail-open):** accepted as designed. A grace grant is an affirmative, resolved, configured decision; default `:none` preserves the shipped fail-closed contract — documented in the truth-table footnote and the config `doc:` string.

## Next Phase Readiness

- Phase 126's admin entitlements view + public `guides/entitlements.md` can derive past-due access state and the `:past_due_grace` / `:past_due_expired` reasons from this plan's resolved signals + truth-table footnote.
- No blockers. ENT-09 is complete: lifecycle truth SSOT (Plan 02) + the fail-safe past-due grace knob (this plan), both merge-blocking-tested.

## Self-Check: PASSED

All 2 created files + 9 modified files exist on disk; all three task commits (`e666c35`, `89aa139`, `c3e240b`) are present in git history (verified below).

---
*Phase: 125-provider-honesty-lifecycle-truth*
*Completed: 2026-05-23*
