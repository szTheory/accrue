---
phase: 101
plan: 08
subsystem: portal-checkout
tags:
  - braintree
  - portal
  - webhook
  - telemetry
requires:
  - 101-04
provides:
  - synthetic portal checkout completion worker
  - default-handler reduction for portal completion
  - portal checkout completion telemetry coverage
affects:
  - accrue_portal checkout success handoff
  - accrue webhook reduction path
tech_stack:
  added:
    - Oban worker handoff for portal completion
  patterns:
    - persisted synthetic webhook rows before reduction
    - default-handler reuse for local checkout completion
key_files:
  created:
    - accrue/lib/accrue/portal/checkout/completion_job.ex
  modified:
    - accrue_portal/lib/accrue_portal/live/checkout_live.ex
    - accrue/lib/accrue/webhook/default_handler.ex
    - accrue/test/accrue/webhook/default_handler_portal_event_test.exs
    - accrue/test/accrue/telemetry/portal_checkout_completed_test.exs
decisions:
  - Checkout success now enqueues an async completion job instead of reducing inside the LiveView.
  - Synthetic portal completion rows are persisted in `accrue_webhook_events` before reduction.
  - `accrue.portal.checkout.completed` reuses the checkout-session reconciliation path through `Accrue.Webhook.DefaultHandler`.
metrics:
  duration: "8m"
  completed_at: "2026-05-02T14:52:00Z"
  task_commits:
    - b4599a2
    - ce86b7b
    - ee22a3f
---

# Phase 101 Plan 08: Portal Checkout Completion Summary

Local Braintree checkout now hands off to a persisted synthetic completion event that reduces through the existing webhook default-handler path and emits portal completion telemetry without blocking the LiveView success response.

## Completed Work

1. Added `Accrue.Portal.Checkout.CompletionJob` to enqueue, persist, and reduce `accrue.portal.checkout.completed` after a successful local subscribe.
2. Wired `AccruePortal.Live.CheckoutLive` to enqueue completion work immediately after `Billing.subscribe/3` and `LocalSession.mark_completed/1`, while keeping the customer response non-blocking if enqueue logging fails.
3. Extended `Accrue.Webhook.DefaultHandler` so the synthetic portal completion type feeds the existing checkout-session subscription-linking path and records the canonical `checkout.session.completed` ledger event.
4. Added focused reducer and telemetry regression coverage in the owned Accrue-side tests.

## Verification

Commands run:

```bash
cd /Users/jon/projects/accrue/accrue && mix test test/accrue/webhook/default_handler_portal_event_test.exs test/accrue/telemetry/portal_checkout_completed_test.exs
cd /Users/jon/projects/accrue/accrue_portal && mix test test/accrue_portal/live/checkout_live_test.exs
```

Results:
- Both Accrue-side portal completion tests passed.
- The existing `accrue_portal` checkout LiveView regression suite passed after the enqueue wiring change.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Verification command drift] `mix test ... -x` is stale in this repo**
- **Found during:** RED verification
- **Issue:** Mix on this branch rejects `-x` as an unknown option.
- **Fix:** Re-ran the targeted suites with the actual supported commands shown above.
- **Files modified:** `.planning/phases/101-accrue-portal-foundation-checkout/101-08-SUMMARY.md`

### Ownership-Constrained Adjustments

**1. The plan’s enqueue assertion stayed in the existing portal suite instead of a new direct assertion**
- **Reason:** The owned-file boundary for this task excluded `accrue_portal/test/accrue_portal/live/checkout_live_test.exs`.
- **Adjustment:** Left the portal test file unchanged, verified it still passes with the new enqueue path, and added direct Accrue-side proofs for synthetic event persistence, reduction, and telemetry.

## Known Stubs

None.

## Threat Flags

None beyond the plan’s declared synthetic webhook surface.

## Self-Check: PASSED

- Summary file present: `.planning/phases/101-accrue-portal-foundation-checkout/101-08-SUMMARY.md`
- Commits present: `b4599a2`, `ce86b7b`, `ee22a3f`
