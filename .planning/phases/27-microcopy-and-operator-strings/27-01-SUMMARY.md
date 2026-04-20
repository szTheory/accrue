---
phase: 27-microcopy-and-operator-strings
plan: 01
subsystem: ui
tags: [liveview, copy, admin]

requires: []
provides:
  - AccrueAdmin.Copy SSOT for money index empty states and DataTable defaults
  - Four money index LiveViews wired to Copy
  - ExUnit coverage for empty-table path
affects: [27-02, 27-03]

tech-stack:
  added: []
  patterns:
    - "Tier A operator copy lives in AccrueAdmin.Copy; LiveViews call named functions."

key-files:
  created:
    - accrue_admin/lib/accrue_admin/copy.ex
  modified:
    - accrue_admin/lib/accrue_admin/components/data_table.ex
    - accrue_admin/lib/accrue_admin/live/customers_live.ex
    - accrue_admin/lib/accrue_admin/live/subscriptions_live.ex
    - accrue_admin/lib/accrue_admin/live/invoices_live.ex
    - accrue_admin/lib/accrue_admin/live/charges_live.ex
    - accrue_admin/test/accrue_admin/components/data_table_test.exs
    - accrue_admin/test/accrue_admin/live/customers_live_test.exs
    - accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs
    - accrue_admin/test/accrue_admin/live/invoices_live_test.exs
    - accrue_admin/test/accrue_admin/live/charges_live_test.exs
    - .planning/phases/25-admin-ux-inventory/25-INV-03-spec-alignment.md

key-decisions:
  - "Empty index copy uses CONTEXT D-02 Tier A strings verbatim in Copy module."

patterns-established:
  - "Money index pages: empty_title/empty_copy from AccrueAdmin.Copy only."

requirements-completed: [COPY-01, COPY-03]

duration: 25min
completed: 2026-04-20
---

# Phase 27: Microcopy — Plan 01 summary

**Introduced `AccrueAdmin.Copy` and routed money index + DataTable default empty chrome through it, with tests and INV-03 traceability.**

## Task commits

1. **Task 1** — `27c6819` feat(27-01): add AccrueAdmin.Copy for money index empty states
2. **Task 2** — `8d7ada1` feat(27-01): delegate DataTable empty defaults to Copy
3. **Task 3** — `0e3b1df` feat(27-01): wire money index LiveViews to AccrueAdmin.Copy
4. **Task 4** — `99245df` test(27-01): assert Copy-backed money index empty states
5. **Task 5** — (this commit) docs: INV-03 C-01 evidence for Phase 27 plan 01

## Verification

- `cd accrue_admin && mix test test/accrue_admin/components/data_table_test.exs test/accrue_admin/live/customers_live_test.exs test/accrue_admin/live/subscriptions_live_test.exs test/accrue_admin/live/invoices_live_test.exs test/accrue_admin/live/charges_live_test.exs` — PASS

## Self-Check: PASSED
