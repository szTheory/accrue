---
phase: 27-microcopy-and-operator-strings
plan: 02
subsystem: ui
tags: [liveview, copy, admin]

requires:
  - phase: 27-01
    provides: AccrueAdmin.Copy module
provides:
  - AccrueAdmin.Copy.Locked with owner_access_denied/0
  - Money detail Copy helpers and LiveView wiring
affects: [27-03]

tech-stack:
  added: []
  patterns:
    - "Operator flashes and denial strings route through Copy / Copy.Locked."

key-files:
  created:
    - accrue_admin/lib/accrue_admin/copy/locked.ex
  modified:
    - accrue_admin/lib/accrue_admin/copy.ex
    - accrue_admin/lib/accrue_admin/live/subscription_live.ex
    - accrue_admin/lib/accrue_admin/live/customer_live.ex
    - accrue_admin/lib/accrue_admin/live/invoice_live.ex
    - accrue_admin/lib/accrue_admin/live/charge_live.ex
    - accrue_admin/test/accrue_admin/live/subscription_live_test.exs
    - accrue_admin/test/accrue_admin/live/customer_live_test.exs
    - accrue_admin/test/accrue_admin/live/invoice_live_test.exs
    - accrue_admin/test/accrue_admin/live/charge_live_test.exs
    - .planning/phases/25-admin-ux-inventory/25-INV-03-spec-alignment.md

key-decisions:
  - "payment_processor_action_warning/1 keeps inspect/1 parity with prior HEEx interpolation."

patterns-established:
  - "Detail LiveViews: use Copy.* for Tier A churn; Copy.Locked for verbatim denial."

requirements-completed: [COPY-02, COPY-03]

duration: 30min
completed: 2026-04-20
---

# Phase 27: Microcopy — Plan 02 summary

**Centralized money-detail operator strings into `AccrueAdmin.Copy` / `AccrueAdmin.Copy.Locked` with regression tests and INV-03 trace rows.**

## Task commits

1. **Task 1** — `7c3d304` feat(27-02): add Copy.Locked and money detail copy helpers
2. **Task 2** — `9ce9dde` feat(27-02): migrate subscription and customer detail copy to Copy
3. **Task 3** — `57847ff` feat(27-02): migrate invoice and charge detail flashes to Copy
4. **Task 4** — (next commit) test(27-02): assert Copy-backed detail strings
5. **Task 5** — (next commit) docs: INV-03 + this SUMMARY

## Verification

- `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs test/accrue_admin/live/invoice_live_test.exs test/accrue_admin/live/charge_live_test.exs test/accrue_admin/live/customer_live_test.exs` — PASS

## Self-Check: PASSED
