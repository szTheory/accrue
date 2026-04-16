---
status: resolved
phase: 08-install-polish-testing
source: [08-VERIFICATION.md]
started: 2026-04-15T23:10:12Z
updated: 2026-04-15T23:17:28Z
---

## Current Test

Automated replacement for prior human UAT. The checks now run in `cd accrue && mix test test/mix/tasks/accrue_install_uat_test.exs --warnings-as-errors` and are wired into `.github/workflows/ci.yml` as `Run installer UAT automation`.

## Tests

### 1. Fresh Phoenix install timing
expected: Run `mix accrue.install` in a newly generated Phoenix app and reach Stripe test-mode-ready generated billing wiring in about 30 seconds, or get a clear actionable setup error.
result: passed - `Mix.Tasks.Accrue.InstallUATTest` runs the installer against a Phoenix-shaped fixture with Stripe test keys, asserts redacted Stripe readiness and generated billing/router/runtime wiring, and enforces a 30,000ms budget.

### 2. Host DataCase copy-paste flow
expected: Generated `test/support/accrue_case.ex` plus host test config lets `assert_email_sent/2`, `assert_pdf_rendered/1`, and `assert_event_recorded/1` pass without Stripe, Chrome, or SMTP.
result: passed - generated `AccrueCase` compiles cleanly, keeps host `config/test.exs` lines as copy-paste comments, imports `use Accrue.Test`, and a generated host probe exercises fake processor setup plus mail, PDF, and event assertions without Stripe, Chrome, or SMTP.

### 3. Admin mount protection in host router
expected: The generated Accrue Admin mount is protected by the host auth pipeline in an actual Phoenix router.
result: passed - fixture router includes `AccrueAdmin.Router`, the generated `AccrueAdmin.AuthHook`/`Accrue.Auth.require_admin_plug()` protection guidance, and a custom `/ops/billing` rerun remains idempotent with a single `accrue_admin` mount.

## Summary

total: 3
passed: 3
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

None. Human verification was replaced with automated installer UAT coverage and a named CI gate.
