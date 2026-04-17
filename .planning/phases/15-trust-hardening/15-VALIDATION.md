---
phase: 15
slug: trust-hardening
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-04-17
---

# Phase 15 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit plus Playwright Test with `@axe-core/playwright` |
| **Config file** | `examples/accrue_host/playwright.config.js`, `accrue_admin/playwright.config.js`, Mix aliases in `examples/accrue_host/mix.exs` |
| **Quick run command** | `cd examples/accrue_host && mix verify.full` for the canonical host lane; `cd examples/accrue_host && npm run e2e` for browser-only iteration |
| **Full suite command** | `cd accrue && mix test --warnings-as-errors && cd ../accrue_admin && mix test --warnings-as-errors && cd ../examples/accrue_host && mix verify.full` |
| **Estimated runtime** | TBD during Wave 0 calibration |

---

## Sampling Rate

- **After every task commit:** Run the narrow command for the touched surface, usually `cd accrue && mix test <file> -x`, `cd examples/accrue_host && mix test <file> -x`, or `cd examples/accrue_host && npm run e2e -- --project=<project>`.
- **After every plan wave:** Run `cd examples/accrue_host && mix verify.full` plus any touched package docs tests.
- **Before `$gsd-verify-work`:** Required CI floor/target cells green, host trust lane green, advisory cells clearly non-blocking, and trust artifacts/doc tests committed.
- **Max feedback latency:** TBD during Wave 0 calibration.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 15-W0-01 | TBD | 0 | TRUST-01 | T-15-webhook / T-15-admin / T-15-replay | Security review artifact maps webhook, auth, admin, replay, and generated-host boundaries to checked evidence. | docs contract | `cd accrue && mix test test/accrue/docs/trust_review_test.exs -x` | No | pending |
| 15-W0-02 | TBD | 0 | TRUST-02 | T-15-latency | Seeded webhook ingest and admin responsiveness stay within documented smoke budgets. | integration smoke | `cd examples/accrue_host && mix test test/accrue_host_web/trust_smoke_test.exs -x` | No | pending |
| 15-W0-03 | TBD | 0 | TRUST-03 | T-15-compat | Supported floor/target combinations are exercised, and advisory cells remain labeled. | CI matrix | `.github/workflows/ci.yml` release-gate plus host-integration jobs | Existing workflow, edits needed | pending |
| 15-W0-04 | TBD | 0 | TRUST-04 | T-15-browser | Demo/admin flows pass desktop/mobile behavior checks and critical/serious Axe scans. | browser e2e | `cd examples/accrue_host && npm run e2e` | Existing host suite, mobile extension needed | pending |
| 15-W0-05 | TBD | 0 | TRUST-05 | T-15-leakage | Docs, logs, public errors, and retained artifacts are scanned for secrets and PII leakage. | docs/log contract | `cd accrue && mix test test/accrue/docs/trust_leakage_test.exs -x` | No | pending |
| 15-W0-06 | TBD | 0 | TRUST-06 | T-15-release | Release docs and workflow labels distinguish required blockers from advisory checks. | docs contract | `cd accrue && mix test test/accrue/docs/release_guidance_test.exs -x` and `bash scripts/ci/verify_package_docs.sh` | Existing docs, edits likely needed | pending |

*Status: pending, green, red, flaky.*

---

## Wave 0 Requirements

- [ ] `accrue/test/accrue/docs/trust_review_test.exs` - stubs for TRUST-01.
- [ ] `examples/accrue_host/test/accrue_host_web/trust_smoke_test.exs` or equivalent scripted contract test - stubs for TRUST-02.
- [ ] Host Playwright mobile project in `examples/accrue_host/playwright.config.js` - coverage for TRUST-04.
- [ ] Leakage contract tests for docs/artifacts/log-safe copy - coverage for TRUST-05.
- [ ] Release-guidance contract expansion if current `release_guidance_test.exs` does not cover new required trust gates - coverage for TRUST-06.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Advisory provider-backed Stripe parity remains non-blocking | TRUST-06 | Requires external Stripe credentials and provider availability. | Confirm the CI job is marked advisory or `continue-on-error`, uses GitHub/environment secrets, and is documented outside deterministic release blockers. |

---

## Validation Sign-Off

- [x] All tasks have automated verify targets or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [ ] Feedback latency calibrated after smoke-command implementation.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending
