---
phase: 128-campaign-engine-foundation-idempotency-must-fix
plan: 03
subsystem: payments
tags: [dunning, elixir, stream_data, property-testing, pure-function, oban-seam]

# Dependency graph
requires:
  - phase: 128-01
    provides: "dunning campaign config step contract [after_days:, key:, template:] (strictly-increasing, unique after_days)"
provides:
  - "Pure Accrue.Dunning.Campaign.next_step/3 resolver: (steps, campaign_started_at, now) -> {:next, step, schedule_in} | :done"
  - "Property + edge-case test suite pinning the resolver math (DUN-02)"
  - "Phase-131 Accrue.Dunning.Engine extraction seam (pure, side-effect-free)"
affects: [128-05 DunningStep worker (consumes next_step/3), 131 Dunning.Engine behaviour extraction, 130 Fake-lane clock-advance proof]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pure-policy module convention (Accrue.Billing.Dunning shape): moduledoc no-side-effects contract, @type up top, @spec'd entry, nil/empty boundary clause"
    - "Resolver takes now + campaign_started_at as arguments (never reads a clock) — keeps property test async:true sandbox-free and the Phase-131 engine seam clean"

key-files:
  created:
    - accrue/lib/accrue/dunning/campaign.ex
    - accrue/test/property/dunning_campaign_property_test.exs
  modified: []

key-decisions:
  - "Return contract: {:next, step, schedule_in_seconds} for a pending step, :done for terminal/empty (planner discretion per <interfaces>; documented in @spec/@doc)"
  - "Boundary is >= (not strict >): a step whose after_days boundary has not yet PASSED is still pending. This is what makes day-0 return the first step immediately with schedule_in 0 (must_have truth #2). RED tests initially encoded strict > and were reconciled to >= during GREEN."
  - "schedule_in clamped to max(0, after_days_seconds - elapsed) so clock skew / stale anchor can never produce a negative delay (T-128-05 mitigation; Oban rejects negative delays)"
  - "Module is asserted side-effect-free via grep gate (zero Repo./Oban./Accrue.Clock references) — purity is machine-checkable (T-128-06)"

patterns-established:
  - "Pure dunning resolver: clone connect_platform_fee_property_test.exs structure (named defp *_gen generators, check all max_runs: 200) + Accrue.Billing.Dunning module shape for the implementation"
  - "Independent oracle in property tests (expected_next/2 recomputes the contract separately from the implementation)"

requirements-completed: [DUN-02]

# Metrics
duration: 3min
completed: 2026-05-24
---

# Phase 128 Plan 03: Pure Dunning Campaign Step Resolver Summary

**Side-effect-free `Accrue.Dunning.Campaign.next_step/3` resolver that maps `(steps, campaign_started_at, now)` to the next dunning step plus a non-negative `schedule_in` delay (or `:done`), property-proven over ordered step lists with day-0, at-boundary, single-step, past-last-step, and empty-list edge cases.**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-05-24T17:48:45Z
- **Completed:** 2026-05-24T17:51:29Z
- **Tasks:** 2 (TDD: RED + GREEN)
- **Files modified:** 2 (both created)

## Accomplishments

- Pure resolver `Accrue.Dunning.Campaign.next_step/3` — no DB, no Oban, no Stripe, no clock; both `now` and `campaign_started_at` are passed in, keeping the function total and the Phase-131 engine extraction a clean seam.
- 4 stream_data properties (day-0 immediate, schedule_in non-negative + equals `max(0, next_boundary - elapsed)`, past-last-step → `:done`, determinism) + 4 edge-case unit tests (empty list, single-step, at-exact-boundary, default `[0,5,12]` journey), all green.
- Mirrors the `Accrue.Billing.Dunning` pure-policy SHAPE: moduledoc no-side-effects contract, `@type` declarations, `@spec`'d entry, nil/empty-tolerant boundary clause.
- `schedule_in` clamped to `max(0, ...)` (T-128-05) and purity asserted by grep gate returning 0 (T-128-06).

## Task Commits

Each task was committed atomically (TDD RED → GREEN):

1. **Task 1: RED — property + unit tests for the pure resolver (DUN-02)** - `d05e3ea` (test)
2. **Task 2: GREEN — implement the pure Accrue.Dunning.Campaign resolver (DUN-02, D-11)** - `e934775` (feat)

**Plan metadata:** (this commit) (docs: complete plan)

_Note: the GREEN commit also reconciled the property-test boundary expectations to the `>=` contract — see Deviations._

## Files Created/Modified

- `accrue/lib/accrue/dunning/campaign.ex` - Pure step resolver. `next_step/3` computes `elapsed = DateTime.diff(now, campaign_started_at, :second)`, finds the first step whose `after_days * 86_400 >= elapsed` (pending), and returns `{:next, step, max(0, after_days_seconds - elapsed)}`, or `:done` when exhausted/empty.
- `accrue/test/property/dunning_campaign_property_test.exs` - stream_data property tests + edge-case unit tests pinning the contract (cloned from `connect_platform_fee_property_test.exs`; `use ExUnit.Case, async: true` + `use ExUnitProperties`).

## Decisions Made

- **Return shape `{:next, step, schedule_in} | :done`** — chosen over `nil` terminal for an explicit, pattern-matchable contract the Plan-05 worker can dispatch on. The `<interfaces>` block left exact tuple shape and day-0 semantics to planner discretion; both are documented in the `@spec`/`@doc`.
- **`>=` boundary (pending iff boundary not yet passed)** — directly forced by must_have truth #2 ("Day-0 zero-elapsed returns the first step immediately"). With a `after_days: 0` first step at `elapsed == 0`, `0 >= 0` holds, so the resolver returns it with `schedule_in == 0`. The `<interfaces>` sketch used strict `>`, but that contradicts the day-0 must_have; the must_have is the authoritative contract and the strict-`>` sketch was the discretionary part.
- **Clock injected, never read** — the worker (Plan 05) reads the wall clock once and passes the timestamps in. This is the single design choice that keeps the property test sandbox-free (`async: true`) and the Phase-131 `Accrue.Dunning.Engine` extraction clean.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] RED tests encoded strict `>` boundary; reconciled to `>=` to satisfy the day-0 must_have**
- **Found during:** Task 2 (GREEN) — the day-0 property failed because a `after_days: 0` step at `elapsed == 0` was skipped under strict `>`, contradicting must_have truth #2 ("Day-0 returns the first step immediately").
- **Issue:** The Task-1 (RED) oracle (`expected_next/2`), the `at-exact-boundary` unit test, and the implementation's boundary predicate all assumed strict `>`. The frontmatter must_have requires day-0 to return the first step immediately, which forces a `>=` boundary.
- **Fix:** Implemented `pending_step?` with `>= elapsed`; updated the test oracle to `>=`; rewrote the `at-exact-boundary` test to assert the at-boundary step stays pending (`schedule_in 0`) and only a strictly-past `elapsed` advances. The must_have (not the discretionary `<interfaces>` sketch) is authoritative for day-0 semantics.
- **Files modified:** `accrue/lib/accrue/dunning/campaign.ex`, `accrue/test/property/dunning_campaign_property_test.exs`
- **Verification:** `mix test test/property/dunning_campaign_property_test.exs --seed 0` → 4 properties, 4 tests, 0 failures.
- **Committed in:** `e934775` (Task 2 / GREEN commit)

**2. [Rule 3 - Blocking] Moduledoc prose tripped the purity grep gate**
- **Found during:** Task 2 acceptance-criteria check — `grep -c "Accrue.Clock\|Repo\.\|Oban\." lib/accrue/dunning/campaign.ex` returned 1 (required 0).
- **Issue:** The moduledoc explained the worker "reads the clock once via `Accrue.Clock.utc_now/0`" — a documentation mention, not a call. The acceptance gate (which a later-phase verifier re-runs) is a literal grep that must return 0.
- **Fix:** Rephrased the moduledoc to describe the clock injection without the literal `Accrue.Clock.` / `Repo.` / `Oban.` token patterns ("reads the wall clock once", "no job queue"), preserving the accurate intent. The module remains genuinely pure (no side-effecting calls).
- **Files modified:** `accrue/lib/accrue/dunning/campaign.ex`
- **Verification:** purity grep now returns 0; `grep -ni "no side effects"` still matches; `mix compile --warnings-as-errors` exit 0; `mix credo --strict` no issues.
- **Committed in:** `e934775` (Task 2 / GREEN commit)

---

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking)
**Impact on plan:** Both auto-fixes necessary for contract correctness (day-0 must_have) and the machine-checkable purity gate. No scope creep — the module remains exactly the pure resolver specified, no `Accrue.Dunning.Engine` behaviour introduced (correctly deferred to Phase 131).

## Issues Encountered

- The `<interfaces>` block's strict-`>` boundary sketch conflicted with must_have truth #2's day-0-immediate requirement. Resolved by treating the must_have as authoritative (day-0 semantics were explicitly "planner's discretion" in `<interfaces>`) and adopting the `>=` boundary, then reconciling the test expectations. Documented as Deviation #1.

## Known Stubs

None. The `:done` terminal is the intended exhaustion signal, not a stub. No hardcoded empty UI values, placeholder text, or TODO/FIXME markers.

## User Setup Required

None - pure domain module, no external service configuration required.

## Next Phase Readiness

- `Accrue.Dunning.Campaign.next_step/3` is ready for the Plan-05 `Accrue.Workers.DunningStep` worker to call after each delivery (consumes the `{:next, step, schedule_in} | :done` contract; the worker passes `Accrue.Clock.utc_now/0` as `now` and the ISO8601-decoded `campaign_started_at`).
- Engine seam is clean for Phase 131 (pure, side-effect-free, no behaviour introduced here per the phase-boundary decision).
- No blockers.

## Self-Check: PASSED

- FOUND: `accrue/lib/accrue/dunning/campaign.ex`
- FOUND: `accrue/test/property/dunning_campaign_property_test.exs`
- FOUND: `.planning/phases/128-campaign-engine-foundation-idempotency-must-fix/128-03-SUMMARY.md`
- FOUND commit `d05e3ea` (test/RED)
- FOUND commit `e934775` (feat/GREEN)

---
*Phase: 128-campaign-engine-foundation-idempotency-must-fix*
*Completed: 2026-05-24*
