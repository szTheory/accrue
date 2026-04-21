---
phase: 31-advisory-integration-alignment
plan: 03
subsystem: testing
tags: [playwright, e2e, ci, documentation]

requires: []
provides:
  - Structural phase7 webhook replay assertions
  - Workflow + README pointers to host VERIFY-01 as canonical browser gate
affects: []

tech-stack:
  added: []
  patterns:
    - "Prefer data-role + regex toasts over long Copy.Locked literals in fixture UAT"

key-files:
  created: []
  modified:
    - accrue_admin/e2e/phase7-uat.spec.js
    - .github/workflows/accrue_admin_browser.yml
    - accrue_admin/README.md

key-decisions:
  - "Webhooks index assertion uses heading role to avoid strict-mode duplicate caption match."

patterns-established: []

requirements-completed: [COPY-03, INV-01, INV-03]

duration: 25min
completed: 2026-04-21
---

# Phase 31 — Plan 03 Summary

**Fixture Playwright now keys off `data-role` and flexible copy regex for webhook replay flows; CI workflow and admin README document host `VERIFY-01` as the merge-blocking mounted-admin path.**

## Task Commits

1. **Task 1: Refactor phase7-uat — webhook replay flow** — `fecd842` (test)
2. **Task 2: Refactor phase7-uat — bulk replay confirmation** — `75c4cf4` (test)
3. **Task 3: Workflow maintainer comment** — `bfbff4d` (docs)
4. **Task 4: README Browser UAT — pointer to host VERIFY-01** — `55c1c2e` (docs)

## Verification

- `cd accrue_admin && npm run e2e` — 6 passed
- `python3 -c "import yaml; yaml.safe_load(...)"` on workflow — ok

## Deviations

- **Webhooks index wait:** Replaced `getByText("Replay, inspect…")` with `getByRole("heading", { name: /Replay, inspect…/ })` because the same copy appears on a table caption and Playwright strict mode failed the test (not requested in plan; required for green suite).
- **Bulk success toast:** Updated the post–bulk-replay success matcher to a regex in task 1 so task 1 acceptance criteria (`rg` for verbatim `Replay requested…` / `Webhook replay…`) could pass while keeping coverage.

## Self-Check: PASSED

- Plan `acceptance_criteria` rg checks satisfied after deviations documented
- E2E suite green on final tree
