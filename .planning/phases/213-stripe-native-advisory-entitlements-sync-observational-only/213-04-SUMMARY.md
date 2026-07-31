---
phase: 213-stripe-native-advisory-entitlements-sync-observational-only
plan: "04"
subsystem: stripe-native-advisory-entitlements-sync
status: complete
tags:
  - stripe
  - entitlements
  - advisory-sync
  - processor-facade
dependency_graph:
  requires:
    - "213-01 shared pull/webhook Reconcile writer"
    - "213-02 Stripe active-entitlement adapter"
    - "213-03 isolation guard and grant-invariance proof"
  provides:
    - "Optional-callback-safe Processor.list_active_entitlements/2 facade"
    - "Deterministic same-second entitlement-summary webhook ordering"
    - "Gap-closure regressions for Phase 213 verification failures"
  affects:
    - accrue/lib/accrue/processor.ex
    - accrue/lib/accrue/entitlements/reconcile.ex
    - accrue/test/accrue/processor/optional_entitlements_callback_test.exs
    - accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs
tech_stack:
  added: []
  patterns:
    - "Optional Processor callbacks guarded with function_exported?/3 after module load"
    - "Shared timestamp-plus-event-id total order mirrored in reducer and Ecto upsert SQL"
key_files:
  created:
    - accrue/test/accrue/processor/optional_entitlements_callback_test.exs
  modified:
    - accrue/lib/accrue/processor.ex
    - accrue/lib/accrue/entitlements/reconcile.ex
    - accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs
key_decisions:
  - "Callback-omitting adapters return a bounded unsupported_operation APIError instead of a false empty snapshot or UndefinedFunctionError."
  - "Same-second webhook summaries are ordered by {synced_at, event_id}; the bytewise-greater event id wins."
  - "Exact duplicate webhook summaries remain stale and emit the existing summary_synced result: :unchanged telemetry without a new ledger row."
requirements_completed:
  - SYNC-01
  - SYNC-02
  - SYNC-05
coverage:
  - id: D1
    description: "Processor.list_active_entitlements/2 is safe for configured adapters that omit the optional callback."
    requirement: SYNC-01
    verification:
      - kind: unit
        ref: "mix test test/accrue/processor/optional_entitlements_callback_test.exs test/accrue/processor/stripe_entitlements_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Distinct same-second entitlement-summary webhooks converge to the bytewise-greater event id and payload in either arrival order."
    requirement: SYNC-02
    verification:
      - kind: integration
        ref: "mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs test/accrue/webhook/wr05_concurrency_test.exs test/property/entitlement_summary_monotonic_property_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "Gap closure preserves observational-only isolation and the targeted Fake/Test-only verification lane."
    requirement: SYNC-05
    verification:
      - kind: other
        ref: "mix compile --warnings-as-errors && targeted phase suite && bash scripts/ci/verify_entitlement_sync_isolation.sh"
        status: pass
    human_judgment: false
metrics:
  started_at: 2026-07-31T01:08:47Z
  completed_at: 2026-07-31T01:13:02Z
  duration: "4 min"
  tasks_completed: 2
  commits: 4
---

# Phase 213 Plan 04: Verification Gap Closure Summary

Optional advisory entitlement callbacks now fail as typed unsupported operations when absent, and same-second Stripe entitlement-summary webhooks converge deterministically by event id without affecting the grant path.

## Performance

- **Duration:** 4 min
- **Started:** 2026-07-31T01:08:47Z
- **Completed:** 2026-07-31T01:13:02Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added a regression proving callback-omitting processor adapters return `%Accrue.APIError{code: "unsupported_operation", http_status: 501}` instead of raising.
- Guarded `Processor.list_active_entitlements/2` with module loading plus `function_exported?/3`, while preserving unchanged delegation for Stripe/Fake-style adapters.
- Replaced same-second stale behavior with one timestamp-plus-event-id ordering policy shared by `check_stale` and the `ON CONFLICT` predicate.
- Added same-second changed-payload webhook coverage for both arrival orders, exact duplicate replay, and lower-id stale replay.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: optional entitlement callback regression** - `d63295e9` (test)
2. **Task 1 GREEN: guarded optional callback dispatch** - `ffd586d8` (feat)
3. **Task 2 RED: same-second webhook ordering regression** - `d5c377c7` (test)
4. **Task 2 GREEN: deterministic summary ordering policy** - `192eb8ce` (feat)

## Files Created/Modified

- `accrue/test/accrue/processor/optional_entitlements_callback_test.exs` - New adapter-without-callback and adapter-with-callback regression coverage.
- `accrue/lib/accrue/processor.ex` - Added bounded unsupported-operation handling for missing optional entitlement callback.
- `accrue/lib/accrue/entitlements/reconcile.ex` - Added shared timestamp/event-id ordering, bytewise SQL tie predicate, single `synced_at` capture, and duplicate unchanged telemetry preservation.
- `accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs` - Replaced equal-timestamp stale expectation with deterministic same-second convergence tests.

## Decisions Made

- Missing optional processor entitlement callbacks are unsupported operations, not successful empty diagnostic snapshots.
- Event-id ties use bytewise ascending order so the lexicographically greater Stripe event id wins for equal timestamps.
- Timestamp-less webhook handling still captures one `synced_at` value and carries forward existing event watermarks; pull writes still rely on strictly newer `synced_at` and do not invent event ids.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Loaded adapter modules before export checks**
- **Found during:** Task 1 GREEN verification
- **Issue:** `function_exported?/3` returned false for `Accrue.Processor.Stripe` before the module was loaded, causing the Stripe contract tests to see a false unsupported-operation error.
- **Fix:** Added `Code.ensure_loaded(adapter)` before checking for `list_active_entitlements/2`.
- **Files modified:** `accrue/lib/accrue/processor.ex`
- **Verification:** `cd accrue && mix test test/accrue/processor/optional_entitlements_callback_test.exs test/accrue/processor/stripe_entitlements_contract_test.exs`
- **Committed in:** `ffd586d8`

**2. [Rule 1 - Bug] Preserved duplicate webhook unchanged telemetry**
- **Found during:** Task 2 GREEN verification
- **Issue:** Moving exact duplicate detection into the reducer pre-check bypassed the previous DB-stale path that emitted `[:accrue, :entitlements, :summary_synced]` with `result: :unchanged`.
- **Fix:** Split exact-key stale from older stale and emitted the unchanged telemetry for exact duplicates without recording a new ledger event.
- **Files modified:** `accrue/lib/accrue/entitlements/reconcile.ex`
- **Verification:** `cd accrue && mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs test/accrue/webhook/wr05_concurrency_test.exs test/property/entitlement_summary_monotonic_property_test.exs`
- **Committed in:** `192eb8ce`

**Total deviations:** 2 auto-fixed (Rule 1).
**Impact on plan:** Both fixes were required to preserve existing contracts while closing the verification gaps; no scope was added beyond 213-04.

## Issues Encountered

None beyond the auto-fixed issues above.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Threat Flags

None. The changes affect a processor facade branch and advisory-cache reconciliation only; they add no network endpoint, auth path, file access path, schema change, dependency, or grant-authority surface.

## Verification

- `cd accrue && mix test test/accrue/processor/optional_entitlements_callback_test.exs test/accrue/processor/stripe_entitlements_contract_test.exs` - passed, 5 tests.
- `cd accrue && mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs test/accrue/webhook/wr05_concurrency_test.exs test/property/entitlement_summary_monotonic_property_test.exs` - passed, 1 property and 18 tests.
- `cd accrue && mix compile --warnings-as-errors && mix test test/accrue/processor/optional_entitlements_callback_test.exs test/accrue/processor/stripe_entitlements_contract_test.exs test/accrue/entitlements/stripe_sync_refresh_test.exs test/accrue/webhook/default_handler_entitlement_summary_test.exs test/accrue/webhook/wr05_concurrency_test.exs test/property/entitlement_summary_monotonic_property_test.exs test/accrue/entitlements/stripe_sync_disabled_isolation_test.exs && cd .. && bash scripts/ci/verify_entitlement_sync_isolation.sh` - passed, 31 tests, 1 property, isolation OK.

## Next Phase Readiness

Phase 213 is ready for re-verification and Phase 214 docs/truth reconciliation. The two verifier gaps are closed without changing the observational-only authority boundary.

## Self-Check: PASSED

- Found summary file and all key created/modified files.
- Found task commits `d63295e9`, `ffd586d8`, `d5c377c7`, and `192eb8ce` in git history.
- No known stubs, skipped tests, unrun verification items, or new threat surfaces were left behind.

---
*Phase: 213-stripe-native-advisory-entitlements-sync-observational-only*
*Completed: 2026-07-31*
