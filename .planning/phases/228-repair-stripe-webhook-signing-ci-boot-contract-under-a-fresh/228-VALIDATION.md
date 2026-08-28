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
| **Quick run command** | `node scripts/ci/verify_provider_proof.mjs --fixtures && node scripts/ci/verify_stripe_webhook_boot_evidence.mjs --fixtures` |
| **Full suite command** | `cd accrue && mix test test/accrue/runtime_config_test.exs test/accrue/config_test.exs` |
| **Measured runtime** | Node fixtures: 0.2s combined; focused Mix run: 0.9s; full deterministic feedback: 1.1s |

---

## Sampling Rate

- **After every task commit:** Run `node scripts/ci/verify_provider_proof.mjs --fixtures && node scripts/ci/verify_stripe_webhook_boot_evidence.mjs --fixtures`
- **After every plan wave:** Run the targeted Mix configuration test
- **Before `$gsd-verify-work`:** The targeted suite must be green and the fresh provider-proof record must satisfy the existing finalizer contract
- **Max feedback latency:** 1.1s measured for both Node fixtures plus the focused Mix run; the per-task Node fixture check remains below it

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 228-01-01 | 228-01 | 1 | none (phase has no mapped IDs) | T-228-01, T-228-02, T-228-04 | Missing/renamed signing-secret edges fail; evidence verifier fixtures accept exact reachable live/no-run tuples and reject skipped/intentional_bypass as structurally impossible from the only dispatch input, input-gated job, and no-bypass finalizer; test runtime maps a nonempty signing secret before Stripe boot validation | static negative fixture + evidence mutation fixtures + integration/no-network | `node scripts/ci/verify_provider_proof.mjs --fixtures && node scripts/ci/verify_stripe_webhook_boot_evidence.mjs --fixtures && cd accrue && mix test test/accrue/runtime_config_test.exs test/accrue/config_test.exs` | ✅ | ✅ green |
| 228-01-02 | 228-01 | 1 | none (phase has no mapped IDs) | T-228-03 | Evidence schema exists before authority and preserves nonempty proof semantics | document contract + deterministic suites | `node scripts/ci/verify_provider_proof.mjs --fixtures && cd accrue && mix test test/accrue/runtime_config_test.exs test/accrue/config_test.exs && cd .. && rg -n 'readiness_not_authorized|first-attempt|consumed: `false`|selected_count|live-stripe-proof|Phase 227' .planning/phases/228-repair-stripe-webhook-signing-ci-boot-contract-under-a-fresh/228-STRIPE-WEBHOOK-BOOT-EVIDENCE.md` | ✅ | ✅ green |
| 228-02-01 | 228-02 | 2 | none (phase has no mapped IDs) | T-228-05, T-228-06, T-228-08 | Exact endpoint-secret administration is confirmed without disclosure | deterministic gate + blocking human checkpoint | `node scripts/ci/verify_provider_proof.mjs --fixtures && cd accrue && mix test test/accrue/runtime_config_test.exs test/accrue/config_test.exs` plus sanitized `configured` confirmation | ✅ plan contract | ⬜ pending |
| 228-02-02 | 228-02 | 2 | none (phase has no mapped IDs) | T-228-07, T-228-08 | One attempt is explicitly authorized or declined without dispatch | deterministic evidence-budget gate + blocking decision | `node scripts/ci/verify_provider_proof.mjs --fixtures && rg -n 'consumed: `false`|first-attempt|additional dispatch authorized: `false`' .planning/phases/228-repair-stripe-webhook-signing-ci-boot-contract-under-a-fresh/228-STRIPE-WEBHOOK-BOOT-EVIDENCE.md && git diff --exit-code -- .planning/phases/227-measured-critical-path-improvement` plus exact binary decision | ✅ plan contract | ⬜ pending |
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

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Configure the real test-mode endpoint signing secret | 228-02-01 | Repository access and maintainer authority are external to the codebase | Retrieve the matching test-mode endpoint secret from Stripe Dashboard, set the same-named repository configuration, and confirm only the generic configured result. |
| Dispatch exactly one newly authorized first-attempt provider run | 228-03-01 | Requires GitHub Actions authorization, GitHub API availability, and the configured secret | Dispatch only after deterministic checks pass; retain the run ID, selected-test count, manifest presence, raw conclusion, finalizer result, and sanitized proof artifact. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency is measured and bounded
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated locally on 2026-08-28; external authority remains gated by Plans 228-02 and 228-03.
