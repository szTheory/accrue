---
phase: 53-auxiliary-admin-connect-events-layout-verify
plan: "01"
subsystem: ui
tags: [copy, liveview, connect, events, ax-tokens]

requires: []
provides:
  - AccrueAdmin.Copy.Connect and Copy.BillingEvent modules with AccrueAdmin.Copy defdelegates
  - ConnectAccountsLive, ConnectAccountLive, EventsLive migrated to Copy + optional DataTable filter_submit_label
  - theme-exceptions.md Phase 53 reviewer note (no token bypasses)
affects: [verify01, export_copy_strings]

tech-stack:
  added: []
  patterns:
    - "Per-surface Copy submodules (Connect, BillingEvent) mirror Coupon/PromotionCode"

key-files:
  created:
    - accrue_admin/lib/accrue_admin/copy/connect.ex
    - accrue_admin/lib/accrue_admin/copy/billing_event.ex
    - accrue_admin/test/accrue_admin/copy/connect_test.exs
    - accrue_admin/test/accrue_admin/copy/billing_event_test.exs
  modified:
    - accrue_admin/lib/accrue_admin/copy.ex
    - accrue_admin/lib/accrue_admin/components/data_table.ex
    - accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex
    - accrue_admin/lib/accrue_admin/live/connect_account_live.ex
    - accrue_admin/lib/accrue_admin/live/events_live.ex
    - accrue_admin/guides/theme-exceptions.md

key-decisions:
  - "DataTable accepts optional filter_submit_label; default remains AccrueAdmin.Copy.data_table_filter_submit_label/0 for other list pages."

patterns-established:
  - "Connect/events operator strings use D-10 prefixes connect_accounts_*, connect_account_*, billing_events_*"

requirements-completed: [AUX-03, AUX-04, AUX-05]

duration: 45min
completed: 2026-04-23
---

# Phase 53 plan 01 summary

**Connect and billing events admin surfaces now read from the same Copy SSOT pattern as coupons and promotion codes, with an honest theme-exception register for Phase 53.**

## Accomplishments

- Added **`AccrueAdmin.Copy.Connect`** and **`AccrueAdmin.Copy.BillingEvent`** with UI-SPEC-aligned literals (including Connect index empty copy and events empty copy).
- Migrated **`ConnectAccountsLive`**, **`ConnectAccountLive`**, and **`EventsLive`** to **`AccrueAdmin.Copy.*`** and wired **`DataTable`** filter submit labels for Connect/events flows.
- Replaced the placeholder **`theme-exceptions.md`** row with a **Phase 53** reviewer note documenting **no new token bypasses**.

## Verification

- `cd accrue_admin && mix test` — **0** failures.
- Plan greps: **`AccrueAdmin.Copy.`** reference counts on the three LiveViews meet plan thresholds; no deauthorize affordances on **`ConnectAccountLive`**.

## Self-Check: PASSED
