---
phase: 244-operator-language-and-evidence
reviewed: 2026-10-10T23:00:00Z
depth: standard
files_reviewed: 18
files_reviewed_list:
  - accrue_admin/assets/css/app.css
  - accrue_admin/assets/js/app.js
  - accrue_admin/assets/js/hooks/preserve_disclosure.js
  - accrue_admin/lib/accrue_admin/components/timeline.ex
  - accrue_admin/lib/accrue_admin/copy.ex
  - accrue_admin/lib/accrue_admin/copy/billing_event.ex
  - accrue_admin/lib/accrue_admin/live/dashboard_live.ex
  - accrue_admin/lib/accrue_admin/live/event_live.ex
  - accrue_admin/lib/accrue_admin/live/events_live.ex
  - accrue_admin/lib/accrue_admin/live/webhook_live.ex
  - accrue_admin/priv/static/accrue_admin.css
  - accrue_admin/priv/static/accrue_admin.js
  - accrue_admin/test/accrue_admin/copy/billing_event_test.exs
  - accrue_admin/test/accrue_admin/live/dashboard_live_test.exs
  - accrue_admin/test/accrue_admin/live/event_live_test.exs
  - accrue_admin/test/accrue_admin/live/events_live_test.exs
  - accrue_admin/test/accrue_admin/live/webhook_live_test.exs
  - examples/accrue_host/e2e/phase244-operator-evidence.spec.js
findings:
  critical: 1
  warning: 1
  info: 0
  total: 2
status: issues_found
---

# Phase 244: Code Review Report

**Reviewed:** 2026-10-10T23:00:00Z  
**Depth:** standard  
**Files Reviewed:** 18  
**Status:** issues_found

## Summary

Reviewed the Phase 244 Admin copy, evidence disclosures, LiveView behavior, bundled assets, and browser acceptance spec. The lazily loaded Activity and Raw payload disclosures on Event and Webhook detail do not all preserve the native open state across their LiveView patch; the newly added 320px timestamp check also measures a different field from the timestamp it claims to validate.

## Critical Issues

### CR-01: Lazy evidence disclosures lose their open state during loading patches

**File:** `accrue_admin/lib/accrue_admin/live/event_live.ex:177` (also `event_live.ex:195`, `webhook_live.ex:302`)
**Classification:** BLOCKER
**Issue:** Opening Event Activity, Event Raw payload, or Webhook Raw payload sends a `phx-click` that patches the same disclosure's contents, but those `<details>` elements do not use `PreserveDisclosure`. The Webhook Activity disclosure needed this hook after the identical lazy-load patch closed it. These remaining disclosures therefore lose the operator's just-opened state when their load patch arrives, hiding the requested evidence until the operator opens them again. The Event disclosure behavior is also missing from the browser coverage.
**Fix:** Add `phx-hook="PreserveDisclosure"` to each lazy `<details>` element that patches its contents, including Event Activity and both Raw payload sections, then exercise open and close across the loading patch.

## Warnings

### WR-01: The mobile timestamp layout assertion measures the first field

**File:** `examples/accrue_host/e2e/phase244-operator-evidence.spec.js:362`
**Classification:** WARNING
**Issue:** The test correctly selects and checks the exact `Recorded` value in `recordedField`, but its width and overflow measurements use `document.querySelector` for the first `.ax-field dd.ax-field-value`. That is typically the Type field, so the reported `valueWidth` and `valueScrollWidth` do not establish that the long fractional timestamp fits at 320px. The document-wide width assertion could pass while the timestamp itself overflows its field.
**Fix:** Measure the already selected `recordedField` element, for example with `recordedField.evaluate(el => ({ width: el.clientWidth, scrollWidth: el.scrollWidth }))`, and assert its own content width.

---

_Reviewed: 2026-10-10T23:00:00Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
