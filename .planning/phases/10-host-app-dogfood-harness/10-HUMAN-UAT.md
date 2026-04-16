---
status: complete
phase: 10-host-app-dogfood-harness
source: [10-VERIFICATION.md]
started: 2026-04-16T17:18:53Z
updated: 2026-04-16T18:08:56Z
automation: scripts/ci/accrue_host_uat.sh
---

## Current Test

[testing complete]

## Tests

### 1. Clean-checkout local boot
expected: From examples/accrue_host, the documented commands rebuild deps, rerun install, create and migrate the database, pass tests, and boot Phoenix on localhost without missing-secret or missing-repo errors.
result: pass
evidence: `ACCRUE_HOST_ALLOW_GENERATED_DRIFT=1 bash scripts/ci/accrue_host_uat.sh` completed the documented setup path, installer idempotence check, compile gate, focused UAT tests, full host regression, asset build, and bounded Phoenix dev boot smoke on 2026-04-16.

### 2. Browser billing and admin smoke
expected: A signed-in normal user can use /app/billing to start and cancel a Fake-backed subscription, and a billing admin can open /billing, inspect state, and replay a webhook row with visible admin UI feedback.
result: pass
evidence: `scripts/ci/accrue_host_uat.sh` seeds deterministic browser fixtures and runs `scripts/ci/accrue_host_browser_smoke.cjs` against a live Phoenix test server with Playwright Chromium. The smoke covers normal-user login, subscription start, cancellation, admin login, admin dashboard, webhook detail, replay feedback, and persisted `admin.webhook.replay.completed` evidence.

## Summary

total: 2
passed: 2
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

No remaining human-only UAT gaps. The prior manual checks are now covered by the repository-local CI script and GitHub Actions workflow.
