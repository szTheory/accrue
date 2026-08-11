---
phase: 226
slug: ci-baseline-proof-semantics
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-11
---

# Phase 226 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Node built-in assertions and shell contract checks; existing ExUnit and Playwright suites remain source proof |
| **Config file** | `examples/accrue_host/playwright.config.js`; `accrue_admin/playwright.config.js`; no root Node test config |
| **Quick run command** | `node scripts/ci/verify_ci_baseline.mjs --fixtures` |
| **Full suite command** | `node scripts/ci/verify_ci_baseline.mjs --fixtures && node scripts/ci/verify_provider_proof.mjs --fixtures && bash scripts/ci/verify_ci_setup_diagnostics.sh && bash scripts/ci/verify_phase225_required_lane_evidence.sh` |
| **Estimated runtime** | Under 120 seconds for fixture and contract checks |

---

## Sampling Rate

- **After every task commit:** Run the relevant fixture command plus `node --check` on changed `.mjs` files
- **After every plan wave:** Run all Phase 226 fixture and contract checks
- **Before `$gsd-verify-work`:** Full suite must be green and the frozen snapshot inspected
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 226-01-01 | 01 | 1 | BASE-01 | T-226-01 | Only allowlisted, sanitized CI evidence is persisted | unit/fixture | `node scripts/ci/verify_ci_baseline.mjs --fixtures` | ❌ W0 | ⬜ pending |
| 226-01-02 | 01 | 1 | BASE-02 | Provider states cannot promote skipped or non-run evidence to proof | unit/fixture | `node scripts/ci/verify_provider_proof.mjs --fixtures` | ❌ W0 | ⬜ pending |
| 226-02-01 | 02 | 2 | OWN-01 | Diagnostics expose ownership and safe next commands without secrets | contract | `bash scripts/ci/verify_ci_setup_diagnostics.sh` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/ci/verify_ci_baseline.mjs` and fixtures — BASE-01
- [ ] `scripts/ci/verify_provider_proof.mjs` and fixtures — BASE-02
- [ ] `scripts/ci/verify_ci_setup_diagnostics.sh` — OWN-01

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Frozen comparable-run snapshot represents real workflow topology and exposes the measured critical path | BASE-01 | Fixture tests validate mechanics but cannot establish that selected live runs are operationally comparable | Inspect the generated Markdown cohort fingerprint, exclusions, queue and duration fields, and critical-path claim against the sanitized NDJSON snapshot |
| Provider freshness window matches the selected scheduled/manual cadence | BASE-02 | The acceptable operational grace window is a maintainer policy choice | Confirm the documented grace period and inspect fresh, stale, skipped, misconfigured, and non-run examples in the generated report |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
