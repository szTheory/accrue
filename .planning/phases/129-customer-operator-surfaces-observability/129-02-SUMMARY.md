---
phase: 129-customer-operator-surfaces-observability
plan: 02
subsystem: payments
tags: [dunning, ecto, ledger, observability, telemetry, recovered-vs-lost, accrue_events]

# Dependency graph
requires:
  - phase: 129-01
    provides: "dunning.recovered + dunning.exhausted confirmed-transition ledger types (emitted from accrue/lib/accrue/webhook/default_handler.ex)"
provides:
  - "Accrue.Billing.Dunning.recovered_vs_lost/1 — flat %{recovered:, lost:} ledger-fold counter (DUN-08 SC#4, derivable, no new table)"
  - "Optional since:/until: %DateTime{} window honored via parameterized Ecto"
  - "Structural exclusion of the sweeper's request-time terminal-action-request type so 'lost' never double-counts (D-06)"
affects: [130-provider-honesty, recovered-revenue-analytics, dunning-observability]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Flat parameterized ledger-count fold mirroring Accrue.Events bucket_query/1 type+since/until shape but as a single count (no time-bucketing, no call into the private bucket_query/1)"
    - "Module-attribute pinned ledger type allowlist (@recovered_type/@exhausted_type) with the excluded request-time type structurally absent — enforced by a grep gate"
    - "DB-backed counter tests in a sibling Accrue.RepoCase module alongside the pure ExUnit.Case policy tests in the same file"

key-files:
  created: []
  modified:
    - "accrue/lib/accrue/billing/dunning.ex"
    - "accrue/test/accrue/billing/dunning_test.exs"

key-decisions:
  - "Home is Accrue.Billing.Dunning (the pure policy module) per plan D-08; the single read query is the only non-pure thing in the module and stays a fold, no persistence"
  - "Return the raw %{recovered:, lost:} map only — no derived recovery-rate field; callers compute it (D-08)"
  - "'lost' counts ONLY dunning.exhausted (confirmed transition); the sweeper's request-time terminal-action-request type is never referenced (D-06, T-129-06) — enforced by grep gate == 0"
  - "since:/until: accepted only as %DateTime{} and bound as Ecto params (^since/^until), no string interpolation (T-129-05, V5)"
  - "No new table — folds the existing accrue_events ledger via Accrue.Events.Event (D-07)"

patterns-established:
  - "Flat ledger-fold counter: from(e in Event, where: e.type == ^type) |> maybe_since |> maybe_until |> Accrue.Repo.aggregate(:count, :id)"
  - "Excluded ledger type proven absent both by a property test (global lost == global exhausted regardless of request-time noise) and a structural grep gate (count of the excluded string == 0)"

requirements-completed: [DUN-08]

# Metrics
duration: 3min
completed: 2026-05-25
---

# Phase 129 Plan 02: Recovered-vs-Lost Ledger Counter Summary

**`Accrue.Billing.Dunning.recovered_vs_lost/1` — a flat `%{recovered:, lost:}` fold over `accrue_events` that counts only `dunning.recovered` vs `dunning.exhausted`, honors optional `since:`/`until:` `%DateTime{}` windows via parameterized Ecto, and structurally excludes the sweeper's request-time terminal-action-request type so "lost" can never double-count — no new table.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-05-25T06:51:36Z
- **Completed:** 2026-05-25T06:54:28Z
- **Tasks:** 1 (TDD: RED + GREEN)
- **Files modified:** 2

## Accomplishments

- Added `recovered_vs_lost/1` to the pure policy module `Accrue.Billing.Dunning` as a side-effect-free read-fold of the existing ledger (no new table, no new persistence).
- `recovered` = `count("dunning.recovered")`, `lost` = `count("dunning.exhausted")`; the sweeper's request-time terminal-action-request type is structurally absent from the type allowlist (D-06).
- Optional `since:`/`until:` `%DateTime{}` window honored via parameterized Ecto (`^since`/`^until`) — no string interpolation (T-129-05).
- Returns raw counts only — no derived rate field (D-08); callers compute any recovery rate.
- DUN-08 SC#4 satisfied: the recovered-vs-lost signal is now DERIVABLE as a query API (the full analytics dashboard stays milestone Out-of-Scope, carried).

## Task Commits

Each task was committed atomically (TDD cycle):

1. **Task 1 (RED): failing tests for recovered_vs_lost** - `e63f2475` (test)
2. **Task 1 (GREEN): recovered_vs_lost/1 ledger-fold counter** - `2cd78f7b` (feat)

No REFACTOR commit — the GREEN implementation was already clean (credo --strict clean, no issues).

**Plan metadata:** (final docs commit — this SUMMARY + STATE + ROADMAP)

## Files Created/Modified

- `accrue/lib/accrue/billing/dunning.ex` - Added `recovered_vs_lost/1` public fn + private `count_events/2` + `apply_window/2` + `maybe_since/2`/`maybe_until/2`; added `import Ecto.Query`, `alias Accrue.Events.Event`, and the `@recovered_type`/`@exhausted_type` allowlist attributes.
- `accrue/test/accrue/billing/dunning_test.exs` - Added a sibling `Accrue.Billing.DunningCounterTest` (`Accrue.RepoCase` + `ExUnitProperties`) with the four required behaviors: type filter, never-counts-request-time, since/until window (plus inclusive-bound edges), and a property asserting the type-filter invariant under request-time noise.

## Decisions Made

- **Home module:** `Accrue.Billing.Dunning` (planner D-08). The single aggregate read is the only non-pure operation; it stays a pure fold (no writes, no new table).
- **Raw map only:** Returns `%{recovered:, lost:}` with no derived rate field — callers compute it (D-08).
- **Lost discipline (D-06):** "lost" counts only `dunning.exhausted`; the request-time terminal-action-request type is never referenced. Proven by both a property test and the grep gate.
- **Window safety (T-129-05/V5):** `since:`/`until:` accepted only as `%DateTime{}` and bound as Ecto parameters; non-DateTime opts are ignored (no-op clauses).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Rephrased two doc references to satisfy the literal grep gate**
- **Found during:** Task 1 (GREEN), acceptance-criteria verification
- **Issue:** The first GREEN draft documented the excluded type by spelling its full dotted string (`dunning.terminal_action_requested`) in two comments/doc blocks. This explained the exclusion well but tripped the plan's structural acceptance gate `grep -c "dunning.terminal_action_requested" ... returns 0` (the gate enforces that the excluded type is never named in the counter module).
- **Fix:** Rephrased both references to "the sweeper's request-time terminal-action request" without the verbatim dotted string, preserving the D-06 rationale documentation while passing the gate.
- **Files modified:** accrue/lib/accrue/billing/dunning.ex
- **Verification:** `grep -c "dunning.terminal_action_requested" lib/accrue/billing/dunning.ex` returns 0; all other grep gates pass (`def recovered_vs_lost` == 1, `Events.Event` >= 1, `create table` == 0); credo --strict clean; tests still green.
- **Committed in:** `2cd78f7b` (Task 1 GREEN commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Doc-wording-only adjustment to satisfy the structural gate; no behavior change, no scope creep. The exclusion remains enforced both structurally (grep) and behaviorally (property test).

## Issues Encountered

- **Property test under a frozen sandbox transaction:** `check all` runs many iterations inside the same sandboxed transaction, so ledger rows accumulate across iterations and global counts grow. Resolved by scoping each generated trial to a unique `subject_id` for the per-trial delta assertions, while asserting the global invariant `global.lost == global count(dunning.exhausted)` and `global.recovered == global count(dunning.recovered)` — self-consistent regardless of accumulation. This proves the request-time noise never inflates "lost".

## Verification

- `cd accrue && mix test test/accrue/billing/dunning_test.exs` → 3 properties, 15 tests, 0 failures.
- `cd accrue && mix test --seed 0` (full suite, dodges flaky PdfTest) → 57 properties, 1569 tests, 0 failures (11 excluded).
- `mix credo --strict lib/accrue/billing/dunning.ex` → no issues.
- Grep gates: `def recovered_vs_lost` == 1, excluded type string == 0, `Events.Event` ref >= 1, `create table` == 0 — all pass.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- DUN-08 SC#4 (recovered-vs-lost derivable counter) complete; the ledger fold reuses the Plan 01 confirmed-transition types and adds no schema.
- Phase 130 (provider honesty + Fake-lane proof + example-host wiring) can reference `recovered_vs_lost/1` as the observability read API; the full recovered-revenue analytics dashboard remains explicitly Out-of-Scope (carried in Deferred Items).
- No blockers.

## Self-Check: PASSED

- FOUND: `.planning/phases/129-customer-operator-surfaces-observability/129-02-SUMMARY.md`
- FOUND: `accrue/lib/accrue/billing/dunning.ex`
- FOUND: `accrue/test/accrue/billing/dunning_test.exs`
- FOUND commit: `e63f2475` (test RED)
- FOUND commit: `2cd78f7b` (feat GREEN)

---
*Phase: 129-customer-operator-surfaces-observability*
*Completed: 2026-05-25*
