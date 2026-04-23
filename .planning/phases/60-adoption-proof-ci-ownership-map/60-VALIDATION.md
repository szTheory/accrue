---
phase: 60
slug: adoption-proof-ci-ownership-map
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-23
---

# Phase 60 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (`accrue` app) + bash shift-left scripts |
| **Config file** | `accrue/mix.exs` aliases (implicit); no new config required |
| **Quick run command** | `bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_verify01_readme_contract.sh && bash scripts/ci/verify_adoption_proof_matrix.sh` |
| **Full suite command** | `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` |
| **Estimated runtime** | ~60–120 seconds (machine-dependent) |

## Sampling Rate

- **After every task commit:** Quick bash trio when any touched file is on the trio’s path; **always** run `verify_adoption_proof_matrix.sh` after editing `adoption-proof-matrix.md`.
- **After every plan wave:** `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs`
- **Before `/gsd-verify-work`:** Quick trio + package docs test green
- **Max feedback latency:** 180 seconds

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 60-01-01 | 01 | 1 | INT-07 | — | N/A (docs) | bash | `bash scripts/ci/verify_adoption_proof_matrix.sh` | ✅ | ⬜ pending |
| 60-01-02 | 01 | 1 | INT-07 | — | N/A | bash | `bash scripts/ci/verify_verify01_readme_contract.sh` | ✅ | ⬜ pending |
| 60-02-01 | 02 | 1 | INT-07 | — | N/A | bash | `bash scripts/ci/verify_package_docs.sh` | ✅ | ⬜ pending |
| 60-02-02 | 02 | 1 | INT-07 | — | N/A | ExUnit | `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` | ✅ | ⬜ pending |

## Wave 0 Requirements

Existing infrastructure covers all phase requirements — no new test stubs.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Evaluator scan of matrix vs walkthrough tone | INT-07 | Subjective “honesty” of narrative | Read matrix **Layer B/C** + walkthrough §A side-by-side; confirm no claim of merge-blocking Stripe lane. |

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: doc tasks chained to bash trio
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 180s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending execution
