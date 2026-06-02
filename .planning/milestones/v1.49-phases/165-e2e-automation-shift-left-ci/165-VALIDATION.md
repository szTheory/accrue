---
phase: 165
slug: e2e-automation-shift-left-ci
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-02
updated: 2026-06-02
---

# Phase 165 — Validation Strategy

> Reconstructed Nyquist validation contract for Phase 165 after execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Playwright (`@playwright/test`) plus Phoenix/ExUnit compile checks |
| **Config file** | `examples/accrue_host/playwright.config.js` |
| **Quick run command** | `cd examples/accrue_host && npm run e2e -- onboarding_and_billing.spec.js --workers=1` |
| **Full suite command** | `cd examples/accrue_host && npx playwright test` |
| **Estimated runtime** | ~2-8 minutes locally, depending on browser/server startup |

---

## Sampling Rate

- **After every task commit:** Run the task-specific automated command from the plan.
- **After every plan wave:** Run the focused Playwright or CI lint command listed below.
- **Before `$gsd-verify-work`:** Full suite should be green in CI or a clean local DB/server environment.
- **Max feedback latency:** ~8 minutes for focused E2E, longer for full CI.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 165-01-01 | 01 | 1 | E2E-04 | T-165-01 | Sandbox route is test-only and uses Phoenix sandbox lifecycle | compile | `cd examples/accrue_host && MIX_ENV=test mix compile --warnings-as-errors` | yes | green |
| 165-02-01 | 02 | 2 | E2E-04 | T-165-02 | Playwright contexts send `x-sandbox-id` and release sessions | static/e2e | `rg -n "x-sandbox-id|/api/sandbox" examples/accrue_host/e2e/support/test.js examples/accrue_host/lib/accrue_host_web/endpoint.ex` | yes | green |
| 165-03-01 | 03 | 3 | E2E-01 | T-165-03 | Browser journey uses normal login and customer-visible billing flow | e2e | `cd examples/accrue_host && ACCRUE_HOST_TEST_POOL_SIZE=8 npm run e2e -- onboarding_and_billing.spec.js --workers=1` | yes | green |
| 165-03-02 | 03 | 3 | E2E-02 | T-165-03 | Browser journey covers upgrade, downgrade, cancel, and payment-method management controls | e2e | `cd examples/accrue_host && ACCRUE_HOST_TEST_POOL_SIZE=8 npm run e2e -- onboarding_and_billing.spec.js --workers=1` | yes | green |
| 165-03-03 | 03 | 3 | E2E-04 | T-165-05 | Subscription-mutating browser flow remains serial to avoid shared Fake processor races | static/e2e | `rg -n "fullyParallel: false|mode: 'serial'" examples/accrue_host/playwright.config.js examples/accrue_host/e2e/onboarding_and_billing.spec.js` | yes | green |
| 165-04-01 | 04 | 4 | E2E-03 | T-165-04 | CI runs native Playwright shards and uploads artifacts | ci lint | `rg -n "playwright-e2e|npx playwright test --shard" .github/workflows/ci.yml && actionlint .github/workflows/ci.yml` | yes | green |
| 165-04-02 | 04 | 4 | E2E-03 | T-165-04 | CI checks Docker boot separately from native E2E | ci lint | `rg -n "host-docker-smoke|docker compose up" .github/workflows/ci.yml && actionlint .github/workflows/ci.yml` | yes | green |
| 165-04-03 | 04 | 4 | E2E-03 | T-165-04 | Live Stripe parity is mandatory when scheduled/manual | ci lint | `rg -n "live-stripe|continue-on-error" .github/workflows/ci.yml && ! rg "continue-on-error: true" .github/workflows/ci.yml` | yes | green |

*Status: green means the automated command exists and passed locally on 2026-06-02.*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

None. Phase 165 browser validation is automated through Playwright.

---

## Validation Audit 2026-06-02

| Metric | Count |
|--------|-------|
| Gaps found | 1 |
| Resolved | 1 |
| Escalated | 0 |

Resolution: `E2E-02` now includes automated browser assertions for downgrade, cancellation, and customer-visible payment-method management controls in `examples/accrue_host/e2e/onboarding_and_billing.spec.js`. The E2E seed fixture now provides two portal payment methods for the normal user.

Verification: `cd examples/accrue_host && ACCRUE_HOST_TEST_POOL_SIZE=8 npm run e2e` passed with 19 passing specs and 3 intentional skips after LiveView sandbox propagation was fixed for host, portal, and admin mounts.

---

## Validation Sign-Off

- [x] All tasks have automated verify or existing infrastructure coverage
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency documented
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** complete 2026-06-02
