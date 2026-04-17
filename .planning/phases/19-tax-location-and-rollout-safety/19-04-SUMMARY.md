---
phase: 19-tax-location-and-rollout-safety
plan: 04
subsystem: ui
tags: [stripe-tax, accrue-admin, liveview, host-app, exunit]
requires:
  - phase: 19-02
    provides: public `Accrue.Billing.update_customer_tax_location/2` and stable invalid-location repair errors
  - phase: 19-03
    provides: local subscription and invoice disabled-reason/finalization-error projections
provides:
  - Admin customer, subscription, and invoice detail visibility for local tax-risk state
  - Host tax-location repair form routed through `AccrueHost.Billing`
  - Focused admin and host package-local tests for invalid-location recovery messaging
affects: [19-05, TAX-02, TAX-03, accrue_admin, examples/accrue_host]
tech-stack:
  added: []
  patterns: [local tax-risk projection rendering, host facade tax-location repair wrapper, example-host migration parity]
key-files:
  created:
    - .planning/phases/19-tax-location-and-rollout-safety/19-04-SUMMARY.md
    - examples/accrue_host/priv/repo/migrations/20260417180000_add_automatic_tax_columns_to_billing_tables.exs
    - examples/accrue_host/priv/repo/migrations/20260417193000_add_tax_rollout_safety_columns.exs
    - examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs
  modified:
    - accrue_admin/lib/accrue_admin/live/customer_live.ex
    - accrue_admin/lib/accrue_admin/live/subscription_live.ex
    - accrue_admin/lib/accrue_admin/live/invoice_live.ex
    - accrue_admin/test/accrue_admin/live/customer_live_test.exs
    - accrue_admin/test/accrue_admin/live/subscription_live_test.exs
    - accrue_admin/test/accrue_admin/live/invoice_live_test.exs
    - examples/accrue_host/lib/accrue_host/billing.ex
    - examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex
    - examples/accrue_host/test/accrue_host/billing_facade_test.exs
key-decisions:
  - "Admin tax-risk panels stay on local `Repo` rows and projected observability fields instead of fetching or displaying raw provider payloads."
  - "The host repair flow goes through a generated-facade wrapper over `Accrue.Billing.update_customer_tax_location/2` so the example keeps proving public Accrue APIs."
patterns-established:
  - "Operator tax diagnostics in `accrue_admin` should summarize projected disabled reasons and finalization codes with local recovery copy."
  - "When the example host app consumes new Accrue billing columns, it must copy the corresponding generated migrations so package-local tests stay schema-compatible."
requirements-completed: [TAX-02, TAX-03]
duration: 9 min
completed: 2026-04-17
---

# Phase 19 Plan 04: Tax Risk Visibility Summary

**Admin detail views now expose local tax-risk state, and the canonical host example can collect customer tax location through its public billing facade before tax-enabled subscription start**

## Performance

- **Duration:** 9 min
- **Started:** 2026-04-17T18:21:00Z
- **Completed:** 2026-04-17T18:30:17Z
- **Tasks:** 2
- **Files modified:** 14

## Accomplishments
- Added admin-side tax-risk visibility for customer, subscription, and invoice detail screens using only local projected billing rows.
- Added a host-facing tax-location repair form and facade wrapper that use public Accrue billing APIs instead of direct provider access.
- Added focused admin and host tests covering repair guidance, disabled-reason copy, and finalization failure visibility.

## Task Commits

Each task was committed atomically:

1. **Task 1: Surface tax-risk state in admin detail views** - `f41d539` (feat)
2. **Task 2: Add a host-facing tax-location repair path** - `d167abe` (feat)

## Files Created/Modified
- `accrue_admin/lib/accrue_admin/live/customer_live.ex` - Adds a customer-level tax-risk KPI derived from projected subscriptions and invoices.
- `accrue_admin/lib/accrue_admin/live/subscription_live.ex` - Adds local automatic-tax disabled-reason recovery copy for operators.
- `accrue_admin/lib/accrue_admin/live/invoice_live.ex` - Adds local disabled-reason and finalization-failure visibility beside invoice controls.
- `accrue_admin/test/accrue_admin/live/customer_live_test.exs` - Covers customer tax-risk summary output.
- `accrue_admin/test/accrue_admin/live/subscription_live_test.exs` - Covers subscription disabled-reason recovery copy.
- `accrue_admin/test/accrue_admin/live/invoice_live_test.exs` - Covers invoice finalization failure visibility.
- `examples/accrue_host/lib/accrue_host/billing.ex` - Adds a generated-facade wrapper for tax-location updates.
- `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` - Adds the host repair form, stable invalid-location guidance, and `automatic_tax: true` subscription start.
- `examples/accrue_host/test/accrue_host/billing_facade_test.exs` - Covers delegation through the host facade to the public Accrue API.
- `examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs` - Covers the host repair form and stable invalid-location guidance.
- `examples/accrue_host/priv/repo/migrations/20260417180000_add_automatic_tax_columns_to_billing_tables.exs` - Syncs the example host schema with Phase 18 automatic-tax columns.
- `examples/accrue_host/priv/repo/migrations/20260417193000_add_tax_rollout_safety_columns.exs` - Syncs the example host schema with Phase 19 rollout-safety columns.

## Decisions Made
- Kept all admin diagnosis copy anchored to local disabled-reason and finalization-code fields, not raw Stripe payloads or dashboard lookups.
- Wrapped host tax-location repair in `AccrueHost.Billing` so the example stays within the host-owned facade pattern established by the installer.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added the missing host LiveView test path**
- **Found during:** Task 2 (Add a host-facing tax-location repair path)
- **Issue:** The plan’s verification command referenced `examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs`, but that file did not exist in the repo.
- **Fix:** Added the missing LiveView test file with focused repair-form and invalid-location guidance coverage.
- **Files modified:** `examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs`
- **Verification:** `cd examples/accrue_host && mix test test/accrue_host/billing_facade_test.exs test/accrue_host_web/live/subscription_live_test.exs`
- **Committed in:** `d167abe`

**2. [Rule 3 - Blocking] Synced the example host database schema with Phase 18/19 Accrue billing columns**
- **Found during:** Task 2 (Add a host-facing tax-location repair path)
- **Issue:** The example host test database did not have `automatic_tax`, `automatic_tax_status`, `automatic_tax_disabled_reason`, or `last_finalization_error_code`, so focused host tests crashed on missing columns.
- **Fix:** Added the generated migration copies for the Phase 18 and Phase 19 billing-table column additions under `examples/accrue_host/priv/repo/migrations/`.
- **Files modified:** `examples/accrue_host/priv/repo/migrations/20260417180000_add_automatic_tax_columns_to_billing_tables.exs`, `examples/accrue_host/priv/repo/migrations/20260417193000_add_tax_rollout_safety_columns.exs`
- **Verification:** `cd examples/accrue_host && mix test test/accrue_host/billing_facade_test.exs test/accrue_host_web/live/subscription_live_test.exs`
- **Committed in:** `d167abe`

---

**Total deviations:** 2 auto-fixed (2 blocking)
**Impact on plan:** Both fixes were required to make the planned host verification surface exist and run against the current Accrue schema. No behavior outside the plan scope changed.

## Issues Encountered

- The host LiveView proof initially reused a generic form selector and then exposed that the example app’s copied billing migrations had drifted behind the core package. After the test path and migration parity were restored, the package-local verification command passed cleanly.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 19 now has public repair flow proof in the host example and local operator visibility for tax rollback state in admin.
- The remaining phase work is `19-05`, which can build on the stable copy and local-field contract now visible in admin and host surfaces.

## Self-Check: PASSED

- Found `.planning/phases/19-tax-location-and-rollout-safety/19-04-SUMMARY.md`
- Found commit `f41d539`
- Found commit `d167abe`
