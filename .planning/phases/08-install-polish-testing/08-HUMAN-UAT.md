---
status: partial
phase: 08-install-polish-testing
source: [08-VERIFICATION.md]
started: 2026-04-15T23:10:12Z
updated: 2026-04-15T23:10:12Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Fresh Phoenix install timing
expected: Run `mix accrue.install` in a newly generated Phoenix app and reach Stripe test-mode-ready generated billing wiring in about 30 seconds, or get a clear actionable setup error.
result: [pending]

### 2. Host DataCase copy-paste flow
expected: Generated `test/support/accrue_case.ex` plus host test config lets `assert_email_sent/2`, `assert_pdf_rendered/1`, and `assert_event_recorded/1` pass without Stripe, Chrome, or SMTP.
result: [pending]

### 3. Admin mount protection in host router
expected: The generated Accrue Admin mount is protected by the host auth pipeline in an actual Phoenix router.
result: [pending]

## Summary

total: 3
passed: 0
issues: 0
pending: 3
skipped: 0
blocked: 0

## Gaps
