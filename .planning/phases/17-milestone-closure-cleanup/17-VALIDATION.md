---
phase: 17
slug: milestone-closure-cleanup
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-17
---

# Phase 17 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit plus existing host shell/browser trust scripts |
| **Config file** | `accrue/mix.exs`, `examples/accrue_host/mix.exs`, `examples/accrue_host/playwright.config.js` |
| **Quick run command** | `cd examples/accrue_host && MIX_ENV=test mix test test/accrue_host/seed_e2e_cleanup_test.exs --trace` and `cd accrue && mix test test/accrue/docs/release_guidance_test.exs test/accrue/docs/package_docs_verifier_test.exs --trace` |
| **Full suite command** | `bash scripts/ci/accrue_host_uat.sh` |
| **Estimated runtime** | ~30 seconds for quick docs contracts; host UAT depends on local dependency/DB state |

---

## Sampling Rate

- **After every docs/planning task commit:** Run `cd accrue && mix test test/accrue/docs/release_guidance_test.exs test/accrue/docs/package_docs_verifier_test.exs --trace`
- **After browser seed cleanup task commit:** Run `cd examples/accrue_host && MIX_ENV=test mix test test/accrue_host/seed_e2e_cleanup_test.exs --trace`
- **After every plan wave:** Run the focused cleanup regression, quick docs contracts, and `bash scripts/ci/accrue_host_uat.sh`
- **Before `$gsd-verify-work`:** Focused docs contracts and host trust lane must be green or a blocker must be recorded with exact failing command output
- **Max feedback latency:** 120 seconds for focused cleanup/docs feedback; host UAT may exceed this but is reserved for wave-end/final confidence

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 17-01-01 | 01 | 1 | Audit cleanup | T-17-01 / T-17-02 | Planning docs report completed Phase 13/canonical demo state without changing product scope | docs grep | `rg -n "Phase 13|canonical demo" .planning/PROJECT.md .planning/ROADMAP.md` | yes | pending |
| 17-01-02 | 01 | 1 | Audit cleanup | T-17-03 | Seed cleanup deletes only fixture-owned webhook/payment-failed/replay rows and preserves unrelated shared DB history | focused cleanup regression | `cd examples/accrue_host && MIX_ENV=test mix test test/accrue_host/seed_e2e_cleanup_test.exs --trace` | yes | pending |
| 17-01-03 | 01 | 1 | Audit cleanup | T-17-04 | Release/provider/contributor docs name current trust lanes and avoid stale CI/job references | docs contract | `cd accrue && mix test test/accrue/docs/release_guidance_test.exs test/accrue/docs/package_docs_verifier_test.exs --trace` | yes | pending |
| 17-01-04 | 01 | 1 | Audit cleanup | T-17-05 | Package docs verifier locks the corrected release/trust wording against future drift | shell verifier | `bash scripts/ci/verify_package_docs.sh` | yes | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No new test framework, fixture harness, or package dependency is required.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Milestone audit closure judgment | Audit cleanup | The final archival decision is a project governance judgment, not only a code assertion | Re-read `.planning/v1.2-MILESTONE-AUDIT.md`, `.planning/PROJECT.md`, `.planning/ROADMAP.md`, and Phase 17 summary after execution; confirm all six non-critical audit items are closed |

---

## Validation Sign-Off

- [x] All tasks have automated verify commands or existing Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency documented for quick and host trust checks
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-17
