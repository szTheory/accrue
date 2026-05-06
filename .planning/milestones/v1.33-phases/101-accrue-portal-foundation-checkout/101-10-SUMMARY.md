---
phase: 101
plan: 10
subsystem: portal-proof
tags:
  - phoenix
  - liveview
  - portal
  - multitenancy
  - tests
requires:
  - 101-06
  - 101-07
  - 101-09
provides:
  - router coverage for the remaining BT-03 routes
  - payment-method and invoice page proofs from the portal harness
  - fail-closed wrong-tenant payment-method mutations
affects:
  - BT-03
  - D-19
  - portal payment-method and invoice surfaces
tech_stack:
  added:
    - focused LiveView proofs for payment methods, add-card, and invoices
  patterns:
    - wrong-tenant controller denials via customer-scoped read-model lookup
    - package-local portal fixtures reused across page proofs
key_files:
  created:
    - accrue_portal/test/accrue_portal/live/payment_methods_live_test.exs
    - accrue_portal/test/accrue_portal/live/add_payment_method_live_test.exs
    - accrue_portal/test/accrue_portal/live/invoices_live_test.exs
    - accrue_portal/test/accrue_portal/live/payment_methods_wrong_tenant_test.exs
    - accrue_portal/test/accrue_portal/live/invoices_wrong_tenant_test.exs
  modified:
    - accrue_portal/test/accrue_portal/router_test.exs
    - accrue_portal/lib/accrue_portal/billing_read_model.ex
    - accrue_portal/lib/accrue_portal/controllers/payment_method_controller.ex
decisions:
  - Router proof now covers `/payment-methods/new` alongside the existing mounted surfaces.
  - Wrong-tenant payment-method mutations return an explicit `404` response instead of surfacing an internal error.
  - Invoice denial is proven as customer-scoped invisibility because the portal exposes invoice history as a list page, not a tenant-addressable detail route.
metrics:
  duration: "16m"
  completed_at: "2026-05-02T15:16:00Z"
  task_commits: []
---

# Phase 101 Plan 10: Portal Payment Method and Invoice Proof Summary

The remaining BT-03 portal surfaces now have focused package-local proof: route coverage for the mounted payment-method and invoice pages, Hosted Fields add-card coverage, and explicit tenant-boundary checks for payment-method mutations and invoice visibility.

## Completed Work

1. Extended the router regression to cover `/billing/payment-methods/new` and the full mounted LiveView count for the portal shell.
2. Added focused LiveView tests for the payment-method index, the Hosted Fields add-card page, and invoice history rendering.
3. Added explicit wrong-tenant mutation coverage for payment-method default/delete actions and dedicated invoice denial coverage for foreign records.
4. Hardened the payment-method controller path so foreign ids now return `404` instead of letting `Ecto.NoResultsError` escape as a `500`.

## Verification

Commands run:

```bash
cd /Users/jon/projects/accrue/accrue_portal && mix test test/accrue_portal/router_test.exs test/accrue_portal/live/payment_methods_live_test.exs test/accrue_portal/live/add_payment_method_live_test.exs test/accrue_portal/live/invoices_live_test.exs test/accrue_portal/live/payment_methods_wrong_tenant_test.exs test/accrue_portal/live/invoices_wrong_tenant_test.exs
```

Results:
- Focused router and portal proof suite passed.
- Final result: `9 tests, 0 failures`.

## Deviations from Plan

### Auto-fixed Issues

**1. Wrong-tenant payment-method mutations were leaking as `500`**
- **Found during:** focused proof verification
- **Issue:** `PaymentMethodController` used `BillingReadModel.payment_method!/2`, which raised `Ecto.NoResultsError` for foreign ids and converted the denial path into an internal error.
- **Fix:** Added a non-bang scoped lookup and returned an explicit `404` response for foreign payment-method ids.
- **Files modified:** `accrue_portal/lib/accrue_portal/billing_read_model.ex`, `accrue_portal/lib/accrue_portal/controllers/payment_method_controller.ex`

### Ownership-Constrained Adjustments

**1. Invoice D-19 proof is page-level denial rather than route-level not-found**
- **Reason:** The portal exposes invoice history as a single customer-scoped list page; there is no invoice detail route keyed by tenant-controlled ids.
- **Adjustment:** Proved the boundary by asserting foreign invoice numbers and hosted URLs never render for the signed-in customer.

## Known Stubs

None.

## Threat Flags

None beyond the plan's declared tenant-boundary proof surface.

## Self-Check: PASSED

- Summary file present: `.planning/phases/101-accrue-portal-foundation-checkout/101-10-SUMMARY.md`
- Focused verification passed in the current workspace
