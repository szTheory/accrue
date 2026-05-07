---
phase: 118-admin-portal-change-flows
plan: 02
subsystem: accrue_admin
tags: [admin, subscriptions, preview, braintree]
requires: [118-01]
provides: [SCM-04]
affects:
  - accrue_admin/lib/accrue_admin/copy/subscription.ex
  - accrue_admin/lib/accrue_admin/live/subscription_live.ex
  - accrue_admin/test/accrue_admin/live/subscription_live_test.exs
tech_stack:
  added: []
  patterns:
    - staged operator actions
    - provider-honest copy seams
    - preview-before-commit for supported plan swaps
key_files:
  created:
    - .planning/milestones/v1.37-phases/118-admin-portal-change-flows/118-02-SUMMARY.md
  modified:
    - accrue_admin/lib/accrue_admin/copy/subscription.ex
    - accrue_admin/lib/accrue_admin/live/subscription_live.ex
    - accrue_admin/test/accrue_admin/live/subscription_live_test.exs
decisions:
  - Reused the existing `prepare_action` and `confirm_action` flow instead of introducing a second admin change surface.
  - Kept preview limited to supported Stripe/Fake swap-plan staging while exposing quantity and item mutations as direct supported actions.
  - Kept Braintree swap-only with actionable `:plan_resolver` setup copy and explicit unsupported quantity/item guidance.
metrics:
  verification_command: cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs
  completed_at: 2026-05-07
---

# Phase 118 Plan 02: Admin Change Flow Summary

One bounded operator subscription-change flow now stages preview-backed plan swaps, exposes supported quantity and item mutations on Stripe/Fake, and keeps Braintree explicitly swap-only with setup and unsupported guidance.

## Tasks Completed

| Task | Result | Commit |
| ---- | ------ | ------ |
| 118-02-01 | Added preview-backed swap staging plus supported quantity/item admin actions | `9430313` |
| 118-02-02 | Added merge-blocking admin tests for preview, setup gates, and unsupported branches | `7561a5f` |

## Verification

- `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs`
  Result: passed, `8 tests, 0 failures`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed preview money rendering against `Accrue.Money`**
- **Found during:** verification rerun after the first implementation pass
- **Issue:** the new preview panel read `money.amount`, but `Accrue.Money` exposes `amount_minor`
- **Fix:** switched the renderer to `amount_minor` and reran the plan test command
- **Files modified:** `accrue_admin/lib/accrue_admin/live/subscription_live.ex`
- **Verification:** `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs`
- **Commit:** `9430313`

## Known Stubs

None.

## Threat Flags

None.

## Execution Notes

- State-tracking files outside the owned file list were left untouched for this run.

## Self-Check: PASSED

- Summary file exists at `.planning/milestones/v1.37-phases/118-admin-portal-change-flows/118-02-SUMMARY.md`
- Referenced commits `9430313` and `7561a5f` exist in git history
