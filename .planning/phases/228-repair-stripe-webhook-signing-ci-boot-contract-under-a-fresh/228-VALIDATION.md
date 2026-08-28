---
phase: 228
slug: repair-stripe-webhook-signing-ci-boot-contract-under-a-fresh
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-28
---

# Phase 228 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Dependency-free Node `assert` fixtures plus ExUnit / Mix runtime checks |
| **Config file** | `accrue/config/runtime.exs` |
| **Quick run command** | `node scripts/ci/bootstrap_stripe_provider_proof.mjs --self-test && node scripts/ci/provider_proof_automation.mjs --self-test && node scripts/ci/verify_provider_proof.mjs --fixtures` |
| **Full suite command** | `node scripts/ci/verify_executable_uat_contract.mjs --self-test && node scripts/ci/verify_executable_uat_contract.mjs --all-opted-in && cd accrue && mix test test/accrue/backend_automation_contract_test.exs test/accrue/runtime_config_test.exs test/accrue/config_test.exs` |
| **Measured runtime** | Node automation/provider fixtures: under 1s; focused backend policy test: under 2s outside sandbox startup |

---

## Sampling Rate

- **After every task commit:** Run `node scripts/ci/verify_provider_proof.mjs --fixtures && node scripts/ci/verify_stripe_webhook_boot_evidence.mjs --fixtures`
- **After every plan wave:** Run the targeted Mix configuration test
- **Before phase completion:** The targeted suite, fresh provider-proof record, `behavior_unverified: 0`, and generated executable UAT must all pass; no `$gsd-verify-work` step remains
- **Max feedback latency:** 1.1s measured for both Node fixtures plus the focused Mix run; the per-task Node fixture check remains below it

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 228-01-01 | 228-01 | 1 | none (phase has no mapped IDs) | T-228-01, T-228-02, T-228-04 | Missing/renamed signing-secret edges fail; evidence verifier fixtures accept exact reachable live/no-run tuples and reject skipped/intentional_bypass as structurally impossible from the only dispatch input, input-gated job, and no-bypass finalizer; test runtime maps a nonempty signing secret before Stripe boot validation | static negative fixture + evidence mutation fixtures + integration/no-network | `node scripts/ci/verify_provider_proof.mjs --fixtures && node scripts/ci/verify_stripe_webhook_boot_evidence.mjs --fixtures && cd accrue && mix test test/accrue/runtime_config_test.exs test/accrue/config_test.exs` | ✅ | ✅ green |
| 228-01-02 | 228-01 | 1 | none (phase has no mapped IDs) | T-228-03 | Evidence schema exists before authority and preserves nonempty proof semantics | document contract + deterministic suites | `node scripts/ci/verify_provider_proof.mjs --fixtures && cd accrue && mix test test/accrue/runtime_config_test.exs test/accrue/config_test.exs && cd .. && rg -n 'readiness_not_authorized|first-attempt|consumed: `false`|selected_count|live-stripe-proof|Phase 227' .planning/phases/228-repair-stripe-webhook-signing-ci-boot-contract-under-a-fresh/228-STRIPE-WEBHOOK-BOOT-EVIDENCE.md` | ✅ | ✅ green |
| 228-02-01 | 228-02 | 2 | none (phase has no mapped IDs) | T-228-05, T-228-06, T-228-08 | Bootstrap keeps the endpoint secret on stdin, verifies only secret names, and constructs one explicitly authorized dispatch | dependency-free mutation fixtures | `node scripts/ci/bootstrap_stripe_provider_proof.mjs --self-test && node scripts/ci/provider_proof_automation.mjs --self-test` | ✅ | ✅ green |
| 228-02-02 | 228-02 | 2 | none (phase has no mapped IDs) | T-228-07, T-228-08 | Relevant repair proofs, failure ownership, and backend UAT remain deterministic and zero-human | static CI fixtures + policy fixtures + focused ExUnit | `node scripts/ci/verify_provider_proof.mjs --fixtures && node scripts/ci/verify_executable_uat_contract.mjs --self-test && node scripts/ci/verify_executable_uat_contract.mjs --all-opted-in && cd accrue && mix test test/accrue/backend_automation_contract_test.exs` | ✅ | ✅ green |
| 228-03-01 | 228-03 | 3 | none (phase has no mapped IDs) | T-228-09, T-228-12 | Independent live binding proves repository, immutable run URL, CI/workflow_dispatch, exact SHA/attempt/window, input-gated stable job and named steps; no-run proves absence in-window | authoritative live binding/no-run reconciliation | `node scripts/ci/verify_stripe_webhook_boot_evidence.mjs --verify-live-binding --record … --repository … --sha … --dispatch-at … --observed-at …` with the explicit arguments in Plan 228-03 Task 1 | ❌ verifier until Wave 1; ❌ phase outcome until execution | ⬜ pending |
| 228-03-02 | 228-03 | 3 | none (phase has no mapped IDs) | T-228-10, T-228-11, T-228-12 | Independent terminal reconciliation validates exact created-run proved and reachable misconfigured/failed/blocked tuples or the full empty no-run tuple; skipped/intentional_bypass blocks completion as an impossible workflow contract violation | authoritative terminal reconciliation | `node scripts/ci/verify_stripe_webhook_boot_evidence.mjs --verify-terminal --record … --repository … --sha … --dispatch-at … --observed-at … && git diff --exit-code -- .planning/phases/227-measured-critical-path-improvement` with the explicit arguments in Plan 228-03 Task 2 | ❌ verifier until Wave 1; ❌ phase outcome until execution | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Extend `scripts/ci/verify_provider_proof.mjs` fixtures to reject a missing or renamed signing-secret binding and preflight omission without exposing any secret value.
- [x] Add the Phase 228 bypass-impossibility fixture: reject `skipped` / `intentional_bypass`, assert `run_live_stripe` is the sole dispatch input for this path, prove the manual job is input-gated/executed, and prove the finalizer passes no bypass flag or reason.
- [x] Add dependency-free `scripts/ci/verify_stripe_webhook_boot_evidence.mjs` with exhaustive `--fixtures`, `--verify-live-binding`, and `--verify-terminal` modes using existing live-Actions patterns.
- [x] Add a deterministic no-network runtime boot-contract test for the live-key-plus-webhook-secret path.
- [x] Define the sanitized Phase 228 evidence record/schema before a live dispatch.

---

## One-Time Bootstrap Boundary

Credential provenance and GitHub authentication remain a one-time external setup action, not verification or UAT. The bootstrap command accepts the existing endpoint secret over stdin, records only sanitized metadata, dispatches exactly once, and hands all acceptance decisions to machine-verifiable evidence.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency is measured and bounded
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated locally on 2026-08-28; Phase 228 has no recurring human verification or manual UAT, and the remaining external boundary is credential bootstrap only.
