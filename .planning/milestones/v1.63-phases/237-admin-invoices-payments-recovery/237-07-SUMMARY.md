---
phase: 237-admin-invoices-payments-recovery
plan: "07"
subsystem: analytics
tags: [elixir, phoenix-liveview, recovery, currency, owner-scope]
requires:
  - phase: 234
    provides: Existing owner-scoped recovery dashboard, current billing reads, and related-record navigation
  - phase: 237
    provides: Raw recovery event and owner/window fixtures from plan 03
provides:
  - Currency-honest recovery aggregates that preserve unavailable amounts and currencies
  - Scoped asynchronous loading and recoverable read-error states for recovery analytics
  - Distinct current subscription status and historical failure reason
  - Validated owner/window return navigation between recovery and campaigns
affects: [phase-237, recovery-dashboard, ADM-06]
actuals:
  tokens: 4985
  tasks: 2
  commits: 3
plan_head_before: c40cb7377773a19e554472c7ae6fc09bc22ce489
plan_head_after: dd714cf369fcc490ef38fa6ccbee69f9abcfb648
tech-stack:
  added: []
  patterns:
    - Same-name LiveView async tasks keep the latest URL-selected recovery scope authoritative
    - Missing currency and amount facts remain unavailable instead of becoming USD or zero
    - Return paths are rebuilt under the current authorized owner scope
key-files:
  created: []
  modified:
    - accrue/lib/accrue/analytics/dunning.ex
    - accrue_admin/lib/accrue_admin/queries/dunning.ex
    - accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex
    - accrue_admin/lib/accrue_admin/components/at_risk_table.ex
    - accrue_admin/lib/accrue_admin/scoped_path.ex
    - accrue_admin/lib/accrue_admin/live/analytics/campaign_live.ex
    - accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs
    - accrue_admin/test/accrue_admin/components/at_risk_table_test.exs
    - accrue_admin/test/accrue_admin/live/analytics/campaign_live_test.exs
key-decisions:
  - "Do not synthesize USD or zero totals when recovery currency or amount evidence is absent."
  - "Show current subscription status independently from historical payment failure reasons."
  - "Keep recovery reads asynchronous and scoped; only the latest selected window can populate results."
  - "Validate return routes and reconstruct them with the currently authorized owner scope."
patterns-established:
  - "Unavailable financial evidence stays nil through aggregation and presentation."
  - "Recovery detail links preserve valid window context and derive owner authority server-side."
requirements-completed: []
coverage:
  - id: D1
    description: "Recovery amounts retain exact observed currency facts and do not invent USD or zero values."
    requirement: ADM-06
    verification:
      - kind: integration
        ref: "cd accrue_admin && mix test test/accrue_admin/components/at_risk_table_test.exs test/accrue_admin/live/analytics/campaign_live_test.exs test/accrue_admin/live/analytics/recovery_live_test.exs --seed 0"
        status: pass
      - kind: unit
        ref: "cd accrue_admin && mix test --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D2
    description: "Current subscription status is presented separately from immutable historical failure evidence."
    requirement: ADM-06
    verification:
      - kind: integration
        ref: "cd accrue_admin && mix test test/accrue_admin/components/at_risk_table_test.exs test/accrue_admin/live/analytics/recovery_live_test.exs --seed 0"
        status: pass
    human_judgment: false
  - id: D3
    description: "Related campaign navigation round-trips the valid recovery window and current authorized owner scope while rejecting unsafe or forged return context."
    requirement: ADM-06
    verification:
      - kind: integration
        ref: "cd accrue_admin && mix test test/accrue_admin/live/analytics/campaign_live_test.exs test/accrue_admin/live/analytics/recovery_live_test.exs --seed 0"
        status: pass
    human_judgment: false
  - id: D4
    description: "Loading, empty, and failed scoped recovery reads remain distinct and do not show stale results."
    requirement: ADM-06
    verification:
      - kind: integration
        ref: "cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs --seed 0"
        status: pass
      - kind: unit
        ref: "cd accrue_admin && mix test --warnings-as-errors"
        status: pass
    human_judgment: false
duration: 11min
completed: 2026-10-09
status: complete
---

# Phase 237 Plan 07: Recovery currency, history, scope, and return navigation Summary

**Recovery analytics now preserve observed money evidence, separate current billing status from history, and carry validated owner/window context through asynchronous reads and return links.**

## Performance

- **Duration:** 11 minutes
- **Started:** 2026-10-09T00:26:54Z
- **Completed:** 2026-10-09T00:38:44Z
- **Tasks:** 2 completed
- **Files modified:** 9

## Accomplishments

- Removed fabricated currency and zero aggregates where observations lack supported currency or amount evidence.
- Added scoped asynchronous recovery reads with clear loading and recoverable error states; rapid URL changes cannot let stale reads replace the latest selection.
- Distinguished current subscription status from historical failure reasons and preserved validated owner/window return navigation.
- Automated coverage establishes deterministic behavior without a confirmation-only UAT step.

## Task Commits

Each task was committed atomically. Task 2 needed a focused follow-up fix for loading and read-error behavior.

1. **Task 1: Keep recovery currency and window facts exact** — `f995d6ea` (`fix`)
2. **Task 2: Preserve validated owner/window/return navigation** — `82ee2045` (`feat`)
3. **Task 2 follow-up: Show scoped recovery loading and read errors** — `dd714cf3` (`fix`)

## Files Created/Modified

- `accrue/lib/accrue/analytics/dunning.ex` — stopped substituting zero and USD for absent recovery facts.
- `accrue_admin/lib/accrue_admin/queries/dunning.ex` — retains scoped current subscription status and honest currency values.
- `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` — scoped async reads, fresh loading/error states, and latest-selection handling.
- `accrue_admin/lib/accrue_admin/components/at_risk_table.ex` — separate current status and historical failure labels; preserve return context.
- `accrue_admin/lib/accrue_admin/scoped_path.ex` — validates recovery return routes and reapplies authorized owner scope.
- `accrue_admin/lib/accrue_admin/live/analytics/campaign_live.ex` — restores only validated recovery return navigation.
- `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` — currency, scope, status/history, navigation, concurrency, loading, and error assertions.
- `accrue_admin/test/accrue_admin/components/at_risk_table_test.exs` — component status, currency, and return-context assertions.
- `accrue_admin/test/accrue_admin/live/analytics/campaign_live_test.exs` — validated return-path contract assertions.

## Decisions Made

- Missing amount or currency evidence remains unavailable instead of implying USD or a zero total.
- Historical payment failures are immutable event facts and cannot stand in for current subscription state.
- Recovery data loads asynchronously under the URL-selected owner/window; a later selection supersedes stale reads.
- Return navigation is reconstructed through `ScopedPath` using current server-authorized owner scope.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Complete scoped loading and read-error behavior**
- **Found during:** Task 2 final integration review
- **Issue:** The scoped async query path did not yet surface a distinct in-progress state and recoverable query failure after rapid selection changes.
- **Fix:** Added loading-state reset and generic read-error rendering while preserving validated URL scope.
- **Files modified:** `recovery_live.ex`, `recovery_live_test.exs`
- **Verification:** Focused recovery/component/campaign suite and full warnings-as-errors package suite passed.
- **Committed in:** `dd714cf3`

**2. [Rule 3 - Scope] Update shared component contract coverage**
- **Found during:** Task 2
- **Issue:** The component's recovery return URL contract changed, and tests in the shared component and campaign LiveView suites asserted the old URL shape.
- **Fix:** Updated those neighboring contract assertions to check validated return context.
- **Files modified:** `at_risk_table_test.exs`, `campaign_live_test.exs`
- **Verification:** Focused suite passed.
- **Committed in:** `82ee2045`

**Total deviations:** 2 (one correctness fix, one directly required test-contract update). **Impact:** Kept the plan's behavior complete and its adjacent assertions aligned; no dependency, schema, or infrastructure changes.

## Issues Encountered

- `roadmap.update-plan-progress 237` has a known Phase 237 layout recognition issue (`missing_phase_details`). The phase plan checkbox and progress count will be updated manually as allowed by the dispatch instructions.
- The exact readiness query `gsd_run query requirements.ready-ids <237-07-PLAN.md> ADM-06 --raw` reports `0/1` while plan 237-08 (also declaring ADM-06) has no summary. ADM-06 therefore remains pending in this summary and canonical requirements until that sibling completes.

## Verification

- `cd accrue_admin && mix test test/accrue_admin/components/at_risk_table_test.exs test/accrue_admin/live/analytics/campaign_live_test.exs test/accrue_admin/live/analytics/recovery_live_test.exs --seed 0` — **43 tests, 0 failures**.
- `cd accrue_admin && mix test --warnings-as-errors` — **574 tests, 0 failures**.
- `git diff --check` — passed.
- No additional CI workflow was added; the package's existing automated test command covers these behaviors.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

Plan 237-07 is complete. ADM-06 remains pending until plan 237-08, the other declaring plan, has a summary and the readiness resolver reports it safe to mark complete. Plan 237-08 owns the representative served-browser CI proof.

---
*Phase: 237-admin-invoices-payments-recovery*
*Completed: 2026-10-09*

## Self-Check: PASSED

- Summary file exists at the required path.
- Task commits `f995d6ea`, `82ee2045`, and `dd714cf3` are ancestors of the current HEAD.
- Task commit ledger records 3 commits from `c40cb7377773a19e554472c7ae6fc09bc22ce489` through `dd714cf369fcc490ef38fa6ccbee69f9abcfb648`.
