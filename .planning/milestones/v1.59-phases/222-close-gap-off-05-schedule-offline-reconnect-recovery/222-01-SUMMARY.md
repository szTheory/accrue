---
phase: 222-close-gap-off-05-schedule-offline-reconnect-recovery
plan: "01"
subsystem: offline entitlements reference host
tags: [oban, cron, offline-reconnect, pop, es256, host-integration]
requires:
  - phase: 221-close-gap-reference-host-apple-notification-ingress
    provides: recovery-wiring host-test pattern
provides:
  - a fifteen-minute reference-host reconnect sweep
  - a durable host-Repo reconnect recovery proof through signed issuance
affects: [examples/accrue_host, offline-entitlements]
tech-stack:
  added: []
  patterns: [Oban Cron wiring, durable Oban worker recovery, nested test-only host adapters]
key-files:
  created: []
  modified:
    - examples/accrue_host/config/config.exs
    - examples/accrue_host/test/accrue_host/recovery_wiring_test.exs
decisions:
  - ReconnectSweeper uses its existing accrue_entitlements worker queue; Cron adds no queue override.
  - Source and signing adapters remain nested test-only implementations; production offline_reconnect adapter configuration remains host-owned.
metrics:
  duration: 8m
  completed: 2026-08-05
  tasks_completed: 1
  files_modified: 2
status: complete
---

# Phase 222 Plan 01: Offline Reconnect Recovery Schedule Summary

The reference host now runs the existing offline reconnect sweeper every fifteen minutes and proves a PoP-admitted stranded reconnect reaches one cryptographically fresh signed replacement through the durable production worker path.

## Completed Work

- Added exactly one `{"*/15 * * * *", Accrue.Entitlements.Offline.ReconnectSweeper}` Cron entry immediately after the Apple reconciliation entry, preserving all existing queues, plugins, and Cron workers.
- Extended the non-async host recovery authority with static Oban validation and a real `AccrueHost.Repo` recovery proof: admission interruption, durable attempt/wakeup, production sweeper, persisted `ReconnectWorker`, one issuance, and fresh proof verification.
- The proof asserts one configured Stripe status moves unchanged from `due_sources/3` to `refresh/4`, records one call of each, excludes `:proof` and `:client_proof` options, and leaves database locks/execution tokens as ownership authority.
- Nested test adapters and application configuration are restored exactly on exit. Production `:offline_reconnect` adapters are host-owned and explicitly out of scope; scheduled Cron wiring alone does not configure a production reconnect endpoint.
- Follow-up review hardening removes the queued `ReconnectWakeupWorker` job while retaining its durable `ReconnectWakeup` record before invoking `ReconnectSweeper`. This proves the Cron sweep, rather than an immediate wakeup, reclaims the stranded attempt.

## Verification

- `cd examples/accrue_host && mix format --check-formatted config/config.exs test/accrue_host/recovery_wiring_test.exs && MIX_ENV=test mix test test/accrue_host/recovery_wiring_test.exs --warnings-as-errors` — passed (7 tests).
- `cd examples/accrue_host && mix verify` — passed (64 tests).
- `cd accrue && mix test test/accrue/entitlements/offline_reconnect_test.exs` — passed (19 tests).

## TDD Gate Compliance

- RED: `c706356d` added the failing missing-Cron expectation; the focused test failed as expected before implementation.
- GREEN: `bf8bda54` added the Cron wiring and full durable recovery proof; all verification passed.

## Deviations from Plan

The post-execution review identified that the fixture left the immediate wakeup job available. The follow-up test-only change deletes that queued job before sweeping, then reruns the complete verification suite successfully.

## Known Stubs

None.

## Self-Check: PASSED

- Confirmed both implementation files exist.
- Confirmed `c706356d` and `bf8bda54` are present in git history.
