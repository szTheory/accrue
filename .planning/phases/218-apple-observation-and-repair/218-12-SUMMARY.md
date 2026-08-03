---
phase: 218-apple-observation-and-repair
plan: 12
subsystem: entitlements
tags: [apple, jws, pkix, es256, reconciliation]
requires:
  - phase: 218-11
    provides: Apple ES256 purpose-chain fixture corpus and reconciliation admission seams
provides:
  - Explicit current, fixed, and signed-date certificate-time policies for Apple JWS verification
  - Deterministic host-pinned multi-root PKIX validation
  - Per-record signed-date policy selection limited to delayed reconciliation
affects: [apple-verifier, apple-reconciliation, notification-plug]
tech-stack:
  added: []
  patterns: [explicit PKIX policy-time validation, per-record immutable verifier configuration]
key-files:
  created: []
  modified:
    - accrue/lib/accrue/entitlements/apple/verifier/production.ex
    - accrue/lib/accrue/entitlements/apple/admission.ex
    - accrue/lib/accrue/entitlements/apple/reconciliation/admission.ex
    - accrue/test/accrue/entitlements/apple_verifier_test.exs
key-decisions:
  - "Only reconciliation selects :signed_date; live observation and notifications retain current-clock policy."
  - "Policy time is manually checked for every certificate before OTP continues only host-clock certificate-time events."
requirements-completed: [AAPL-02, AAPL-04]
coverage:
  - id: D1
    description: Apple JWS certificate chains use bounded fixed/current/signed-date policy times and every configured pinned root.
    requirement: AAPL-02
    verification:
      - kind: unit
        ref: accrue/test/accrue/entitlements/apple_verifier_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Delayed reconciliation alone uses each record's signed date while direct observation and notifications retain current-clock configuration.
    requirement: AAPL-04
    verification:
      - kind: integration
        ref: cd accrue && mix test test/accrue/entitlements/apple_*_test.exs test/property/apple_convergence_property_test.exs
        status: pass
    human_judgment: false
metrics:
  duration: 8m
  completed: 2026-08-03
status: complete
---

# Phase 218 Plan 12: Apple policy-time verification Summary

**Apple JWS validation now resolves bounded certificate time per verification policy, checks every pinned root, and restricts historical signed-date verification to delayed reconciliation.**

## Performance

- **Duration:** 8 min
- **Completed:** 2026-08-03
- **Tasks:** 2/2
- **Files modified:** 7

## Accomplishments

- Added strict current, fixed UTC, and per-JWS signed-date certificate-time handling before PKIX and ES256 claim validation.
- Validated all certificates at the resolved instant and tried every host-configured pinned root without trusting JWS-provided anchors.
- Scoped `:signed_date` configuration copying to reconciliation records; public observation, fake verifier configs, and NotificationPlug retain their current behavior.

## Task Commits

1. **Task 1: Trace one signed Apple JWS through bounded policy-time multi-root PKIX verification** - `53ff6a62` (RED tests), `db7224e7` (implementation)
2. **Task 2: Propagate signed-date policy only through delayed reconciliation admission** - `983de044`

## Files Created/Modified

- `accrue/lib/accrue/entitlements/apple/verifier.ex` - Declares the verifier certificate-time contract.
- `accrue/lib/accrue/entitlements/apple/verifier/production.ex` - Resolves policy time, validates certificate windows, and iterates pinned roots.
- `accrue/lib/accrue/entitlements/apple/admission.ex` - Applies an internal immutable policy override only to production configs.
- `accrue/lib/accrue/entitlements/apple/reconciliation/admission.ex` - Selects `:signed_date` for each reconciled JWS.
- `accrue/test/accrue/entitlements/apple_verifier_test.exs` - Covers policy-time and multi-root regression cases.
- `accrue/test/fixtures/apple/server_evidence.exs` - Exposes an unrelated pinned-root candidate for root-selection coverage.

## Decisions Made

- `nil` and `:current` continue to resolve the live UTC clock; signed dates are accepted only for the current JWS under reconciliation.
- The verifier keeps OTP's signature, path, and extension checks strict, continuing only redundant host-clock validity events after explicit policy-time validation.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Bound the internal policy option before use**
- **Found during:** Task 2
- **Issue:** The five-argument admission clause discarded `opts`, preventing the internal reconciliation policy selection from compiling.
- **Fix:** Retained the private argument and used it only to select `verification_time`.
- **Files modified:** `accrue/lib/accrue/entitlements/apple/admission.ex`
- **Verification:** Focused observation, notification, and reconciliation suites passed.
- **Committed in:** `983de044`

**Total deviations:** 1 auto-fixed (Rule 1).

## Verification

- `cd accrue && mix test test/accrue/entitlements/apple_verifier_test.exs` — pass (10 tests).
- `cd accrue && mix test test/accrue/entitlements/apple_observation_tracer_test.exs test/accrue/entitlements/apple_notification_test.exs test/accrue/entitlements/apple_reconciliation_test.exs` — pass (29 tests).
- `cd accrue && mix test test/accrue/entitlements/apple_*_test.exs test/property/apple_convergence_property_test.exs` — pass (46 tests, 1 property).
- `cd accrue && mix compile --warnings-as-errors` — pass.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Apple delayed evidence can now validate at its signed instant while live entry points retain current-clock verification. No blockers.

## Self-Check: PASSED

All seven plan-scoped files exist and all three task commits are present in git history.
