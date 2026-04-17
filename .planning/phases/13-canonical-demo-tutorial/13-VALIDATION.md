---
phase: 13
slug: canonical-demo-tutorial
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-17
---

# Phase 13 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit `1.19.5` plus Playwright `1.59.1` |
| **Config file** | `examples/accrue_host/test/test_helper.exs`, `examples/accrue_host/playwright.config.js` |
| **Quick run command** | `cd examples/accrue_host && MIX_ENV=test mix test --warnings-as-errors test/install_boundary_test.exs test/accrue_host/billing_facade_test.exs test/accrue_host_web/subscription_flow_test.exs test/accrue_host_web/webhook_ingest_test.exs test/accrue_host_web/admin_webhook_replay_test.exs test/accrue_host_web/admin_mount_test.exs` |
| **Docs contract command** | `cd accrue && mix test test/accrue/docs/first_hour_guide_test.exs test/accrue/docs/package_docs_verifier_test.exs` |
| **Full suite command** | `cd examples/accrue_host && mix verify.full` and `bash scripts/ci/accrue_host_uat.sh` |
| **Estimated runtime** | Quick host/docs commands should stay under ~90 seconds each; full suite may take several minutes because it includes assets, dev boot, and browser smoke. |

---

## Sampling Rate

- **After every task commit:** Run the narrowest affected command from the quick host proof suite or docs contract command.
- **After every plan wave:** Run `cd examples/accrue_host && mix verify` plus the affected docs contract command.
- **Before `$gsd-verify-work`:** `cd examples/accrue_host && mix verify.full` and `bash scripts/ci/accrue_host_uat.sh` must both be green, or both must intentionally delegate to the same passing full contract.
- **Max feedback latency:** No implementation plan should go more than two task commits without either a focused host proof or docs contract check.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 13-01-01 | 01 | 0 | DEMO-04 | T-13-01 / T-13-04 | Full gate must not advertise a broken dev boot path; webhook/admin security checks remain included. | integration | `cd examples/accrue_host && mix verify.full` | ❌ W0 | ⬜ pending |
| 13-02-01 | 02 | 1 | DEMO-01, DEMO-04 | — | N/A | integration | `cd examples/accrue_host && mix verify` | ❌ W0 | ⬜ pending |
| 13-02-02 | 02 | 1 | DEMO-04 | T-13-01 / T-13-04 | Signed webhook and admin replay proofs stay inside the focused command. | integration | `cd examples/accrue_host && mix verify.full` | ❌ W0 | ⬜ pending |
| 13-03-01 | 03 | 1 | DEMO-05, DEMO-06 | T-13-02 | Docs must forbid private setup surfaces in `First run`. | docs contract | `cd accrue && mix test test/accrue/docs/first_hour_guide_test.exs test/accrue/docs/package_docs_verifier_test.exs` | ⚠️ partial | ⬜ pending |
| 13-04-01 | 04 | 2 | DEMO-01, DEMO-02, DEMO-03, ADOPT-02 | T-13-02 / T-13-03 | First-run tutorial uses public host boundaries; admin routes remain access-controlled. | docs + integration | `cd examples/accrue_host && mix verify && cd ../../accrue && mix test test/accrue/docs/first_hour_guide_test.exs` | ⚠️ partial | ⬜ pending |
| 13-05-01 | 05 | 2 | DEMO-04, DEMO-06 | T-13-01 / T-13-04 | Root wrapper delegates to the same full contract and preserves security-sensitive proof coverage. | release gate | `bash scripts/ci/accrue_host_uat.sh` | ✅ existing, failing dev boot until fixed | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `examples/accrue_host/mix.exs` — add `mix verify` and `mix verify.full` aliases around the focused proof suite and full local gate.
- [ ] `scripts/ci/accrue_host_uat.sh` — reconcile the current dev boot smoke failure and delegate to the host-local full contract.
- [ ] `accrue/test/accrue/docs/*` — add or extend manifest-backed parity checks for README, First Hour, and wrapper command order.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| New evaluator can read the tutorial without being routed into the UAT script first | DEMO-01, ADOPT-02 | Readability and teaching order require human review. | Review `examples/accrue_host/README.md` and `accrue/guides/first_hour.md`; confirm the first visible path is `First run` with `cd examples/accrue_host`, `mix setup`, and app boot before the full verification command. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s for focused checks
- [ ] `nyquist_compliant: true` set in frontmatter after plans include concrete automated checks

**Approval:** pending
