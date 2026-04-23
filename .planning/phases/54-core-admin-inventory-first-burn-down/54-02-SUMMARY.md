---
phase: 54-core-admin-inventory-first-burn-down
plan: "02"
subsystem: ui
tags: [accrue_admin, copy, adm-08, invoices]

requires:
  - phase: 54-01
    provides: ADM-07 parity guide and ExDoc registration
provides:
  - AccrueAdmin.Copy.Invoice module with defdelegates from AccrueAdmin.Copy
  - InvoicesLive and InvoiceLive operator chrome routed through Copy
  - Updated core-admin-parity.md invoice rows (clean — ADM-08)
affects: [55]

tech-stack:
  added: []
  patterns:
    - "Domain Copy submodule + defdelegate facade (matches Subscription/Coupon)"

key-files:
  created:
    - accrue_admin/lib/accrue_admin/copy/invoice.ex
  modified:
    - accrue_admin/lib/accrue_admin/copy.ex
    - accrue_admin/lib/accrue_admin/live/invoices_live.ex
    - accrue_admin/lib/accrue_admin/live/invoice_live.ex
    - accrue_admin/test/accrue_admin/live/invoices_live_test.exs
    - accrue_admin/test/accrue_admin/live/invoice_live_test.exs
    - accrue_admin/guides/core-admin-parity.md

key-decisions:
  - "No new theme-exceptions.md rows — token fixes not required (D-10)."

patterns-established:
  - "Invoice operator strings live in AccrueAdmin.Copy.Invoice; Copy.* delegates preserve call sites."

requirements-completed: [ADM-08]

duration: 45min
completed: 2026-04-22
---

# Phase 54 plan 02 summary

**Closed ADM-08 P0 on the invoice list/detail anchor by centralizing operator literals in `AccrueAdmin.Copy.Invoice`, migrating both LiveViews, and refreshing the ADM-07 matrix rows to `clean — ADM-08`.**

## Performance

- **Tasks:** 5 (Task 5: no `theme-exceptions.md` edits — N/A)
- **Files touched:** 7

## Accomplishments

- New **`Copy.Invoice`** module plus **`Copy`** defdelegates (empty states and invoice warnings moved off inline `Copy` defs).
- **`InvoicesLive`** and **`InvoiceLive`** HEEx, assigns, PDF error path, confirm copy, `pdf_summary`, and `source_event_select` labels use **`Copy.*`**.
- **`core-admin-parity.md`** invoice rows now reflect post-burn-down posture.
- **ExUnit** assertions track **`Copy`** / **`AccrueAdmin.Copy.Invoice`** for migrated chrome.

## Task commits

1. **Task 1: Extend Copy surface** — `3c48a4f`
2. **Task 2: Migrate InvoicesLive** — `8b0d174`
3. **Task 3: Migrate InvoiceLive** — `c392875`
4. **Task 4: Tests + parity matrix** — `50d3bf8`
5. **Task 5: Token exceptions** — N/A (no new `theme-exceptions.md` rows)

## Deviations from plan

None.

## Issues encountered

None.

## Next phase readiness

Phase **55** can extend VERIFY-01 against the invoice anchor using this Copy baseline.

---
*Phase: 54-core-admin-inventory-first-burn-down*
*Completed: 2026-04-22*
