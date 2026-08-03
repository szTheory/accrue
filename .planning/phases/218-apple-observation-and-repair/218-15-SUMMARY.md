---
phase: 218-apple-observation-and-repair
plan: 15
subsystem: payments
tags: [apple, webhooks, phoenix, jws, es256, verification]
requires:
  - phase: 218-apple-observation-and-repair
    provides: "Plan 218-14 durable Apple Intake, quarantine, and reconciliation wakeup contracts"
provides:
  - "Fail-closed Apple raw-body admission with retryable capture failures"
  - "Dedicated documented Apple Notifications V2 route macro and parser contract"
  - "Deterministic decoded-signature-byte tampering proof for outer and nested JWS boundaries"
affects: [apple-notifications, webhook-routing, cryptographic-verification]
tech-stack:
  added: []
  patterns: ["Route-captured bytes are required before Apple verification or quarantine", "JWS negative tests mutate decoded signature bytes rather than Base64url text"]
key-files:
  created: []
  modified:
    - accrue/lib/accrue/entitlements/apple/notification_plug.ex
    - accrue/lib/accrue/router.ex
    - accrue/guides/webhooks.md
    - accrue/test/fixtures/apple/server_evidence.exs
    - accrue/test/accrue/entitlements/apple_notification_test.exs
key-decisions:
  - "Missing, empty, or malformed Apple body capture returns retryable 503 before verifier, quarantine, or persistence."
  - "Cryptographic tampering tests flip a fixed bit in decoded ES256 signature bytes."
requirements-completed: [AAPL-02, AAPL-03]
coverage:
  - id: D1
    description: "Apple notifications without an exact non-empty cached body reject retryably without verification, Intake, wakeup, observation, or grant writes."
    requirement: AAPL-03
    verification:
      - kind: integration
        ref: "accrue/test/accrue/entitlements/apple_notification_test.exs#retries a non-empty delivery whose exact raw capture is absent or unusable"
        status: pass
      - kind: unit
        ref: "cd accrue && mix test test/accrue/webhook/plug_test.exs --seed 458442"
        status: pass
    human_judgment: false
  - id: D2
    description: "Outer, transaction, and renewal JWS signature byte corruption independently returns invalid_signature and never produces a wakeup, observation, or grant."
    requirement: AAPL-02
    verification:
      - kind: integration
        ref: "accrue/test/accrue/entitlements/apple_notification_test.exs#production V2 independently closes outer and nested signature tampering"
        status: pass
      - kind: unit
        ref: "cd accrue && mix test test/accrue/entitlements/apple_verifier_test.exs --seed 458442"
        status: pass
      - kind: other
        ref: "cd accrue && mix test test/accrue/entitlements/apple_*_test.exs test/property/apple_convergence_property_test.exs"
        status: pass
    human_judgment: false
duration: 5min
completed: 2026-08-03
status: complete
---

# Phase 218 Plan 15: Apple Capture and Signature Repair Summary

**Apple Notifications V2 now requires exact cached request bytes before any admission, while deterministic byte-level ES256 corruption proves every JWS boundary closes before entitlement authority.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-08-03T20:58:00Z
- **Completed:** 2026-08-03T21:01:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Rejects missing, empty, and malformed Apple raw-body capture with a storage-free retryable 503.
- Adds a host-facing Apple notification route macro and documented route-scoped `CachingBodyReader` setup.
- Replaces padding-bit text mutation with deterministic decoded-signature-byte corruption across outer, transaction, and renewal JWS values.

## Task Commits

1. **Task 1: Trace an uncaptured non-empty delivery to retry without persistence** — `b1a48e73` (feat)
2. **Task 2: Prove decoded-byte corruption closes each JWS boundary independently** — `a2863c34` (test)

## Files Created/Modified

- `accrue/lib/accrue/entitlements/apple/notification_plug.ex` — validates only non-empty binary or binary chunk captures before all processing.
- `accrue/lib/accrue/router.ex` — supplies `accrue_apple_notifications/2` for the host route.
- `accrue/guides/webhooks.md` — documents Apple parser, verifier configuration, rate policy, and 503 capture failure handling.
- `accrue/test/fixtures/apple/server_evidence.exs` — flips a decoded ES256 signature bit and exposes safe signature-byte inspection.
- `accrue/test/accrue/entitlements/apple_notification_test.exs` — proves side-effect-free capture rejection and repeated independent JWS rejection.

## Decisions Made

- Missing raw capture is not an invalid payload to terminally quarantine; it is a retryable host-pipeline failure.
- Header and payload segments remain unchanged while a fixed decoded signature byte is altered for deterministic cryptographic negative tests.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Issues Encountered

- The Task 1 full notification suite initially retained the planned Task 2 failing signature regression; focused Task 1 evidence passed before its atomic commit, and the full specified corpus passed after Task 2.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The Apple notification boundary and negative cryptographic proof are ready for the remaining reconciliation repair work in Plan 218-16.

## Self-Check: PASSED

- Confirmed all five modified files exist and task commits `b1a48e73` and `a2863c34` are present in git history.
