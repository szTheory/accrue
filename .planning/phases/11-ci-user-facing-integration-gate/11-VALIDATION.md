---
phase: 11
slug: ci-user-facing-integration-gate
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-16
---

# Phase 11 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Mix test, shell CI scripts, Playwright Test |
| **Config file** | `.github/workflows/ci.yml`, `examples/accrue_host/package.json`, Playwright config added during phase |
| **Quick run command** | `mix test` |
| **Full suite command** | `scripts/ci/accrue_host_uat.sh` plus host Playwright CI command added during phase |
| **Estimated runtime** | TBD after host Playwright command lands |

---

## Sampling Rate

- **After every task commit:** Run the narrow command listed in that task's `<verification>` block.
- **After every plan wave:** Run `mix test` and the host CI/UAT command owned by that wave.
- **Before `$gsd-verify-work`:** Full CI-equivalent suite must be green locally where practical.
- **Max feedback latency:** TBD after Playwright browser artifacts are wired.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 11-TBD | TBD | TBD | CI-01..CI-06 | TBD | CI blocks regressions without requiring live Stripe secrets | CI/browser | TBD in PLAN.md | pending | pending |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

- [ ] Planner must define concrete CI-equivalent commands for package tests, host setup, generated drift checks, and Fake-backed browser flows.
- [ ] Planner must identify whether host Playwright tooling is added under `examples/accrue_host/` or shared with existing admin Playwright tooling.
- [ ] Planner must include artifact expectations for traces, screenshots, and reports on browser failure.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| GitHub required-check behavior | CI-01..CI-06 | Repository branch protection settings may be outside source control | Confirm configured required checks after workflow lands |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or explicit manual-only justification
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all missing references
- [ ] No watch-mode flags
- [ ] Feedback latency threshold defined
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
