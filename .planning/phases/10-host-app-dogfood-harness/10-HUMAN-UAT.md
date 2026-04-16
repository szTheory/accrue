---
status: partial
phase: 10-host-app-dogfood-harness
source: [10-VERIFICATION.md]
started: 2026-04-16T17:18:53Z
updated: 2026-04-16T17:18:53Z
---

## Current Test

awaiting human testing

## Tests

### 1. Clean-checkout local boot
expected: From examples/accrue_host, the documented commands rebuild deps, rerun install, create and migrate the database, pass tests, and boot Phoenix on localhost without missing-secret or missing-repo errors.
result: pending

### 2. Browser billing and admin smoke
expected: A signed-in normal user can use /app/billing to start and cancel a Fake-backed subscription, and a billing admin can open /billing, inspect state, and replay a webhook row with visible admin UI feedback.
result: pending

## Summary

total: 2
passed: 0
issues: 0
pending: 2
skipped: 0
blocked: 0

## Gaps
