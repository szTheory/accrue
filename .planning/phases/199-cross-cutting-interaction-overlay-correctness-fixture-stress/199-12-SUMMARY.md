---
phase: 199
plan: 12
name: list-and-recovery-copy-call-site-sweep
status: complete
subsystem: admin-ui
tags:
  - copy
  - microcopy
  - phoenix-liveview
  - phase199
dependencies:
  requires:
    - "199-11 shared copy helper surface"
  provides:
    - "List and recovery page state copy routed through AccrueAdmin.Copy.resource_state_copy/3"
    - "Source-contract coverage for named list and recovery call sites"
  affects:
    - phase199
    - admin-ui
    - list-pages
    - recovery
    - copy
tech_stack:
  added: []
  patterns:
    - "Resource state copy lookup at list LiveView empty/loading state boundaries"
    - "Focused source contract for CPY-01 copy helper adoption"
key_files:
  created:
    - ".planning/phases/199-cross-cutting-interaction-overlay-correctness-fixture-stress/199-12-SUMMARY.md"
  modified:
    - "accrue_admin/test/accrue_admin/copy_test.exs"
    - "accrue_admin/lib/accrue_admin/copy.ex"
    - "accrue_admin/lib/accrue_admin/components/at_risk_table.ex"
    - "accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex"
    - "accrue_admin/lib/accrue_admin/live/customers_live.ex"
    - "accrue_admin/lib/accrue_admin/live/invoices_live.ex"
    - "accrue_admin/lib/accrue_admin/live/charges_live.ex"
    - "accrue_admin/lib/accrue_admin/live/webhooks_live.ex"
    - "accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex"
    - "accrue_admin/lib/accrue_admin/live/subscriptions_live.ex"
    - "accrue_admin/lib/accrue_admin/live/coupons_live.ex"
    - "accrue_admin/lib/accrue_admin/live/promotion_codes_live.ex"
    - "accrue_admin/lib/accrue_admin/live/events_live.ex"
key_decisions:
  - "Use Copy.resource_state_copy/3 at each list LiveView state resolver instead of adding page-specific helper sets."
  - "Keep DataTable availability behavior conditional while routing only state copy through shared helpers."
  - "Pass dunning queue copy into AtRiskTable from RecoveryLive so the recovery work-queue empty state uses the same Copy surface."
requirements_completed:
  - CPY-01
  - IXN-03
metrics:
  started_at: "2026-06-30T00:14:18Z"
  completed_at: "2026-06-30T01:59:59Z"
  duration: "1h 45m 41s"
  tasks_completed: 1
  files_changed: 13
commits:
  - "86e99994 test(199-12): add failing list copy call-site contract"
  - "130e965a feat(199-12): route list state copy through shared helpers"
---

# Phase 199 Plan 12: List and Recovery Copy Call-Site Sweep Summary

List and recovery state copy now resolves through `AccrueAdmin.Copy.resource_state_copy/3` with focused source-contract coverage.

## What Changed

- Added a CPY-01 source contract that names each required list/recovery page and fails unless it calls the shared resource-state helper surface.
- Routed Customers, Invoices, Payments, Webhooks, Connect accounts, Subscriptions, Coupons, Promotion codes, Events, and Recovery list-state copy through `Copy.resource_state_copy/3`.
- Added recovery overview Copy helpers and passed dunning queue empty-state copy into `AtRiskTable`.
- Preserved DataTable unavailable-control behavior by keeping clear filters, bulk action, pagination, and clear-row-selection controls conditionally rendered.

## Task Results

| Task | Name | Status | Commit |
| ---- | ---- | ------ | ------ |
| 1 | Sweep list and recovery page copy call sites | Complete | `86e99994`, `130e965a` |

## Verification

| Check | Result |
| ----- | ------ |
| RED: `cd accrue_admin && mix test test/accrue_admin/copy_test.exs --max-failures 5` | Failed as expected before implementation on Recovery missing `Copy.resource_state_copy/3`. |
| GREEN: `cd accrue_admin && mix test test/accrue_admin/copy_test.exs --max-failures 5` | Passed: 11 tests, 0 failures. |
| `cd accrue_admin && mix compile --warnings-as-errors` | Passed. |
| Dependency-note proof | `rg "Copy\\.resource_state_copy"` found calls in every named list/recovery page. |
| Unavailable controls proof | `data_table.ex` still gates clear filters, bulk action, next-page pagination, and clear-selection controls with `:if` conditions. |

## Dependency-Note Proof

The automated key-link checker could not expand the wildcard from `accrue_admin/lib/accrue_admin/live/*_live.ex` to `copy.ex`, so this plan verified the named files directly:

| File | Helper Call |
| ---- | ----------- |
| `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` | `Copy.resource_state_copy(:dunning, :queue_empty)` |
| `accrue_admin/lib/accrue_admin/live/customers_live.ex` | `Copy.resource_state_copy(:customers, state)` |
| `accrue_admin/lib/accrue_admin/live/invoices_live.ex` | `Copy.resource_state_copy(:invoices, state)` |
| `accrue_admin/lib/accrue_admin/live/charges_live.ex` | `Copy.resource_state_copy(:payments, state)` |
| `accrue_admin/lib/accrue_admin/live/webhooks_live.ex` | `Copy.resource_state_copy(:webhooks, state)` |
| `accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex` | `Copy.resource_state_copy(:connect_accounts, state)` |
| `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` | `Copy.resource_state_copy(:subscriptions, state)` |
| `accrue_admin/lib/accrue_admin/live/coupons_live.ex` | `Copy.resource_state_copy(:coupons, state)` |
| `accrue_admin/lib/accrue_admin/live/promotion_codes_live.ex` | `Copy.resource_state_copy(:promotion_codes, state)` |
| `accrue_admin/lib/accrue_admin/live/events_live.ex` | `Copy.resource_state_copy(:events, state)` |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Functionality] Recovery work-queue copy lived in the table component**
- **Found during:** Task 1
- **Issue:** Recovery was listed as a target page, but the at-risk work-queue empty-state strings were owned by `AtRiskTable`, so changing only `RecoveryLive` would leave a recovery list state outside the Copy helper surface.
- **Fix:** Added an `empty_copy` attr to `AtRiskTable`, normalized it with the existing dunning fallback, and passed `Copy.resource_state_copy(:dunning, :queue_empty)` from `RecoveryLive`.
- **Files modified:** `accrue_admin/lib/accrue_admin/components/at_risk_table.ex`, `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex`, `accrue_admin/lib/accrue_admin/copy.ex`
- **Commit:** `130e965a`

**2. [Rule 1 - Bug] Resource-state helper copy was too generic for three resource contracts**
- **Found during:** Task 1 GREEN verification
- **Issue:** Focused copy tests required filtered/queue states to remain resource-specific. Event filtered copy, connected-account queue copy, and webhook queue copy were too generic.
- **Fix:** Updated the Copy metadata for events, connect accounts, and webhooks so the helper-generated text names the relevant resource.
- **Files modified:** `accrue_admin/lib/accrue_admin/copy.ex`
- **Commit:** `130e965a`

## Auth Gates

None.

## Known Stubs

None. Stub scan found only legitimate filter `placeholder` labels in the touched LiveViews; no newly introduced mock data, TODO/FIXME markers, or unimplemented UI data sources were found.

## Threat Flags

None. The plan changed UI copy routing and component inputs only; it did not add network endpoints, auth paths, file access, schema changes, or new trust-boundary behavior.

## TDD Gate Compliance

- RED gate commit: `86e99994 test(199-12): add failing list copy call-site contract`
- GREEN gate commit: `130e965a feat(199-12): route list state copy through shared helpers`

## Self-Check: PASSED

- Summary file exists at `.planning/phases/199-cross-cutting-interaction-overlay-correctness-fixture-stress/199-12-SUMMARY.md`.
- Task commits exist in git history: `86e99994`, `130e965a`.
- Post-implementation status contains only the plan summary and the pre-existing untracked `.planning/research/.cache/`.
