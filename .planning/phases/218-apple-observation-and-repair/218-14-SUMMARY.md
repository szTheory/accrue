---
phase: 218-apple-observation-and-repair
plan: 14
subsystem: entitlements
tags: [apple, app-store-notifications-v2, jws, ecto, reconciliation]
requires:
  - phase: 218-12
    provides: strict production Apple JWS certificate and current-time policy
  - phase: 218-13
    provides: durable Apple Intake and reconciliation repair semantics
provides:
  - Authenticated V2 outer envelopes with application claims validated from `data`
  - Independently verified transaction and renewal evidence before wakeup admission
  - Production-backed replay, parallel delivery, rollback, and fail-closed regression coverage
affects: [apple-notifications, reconciliation-wakeups, verifier]
tech-stack:
  added: []
  patterns: [separate cryptographic envelope authentication from application claim validation]
key-files:
  created: []
  modified:
    - accrue/lib/accrue/entitlements/apple/verifier/production.ex
    - accrue/test/fixtures/apple/server_evidence.exs
    - accrue/test/accrue/entitlements/apple_notification_test.exs
key-decisions:
  - "Validate notification bundle, environment, and app identity only after authenticating the outer envelope's data map."
  - "Retain outer notificationUUID as provider-event identity while independently validating both nested JWS values."
patterns-established:
  - "Notifications authenticate their outer envelope separately from application-claim validation."
requirements-completed: [AAPL-02, AAPL-03]
coverage:
  - id: D1
    description: Production V2 notification envelopes durably coalesce into an account-independent reconciliation wakeup.
    requirement: AAPL-02
    verification:
      - kind: integration
        ref: accrue/test/accrue/entitlements/apple_notification_test.exs#production V2 delivery replays and converges concurrently on one durable wakeup
        status: pass
    human_judgment: false
  - id: D2
    description: Wrong data claims and independently tampered outer or nested signatures remain non-granting and wakeup-free.
    requirement: AAPL-03
    verification:
      - kind: integration
        ref: accrue/test/accrue/entitlements/apple_notification_test.exs#production V2 rejects authenticated wrong application data without a wakeup
        status: pass
      - kind: integration
        ref: accrue/test/accrue/entitlements/apple_notification_test.exs#production V2 independently closes outer and nested signature tampering
        status: pass
    human_judgment: false
duration: 6min
completed: 2026-08-03
status: complete
---

# Phase 218 Plan 14: Apple Notification Data Envelope Repair Summary

**Production App Store Notifications V2 now authenticate outer envelopes, validate signed `data` claims, and independently verify nested evidence before one durable repair wakeup is acknowledged.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-08-03T19:24:00Z
- **Completed:** 2026-08-03T19:30:00Z
- **Tasks:** 1
- **Files modified:** 3

## Accomplishments

- Split Production's cryptographic-envelope authentication from application-claim validation so V2 identity comes from authenticated `data`.
- Added deterministic signed outer, transaction, and renewal JWS fixtures without changing public verifier behaviour or configuration.
- Proved real Production Plug delivery, serial replay, parallel coalescing, rollback retryability, privacy-safe wakeup-only semantics, and independent fail-closed signature and identity handling.

## Task Commits

1. **Task 1: Trace a genuine production outer data envelope to one durable repair wakeup** - `5a634b5a` (test), `5b9ebe72` (feat)

## Files Created/Modified

- `accrue/lib/accrue/entitlements/apple/verifier/production.ex` - Separates outer authentication from data-map validation and nested verification.
- `accrue/test/fixtures/apple/server_evidence.exs` - Signs deterministic nested and outer V2 notification evidence.
- `accrue/test/accrue/entitlements/apple_notification_test.exs` - Exercises the Production verifier through NotificationPlug and durable Intake state.

## Decisions Made

- Validate notification application identity on authenticated `data`; leave transaction and renewal claim validation inside their own independently authenticated JWS paths.
- Preserve the authenticated outer `notificationUUID` for provider-event identity; never return raw outer data or JWS values.

## Deviations from Plan

None - plan executed exactly as written.

## Verification

- `mix test test/accrue/entitlements/apple_notification_test.exs test/accrue/entitlements/apple_verifier_test.exs` — passed (20 tests).
- `mix test test/accrue/entitlements/apple_*_test.exs test/property/apple_convergence_property_test.exs` — passed (52 tests, 1 property).
- `mix format --check-formatted ...` and `mix compile --warnings-as-errors` — passed.
- `git diff --quiet -- mix.exs mix.lock` — passed; no dependency changes.

## Known Stubs

None.

## Next Phase Readiness

The production notification-driven repair path is now covered end-to-end with no verifier callback, configuration, schema, ownership, or provider-lifecycle changes.

---
*Phase: 218-apple-observation-and-repair*
*Completed: 2026-08-03*
