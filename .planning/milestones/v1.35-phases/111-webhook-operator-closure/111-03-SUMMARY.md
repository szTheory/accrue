---
phase: 111-webhook-operator-closure
plan: 03
subsystem: testing
tags: [webhook-replay, dlq, portal-checkout, host-verifier]
requires:
  - phase: 111-01
    provides: finalized webhook and operator support contract
  - phase: 111-02
    provides: docs-gate coverage for replay and recovery wording
provides:
  - stronger replay determinism tests
  - Braintree CLI replay coverage
  - idempotent portal-completion reduction proof
affects: [host verification, supportability, webhook replay]
tech-stack:
  added: []
  patterns: [idempotent-replay-proof, local-portal-completion-proof]
key-files:
  created: []
  modified:
    - accrue/test/accrue/webhooks/dlq_test.exs
    - accrue/test/mix/tasks/accrue_webhooks_replay_test.exs
    - accrue/test/accrue/webhook/default_handler_portal_event_test.exs
key-decisions:
  - "Strengthened library-side proof without changing the bounded host verifier scope."
  - "Treated the failing host verifier as an external blocker because its failures are outside the Phase 111 write set."
patterns-established:
  - "Replay tests must cover both generic dead-letter rows and Braintree local portal completion rows."
requirements-completed: [OPS-02]
duration: 12 min
completed: 2026-05-06
---

# Phase 111 Plan 03: Webhook & Operator Closure Summary

**Deterministic replay and local portal-completion proof for the library slice, with host closeout blocked by pre-existing `/billing` verifier failures**

## Performance

- **Duration:** 12 min
- **Started:** 2026-05-07T00:08:00Z
- **Completed:** 2026-05-07T00:16:14Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added replay determinism coverage to `DLQTest`, including the no-second-replay contract once a row leaves dead-lettered status.
- Added CLI coverage proving `mix accrue.webhooks.replay` requeues a Braintree `accrue.portal.checkout.completed` row through the same persisted path.
- Added idempotent local projection proof to `DefaultHandlerPortalEventTest` so repeated reduction of the same portal completion event does not duplicate subscriptions or ledger rows.

## Task Commits

No atomic task commit was created in this run because the workspace already contained unrelated and overlapping uncommitted changes. The plan was executed and verified in-place.

## Files Created/Modified

- `accrue/test/accrue/webhooks/dlq_test.exs` - replay determinism and single-ledger-row assertions
- `accrue/test/mix/tasks/accrue_webhooks_replay_test.exs` - Braintree portal-completion replay coverage for the CLI path
- `accrue/test/accrue/webhook/default_handler_portal_event_test.exs` - idempotent repeated portal-completion reduction proof

## Decisions Made

The bounded host verifier script stayed unchanged because the intended host replay anchor (`test/accrue_host_web/admin_webhook_replay_test.exs`) was already included; the failing host state came from unrelated route/admin drift outside this phase.

## Deviations from Plan

### External blocker

The plan-level host verification command failed, but the failures were outside the Phase 111 write set:

- `test/install_boundary_test.exs`
- `test/accrue_host_web/org_billing_access_test.exs`
- `test/accrue_host_web/subscription_flow_test.exs`
- `test/accrue_host_web/admin_mount_test.exs`
- `test/accrue_host_web/admin_webhook_replay_test.exs`

**Impact on plan:** Library-side proof is complete and green. Phase closeout remains blocked until the pre-existing `/billing` route/admin regressions in `examples/accrue_host` are resolved.

## Issues Encountered

Phase-owned verification passed:

- `cd accrue && mix test test/accrue/webhooks/dlq_test.exs test/mix/tasks/accrue_webhooks_replay_test.exs test/accrue/webhook/default_handler_portal_event_test.exs test/accrue/telemetry/portal_checkout_completed_test.exs`
- `cd accrue && mix test test/accrue/webhooks/dlq_test.exs test/mix/tasks/accrue_webhooks_replay_test.exs test/accrue/webhook/default_handler_portal_event_test.exs test/accrue/telemetry/portal_checkout_completed_test.exs test/accrue/telemetry/ops_event_contract_test.exs test/accrue/telemetry/metrics_ops_parity_test.exs test/accrue/docs/testing_guide_test.exs test/accrue/billing_portal_test.exs`

Host verification did not pass:

- `cd examples/accrue_host && ../../scripts/ci/accrue_host_verify_test_bounded.sh`

The host failures reference route and admin-mount behavior already diverging in the dirty workspace, not regressions introduced by the Phase 111 file set.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 111 should not be marked complete yet. The docs and library proof are ready, but final closeout is blocked on restoring the bounded host verifier to green.

---
*Phase: 111-webhook-operator-closure*
*Completed: 2026-05-06*
