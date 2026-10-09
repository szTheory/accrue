---
phase: 237-admin-invoices-payments-recovery
reviewed: 2026-10-09T02:10:46Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - examples/accrue_host/e2e/onboarding_and_billing.spec.js
  - examples/accrue_host/test/accrue_host_web/live/recovery_analytics_test.exs
  - accrue_admin/assets/css/app.css
  - accrue_admin/lib/accrue_admin/live/subscription_live.ex
  - accrue_admin/priv/static/accrue_admin.css
  - accrue/test/accrue/analytics/dunning_test.exs
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
status: clean
---

# Phase 237: Code Review Report

**Reviewed:** 2026-10-09T02:10:46Z
**Depth:** standard  
**Files Reviewed:** 6
**Status:** clean

## Summary

Incremental re-review of the two regression-gate files found no remaining issues. The onboarding spec now describes the Fake-versus-Braintree customer mismatch accurately and skips this legacy Fake journey when `ACCRUE_HOST_BROWSER_USE_BRAINTREE=1`, preventing its unsupported-state assertion from being applied to the Braintree configuration. The targeted default-Fake Playwright run was reported as passing 1/1.

The recovery analytics test's fake-clock adjustment keeps the inserted database-timestamped events within the 30-day query window and restores the clock in `on_exit`; its async page render waits for the query before asserting KPI output.

Incremental review covered the admin typography and Dunning currency regression fixes. The queue title now uses the existing `.ax-type-label` semantic role, while its queue-specific selector only supplies color; the rebuilt static CSS contains those source changes. The Dunning aggregation groups directly on the JSON currency value, so rows without a currency key correctly form a `nil` currency group, matching the updated expectations. No issues found in this incremental scope.

Disposition trace: WR-01 (loading state showed a false zero count) was fixed and confirmed by its component test. WR-02 (misstated Braintree capability in the onboarding regression spec) is fixed by the accurate processor-mismatch explanation and configuration guard. The prior five-file closeout review remains clean.

All reviewed files meet quality standards. No open issues found.

## Narrative Findings (AI reviewer)

No findings.

---

_Reviewed: 2026-10-09T02:10:46Z_
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
