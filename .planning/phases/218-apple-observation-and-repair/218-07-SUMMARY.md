---
phase: 218-apple-observation-and-repair
plan: "07"
subsystem: entitlements
tags: [apple, notifications-v2, plug, durability, privacy]
dependency_graph:
  requires: [218-01, 218-03]
  provides: [bounded-notifications-v2-ingress]
  affects: [apple-reconciliation]
tech_stack:
  added: []
  patterns: [route-scoped Plug, durable acknowledgement, bounded telemetry]
key_files:
  created:
    - accrue/lib/accrue/entitlements/apple/notification_plug.ex
    - accrue/test/accrue/entitlements/apple_notification_test.exs
  modified:
    - accrue/lib/accrue/entitlements/apple/intake.ex
decisions:
  - Notifications are account-independent durable reconciliation signals and never claim ownership or project grants.
  - Only committed verified, noop, or quarantined intake dispositions receive HTTP 200; transient outcomes remain retryable.
metrics:
  tasks_completed: 1
  tests_added: 5
status: complete
---

# Phase 218 Plan 07: Apple Notification Ingress Summary

Bounded Apple Notifications V2 ingress now verifies opaque payloads, records only durable normalized dispositions, and acknowledges Apple only after the commit succeeds.

## Completed Work

- Added route-scoped `NotificationPlug` with a 262,144-byte default limit and host-supplied deterministic rate limiter.
- Added account-independent notification intake that atomically persists verified signals and coalesces reconciliation wakeups by lineage and environment.
- Added bounded terminal quarantine persistence using only a SHA-256 evidence digest; raw body, JWS, tokens, and PII are never stored or emitted.
- Added focused coverage for durable success, duplicate coalescing, terminal quarantine, rollback/retry behavior, size/rate admission, environment isolation, and raw-evidence redaction.

## Verification

- `cd accrue && mix test test/accrue/entitlements/apple_notification_test.exs test/accrue/entitlements/apple_verifier_test.exs` — 9 tests, 0 failures.
- `cd accrue && mix format --check-formatted lib/accrue/entitlements/apple/notification_plug.ex test/accrue/entitlements/apple_notification_test.exs` — passed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] Added account-independent notification intake to the existing intake transaction boundary.**
- **Found during:** Task 1
- **Issue:** Notification delivery has no authenticated account, while the existing `Intake.observe/3` requires one and would incorrectly route a verified signal into ownership/projection.
- **Fix:** Added durable notification and terminal-quarantine intake paths that use the existing environment-qualified lineage and reconciliation-wakeup identities without granting access.
- **Files modified:** `accrue/lib/accrue/entitlements/apple/intake.ex`
- **Commit:** `6ee80aae`

## Known Stubs

None.

## Self-Check: PASSED

- Task commits exist: `029ef326`, `6ee80aae`.
- Notification plug and focused test file exist.
