---
phase: 123-config-core-gate-api-foundation
plan: 03
subsystem: entitlements
tags: [entitlements, plan-gating, telemetry, ecto-read, mapset, fail-closed, behaviour, dispatch]

# Dependency graph
requires:
  - phase: 123-01
    provides: ":entitlements NimbleOptions @schema (plans/resolver/unmapped_action) + Accrue.Config.entitlements/0 runtime accessor + boot price_id-collision guard"
  - phase: billing-core
    provides: "Accrue.Billing.Query.active/1, Subscription.active?/1, SubscriptionItem (price_id/quantity), Customer (owner_type/owner_id), Accrue.Billable.__accrue__/1, Accrue.Telemetry.span/3"
provides:
  - "%Accrue.Entitlements.Plan{plan_id, features: MapSet, quantities: map} pure value struct (no Ecto)"
  - "Accrue.Entitlements.Resolver @behaviour resolve/2 (returns active_plans SET membership contract) + __impl__/0 runtime dispatch (default LocalMap)"
  - "Accrue.Entitlements.Resolver.LocalMap default resolver: read-only customer + active-subs fold, zero processor calls"
  - "Accrue.Entitlements context: entitled?/2, has_active_plan?/2 (set-membership), features_for/1, entitlement_quantity/2 — fail-closed, inline [:accrue, :entitlements, :check] span, zero ledger writes"
affects: [123-04, 124-plug-guard, 124-liveview-guard, 125-resolver-behaviour, 126-admin-entitlements, entitlements]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Fail-closed gate: try/rescue/catch collapses error/exception/throw/exit to false/[]/0; {:ok, affirmative-match} is the SOLE true path"
    - "has_active_plan?/2 tests MapSet.member? on the active_plans SET (membership source of truth), never the representative :plan field — multi-active-plan correct"
    - "Resolver carries active_plans (SET of ALL active plan atoms) alongside a representative :plan; features/quantities UNION across active subs"
    - "Decision + D-18 reason/result computed BEFORE opening the span (span/3 reuses one base_metadata for :start and :stop)"
    - "Read-only customer lookup clones the private fetch_customer/2 query (owner_type, owner_id, limit:1) — never the effectful get-or-create path, never a processor call"

key-files:
  created:
    - accrue/lib/accrue/entitlements/plan.ex
    - accrue/lib/accrue/entitlements/resolver.ex
    - accrue/lib/accrue/entitlements/resolver/local_map.ex
    - accrue/lib/accrue/entitlements.ex
    - accrue/test/accrue/entitlements/resolver_test.exs
    - accrue/test/accrue/entitlements/local_map_test.exs
    - accrue/test/accrue/entitlements_test.exs
  modified: []

key-decisions:
  - "active_plans SET is the has_active_plan?/2 membership source of truth; :plan is representative/display only (mitigates T-123-07b multi-active-plan false negative)"
  - "Unmapped active price_id under :deny is dropped from active_plans + features (fail-closed); under :raise the resolver raises and the context's try/rescue collapses to fail-closed"
  - "resolver_tag :local_map for the default resolver; non-default resolver derives a snake-cased module-tail tag — telemetry carries a tag, not the module"

patterns-established:
  - "LocalMap.resolve/2 read-only fold: Query.active/1 + items join -> {price_id, quantity}; reverse-index price_id->plan from Config.entitlements/0; fold active_plans/features/quantities min(cap,qty)"
  - "Context inline span with D-18 metadata map %{feature, result, resolver, reason, subject_type, subject_id}; subject_id = internal id only (no PII); zero accrue_events writes"

requirements-completed: [ENT-02, ENT-03, ENT-04, ENT-05]

# Metrics
duration: 5min
completed: 2026-05-22
---

# Phase 123 Plan 03: Core Entitlements Gate API Summary

**`Accrue.Entitlements` context tree — `%Plan{}` value struct + `Resolver` behaviour, the read-only `LocalMap` resolver that folds active subscription state into an `active_plans` SET / features UNION / merged quantities, and four fail-closed gate functions (`entitled?`, `has_active_plan?`, `features_for`, `entitlement_quantity`) wrapped in inline `[:accrue, :entitlements, :check]` telemetry with zero audit-ledger writes.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-22T22:39:13Z
- **Completed:** 2026-05-22T22:44:23Z
- **Tasks:** 3 (all TDD: RED → GREEN)
- **Files modified:** 7 (4 source created, 3 test created)

## Accomplishments

- **Contracts (ENT-02..05 substrate):** `%Accrue.Entitlements.Plan{}` pure value struct (no Ecto) and the `Accrue.Entitlements.Resolver` behaviour whose `resolve/2` returns the load-bearing `active_plans` SET (the membership source of truth) plus `plan`/`features`/`quantities`. `Resolver.__impl__/0` runtime dispatch defaults to `LocalMap` and honors a configured override.
- **Default resolver (`LocalMap`):** resolves entitlements from local subscription state with **zero processor calls** — read-only `(owner_type, owner_id)` customer lookup (clone of the private `fetch_customer/2`, never the effectful get-or-create path), `Query.active/1` + items join (never raw `.status`), folding active items into the `active_plans` SET, features UNION, and `min(cap, quantity)` quantities. Multi-active-plan correct: one billable with two active subs on two mapped plans carries BOTH plan atoms and the union of their features.
- **Public gate API (4 fns):** `entitled?/2`, `has_active_plan?/2` (set-membership; accepts atom or `price_id` string), `features_for/1` (sorted, deduped, plain `[atom]` — never a `MapSet`), `entitlement_quantity/2` (`min(cap, qty)` / fail-closed `0`). All wrapped in `try/rescue/catch` so error/exception/throw/exit collapse to `false`/`[]`/`0`.
- **Observability + ledger split (ENT-05):** each check emits `[:accrue, :entitlements, :check, :start|:stop|:exception]` with D-18 metadata `%{feature, result, resolver: :local_map, reason, subject_type, subject_id}` (PII-excluded; `subject_id` = internal id only); unmapped-plan deny carries `reason: :unmapped_plan`; a batch of checks writes **zero** `accrue_events` rows (asserted by row-count).
- **32 tests green** across the three plan test files; `mix compile --warnings-as-errors` clean; `credo --strict` clean on all four source files; D-14 one-way dependency invariant holds (no `Accrue.Entitlements` back-reference under `lib/accrue/billing/`).

## Task Commits

Each task was committed atomically (TDD RED → GREEN):

1. **Task 1: Contracts — Plan struct + Resolver behaviour + dispatch**
   - RED `b10174d` (test) → GREEN `5c78a99` (feat)
2. **Task 2: LocalMap resolver — read-only customer + active-subs fold**
   - RED `f557ab6` (test) → GREEN `3833423` (feat)
3. **Task 3: Public context — 4 fail-closed gate functions with inline telemetry**
   - RED `a6a8a2b` (test) → GREEN `29a2715` (feat)

_No REFACTOR commits were needed — GREEN implementations were already clean (credo --strict clean)._

## Files Created/Modified

- `accrue/lib/accrue/entitlements/plan.ex` — `%Accrue.Entitlements.Plan{plan_id, features: MapSet, quantities: map}` pure value struct (no `use Ecto.Schema`).
- `accrue/lib/accrue/entitlements/resolver.ex` — `@behaviour` with `@callback resolve/2` (active_plans SET membership contract documented) + `__impl__/0` runtime dispatch (`:entitlements` → `:resolver`, default `LocalMap`).
- `accrue/lib/accrue/entitlements/resolver/local_map.ex` — default resolver: read-only customer lookup + `Query.active/1` items fold → `%{plan, active_plans: MapSet, features: MapSet, quantities}`; `:deny`/`:raise` unmapped handling.
- `accrue/lib/accrue/entitlements.ex` — public context with the four fail-closed gate functions, inline `[:accrue, :entitlements, :check]` spans, D-18 metadata, zero ledger writes.
- `accrue/test/accrue/entitlements/resolver_test.exs` — `__impl__/0` default + override contract tests.
- `accrue/test/accrue/entitlements/local_map_test.exs` — read-path: single/multi-active-plan, min(cap,qty)/no-cap, trialing/canceled, unmapped :deny/:raise, no-customer/no-sub/nil/wrong-shape.
- `accrue/test/accrue/entitlements_test.exs` — 4-fn happy/edge, multi-active-plan, telemetry D-18 + PII assertion + `:unmapped_plan` reason, ledger-boundary row count.

## Decisions Made

- **`active_plans` SET is the membership source of truth.** `has_active_plan?/2` tests `MapSet.member?(resolved.active_plans, plan_atom)`, never the representative `:plan`. A single representative would wrongly answer `false` for a billable holding two active subs on two different mapped plans (T-123-07b). This keeps `has_active_plan?/2` consistent with the UNION semantics of `entitled?/2` and `features_for/1`.
- **Telemetry carries a resolver *tag*, not the module.** `:local_map` for the default; a non-default resolver derives a snake-cased module-tail atom — keeps the metadata stable and PII-free.
- **`reason` taxonomy applied uniformly:** `:entitled` (affirmative match), `:not_entitled` (active subs but no match), `:no_active_subscription` (empty active set / no customer / nil), `:unmapped_plan` (price_id string that reverse-indexes to nothing), `:error` (resolver error/exception). `result` is the boolean/scalar projection.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Test billable `billable_type` mismatch with factory `owner_type`**
- **Found during:** Task 2 (LocalMap read-path tests, GREEN)
- **Issue:** The test billable struct used `use Accrue.Billable` without a `billable_type` override, so its `__accrue__(:billable_type)` defaulted to the module-tail `"TestUser"`. The factory seeds customers with `owner_type: "User"`, so the resolver's `(owner_type, owner_id)` lookup found no customer and every active-plan assertion failed even though the data was correct.
- **Fix:** Set `use Accrue.Billable, billable_type: "User"` on the test billable structs (both `local_map_test.exs` and `entitlements_test.exs`) so the lookup resolves the factory-seeded customer.
- **Files modified:** accrue/test/accrue/entitlements/local_map_test.exs, accrue/test/accrue/entitlements_test.exs
- **Verification:** All 12 LocalMap tests + 17 context tests green after the fix.
- **Committed in:** `3833423` (Task 2 GREEN) and `a6a8a2b` (Task 3 RED, written correctly from the start)

**2. [Rule 3 - Blocking] Acceptance-criteria grep literals vs. idiomatic code shape**
- **Found during:** Tasks 1 and 3 (post-GREEN acceptance-grep verification)
- **Issue:** Two acceptance criteria are literal greps: `Application.get_env(:accrue, :entitlements` (single-line) in `resolver.ex`, and `Telemetry.span(\[:accrue, :entitlements, :check\]` (inline event literal) in `entitlements.ex`. The first draft used the pipe idiom (`:accrue |> Application.get_env(...)`) and a `@event` module attribute for the span event, so both literal greps returned 0.
- **Fix:** Reshaped `__impl__/0` to start the pipe at `Application.get_env(:accrue, :entitlements, [])`, and inlined the `[:accrue, :entitlements, :check]` event literal directly in the `span/3` call (dropped the `@event` attribute). Semantics unchanged.
- **Files modified:** accrue/lib/accrue/entitlements/resolver.ex, accrue/lib/accrue/entitlements.ex
- **Verification:** Both literal greps now return 1; all tests still green; compile + credo --strict clean.
- **Committed in:** `5c78a99` (Task 1 GREEN), `29a2715` (Task 3 GREEN)

**3. [Rule 3 - Blocking] Forbidden-pattern grep matched moduledoc comments in `local_map.ex`**
- **Found during:** Task 2 (post-GREEN acceptance-grep verification)
- **Issue:** The acceptance gate `grep -c "Billing.customer\b\|Accrue.Processor\|s.status"` must return 0, but the moduledoc/comments referenced `Accrue.Billing.customer/1` and `.status` while *explaining* what the resolver must NOT call. The intent was correct (those calls never appear in code), but the literal gate would fail.
- **Fix:** Reworded the moduledoc and inline comments to describe the forbidden paths without the literal tokens ("effectful get-or-create customer path" instead of `Accrue.Billing.customer/1`).
- **Files modified:** accrue/lib/accrue/entitlements/resolver/local_map.ex
- **Verification:** The forbidden-pattern grep returns 0; `Query.active`, `owner_type`/`owner_id`, and `active_plans` greps all pass; tests green.
- **Committed in:** `3833423` (Task 2 GREEN)

---

**Total deviations:** 3 auto-fixed (all Rule 3 - blocking)
**Impact on plan:** All three were test/wording adjustments to make the work satisfy the plan's literal acceptance gates with identical runtime semantics. The public surface, contracts, and behavior match the plan exactly. No scope creep; no architectural change.

## Issues Encountered

- The factory's `active_subscription/1` mints a fresh random `owner_id` per call, so a second factory call would create a distinct customer. The multi-active-plan fixtures correctly build the second active sub via `Accrue.Billing.subscribe(result.customer, "price_p2")` on the SAME customer (per the plan's explicit guidance), which the resolver's single-customer `limit:1` lookup then folds together.

## Threat Surface

- **T-123-06 (EoP — fail-open on error) mitigated:** `{:ok, affirmative-match}` is the SOLE true path; `try/rescue/catch` collapses errors/exceptions/throws/exits to `false`/`[]`/`0`. Pinned by the raising-resolver test (full property test lands in Plan 04, D-10).
- **T-123-07 (EoP — unmapped price_id silently allows) mitigated:** unmapped active price_id under `:deny` is dropped from `active_plans`+`features`; `reason: :unmapped_plan` set in `:stop` metadata; `:raise` collapses via the context's `try/rescue`.
- **T-123-07b (multi-active-plan false negative) mitigated:** resolver carries `active_plans`; `has_active_plan?/2` tests `MapSet.member?` on that set — true for both plans (read-path + context tests assert this).
- **T-123-08 (Tampering — ledger flood) mitigated:** zero `Accrue.Events.record/1`/`record_multi/3` calls; ledger-boundary test asserts the `accrue_events` row count is unchanged across a batch of checks.
- **T-123-09 (DoS — processor on the gate path) mitigated:** local-only resolution; never the effectful customer path or any `Accrue.Processor.*` (grep-asserted absent).
- **T-123-10 (Info Disclosure — PII in telemetry) mitigated:** `subject_id` is the internal id only; test asserts metadata excludes `:email`/`:name`.
- **T-123-11 (Tampering — raw `.status`) mitigated:** reuse `Query.active/1`; `s.status` grep-asserted absent in `local_map.ex`.
- No threat surface introduced beyond the plan's `<threat_model>`.

## Known Stubs

None. All four gate functions are fully wired to the `LocalMap` resolver and exercised end-to-end against factory-seeded subscription state.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- **Plan 04** can layer the fail-closed property test (D-10) and the public `Accrue.*` `defdelegate` shims plus the final D-14 gate on top of this context.
- **Phase 124** (Plug + LiveView guards) consumes `Accrue.Entitlements.has_active_plan?/2` and `entitled?/2` directly.
- **Phase 125** (resolver behaviour + capability matrix) extends `Accrue.Entitlements.Resolver` with the `capabilities/0` callback (intentionally absent here per D-12).
- No migrations, no Ecto schema, no external dependency added.

## Self-Check: PASSED

- FOUND: accrue/lib/accrue/entitlements/plan.ex
- FOUND: accrue/lib/accrue/entitlements/resolver.ex
- FOUND: accrue/lib/accrue/entitlements/resolver/local_map.ex
- FOUND: accrue/lib/accrue/entitlements.ex
- FOUND: accrue/test/accrue/entitlements/resolver_test.exs
- FOUND: accrue/test/accrue/entitlements/local_map_test.exs
- FOUND: accrue/test/accrue/entitlements_test.exs
- FOUND commit: b10174d (Task 1 RED), 5c78a99 (Task 1 GREEN)
- FOUND commit: f557ab6 (Task 2 RED), 3833423 (Task 2 GREEN)
- FOUND commit: a6a8a2b (Task 3 RED), 29a2715 (Task 3 GREEN)

---
*Phase: 123-config-core-gate-api-foundation*
*Completed: 2026-05-22*
