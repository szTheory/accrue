---
phase: 10-host-app-dogfood-harness
plan: 06
subsystem: testing
tags: [phoenix, elixir, accrue, webhooks, oban, host-app]
requires:
  - phase: 10-04
    provides: installer-owned webhook route, generated billing handler, and host billing facade wiring
  - phase: 10-05
    provides: fake-backed signed-in host billing flow with persisted subscriptions
provides:
  - Host-local webhook handler registration for inline host-app verification
  - Signed `/webhooks/stripe` endpoint proof covering ingest, dispatch, tamper rejection, and duplicate replay
  - Durable host-side webhook evidence recorded in the host event ledger
affects: [phase-10, host-app, webhooks, testing, admin-ui]
tech-stack:
  added: []
  patterns: [host-owned-webhook-ledger-evidence, signed-host-webhook-proof]
key-files:
  created: []
  modified:
    - examples/accrue_host/lib/accrue_host/billing_handler.ex
    - examples/accrue_host/config/test.exs
    - examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs
key-decisions:
  - "Register `AccrueHost.BillingHandler` in host test config and let it record explicit `host.webhook.handled` ledger rows instead of inventing a separate host-only table."
  - "Drive the proof with a real Fake-backed subscription plus a signed `customer.subscription.created` POST so the host router, ingest path, Oban job, and dispatch worker all stay on the public integration boundary."
patterns-established:
  - "Host webhook proofs should hit the installed router path with a signed raw payload and then execute the dispatch worker against the persisted webhook row."
  - "Host-owned webhook side effects can use `Accrue.Events.record/1` with `caused_by_webhook_event_id` for durable, replay-safe evidence."
requirements-completed: [HOST-04]
duration: 9min
completed: 2026-04-16
---

# Phase 10 Plan 06: Host App Dogfood Harness Summary

**Signed host webhook ingest proof through `/webhooks/stripe` with durable host-side ledger evidence and duplicate-safe dispatch**

## Performance

- **Duration:** 9 min
- **Started:** 2026-04-16T16:46:00Z
- **Completed:** 2026-04-16T16:55:08Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Registered the host-owned webhook handler in the test environment and made it record explicit `host.webhook.handled` evidence in `accrue_events`.
- Replaced the webhook scaffold with a signed POST proof against the exact host route `/webhooks/stripe`.
- Verified tampered payload rejection, persisted `accrue_webhook_events`, normal dispatch via `Accrue.Webhook.DispatchWorker`, and duplicate-delivery idempotence.

## Task Commits

Each task was committed atomically:

1. **Task 1: Finalize host-local webhook dispatch wiring for inline verification** - `5486e4d` (feat)
2. **Task 2: Replace the webhook placeholder with signed-ingest and idempotency coverage** - `09a590a` (test)

## Files Created/Modified
- `examples/accrue_host/lib/accrue_host/billing_handler.ex` - host-owned handler now records durable ledger evidence for processed webhook events
- `examples/accrue_host/config/test.exs` - host test config now registers the webhook handler and pins the local signing secret
- `examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs` - signed endpoint proof for ingest, tamper rejection, dispatch, and duplicate replay

## Decisions Made
- Used the existing event ledger as the host-side evidence surface so the proof stays inside public Accrue APIs and the host Repo.
- Proved normal dispatch by performing the persisted webhook job after the signed POST, rather than bypassing ingest with direct reducer calls.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- The initial test helper hit the full Phoenix endpoint and produced signature mismatches; switching the proof to the host router preserved the installed raw-body pipeline and matched the existing Accrue plug test pattern.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- The host app now has a durable signed-webhook proof that Phase 10-07 can reuse when validating admin-side webhook inspection and replay.
- `/webhooks/stripe` is covered end to end through host-local config, so later work can build on a stable webhook baseline instead of scaffolding more test plumbing.

## Self-Check: PASSED
- Found `.planning/phases/10-host-app-dogfood-harness/10-06-SUMMARY.md`
- Found `examples/accrue_host/lib/accrue_host/billing_handler.ex`
- Found `examples/accrue_host/config/test.exs`
- Found `examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs`
- Found commit `5486e4d` in git history
- Found commit `09a590a` in git history

---
*Phase: 10-host-app-dogfood-harness*
*Completed: 2026-04-16*
