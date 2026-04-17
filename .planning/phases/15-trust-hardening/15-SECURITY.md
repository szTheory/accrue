---
phase: 15
slug: trust-hardening
status: verified
threats_open: 0
asvs_level: 1
block_on: high
created: 2026-04-17
---

# Phase 15 Security Verification

## Scope

- Phase: 15 - trust-hardening
- ASVS Level: 1
- Block On: high
- Threats Open: 0

## Threat Verification

| Threat ID | Category | Disposition | Status | Evidence |
|-----------|----------|-------------|--------|----------|
| T-15-01 | T | mitigate | CLOSED | `.planning/phases/15-trust-hardening/15-TRUST-REVIEW.md:20`, `.planning/phases/15-trust-hardening/15-TRUST-REVIEW.md:39`, `.planning/phases/15-trust-hardening/15-TRUST-REVIEW.md:40`, `accrue/test/accrue/docs/trust_review_test.exs:19` |
| T-15-02 | E | mitigate | CLOSED | `.planning/phases/15-trust-hardening/15-TRUST-REVIEW.md:49`, `examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs:18`, `examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs:122` |
| T-15-03 | I | mitigate | CLOSED | `accrue/test/accrue/docs/trust_leakage_test.exs:10`, `accrue/test/accrue/docs/trust_leakage_test.exs:20`, `accrue/test/accrue/docs/trust_leakage_test.exs:35`, `scripts/ci/verify_package_docs.sh:111`, `scripts/ci/verify_package_docs.sh:121` |
| T-15-04 | R | mitigate | CLOSED | `RELEASING.md:13`, `RELEASING.md:34`, `CONTRIBUTING.md:65`, `CONTRIBUTING.md:67`, `accrue/test/accrue/docs/release_guidance_test.exs:8` |
| T-15-05 | I | accept | CLOSED | Accepted risk logged below. `.github/ISSUE_TEMPLATE/bug.yml:11`, `.github/ISSUE_TEMPLATE/integration-problem.yml:11` |
| T-15-06 | D | mitigate | CLOSED | `examples/accrue_host/test/accrue_host_web/trust_smoke_test.exs:13`, `examples/accrue_host/test/accrue_host_web/trust_smoke_test.exs:24`, `examples/accrue_host/test/accrue_host_web/trust_smoke_test.exs:38` |
| T-15-07 | T | mitigate | CLOSED | `examples/accrue_host/mix.exs:146`, `examples/accrue_host/mix.exs:152`, `scripts/ci/accrue_host_uat.sh:44`, `scripts/ci/accrue_host_uat.sh:46` |
| T-15-08 | I | mitigate | CLOSED | `examples/accrue_host/playwright.config.js:18`, `examples/accrue_host/playwright.config.js:20`, `examples/accrue_host/playwright.config.js:21`, `examples/accrue_host/e2e/phase13-canonical-demo.spec.js:100`, `examples/accrue_host/e2e/phase13-canonical-demo.spec.js:227`, `examples/accrue_host/e2e/phase13-canonical-demo.spec.js:323`, `scripts/ci/accrue_host_seed_e2e.exs:204` |
| T-15-09 | E | mitigate | CLOSED | `examples/accrue_host/playwright.config.js:29`, `examples/accrue_host/playwright.config.js:35`, `examples/accrue_host/e2e/phase13-canonical-demo.spec.js:143`, `examples/accrue_host/e2e/phase13-canonical-demo.spec.js:267`, `examples/accrue_host/e2e/phase13-canonical-demo.spec.js:289`, `examples/accrue_host/e2e/phase13-canonical-demo.spec.js:313` |
| T-15-10 | R | mitigate | CLOSED | `examples/accrue_host/e2e/phase13-canonical-demo.spec.js:91`, `examples/accrue_host/e2e/phase13-canonical-demo.spec.js:216`, `examples/accrue_host/e2e/phase13-canonical-demo.spec.js:266`, `examples/accrue_host/e2e/phase13-canonical-demo.spec.js:288`, `examples/accrue_host/e2e/phase13-canonical-demo.spec.js:312` |
| T-15-11 | R | mitigate | CLOSED | `.github/workflows/ci.yml:45`, `.github/workflows/ci.yml:54`, `.github/workflows/ci.yml:63`, `.github/workflows/ci.yml:72`, `.github/workflows/ci.yml:99` |
| T-15-12 | D | mitigate | CLOSED | `.github/workflows/ci.yml:259`, `.github/workflows/ci.yml:267`, `.github/workflows/ci.yml:334`, `scripts/ci/accrue_host_uat.sh:5`, `scripts/ci/accrue_host_uat.sh:46` |
| T-15-13 | I | mitigate | CLOSED | `.github/workflows/ci.yml:341`, `.github/workflows/ci.yml:350`, `.github/workflows/ci.yml:359`, `.github/workflows/ci.yml:367`, `examples/accrue_host/e2e/phase13-canonical-demo.spec.js:100`, `examples/accrue_host/e2e/phase13-canonical-demo.spec.js:323` |
| T-15-14 | S | mitigate | CLOSED | `.github/workflows/ci.yml:393`, `.github/workflows/ci.yml:405`, `.github/workflows/ci.yml:409`, `guides/testing-live-stripe.md:20`, `guides/testing-live-stripe.md:77`, `guides/testing-live-stripe.md:98` |

## Accepted Risks Log

| Threat ID | Severity | ASVS | Rationale | Evidence |
|-----------|----------|------|-----------|----------|
| T-15-05 | Low | V8.3, V14.2 | Accepted per the Phase 15 register because public intake is already routed through no-secrets forms. Residual risk is maintainers ignoring template guidance, not a known Accrue path that requests or exposes secrets, customer data, or PII. | `.github/ISSUE_TEMPLATE/bug.yml:11`, `.github/ISSUE_TEMPLATE/integration-problem.yml:11`, `.planning/phases/15-trust-hardening/15-TRUST-REVIEW.md:60` |

## Verification Runs

- `cd accrue && mix test test/accrue/docs/trust_review_test.exs test/accrue/docs/trust_leakage_test.exs test/accrue/docs/release_guidance_test.exs test/accrue/docs/package_docs_verifier_test.exs`

## Unregistered Flags

None. The required Phase 15 summary files do not contain a `## Threat Flags` section.
