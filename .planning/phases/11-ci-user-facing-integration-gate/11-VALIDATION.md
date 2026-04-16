---
phase: 11
slug: ci-user-facing-integration-gate
status: verified
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-16
updated: 2026-04-16
---

# Phase 11 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Mix test, shell CI scripts, Playwright Test |
| **Config file** | `.github/workflows/ci.yml`, `examples/accrue_host/package.json`, `examples/accrue_host/playwright.config.js` |
| **Quick run command** | `cd examples/accrue_host && npm ci && npx playwright test --list` |
| **Full suite command** | `bash scripts/ci/accrue_host_uat.sh` plus `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci.yml"); puts "ci.yml OK"'` and `sed -n '58,76p' .planning/ROADMAP.md` |
| **Estimated runtime** | ~10-15 minutes on a warm machine; allow up to 20 minutes on a cold CI-equivalent local run |

---

## Sampling Rate

- **After every task commit:** Run the narrow command listed in that task's `<verification>` block.
- **After Wave 1 (Plan 11-01):** Run `cd examples/accrue_host && npm ci && npx playwright test --list` and `cd examples/accrue_host && npm ci && npx playwright test e2e/phase11-host-gate.spec.js --list`.
- **After Wave 2 (Plan 11-02):** Run `bash -n scripts/ci/accrue_host_uat.sh` and `bash -n scripts/ci/annotation_sweep.sh`.
- **After Wave 3 (Plan 11-03):** Run `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci.yml"); puts "ci.yml OK"'` and inspect `.planning/ROADMAP.md` with `sed -n '58,76p' .planning/ROADMAP.md` to confirm the Phase 11 plan list remains aligned without unnecessary roadmap edits.
- **Before `$gsd-verify-work`:** Full CI-equivalent suite must be green locally where practical.
- **Max feedback latency:** 20 minutes from edit to task-level signal on the local CI-equivalent path.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 11-01-01 | 11-01 | 1 | CI-02, CI-04 | T-11-01-03, T-11-01-04, T-11-01-05 | Host browser gate uses Playwright Test with retained failure artifacts and no custom raw smoke runner as the blocking path | browser/config | `cd examples/accrue_host && npm ci && npx playwright test --list` | `examples/accrue_host/package.json`, `examples/accrue_host/package-lock.json`, `examples/accrue_host/playwright.config.js` | ✅ green |
| 11-01-02 | 11-01 | 1 | CI-02, CI-04 | T-11-01-01, T-11-01-02 | Browser proof uses real host/admin auth and seeded fixture data to cover the signed-in billing plus replay flow | browser/spec | `cd examples/accrue_host && npm ci && npx playwright test e2e/phase11-host-gate.spec.js --list` | `examples/accrue_host/e2e/phase11-host-gate.spec.js` | ✅ green |
| 11-02-01 | 11-02 | 2 | CI-02, CI-06 | T-11-02-01, T-11-02-02 | Canonical host UAT script preserves drift, compile, test, and Playwright-backed browser ordering without leaking secrets in logs | shell/script | `bash -n scripts/ci/accrue_host_uat.sh` | `scripts/ci/accrue_host_uat.sh` | ✅ green |
| 11-02-02 | 11-02 | 2 | CI-02, CI-06 | T-11-02-03, T-11-02-04, T-11-02-05 | Annotation sweep uses explicit CI env inputs and fails on surviving warning or failure annotations for named release-facing jobs | shell/script | `bash -n scripts/ci/annotation_sweep.sh` | `scripts/ci/annotation_sweep.sh` | ✅ green |
| 11-03-01 | 11-03 | 3 | CI-01, CI-03, CI-04, CI-05, CI-06 | T-11-03-01, T-11-03-02, T-11-03-03, T-11-03-04, T-11-03-05 | Main CI workflow owns the ordered `release-gate -> admin-drift-docs -> host-integration -> annotation-sweep` chain, folds in admin asset freshness/guide drift, uploads host browser failure artifacts, and leaves live Stripe manual or scheduled advisory only | workflow/config | `/Users/jon/.asdf/installs/ruby/3.3.4/bin/ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci.yml"); YAML.load_file(".github/workflows/accrue_host_uat.yml"); YAML.load_file(".github/workflows/accrue_admin_assets.yml"); puts "workflow YAML OK"'` | `.github/workflows/ci.yml` and either rewritten or removed `.github/workflows/accrue_host_uat.yml` plus either rewritten or removed `.github/workflows/accrue_admin_assets.yml` | ✅ green |
| 11-03-02 | 11-03 | 3 | CI-01, CI-03, CI-05 | T-11-03-03, T-11-03-05 | Roadmap remains aligned with the finalized three-plan Phase 11 execution set and is only edited if the current plan list drifts from approved text | docs/config | `sed -n '58,76p' .planning/ROADMAP.md` | `.planning/ROADMAP.md` | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Artifact Expectations

| Plan | Failure/Output Artifact | Expected Location | Why It Matters |
|------|-------------------------|-------------------|----------------|
| 11-01 | Playwright HTML report | `examples/accrue_host/playwright-report` | Gives browser-step context without rerunning locally |
| 11-01 | Playwright traces and screenshots | `examples/accrue_host/test-results` | Captures retained trace and failure screenshots per CI-04 |
| 11-02 | Host browser/server log | Path emitted by `scripts/ci/accrue_host_uat.sh` via `browser_log_file` handling | Preserves Phoenix-side evidence for the failing browser window |
| 11-03 | Admin asset freshness and guide drift blocker | `admin-drift-docs` job in `.github/workflows/ci.yml` | Keeps `accrue_admin` generated assets and guide references inside the canonical ordered gate instead of a separate required workflow |
| 11-03 | Uploaded CI artifacts | `accrue-host-playwright-report`, `accrue-host-playwright-traces`, `accrue-host-server-log` from `.github/workflows/ci.yml` | Makes failed PR and `main` runs debuggable from the Actions UI |

---

## Wave 0 Requirements

- [x] Concrete task-level commands are defined for all six tasks across Plans 11-01 through 11-03.
- [x] Host Playwright tooling is localized under `examples/accrue_host/`, following `accrue_admin` patterns without sharing its runner.
- [x] Failure artifact expectations cover Playwright HTML report, traces, screenshots, and host server log upload.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| GitHub required-check behavior | CI-01..CI-06 | Repository branch protection settings may be outside source control and cannot be fully enforced from the repo | After workflow changes land on GitHub, open repository branch protection for `main` and confirm the required checks point at the canonical `CI` workflow jobs introduced by Plan 11-03, not the old duplicate host or admin-assets workflows. |

---

## Validation Sign-Off

- [x] All tasks have automated verify or explicit manual-only justification
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency threshold defined
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-16

## Audit Update

Nyquist audit rerun on 2026-04-16 confirmed that all six mapped automated checks execute successfully as written. No additional behavioral tests were needed because Phase 11 already ships executable coverage for the host Playwright contract, the host browser gate spec, the shell/UAT scripts, workflow YAML integrity, roadmap alignment, and the full `CI=true bash scripts/ci/accrue_host_uat.sh` path.
