---
phase: 15
slug: trust-hardening
status: verified
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-17
---

# Phase 15 - Validation Strategy

> Reconciled Phase 15 validation map against executed plans, summaries, verification, tests, and current repo state.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit plus Playwright Test with `@axe-core/playwright` |
| **Config file** | `examples/accrue_host/playwright.config.js`, `accrue_admin/playwright.config.js`, Mix aliases in `examples/accrue_host/mix.exs` |
| **Quick run command** | `cd accrue && mix test test/accrue/docs/trust_review_test.exs test/accrue/docs/trust_leakage_test.exs test/accrue/docs/release_guidance_test.exs test/accrue/docs/package_docs_verifier_test.exs`; `cd examples/accrue_host && mix test test/accrue_host_web/trust_smoke_test.exs`; `cd examples/accrue_host && npx playwright test e2e/phase13-canonical-demo.spec.js --grep @phase15-trust` |
| **Full suite command** | `cd accrue && mix test --warnings-as-errors && cd ../accrue_admin && mix test --warnings-as-errors && cd ../examples/accrue_host && mix verify.full` |
| **Estimated runtime** | ~20 minutes for the focused Phase 15 trust commands on a warm local environment |

---

## Sampling Rate

- **After every task commit:** Run the narrow command for the touched surface.
- **After every plan wave:** Run `cd examples/accrue_host && mix verify.full` plus any touched package docs tests.
- **Before `$gsd-verify-work`:** Required CI floor/target cells green, host trust lane green, advisory cells clearly non-blocking, and trust artifacts/doc tests committed.
- **Max feedback latency:** Focused docs plus smoke checks complete in about 1 minute locally; the tagged Playwright trust flow completed in 15.9 seconds during this audit.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 15-W0-01 | 15-01 | 1 | TRUST-01 | T-15-01 / T-15-02 | Security review artifact maps webhook, auth, admin, replay, generated-host, retained-artifact, and intake boundaries to checked evidence. | docs contract | `cd accrue && mix test test/accrue/docs/trust_review_test.exs` | Yes | green |
| 15-W0-02 | 15-02 | 1 | TRUST-02 | T-15-06 / T-15-12 | Seeded webhook ingest and admin responsiveness stay within documented smoke budgets through ExUnit plus tagged browser timing checks. | integration smoke | `cd examples/accrue_host && mix test test/accrue_host_web/trust_smoke_test.exs` and `cd examples/accrue_host && npx playwright test e2e/phase13-canonical-demo.spec.js --grep @phase15-trust` | Yes | green |
| 15-W0-03 | 15-03 | 2 | TRUST-03 | T-15-11 / T-15-12 / T-15-14 | Supported floor/target combinations are exercised, Phoenix/LiveView compatibility proof is explicit, and advisory cells remain labeled. | CI matrix | `bash -lc 'grep -n "elixir: '\''1.17.3'\''" .github/workflows/ci.yml && grep -n "elixir: '\''1.18.0'\''" .github/workflows/ci.yml && grep -n "elixir: '\''1.18.4'\''" .github/workflows/ci.yml && grep -n "continue-on-error: \${{ matrix.continue-on-error }}" .github/workflows/ci.yml && grep -n "Phoenix/LiveView compatibility proof" .github/workflows/ci.yml && grep -n "phoenix_live_view" examples/accrue_host/mix.exs && grep -n "phoenix_live_view" accrue_admin/mix.exs'` | Yes | green |
| 15-W0-04 | 15-02 | 1 | TRUST-04 | T-15-08 / T-15-09 / T-15-10 | Demo/admin flows pass desktop/mobile responsive checks, transition budgets, and critical/serious Axe scans. | browser e2e | `cd examples/accrue_host && npx playwright test e2e/phase13-canonical-demo.spec.js --grep @phase15-trust` | Yes | green |
| 15-W0-05 | 15-01 | 1 | TRUST-05 | T-15-03 | Docs, logs, public errors, and retained artifacts are scanned for secrets and PII leakage. | docs/log contract | `cd accrue && mix test test/accrue/docs/trust_leakage_test.exs test/accrue/docs/package_docs_verifier_test.exs` and `bash scripts/ci/verify_package_docs.sh` | Yes | green |
| 15-W0-06 | 15-01 / 15-03 | 1 / 2 | TRUST-06 | T-15-04 / T-15-11 / T-15-14 | Release docs and workflow labels distinguish required blockers from advisory checks. | docs contract | `cd accrue && mix test test/accrue/docs/release_guidance_test.exs test/accrue/docs/package_docs_verifier_test.exs` and `bash -lc 'grep -n "continue-on-error: true" .github/workflows/ci.yml && grep -n "live-stripe" .github/workflows/ci.yml && grep -n "Run host integration gate" .github/workflows/ci.yml'` | Yes | green |

*Status: pending, green, red, flaky.*

---

## Wave 0 Reconciliation

- [x] `accrue/test/accrue/docs/trust_review_test.exs` exists and passed on 2026-04-17.
- [x] `examples/accrue_host/test/accrue_host_web/trust_smoke_test.exs` exists and passed on 2026-04-17.
- [x] `examples/accrue_host/playwright.config.js` now includes desktop and Pixel 5 projects, and the tagged trust flow passed on 2026-04-17.
- [x] Leakage contract coverage exists in `accrue/test/accrue/docs/trust_leakage_test.exs` and `accrue/test/accrue/docs/package_docs_verifier_test.exs`.
- [x] Release-guidance coverage exists in `accrue/test/accrue/docs/release_guidance_test.exs`, `scripts/ci/verify_package_docs.sh`, and `.github/workflows/ci.yml`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Advisory provider-backed Stripe parity remains non-blocking | TRUST-06 | Requires external Stripe credentials and provider availability. | Confirm the CI job is marked advisory or `continue-on-error`, uses GitHub/environment secrets, and is documented outside deterministic release blockers. |

---

## Requirement Coverage Status

| Requirement | Coverage | Evidence | Status |
|-------------|----------|----------|--------|
| TRUST-01 | Automated docs contract | `accrue/test/accrue/docs/trust_review_test.exs`, `.planning/phases/15-trust-hardening/15-TRUST-REVIEW.md` | green |
| TRUST-02 | Automated ExUnit smoke plus tagged Playwright timing | `examples/accrue_host/test/accrue_host_web/trust_smoke_test.exs`, `examples/accrue_host/e2e/phase13-canonical-demo.spec.js` | green |
| TRUST-03 | Automated CI-matrix invariant checks plus host dependency proof | `.github/workflows/ci.yml`, `examples/accrue_host/mix.exs`, `accrue_admin/mix.exs` | green |
| TRUST-04 | Automated desktop/mobile browser checks with Axe | `examples/accrue_host/playwright.config.js`, `examples/accrue_host/e2e/phase13-canonical-demo.spec.js` | green |
| TRUST-05 | Automated leakage and docs verifier contracts | `accrue/test/accrue/docs/trust_leakage_test.exs`, `accrue/test/accrue/docs/package_docs_verifier_test.exs`, `scripts/ci/verify_package_docs.sh` | green |
| TRUST-06 | Automated release-guidance and CI-label checks, plus one manual advisory-lane review | `accrue/test/accrue/docs/release_guidance_test.exs`, `scripts/ci/verify_package_docs.sh`, `.github/workflows/ci.yml` | green |

---

## Verification Runs

- `cd accrue && mix test test/accrue/docs/trust_review_test.exs test/accrue/docs/trust_leakage_test.exs test/accrue/docs/release_guidance_test.exs test/accrue/docs/package_docs_verifier_test.exs` -> 14 tests, 0 failures
- `cd examples/accrue_host && mix test test/accrue_host_web/trust_smoke_test.exs` -> 1 test, 0 failures
- `cd examples/accrue_host && npx playwright test e2e/phase13-canonical-demo.spec.js --grep @phase15-trust` -> 2 tests, 0 failures
- `bash scripts/ci/verify_package_docs.sh` -> passed
- `bash -lc 'grep -n "elixir: '\''1.17.3'\''" .github/workflows/ci.yml && grep -n "elixir: '\''1.18.0'\''" .github/workflows/ci.yml && grep -n "elixir: '\''1.18.4'\''" .github/workflows/ci.yml && grep -n "continue-on-error: \${{ matrix.continue-on-error }}" .github/workflows/ci.yml && grep -n "Phoenix/LiveView compatibility proof" .github/workflows/ci.yml && grep -n "phoenix_live_view" examples/accrue_host/mix.exs && grep -n "phoenix_live_view" accrue_admin/mix.exs && grep -n "Run host integration gate" .github/workflows/ci.yml && grep -n "Upload Playwright report" .github/workflows/ci.yml && grep -n "Upload Playwright traces" .github/workflows/ci.yml && grep -n "accrue-host-phase15-screenshots" .github/workflows/ci.yml && grep -n "live-stripe" .github/workflows/ci.yml'` -> passed

## Validation Sign-Off

- [x] All tasks have automated verify targets or reconciled Wave 0 coverage.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency calibrated after smoke-command implementation.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved (2026-04-17)
