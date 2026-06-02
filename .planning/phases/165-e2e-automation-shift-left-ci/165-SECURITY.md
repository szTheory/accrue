---
phase: 165
slug: e2e-automation-shift-left-ci
status: verified
threats_open: 0
asvs_level: 1
created: 2026-06-02
---

# Phase 165 - Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| CI -> Phoenix | Test environment API is restricted to `:test` mix env only. | Sandbox session metadata for test-only database transaction ownership |
| Browser -> Phoenix | Standard browser interactions in test environment. | Auth/session cookies, CSRF-protected form posts, and billing UI actions against seeded test data |
| CI -> Docker | Local build process is contained within the standard GitHub Actions runner. | Build artifacts, app HTTP readiness check, and Docker Compose service state |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-165-01 | Information Disclosure | Sandbox API | accept | Verified `examples/accrue_host/config/test.exs` sets `config :accrue_host, :sql_sandbox, true`; `examples/accrue_host/lib/accrue_host_web/endpoint.ex` only mounts `Phoenix.Ecto.SQL.Sandbox` when `Application.compile_env(:accrue_host, :sql_sandbox)` is enabled. | closed |
| T-165-02 | Information Disclosure | Sandbox API | accept | Verified Playwright uses `examples/accrue_host/e2e/support/test.js` to checkout `/api/sandbox`, attach `x-sandbox-id`, and release it with `DELETE /api/sandbox`; all `examples/accrue_host/e2e/*.spec.js` files import the custom fixture. | closed |
| T-165-03 | Spoofing | Auth flows | accept | Verified E2E flows use the standard `/users/log-in` page, CSRF token extraction, POST `/users/log-in`, and normal authenticated navigation in `examples/accrue_host/e2e/support/fixture.js`; `examples/accrue_host/e2e/onboarding_and_billing.spec.js` exercises authenticated onboarding, billing, upgrade, metered usage, and cancellation paths. | closed |
| T-165-04 | Denial of Service | CI Worker | accept | Verified `.github/workflows/ci.yml` runs Playwright as a bounded GitHub Actions matrix job, depends on `host-integration`, uploads failure artifacts only on failure, isolates Docker boot smoke into its own job, and leaves scheduled `live-stripe` isolated from push/PR runs. GitHub Actions default job timeout remains the transferred runner-level control. | closed |
| T-165-05 | Tampering / Reliability | Subscription-mutating E2E flow | accept | Summary threat flag verified: `examples/accrue_host/playwright.config.js` has `fullyParallel: false`, and `examples/accrue_host/e2e/onboarding_and_billing.spec.js` configures the sensitive billing journey with `mode: 'serial'` to avoid shared Fake processor state races. | closed |

*Status: open / closed*
*Disposition: mitigate (implementation required) / accept (documented risk) / transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-165-01 | T-165-01 | The sandbox API exposes database sandbox session metadata but is compiled into the host app only when test configuration enables `:sql_sandbox`. | GSD security audit | 2026-06-02 |
| AR-165-02 | T-165-02 | Playwright must exchange sandbox metadata to isolate E2E transactions; exposure is limited to test runs and uses the built-in Phoenix sandbox lifecycle. | GSD security audit | 2026-06-02 |
| AR-165-03 | T-165-03 | The phase does not introduce new auth primitives; coverage deliberately exercises the existing registration/login/session paths. | GSD security audit | 2026-06-02 |
| AR-165-04 | T-165-04 | CI resource exhaustion risk is transferred to GitHub Actions runner limits for this phase; jobs are split by concern and scheduled Stripe parity is isolated. | GSD security audit | 2026-06-02 |
| AR-165-05 | T-165-05 | Shared Fake processor state is accepted as a test-environment limitation and mitigated operationally by serializing subscription-mutating Playwright coverage. | GSD security audit | 2026-06-02 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-06-02 | 5 | 5 | 0 | Codex / gsd-secure-phase |

## Security Audit 2026-06-02

| Metric | Count |
|--------|-------|
| Threats found | 5 |
| Closed | 5 |
| Open | 0 |

Evidence reviewed:

- `.planning/phases/165-e2e-automation-shift-left-ci/165-01-PLAN.md`
- `.planning/phases/165-e2e-automation-shift-left-ci/165-02-PLAN.md`
- `.planning/phases/165-e2e-automation-shift-left-ci/165-03-PLAN.md`
- `.planning/phases/165-e2e-automation-shift-left-ci/165-04-PLAN.md`
- `.planning/phases/165-e2e-automation-shift-left-ci/165-01-SUMMARY.md`
- `.planning/phases/165-e2e-automation-shift-left-ci/165-03-SUMMARY.md`
- `.planning/phases/165-e2e-automation-shift-left-ci/165-04-SUMMARY.md`
- `examples/accrue_host/config/test.exs`
- `examples/accrue_host/lib/accrue_host_web/endpoint.ex`
- `examples/accrue_host/lib/accrue_host_web/router.ex`
- `examples/accrue_host/e2e/support/test.js`
- `examples/accrue_host/e2e/support/fixture.js`
- `examples/accrue_host/e2e/onboarding_and_billing.spec.js`
- `examples/accrue_host/playwright.config.js`
- `.github/workflows/ci.yml`

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-06-02
