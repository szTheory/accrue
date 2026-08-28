---
phase: 228
slug: repair-stripe-webhook-signing-ci-boot-contract-under-a-fresh
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false)
status: draft
nyquist_compliant: false
wave_0_complete: false
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
| **Full suite command** | `cd accrue && mix test test/accrue/config_test.exs` plus the no-network runtime boot-contract command defined by the plan |
| **Estimated runtime** | To be measured during Wave 0 |

---

## Sampling Rate

- **After every task commit:** Run `node scripts/ci/verify_provider_proof.mjs --fixtures && node scripts/ci/verify_stripe_webhook_boot_evidence.mjs --fixtures`
- **After every plan wave:** Run the targeted Mix configuration test
- **Before `$gsd-verify-work`:** The targeted suite must be green and the fresh provider-proof record must satisfy the existing finalizer contract
- **Max feedback latency:** Record the measured targeted-suite latency during Wave 0; keep the per-task fixture check below it

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 228-01-01 | 228-01 | 1 | none (phase has no mapped IDs) | T-228-01, T-228-02, T-228-04 | Missing/renamed signing-secret edges fail; evidence verifier fixtures exhaustively accept/reject exact live/no-run tuples; test runtime maps a nonempty signing secret before Stripe boot validation | static negative fixture + evidence mutation fixtures + integration/no-network | `node scripts/ci/verify_provider_proof.mjs --fixtures && node scripts/ci/verify_stripe_webhook_boot_evidence.mjs --fixtures && cd accrue && mix test test/accrue/runtime_config_test.exs test/accrue/config_test.exs` | ❌ new verifier/runtime test until execution | ⬜ pending |
| 228-01-02 | 228-01 | 1 | none (phase has no mapped IDs) | T-228-03 | Evidence schema exists before authority and preserves nonempty proof semantics | document contract + deterministic suites | `rg -n 'readiness_not_authorized|first-attempt|selected_count|live-stripe-proof' .planning/phases/228-repair-stripe-webhook-signing-ci-boot-contract-under-a-fresh/228-STRIPE-WEBHOOK-BOOT-EVIDENCE.md` | ❌ until execution | ⬜ pending |
| 228-02-01 | 228-02 | 2 | none (phase has no mapped IDs) | T-228-05, T-228-06, T-228-08 | Exact endpoint-secret administration is confirmed without disclosure | deterministic gate + blocking human checkpoint | `node scripts/ci/verify_provider_proof.mjs --fixtures && cd accrue && mix test test/accrue/runtime_config_test.exs test/accrue/config_test.exs` plus sanitized `configured` confirmation | ✅ plan contract | ⬜ pending |
| 228-02-02 | 228-02 | 2 | none (phase has no mapped IDs) | T-228-07, T-228-08 | One attempt is explicitly authorized or declined without dispatch | deterministic evidence-budget gate + blocking decision | `node scripts/ci/verify_provider_proof.mjs --fixtures && rg -n 'consumed: `false`|first-attempt|additional dispatch authorized: `false`' .planning/phases/228-repair-stripe-webhook-signing-ci-boot-contract-under-a-fresh/228-STRIPE-WEBHOOK-BOOT-EVIDENCE.md && git diff --exit-code -- .planning/phases/227-measured-critical-path-improvement` plus exact binary decision | ✅ plan contract | ⬜ pending |
| 228-03-01 | 228-03 | 3 | none (phase has no mapped IDs) | T-228-09, T-228-12 | Independent live binding proves repository, immutable run URL, CI/workflow_dispatch, exact SHA/attempt/window, input-gated stable job and named steps; no-run proves absence in-window | authoritative live binding/no-run reconciliation | `node scripts/ci/verify_stripe_webhook_boot_evidence.mjs --verify-live-binding --record … --repository … --sha … --dispatch-at … --observed-at …` with the explicit arguments in Plan 228-03 Task 1 | ❌ verifier until Wave 1; ❌ phase outcome until execution | ⬜ pending |
| 228-03-02 | 228-03 | 3 | none (phase has no mapped IDs) | T-228-10, T-228-11, T-228-12 | Independent terminal reconciliation validates exact created-run proved/non-proved tuples or full empty no-run tuple against GitHub jobs and temporary proof/manifest artifacts | authoritative terminal reconciliation | `node scripts/ci/verify_stripe_webhook_boot_evidence.mjs --verify-terminal --record … --repository … --sha … --dispatch-at … --observed-at … && git diff --exit-code -- .planning/phases/227-measured-critical-path-improvement` with the explicit arguments in Plan 228-03 Task 2 | ❌ verifier until Wave 1; ❌ phase outcome until execution | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Extend `scripts/ci/verify_provider_proof.mjs` fixtures to reject a missing or renamed signing-secret binding and preflight omission without exposing any secret value.
- [ ] Add dependency-free `scripts/ci/verify_stripe_webhook_boot_evidence.mjs` with exhaustive `--fixtures`, `--verify-live-binding`, and `--verify-terminal` modes using existing live-Actions patterns.
- [ ] Add a deterministic no-network runtime boot-contract test for the live-key-plus-webhook-secret path.
- [ ] Define the sanitized Phase 228 evidence record/schema before a live dispatch.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Configure the real test-mode endpoint signing secret | TBD-228-02 | Repository access and maintainer authority are external to the codebase | Retrieve the matching test-mode endpoint secret from Stripe Dashboard, set `STRIPE_WEBHOOK_SECRET` as a GitHub repository secret, and confirm only presence—not value—in the job preflight. |
| Dispatch exactly one newly authorized first-attempt provider run | TBD-228-03 | Requires GitHub Actions authorization, GitHub API availability, and the configured secret | Dispatch only after deterministic checks pass; retain the run ID, selected-test count, manifest presence, raw conclusion, finalizer result, and sanitized proof artifact. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency is measured and bounded
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
