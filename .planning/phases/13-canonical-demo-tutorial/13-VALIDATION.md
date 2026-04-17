---
phase: 13
slug: canonical-demo-tutorial
status: draft
nyquist_compliant: true
wave_0_complete: true
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
| **Docs contract command** | `cd accrue && mix test test/accrue/docs/first_hour_guide_test.exs test/accrue/docs/canonical_demo_contract_test.exs test/accrue/docs/package_docs_verifier_test.exs` |
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
| 13-01-01 | 13-01 Task 1 | 0 | DEMO-05, DEMO-06 | T-13-02 | The manifest records exact mode labels and ordered command data so docs/tests consume one canonical contract instead of duplicating tutorial steps. | unit / contract | `test -f examples/accrue_host/demo/command_manifest.exs && rg -n 'First run|Seeded history|mix verify.full' examples/accrue_host/demo/command_manifest.exs` | `examples/accrue_host/demo/command_manifest.exs` | ⬜ pending |
| 13-01-02 | 13-01 Task 2 | 0 | DEMO-04, DEMO-05 | T-13-01 / T-13-04 | The package-local fast/full verification aliases stay truthful and keep the signed webhook/admin proof path inside the advertised local contract. | integration | `cd examples/accrue_host && mix verify` | `examples/accrue_host/mix.exs` | ⬜ pending |
| 13-01-03 | 13-01 Task 3 | 0 | DEMO-04 | T-13-03 | The repo-root wrapper delegates to the same repaired full gate and fails closed on the host-local CI-equivalent verification command. | release gate | `bash scripts/ci/accrue_host_uat.sh` | `scripts/ci/accrue_host_uat.sh` | ⬜ pending |
| 13-02-01 | 13-02 Task 1 | 1 | DEMO-06 | T-13-05 / T-13-06 / T-13-08 | Manifest-backed docs tests enforce label parity, ordered-step parity, and forbidden private surfaces in `First run`. | docs contract | `cd accrue && mix test test/accrue/docs/first_hour_guide_test.exs test/accrue/docs/canonical_demo_contract_test.exs` | `accrue/test/accrue/docs/first_hour_guide_test.exs`, `accrue/test/accrue/docs/canonical_demo_contract_test.exs` | ⬜ pending |
| 13-02-02 | 13-02 Task 2 | 1 | DEMO-06 | T-13-07 | The shell verifier remains narrow and deterministic, checking only fixed docs invariants while ExUnit owns semantics. | docs verifier | `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` | `scripts/ci/verify_package_docs.sh`, `accrue/test/accrue/docs/package_docs_verifier_test.exs` | ⬜ pending |
| 13-03-01 | 13-03 Task 1 | 2 | DEMO-01, DEMO-02, DEMO-03 | T-13-09 / T-13-10 / T-13-12 | The host README teaches the public `First run` path through Fake-backed subscription, signed webhook ingest, and mounted admin inspection without leaking private or live-only setup. | docs contract | `cd accrue && mix test test/accrue/docs/canonical_demo_contract_test.exs` | `examples/accrue_host/README.md` | ⬜ pending |
| 13-03-02 | 13-03 Task 2 | 2 | ADOPT-02, DEMO-02, DEMO-03 | T-13-09 / T-13-10 / T-13-11 / T-13-12 | The First Hour guide mirrors the same public-boundary story and clearly separates focused verification from the broader verification modes. | docs contract | `cd accrue && mix test test/accrue/docs/first_hour_guide_test.exs test/accrue/docs/canonical_demo_contract_test.exs` | `accrue/guides/first_hour.md` | ⬜ pending |
| 13-03-03 | 13-03 Task 3 | 2 | DEMO-01, DEMO-05 | T-13-11 | The package README stays an orientation surface that points at the canonical tutorial and references the correct verification commands without duplicating the full walkthrough. | docs verifier | `bash scripts/ci/verify_package_docs.sh` | `accrue/README.md` | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `examples/accrue_host/mix.exs` — add `mix verify` and `mix verify.full` aliases around the focused proof suite and full local gate.
- [ ] `scripts/ci/accrue_host_uat.sh` — reconcile the current dev boot smoke failure and delegate to the host-local full contract.
- [ ] `examples/accrue_host/demo/command_manifest.exs` — establish the canonical labels and ordered command data that Wave 1 docs-contract tests will consume.

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
- [x] `nyquist_compliant: true` set in frontmatter after plans include concrete automated checks

**Approval:** pending
