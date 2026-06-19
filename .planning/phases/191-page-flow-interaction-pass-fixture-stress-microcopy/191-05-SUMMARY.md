---
phase: 191-page-flow-interaction-pass-fixture-stress-microcopy
plan: "05"
subsystem: "Accrue Admin page-flow microcopy"
tags:
  - microcopy
  - liveview
  - playwright
  - ax187
  - destructive-confirmations
dependency_graph:
  requires:
    - "191-01 page-flow harness"
    - "191-02 fixture stress"
    - "191-03 responsive state coverage"
    - "191-04 interaction controls"
  provides:
    - "Centralized PAGE-02 page-state copy helpers"
    - "Object-specific destructive confirmation copy"
    - "Phase 191 browser DOM assertions for copy modules"
  affects:
    - accrue_admin
    - phase-191
    - phase-192
tech_stack:
  added: []
  patterns:
    - "AccrueAdmin.Copy.page_state_copy/2 owns true empty, filtered empty, unavailable, denied, disconnected, reconnecting, and recoverable error copy."
    - "Destructive LiveView confirmations call copy helpers with object, billing effect, owner scope, and audit consequence."
    - "Focused Playwright @copy assertions bind copy helpers to browser-rendered page flows."
key_files:
  created:
    - "accrue_admin/test/accrue_admin/copy_test.exs"
  modified:
    - "accrue_admin/lib/accrue_admin/copy.ex"
    - "accrue_admin/lib/accrue_admin/copy/invoice.ex"
    - "accrue_admin/lib/accrue_admin/copy/subscription.ex"
    - "accrue_admin/lib/accrue_admin/copy/coupon.ex"
    - "accrue_admin/lib/accrue_admin/copy/promotion_code.ex"
    - "accrue_admin/lib/accrue_admin/copy/connect.ex"
    - "accrue_admin/lib/accrue_admin/copy/billing_event.ex"
    - "accrue_admin/lib/accrue_admin/copy/locked.ex"
    - "accrue_admin/lib/accrue_admin/live/invoice_live.ex"
    - "accrue_admin/lib/accrue_admin/live/subscription_live.ex"
    - "accrue_admin/lib/accrue_admin/live/charge_live.ex"
    - "accrue_admin/lib/accrue_admin/live/webhooks_live.ex"
    - "accrue_admin/e2e/admin-page-flow-phase191.spec.js"
key_decisions:
  - "Page-state and destructive-action copy belongs in AccrueAdmin.Copy modules, not inline LiveView strings."
  - "Visible action failures should use recoverable resource-specific copy instead of raw inspect(reason) output."
  - "Browser copy assertions should target mounted page-flow DOM states and avoid auth redirects that render no stable body."
metrics:
  duration: "16m 34s"
  completed_at: "2026-06-19T16:21:16Z"
  tasks_completed: 2
status: complete
---

# Phase 191 Plan 05: Fixture Stress Microcopy Summary

## One-Liner

Phase 191 page-flow microcopy now centralizes recoverable state copy and destructive confirmations with concrete object, owner-scope, billing effect, and audit language.

## What Changed

- Added copy contract tests for PAGE-02 state distinctions and CPY-01 through CPY-03 destructive confirmation requirements.
- Added `AccrueAdmin.Copy.page_state_copy/2` and domain-specific helpers for invoice workflows, subscription workflows, charge refunds, webhook replay, not-found states, owner-scope denial, and domain vocabulary.
- Wired invoice, subscription, charge, and webhook LiveViews to the copy helpers for visible confirmation and recovery text.
- Replaced raw visible `inspect(reason)` action errors in plan-owned LiveViews with resource-specific recovery copy.
- Added Playwright `@copy` coverage for destructive confirmations and mounted page-flow recovery/object-specific copy.

## Task Commits

| Task | Type | Commit | Result |
| ---- | ---- | ------ | ------ |
| 1 | RED | `b5566439` | Added failing copy contract tests. |
| 1 | GREEN | `7bb642b2` | Implemented centralized copy helpers and updated copy modules. |
| 2 | RED | `d48c74bd` | Added failing browser assertions for destructive confirmation copy. |
| 2 | GREEN | `4077cf18` | Wired copy helpers into LiveViews and stabilized browser DOM assertions. |

## Verification

| Command | Result |
| ------- | ------ |
| `cd accrue_admin && mix test test/accrue_admin/copy_test.exs` | Passed: 4 tests, 0 failures. |
| `cd accrue_admin && node --check e2e/admin-page-flow-phase191.spec.js` | Passed. |
| `cd accrue_admin && npm run e2e:phase191 -- --grep "@copy" --project=chromium-desktop` | Passed: 3 tests, 0 failures. |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Critical functionality] Removed raw visible action errors**
- **Found during:** Task 2 GREEN wiring.
- **Issue:** Existing LiveView action failure paths rendered raw `inspect(reason)` text, which violated threat mitigation T-191-10 and CPY/PAGE recovery copy requirements.
- **Fix:** Replaced raw visible reasons with `Copy.page_state_copy(:recoverable_error, ...)` messages that name the resource, owner scope where relevant, and recovery action.
- **Files modified:** `invoice_live.ex`, `subscription_live.ex`, `charge_live.ex`, `webhooks_live.ex`.
- **Commit:** `4077cf18`

**2. [Rule 1 - Test correctness] Scoped browser copy assertions to stable rendered states**
- **Found during:** Task 2 GREEN verification.
- **Issue:** The existing member-login denial probe navigated through an auth redirect with no stable body, and a generic-copy guard banned the legitimate webhook row status label `Failed`.
- **Fix:** Browser copy coverage now asserts mounted object-specific subscription copy, true-empty recovery copy, webhook copy, and destructive confirmation copy; the generic-copy guard now targets vague prose rather than status labels.
- **Files modified:** `admin-page-flow-phase191.spec.js`.
- **Commit:** `4077cf18`

## Auth Gates

None.

## Known Stubs

None. Stub scan matched existing form-control placeholders and empty option values only; no mock data, hardcoded empty collections, or unwired UI copy was introduced.

## Threat Flags

None. No new endpoint, auth path, file access pattern, schema change, or dependency was introduced.

## TDD Gate Compliance

- RED commit present before implementation: `b5566439`
- GREEN commit present after RED: `7bb642b2`
- Task 2 RED commit present before browser wiring: `d48c74bd`
- Task 2 GREEN commit present after RED: `4077cf18`

## Deferred Issues

None.

## Self-Check: PASSED

- Found summary file: `.planning/phases/191-page-flow-interaction-pass-fixture-stress-microcopy/191-05-SUMMARY.md`
- Found test file: `accrue_admin/test/accrue_admin/copy_test.exs`
- Found task commits: `b5566439`, `7bb642b2`, `d48c74bd`, `4077cf18`
