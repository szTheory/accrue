---
phase: 155-stripefixtures-polish-telemetry-counters
plan: 01
subsystem: testing
tags: [stripe, telemetry, metrics, entitlements]

requires:
  - phase: 154-advisory-cache-core-correctness
    provides: entitlement-summary reducer carry-forward behavior and emitted malformed/orphan telemetry tuples
provides:
  - First-class `omit_livemode: true` support in `Accrue.Test.StripeFixtures.entitlement_summary_event/2`
  - Test-only support contract wording for `Accrue.Test.StripeFixtures`
  - Default telemetry metrics for malformed and orphan entitlement-summary webhook events
affects: [entitlements, stripe-fixtures, telemetry-metrics]

tech-stack:
  added: []
  patterns:
    - Fixture option for key omission instead of nested per-test payload surgery
    - Tuple-based Telemetry.Metrics assertions with bounded tag checks

key-files:
  created: []
  modified:
    - accrue/test/support/stripe_fixtures.ex
    - accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs
    - accrue/lib/accrue/telemetry/metrics.ex
    - accrue/test/accrue/telemetry/metrics_test.exs

key-decisions:
  - "`omit_livemode: true` wins over `livemode:` and removes only the summary object's `livemode` key."
  - "Malformed entitlement-summary metrics expose only `[:reason]`; orphan summary metrics are untagged."
  - "The ops parity inventory remains scoped to `[:accrue, :ops, ...]` events."

patterns-established:
  - "Fixture absence modeling belongs in shared test fixtures when multiple tests need Stripe-shape payload variants."
  - "Default metric coverage should assert emitted event tuples directly, avoiding count/order coupling."

requirements-completed: [POL-03, POL-04]

duration: 8min
completed: 2026-05-31
---

# Phase 155: StripeFixtures Polish + Telemetry Counters Summary

**Stripe entitlement-summary fixtures can model absent `livemode` directly, and default metrics now expose the malformed/orphan entitlement-summary webhook signals.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-05-31T14:28:38Z
- **Completed:** 2026-05-31T14:36:33Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added `omit_livemode: true` to `StripeFixtures.entitlement_summary_event/2`, with documented precedence over `livemode:`.
- Replaced the POL-02 regression's nested `Map.delete` setup with the fixture option and an explicit absence assertion.
- Added default `Telemetry.Metrics` counters for `[:accrue, :webhooks, :malformed_entitlement_summary]` and `[:accrue, :webhooks, :orphan_entitlement_summary]`.
- Added tuple-based metric assertions, including the bounded `[:reason]` tag check for malformed summaries.

## Task Commits

1. **Task 1: Add `omit_livemode: true` fixture support and carry-forward regression usage** - `e808e4c2`
2. **Task 2: Add entitlement-summary webhook counters to `defaults/0`** - `d659bbaa`

## Files Created/Modified

- `accrue/test/support/stripe_fixtures.ex` - Documents test-only/non-Hex support scope and implements `omit_livemode: true`.
- `accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs` - Uses the fixture option in the POL-02 livemode carry-forward regression.
- `accrue/lib/accrue/telemetry/metrics.ex` - Adds malformed/orphan entitlement-summary webhook default counters.
- `accrue/test/accrue/telemetry/metrics_test.exs` - Verifies metric event tuples and malformed-summary tags.

## Decisions Made

None - followed the locked Phase 155 decisions from `155-CONTEXT.md`.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope change.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Verification

- `cd /Users/jon/projects/accrue/accrue && mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs --seed 0` - 15 tests, 0 failures.
- `cd /Users/jon/projects/accrue/accrue && mix test test/accrue/telemetry/metrics_test.exs --seed 0` - 8 tests, 0 failures.
- `cd /Users/jon/projects/accrue/accrue && mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs test/accrue/telemetry/metrics_test.exs --seed 0` - 23 tests, 0 failures.
- Source checks confirmed `omit_livemode`, non-Hex support wording, both metric counters, both event tuple assertions, and the malformed-summary `[:reason]` tag assertion.

## Self-Check: PASSED

- Key modified files exist on disk.
- `git log --oneline --grep="155-01"` returns implementation and metadata commits.
- Plan acceptance criteria and verification commands passed.

## Next Phase Readiness

Phase 155 closes POL-03 and POL-04. The next v1.47 adopter-proof phases can proceed without depending on additional telemetry or fixture polish from this phase.

---
*Phase: 155-stripefixtures-polish-telemetry-counters*
*Completed: 2026-05-31*
