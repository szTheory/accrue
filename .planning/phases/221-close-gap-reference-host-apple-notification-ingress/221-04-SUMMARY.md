---
phase: 221-close-gap-reference-host-apple-notification-ingress
plan: "04"
subsystem: payments
tags: [apple, oban, postgres, phoenix, reconciliation, runtime-configuration]
requires:
  - phase: 221-close-gap-reference-host-apple-notification-ingress
    provides: Host-owned Apple ingress, durable reconciliation wakeups, and shared production verifier configuration
provides:
  - Additive Apple reconciliation queue and 15-minute host Cron schedule
  - Credential-free proof that durable ingress wakeups use the configured existing recovery path
affects: [221-05, examples/accrue_host]
tech-stack:
  added: []
  patterns:
    - Add Oban recovery resources by appending to host-owned queues and Cron workers
    - Prove production runtime configuration by source shape without evaluating secret-backed values
key-files:
  created: []
  modified:
    - examples/accrue_host/config/config.exs
    - examples/accrue_host/test/accrue_host/recovery_wiring_test.exs
key-decisions:
  - "Use the existing :accrue_entitlements queue at concurrency 10 and a single 15-minute ReconciliationSweeper entry."
  - "Treat Oban uniqueness as wakeup coalescing only; PostgreSQL constraints, transactions, and locks remain ownership authority."
requirements-completed: [D-03, D-04, D-05, D-07, D-11]
coverage:
  - id: D1
    description: Existing host recovery queues and Cron workers remain valid while the Apple repair queue and sweeper are added exactly once.
    requirement: D-07
    verification:
      - kind: integration
        ref: examples/accrue_host/test/accrue_host/recovery_wiring_test.exs#base Oban config validates and preserves every recovery cron worker
        status: pass
    human_judgment: false
  - id: D2
    description: The host proof connects durable Apple ingress wakeups to the scheduled sweeper and workers sharing the production-only reconciliation configuration.
    requirement: D-11
    verification:
      - kind: integration
        ref: examples/accrue_host/test/accrue_host/recovery_wiring_test.exs#durable ingress wakeups drain through the scheduled existing recovery workers
        status: pass
      - kind: integration
        ref: examples/accrue_host/test/accrue_host_web/apple_notification_ingest_test.exs#POST /webhooks/apple preserves exact bytes before durable intake and wakeup
        status: pass
    human_judgment: false
metrics:
  duration: 8min
  completed: 2026-08-05
status: complete
---

# Phase 221 Plan 04: Apple Reconciliation Recovery Wiring Summary

**The reference host now schedules Apple reconciliation additively and proves that durable ingress wakeups flow into the existing, production-configured repair path.**

## Performance

- **Duration:** 8 min
- **Tasks:** 2/2
- **Files modified:** 2

## Accomplishments

- Appended `:accrue_entitlements` with concurrency 10 to the existing host Oban queues and appended one 15-minute `ReconciliationSweeper` Cron entry without replacing any queue, plugin, or worker.
- Extended recovery-wiring tests to validate every preserved resource, manual test-mode safety, shared production client/admission configuration, and PostgreSQL ownership authority.
- Added a credential-free bounded proof joining route-created durable wakeups with the sweeper and reconciliation worker queue identities.

## Verification

- PASS — `cd examples/accrue_host && MIX_ENV=test mix test test/accrue_host/recovery_wiring_test.exs --warnings-as-errors` (5 tests, 0 failures).
- PASS — `cd examples/accrue_host && MIX_ENV=test mix test test/accrue_host/recovery_wiring_test.exs test/accrue_host_web/apple_notification_ingest_test.exs --warnings-as-errors` (13 tests, 0 failures).
- PASS — scoped `mix format --check-formatted test/accrue_host/recovery_wiring_test.exs config/config.exs`.
- PASS — `cd examples/accrue_host && mix verify` (37 tests, 0 failures).
- UNRUN/CREDENTIAL-FREE LIMITATION — full `mix format --check-formatted` is blocked by unrelated tracked formatting violations in `lib/accrue_host_web/components/layouts.ex` and two existing migration files; scoped files are formatted.

## Task Commits

1. **Task 1: Append Apple reconciliation resources without disturbing host recovery** — `df28178c` (`feat(221-04)`)
2. **Task 2: Run the bounded host proof across ingress and recovery wiring** — `9873ce0c` (`test(221-04)`)

## Files Created/Modified

- `examples/accrue_host/config/config.exs` — additive entitlement queue and Apple reconciliation Cron schedule.
- `examples/accrue_host/test/accrue_host/recovery_wiring_test.exs` — exact preservation, authority, runtime shape, and route-to-recovery wiring proof.

## Decisions Made

- Preserved every existing recovery resource; the new Apple work is only an appended queue and Cron entry.
- Kept all worker/config assertions structural and deterministic, never loading or printing provider credentials, roots, evidence, PII, or worker arguments.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Formatted the expanded recovery proof**
- **Found during:** Task 2
- **Issue:** The new multiline source helper did not meet the project's Elixir formatter contract.
- **Fix:** Ran the scoped formatter on the task-owned test file.
- **Files modified:** `examples/accrue_host/test/accrue_host/recovery_wiring_test.exs`
- **Verification:** Scoped formatter and focused ingress/recovery proof pass.
- **Commit:** `9873ce0c`

**Total deviations:** 1 auto-fixed (Rule 1). **Impact:** Formatting-only; no scope expansion.

## Known Stubs

None.

## Issues Encountered

- The full host formatter remains blocked by unrelated tracked formatting violations already documented in `deferred-items.md`; the task-owned files pass the scoped formatter and all targeted verification.

## Next Phase Readiness

Plan 221-05 can document the additive, deterministic Apple recovery contract and use the focused proof as merge-blocking evidence.

## Self-Check: PASSED

- Both modified task files exist.
- Task commits `df28178c` and `9873ce0c` exist in git history.
- No task-owned source or test file contains TODO, FIXME, placeholder, or empty rendering stubs.
