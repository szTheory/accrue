---
status: complete
phase: 145-time-window-url-plumbing-window-selector
source: [145-VERIFICATION.md]
started: 2026-05-27T21:15:00Z
updated: 2026-09-12T20:12:00Z
---

> **Resolution (2026-09-12):** Complete. A new LiveView regression test seeds a recovered event ten days old, proves the 30-day view renders `$150.00`, patches to seven days, and proves the KPI changes to `$50.00`. The focused RecoveryLive suite passes 17 tests with zero failures.

## Current Test

[awaiting human testing]

## Tests

### 1. Window buttons reload KPI/funnel data with different counts

expected: Clicking "7 days UTC" / "30d" / "90d" buttons triggers handle_params, re-queries Dunning with the window's since:/until: bounds, and the KPI cards + funnel chart display different numbers for each window (not just different active button state).

result: pass — automated at the rendered LiveView boundary with distinct 7d and 30d KPI values

## Summary

total: 1
passed: 1
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps
