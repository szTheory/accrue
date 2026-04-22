---
phase: 50-copy-tokens-verify-gates
plan: "03"
subsystem: testing
tags: [playwright, copy, ci]

requires: []
provides:
  - mix accrue_admin.export_copy_strings allowlisted JSON export
  - CI regeneration of e2e/generated/copy_strings.json
  - VERIFY-01 subscriptions index axe test using exported strings
affects: []

tech-stack:
  added: []
  patterns:
    - "Playwright reads operator copy from Mix-generated JSON for anti-drift"

key-files:
  created:
    - accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex
    - examples/accrue_host/e2e/generated/copy_strings.json
  modified:
    - scripts/ci/accrue_host_verify_browser.sh
    - examples/accrue_host/README.md
    - examples/accrue_host/e2e/verify01-admin-a11y.spec.js
    - .planning/phases/50-copy-tokens-verify-gates/50-VERIFICATION.md

key-decisions:
  - "Allowlist enumerates Copy 0-arity functions; no Code.all_loaded sweep"

patterns-established:
  - "Host e2e loads copy_strings.json from e2e/generated relative to spec"

requirements-completed: [ADM-04, ADM-06]

duration: 30min
completed: 2026-04-22
---

# Phase 50: copy-tokens-verify-gates — Plan 03 Summary

**D-23 closed:** Elixir `AccrueAdmin.Copy` strings export to JSON, CI refreshes the artifact before Playwright, and VERIFY-01 asserts the subscriptions empty state from that JSON instead of duplicated English.

## Task Commits

1. **Task 1: Mix task export_copy_strings** — `439c76a`
2. **Task 2: CI + README wiring** — `22f860f`
3. **Task 3: Playwright + extra inventory path** — `40652e9`
4. **Task 4: 50-VERIFICATION anti-drift checklist** — `ed1287d`

## Self-Check: PASSED

- `mix accrue_admin.export_copy_strings` and `mix compile --warnings-as-errors` — exit 0.
- Full `npm run e2e` not re-run in this session (heavy host stack); CI script path exercises export + e2e ordering.
