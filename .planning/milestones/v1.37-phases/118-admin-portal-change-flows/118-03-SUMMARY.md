---
phase: 118-admin-portal-change-flows
plan: 03
summary_type: execution
requirements:
  - SCM-05
status: complete
files_changed:
  - accrue_portal/lib/accrue_portal/copy.ex
  - accrue_portal/lib/accrue_portal/live/subscription_live.ex
  - accrue_portal/lib/accrue_portal/live/subscriptions_live.ex
  - accrue_portal/test/accrue_portal/live/subscription_live_test.exs
  - accrue_portal/test/accrue_portal/live/subscriptions_live_test.exs
  - examples/accrue_host/lib/accrue_host/billing.ex
  - accrue/priv/accrue/templates/install/billing.ex.eex
  - examples/accrue_host/test/accrue_host/billing_facade_test.exs
  - examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs
completed_at: 2026-05-07
---

# Phase 118 Plan 03 Summary

Bounded mounted-portal plan-change preview and commit flow with provider-honest Braintree fallback copy, plus a thin host preview/commit facade seam kept adjacent to `Accrue.Billing`.

## What Changed

- Added portal copy and detail-page UI for one self-serve plan-change flow that previews before commit on supported providers.
- Kept Braintree provider-honest by showing explicit unsupported preview/self-serve wording instead of implying parity or schedule semantics.
- Added list-surface guidance that points supported customers to details for preview-backed changes and keeps Braintree host-managed.
- Added `AccrueHost.Billing.preview_plan_change/3` and `change_plan/3` as thin wrappers over `Accrue.Billing`, and mirrored the same seam in the installer template.
- Extended portal and example-host tests to prove the new wording, bounded flow, and thin-facade delegation.

## Verification

- `cd accrue_portal && mix test test/accrue_portal/live/subscription_live_test.exs test/accrue_portal/live/subscriptions_live_test.exs`
  Result: passed, 7 tests, 0 failures.
- `cd examples/accrue_host && mix test test/accrue_host/billing_facade_test.exs test/accrue_host_web/live/subscription_live_test.exs`
  Result: passed, 23 tests, 0 failures.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check

PASSED
