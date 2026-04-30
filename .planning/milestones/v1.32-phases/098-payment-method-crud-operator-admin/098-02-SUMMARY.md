---
phase: 098-payment-method-crud-operator-admin
plan: 02
subsystem: payments
tags: [braintree, liveview, payment-methods, copy-export, host-facade]
requires:
  - phase: 098-01
    provides: canonical payment method CRUD facade and Braintree replacement semantics
provides:
  - admin operator controls for projected payment methods
  - copy-export-backed payment method strings
  - host-owned vault-reference wrappers for add and replace flows
  - hermetic host proof for canonical add/update payment method verbs
affects: [accrue_admin, examples/accrue_host, processor-parity]
tech-stack:
  added: []
  patterns: [server-driven LiveView mutations, host-owned vault handoff, copy-backed operator UI]
key-files:
  created: [examples/accrue_host/test/accrue_host/braintree_payment_method_flow_test.exs]
  modified:
    [
      accrue_admin/lib/accrue_admin/live/customer_live.ex,
      accrue_admin/lib/accrue_admin/copy/customer_payment_methods.ex,
      accrue_admin/lib/accrue_admin/copy.ex,
      accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex,
      accrue_admin/test/accrue_admin/live/customer_live_test.exs,
      examples/accrue_host/e2e/generated/copy_strings.json,
      examples/accrue_host/lib/accrue_host/billing.ex
    ]
key-decisions:
  - "Admin stays projection-first and server-driven: sync, set default, and guarded delete only."
  - "Host add/replace flows stay in AccrueHost.Billing and cross into Accrue.Billing only through vault-reference payloads."
patterns-established:
  - "Payment-method operator copy must route through AccrueAdmin.Copy and the export allowlist."
  - "Host Braintree proofs can use inline Agent-backed processor stubs to assert canonical CRUD handoff shapes."
requirements-completed: [PROC-16, PROC-17]
duration: 27 min
completed: 2026-04-30
---

# Phase 098 Plan 02: Payment Method CRUD Operator Admin Summary

**Admin payment-method controls now expose honest sync/default/delete actions while host billing owns Braintree add and replacement through vault-reference wrappers.**

## Performance

- **Duration:** 27 min
- **Started:** 2026-04-30T21:07:00Z
- **Completed:** 2026-04-30T21:34:00Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Added copy-backed operator controls in `CustomerLive` for payment-method sync, default reassignment, and guarded delete without embedding payment capture.
- Exported the new operator copy into the host E2E snapshot and covered the admin surface with LiveView tests.
- Added host-scoped add/replace wrappers in `AccrueHost.Billing` plus a hermetic Braintree proof that asserts canonical `add_payment_method/3` and `update_payment_method/3` usage.

## Task Commits

1. **Task 1: Implement the admin operator surface and copy/export-backed proof** - `03b4bd0` (`feat`)
2. **Task 2: Implement the host-owned add/replace seam proof against the canonical CRUD facade** - `4aa4fab` (`feat`)

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/live/customer_live.ex` - server-driven payment-method actions, guarded delete flow, and refreshed operator state
- `accrue_admin/lib/accrue_admin/copy/customer_payment_methods.ex` - new operator-facing copy strings
- `accrue_admin/lib/accrue_admin/copy.ex` - delegates for payment-method operator copy
- `accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex` - allowlist updates for exported copy
- `accrue_admin/test/accrue_admin/live/customer_live_test.exs` - render and destructive-flow proofs for the admin tab
- `examples/accrue_host/e2e/generated/copy_strings.json` - regenerated exported copy snapshot
- `examples/accrue_host/lib/accrue_host/billing.ex` - host wrappers for add/replace vault-reference seams
- `examples/accrue_host/test/accrue_host/braintree_payment_method_flow_test.exs` - hermetic host proof for add/replace flows

## Decisions Made

- Kept add/replace out of admin entirely and used explanatory host-handoff copy instead of embedded Braintree browser capture.
- Made payment methods an explicit LiveView assign so the post-delete UI reflects the refreshed projection immediately.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Refreshed the payment-method list through assigns after delete**
- **Found during:** Task 1
- **Issue:** The delete mutation removed the DB row, but the LiveView still rendered the deleted row selector after the event cycle.
- **Fix:** Moved the rendered payment-method inventory onto an explicit `:payment_methods` assign refreshed alongside customer detail.
- **Files modified:** `accrue_admin/lib/accrue_admin/live/customer_live.ex`, `accrue_admin/test/accrue_admin/live/customer_live_test.exs`
- **Verification:** `cd accrue_admin && mix test test/accrue_admin/live/customer_live_test.exs --warnings-as-errors`
- **Committed in:** `03b4bd0`

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Required for truthful operator UI state; no scope creep beyond the planned files.

## Issues Encountered

- `accrue_admin` initially lacked fetched local deps, so `mix deps.get` was needed before verification. The resulting `accrue_admin/mix.lock` change was discarded and not committed.
- The local Postgres pool intermittently reported `too_many_connections` during host-test startup, but the targeted host proof still completed successfully with `2 tests, 0 failures`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Admin and host payment-method surfaces now align with the Phase 98 product boundary.
- Browser-level handoff and broader processor matrix verification remain for the follow-on verification lane, not this plan.

