---
phase: 199-cross-cutting-interaction-overlay-correctness-fixture-stress
plan: "11"
subsystem: ui
tags: [copy, microcopy, phoenix-liveview, exunit, phase199]
dependency_graph:
  requires:
    - Phase 199 Plan 03 ExUnit copy RED contracts
    - Phase 199 Plan 04 command-palette copy helper and safe HTML precedent
    - Phase 197/198 list and detail interaction propagation context
  provides:
    - CPY-01 resource-state copy helper surface
    - Hidden action context helper surface for compact repeated controls
    - Deterministic raw fallback guard coverage for copy/live/component paths
  affects:
    - phase199
    - admin-ui
    - copy
    - list-pages
    - detail-pages
    - overlay-actions
tech_stack:
  added: []
  patterns:
    - ExUnit copy contract tests
    - Phoenix LiveView hidden screen-reader context helpers
    - Deterministic ripgrep raw-copy guard
key_files:
  created:
    - .planning/phases/199-cross-cutting-interaction-overlay-correctness-fixture-stress/199-11-SUMMARY.md
  modified:
    - accrue_admin/lib/accrue_admin/copy.ex
    - accrue_admin/lib/accrue_admin/copy/connect.ex
    - accrue_admin/lib/accrue_admin/copy/customer_payment_methods.ex
    - accrue_admin/lib/accrue_admin/copy/invoice.ex
    - accrue_admin/lib/accrue_admin/copy/locked.ex
    - accrue_admin/lib/accrue_admin/copy/subscription.ex
    - accrue_admin/lib/accrue_admin/live/charge_live.ex
    - accrue_admin/lib/accrue_admin/live/invoice_live.ex
    - accrue_admin/lib/accrue_admin/live/subscription_live.ex
    - accrue_admin/test/accrue_admin/copy_test.exs
decisions:
  - Added a shared Copy.resource_state_copy/3 helper for Phase 199 copy-state call sites instead of inventing page-specific helper sets for every future call site.
  - Changed generic confirmation endings from Continue? to object-specific confirm verbs so the copy guard can reject bare continuation CTAs.
  - Updated invoice/subscription drawer hidden submit context in LiveViews because the deterministic guard scans live templates as well as copy modules.
metrics:
  started: 2026-06-29T23:35:38Z
  completed: 2026-06-29T23:42:29Z
  duration: 6m 51s
  tasks: 1
  files_changed: 10
status: complete
requirements_completed: [CPY-01, IXN-03]
---

# Phase 199 Plan 11: Copy Module Helpers and Deterministic Copy Guard Summary

CPY-01 resource-state and hidden-action copy helpers with deterministic raw fallback guard coverage.

## Overview

Plan 199-11 created the shared copy helper surface needed by later Phase 199 list/detail sweeps. The implementation centralizes resource/state messages for empty, filtered, loading, error, and permission states, adds hidden action context helpers for compact controls, and tightens the deterministic raw-string guard so generic fallback copy cannot drift back into copy, LiveView, or component paths.

## Tasks Completed

| Task | Name | Status | Commit |
| ---- | ---- | ------ | ------ |
| 1 | Implement CPY-01 copy helper surface with TDD guardrails | Complete | 31e18576, 246ae917 |

## Commits

| Commit | Type | Description |
| ------ | ---- | ----------- |
| 31e18576 | test | Added failing ExUnit contracts for resource-state copy helpers, hidden action context helpers, and deterministic raw/voice guards. |
| 246ae917 | feat | Implemented the shared copy helpers, resolved raw fallback strings in copy modules, and routed guarded live copy through the helper surface. |

## Files Changed

| File | Change |
| ---- | ------ |
| `accrue_admin/test/accrue_admin/copy_test.exs` | Added CPY-01 helper contract tests, copy uniqueness checks, raw fallback guard, and brand voice guard. |
| `accrue_admin/lib/accrue_admin/copy.ex` | Added `resource_state_copy/3`, hidden action context helpers, deterministic resource/state copy data, and non-generic filtered/refund confirmations. |
| `accrue_admin/lib/accrue_admin/copy/invoice.ex` | Replaced generic confirmation ending with invoice-specific confirmation copy. |
| `accrue_admin/lib/accrue_admin/copy/subscription.ex` | Replaced generic confirmation ending with subscription-specific confirmation copy. |
| `accrue_admin/lib/accrue_admin/copy/locked.ex` | Replaced generic replay confirmation ending with action-specific confirmation copy. |
| `accrue_admin/lib/accrue_admin/copy/connect.ex` | Replaced generic submitted status copy with Connect-specific status copy. |
| `accrue_admin/lib/accrue_admin/copy/customer_payment_methods.ex` | Replaced a blocked brand-voice term while preserving payment-method meaning. |
| `accrue_admin/lib/accrue_admin/live/invoice_live.ex` | Routed hidden drawer submit context through the copy helper surface. |
| `accrue_admin/lib/accrue_admin/live/subscription_live.ex` | Routed hidden drawer submit context through the copy helper surface. |
| `accrue_admin/lib/accrue_admin/live/charge_live.ex` | Routed refund source-event confirmation through the copy helper surface. |

## Decisions Made

- Added a shared `Copy.resource_state_copy/3` helper covering `:customers`, `:invoices`, `:subscriptions`, `:payments`, `:connect_accounts`, `:webhooks`, `:events`, `:coupons`, `:promotion_codes`, and `:dunning` for six required CPY-01 states.
- Kept the helper return shape as `%{heading: ..., body: ...}` so future list/detail call sites can adopt it without additional view-model plumbing.
- Added copy-owned hidden context helpers for repeated compact action labels instead of leaving LiveViews to concatenate generic hidden strings.
- Treated the deterministic raw-string guard as spanning copy modules and existing LiveView call sites, then resolved the current failures inline so the guard can remain strict.

## Verification

| Check | Result |
| ----- | ------ |
| RED: `cd accrue_admin && mix test test/accrue_admin/copy_test.exs --max-failures 5` | Failed as expected before implementation. The failures covered missing helpers and blocked raw/voice strings. |
| GREEN: `cd accrue_admin && mix test test/accrue_admin/copy_test.exs --max-failures 5` | Passed: 10 tests, 0 failures. |
| Raw guard: Node `rg` guard from 199-11 PLAN.md | Passed with no unapproved generic strings. |
| LiveView sanity: `cd accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs test/accrue_admin/live/subscription_live_test.exs test/accrue_admin/live/charge_live_test.exs --max-failures 5` | Passed: 39 tests, 0 failures. |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Functionality] Routed guarded LiveView copy through the helper surface**
- **Found during:** Task 1 GREEN implementation
- **Issue:** The plan's deterministic raw-string guard scans `lib/accrue_admin/live` as well as copy modules. Existing hidden submit and refund confirmation strings in LiveViews would keep the guard failing even after the copy modules were corrected.
- **Fix:** Added hidden action context helpers and a source-event-aware refund confirmation path in `AccrueAdmin.Copy`, then routed invoice, subscription, and charge LiveViews through those helpers.
- **Files modified:** `accrue_admin/lib/accrue_admin/copy.ex`, `accrue_admin/lib/accrue_admin/live/invoice_live.ex`, `accrue_admin/lib/accrue_admin/live/subscription_live.ex`, `accrue_admin/lib/accrue_admin/live/charge_live.ex`
- **Commit:** 246ae917
- **Verification:** Focused copy tests, the raw-string guard, and invoice/subscription/charge LiveView tests passed.

## Auth Gates

None.

## Known Stubs

None. The stub-pattern scan found existing form defaults, select empty values, placeholder attributes, and test assertions in touched LiveView/test files; none are unimplemented UI data sources or blockers for the CPY-01 helper goal.

## Threat Flags

None. This plan added no new endpoints, schema changes, package installs, file access paths, or network trust boundaries.

## TDD Gate Compliance

- RED gate commit present: `31e18576`
- GREEN gate commit present after RED: `246ae917`
- Refactor gate: not needed

## Next Phase Readiness

The shared helper surface is ready for later Phase 199 plans to replace list/detail call-site copy. Later sweeps can use `Copy.resource_state_copy/3` for page state copy and the hidden action helpers for repeated compact controls without reintroducing generic fallback strings.

## Self-Check: PASSED

- Verified the summary file exists at `.planning/phases/199-cross-cutting-interaction-overlay-correctness-fixture-stress/199-11-SUMMARY.md`.
- Verified task commits exist: `31e18576`, `246ae917`.
- Verified all task files listed above were created or modified in the task commit range.
- Verified focused copy tests, deterministic raw guard, and focused LiveView sanity tests passed.
