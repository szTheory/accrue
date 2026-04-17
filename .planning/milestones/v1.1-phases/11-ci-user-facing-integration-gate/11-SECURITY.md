---
phase: 11
slug: ci-user-facing-integration-gate
status: verified
threats_open: 0
asvs_level: 1
created: 2026-04-16
updated: 2026-04-16
---

# Phase 11 — Security

Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| browser runner -> Phoenix host app | Playwright drives authenticated host and admin routes through the real Phoenix endpoint. | Test-mode HTTP requests, CSRF token, seeded fake billing records |
| seeded fixture file -> Playwright spec | Elixir seed script writes the fixture consumed by Node/Playwright. | Test-only email/password, webhook id, subscription id |
| Playwright artifact output -> CI artifact upload | Reports, traces, screenshots, and host logs may be uploaded after failures. | Fake-backed browser report, traces, screenshots, bounded server log |
| local shell -> Phoenix host app | CI/local shell setup controls DB setup, installer rerun, Phoenix boot, and browser execution. | Test database state, generated files, server logs |
| CI runtime -> GitHub API | Annotation sweep reads workflow jobs and check-run annotations. | GitHub run metadata, annotation summaries, read-only token |
| GitHub Actions workflow -> repo secrets/token | Workflow jobs receive the default GitHub token and advisory live-Stripe secrets only in the live job. | Read-only Actions/checks token, optional Stripe test secrets in advisory job |
| release-gate job -> host-integration job | Later jobs trust earlier package/admin gates before browser flow starts. | GitHub Actions job status and artifacts |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-11-01-01 | Spoofing | host browser login/admin flow | mitigate | `phase11-host-gate.spec.js` logs in through `/users/log-in`, reads the CSRF token, posts normal/admin fixture credentials, clears cookies between users, and verifies billing/admin routes rather than bypassing auth. | closed |
| T-11-01-02 | Tampering | Playwright spec assertions | mitigate | The spec asserts shipped Phase 10 copy and routes including `Choose a plan`, `No billing activity yet`, subscription start/cancel copy, `/billing/webhooks/:id`, and `admin.webhook.replay.completed`. | closed |
| T-11-01-03 | Information Disclosure | traces/screenshots/report | mitigate | The gate is seeded with Fake/test data, live Stripe secrets are not read by the spec or shell gate, Playwright artifacts are uploaded only on failure, and the fixture file is deleted on cleanup. | closed |
| T-11-01-04 | Denial of Service | flaky LiveView/browser waits | mitigate | Playwright config uses 30s test timeout, 5s expect timeout, one worker, bounded webServer timeout, and the spec waits explicitly for `[data-phx-main].phx-connected`. | closed |
| T-11-01-05 | False Negative | raw node smoke remains primary | mitigate | `scripts/ci/accrue_host_uat.sh` invokes `npm run e2e`, and `examples/accrue_host/package.json` maps that to `playwright test`; no workflow calls the old raw Node browser smoke as the blocking path. | closed |
| T-11-02-01 | Information Disclosure | host UAT logs and browser logs | mitigate | Shell output uses a bounded server log path, fixture temp file cleanup, and Fake/test data; no Stripe keys, webhook secrets, cookies, or fixture password are echoed by the script. | closed |
| T-11-02-02 | Tampering | generated-drift and compile/test order | mitigate | `accrue_host_uat.sh` reruns installer setup, blocks generated drift, compiles with warnings-as-errors, builds assets, runs focused tests, full host tests, boot smoke, and only then runs browser success. | closed |
| T-11-02-03 | Repudiation | annotation blocker | mitigate | `annotation_sweep.sh` requires `GITHUB_REPOSITORY` and `GITHUB_RUN_ID`, matches named jobs from the current run, and prints job/path/level/message for blocking annotations. | closed |
| T-11-02-04 | Elevation of Privilege | GitHub token use in sweep script | mitigate | `ci.yml` grants only `actions: read`, `checks: read`, and `contents: read`; `annotation_sweep.sh` uses `GH_TOKEN`/`GITHUB_TOKEN` only for read API calls and fails if auth is absent. | closed |
| T-11-02-05 | False Negative | annotation warnings survive without failing CI | mitigate | `annotation_sweep.sh` fails nonzero on `warning`, `failure`, or `error` annotations and `ci.yml` runs it after release-facing jobs. | closed |
| T-11-03-01 | Elevation of Privilege | GitHub workflow token permissions | mitigate | Main workflow permissions are read-only (`actions`, `checks`, `contents`), and no write scopes were added for host integration or annotation sweep. | closed |
| T-11-03-02 | Information Disclosure | artifact upload and logs | mitigate | Host artifacts upload under `if: failure()`, are limited to Playwright report, `test-results`, and `accrue-host-server.log`, and the mandatory path is Fake-backed; live Stripe secrets remain isolated to advisory `live-stripe`. | closed |
| T-11-03-03 | False Positive | release gate ordering | mitigate | `ci.yml` orders `release-gate -> admin-drift-docs -> host-integration -> annotation-sweep` with explicit `needs`, so browser/admin checks do not report success before prerequisite package gates pass. | closed |
| T-11-03-04 | False Negative | live Stripe becoming mandatory | mitigate | `live-stripe` runs only on `workflow_dispatch` or `schedule` and has `continue-on-error: true`; PR/main mandatory coverage is Fake-backed `host-integration`. | closed |
| T-11-03-05 | Tampering | parallel duplicate workflows | mitigate | `.github/workflows/accrue_host_uat.yml` and `.github/workflows/accrue_admin_assets.yml` are `workflow_dispatch` only; PR/main blocking logic is centralized in `ci.yml`. | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-04-16 | 15 | 15 | 0 | Codex |

---

## Verification Evidence

| Check | Evidence | Status |
|-------|----------|--------|
| Workflow token is read-only | `.github/workflows/ci.yml` defines only `actions: read`, `checks: read`, and `contents: read`. | passed |
| Scheduled runs remain advisory | Required jobs have `if: github.event_name != 'schedule'`; `live-stripe` is schedule/manual and advisory. | passed |
| Browser gate keeps CI artifacts | `playwright.config.js` uses GitHub + HTML reporters under `CI`, retains trace/screenshots, and writes `test-results`. | passed |
| Shell gate reuses server without hiding reporters | `accrue_host_uat.sh` sets `ACCRUE_HOST_REUSE_SERVER=1` without clearing `CI`. | passed |
| Annotation sweep fails closed | Script requires run identity and token, fails if no jobs match, and exits nonzero on warning/failure/error annotations. | passed |
| Auxiliary workflows are manual-only | `accrue_host_uat.yml` and `accrue_admin_assets.yml` expose only `workflow_dispatch`. | passed |

Automated checks already run during Phase 11 completion:

- `/Users/jon/.asdf/installs/ruby/3.3.4/bin/ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci.yml"); YAML.load_file(".github/workflows/accrue_host_uat.yml"); puts "workflow YAML OK"'`
- `bash -n scripts/ci/accrue_host_uat.sh && bash -n scripts/ci/annotation_sweep.sh`
- `cd examples/accrue_host && npx playwright test --list`
- `CI=true bash scripts/ci/accrue_host_uat.sh`

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-04-16
