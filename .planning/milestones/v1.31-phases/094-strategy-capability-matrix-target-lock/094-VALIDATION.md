---
phase: 94
slug: strategy-capability-matrix-target-lock
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-29
---

# Phase 94 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash verifier scripts + ExUnit shell-out docs tests |
| **Config file** | `.github/workflows/ci.yml` |
| **Quick run command** | `bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_processor_support_matrix.sh` |
| **Full suite command** | `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs test/accrue/docs/processor_support_matrix_test.exs` |
| **Estimated runtime** | <30 seconds for the quick path; ~60 seconds for the full ExUnit docs-verifier suite |

---

## Sampling Rate

- **After every task commit:** Run `bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_processor_support_matrix.sh`
- **After every plan wave:** Run `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs test/accrue/docs/processor_support_matrix_test.exs`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds on the quick bash path; use the full ExUnit suite at wave boundaries

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 94-01-01 | 01 | 1 | PROC-09 | T-94-01 / T-94-03 | Strategy tracker records locked posture, Braintree target, explicit non-goals, and custom-processor extension-point boundaries without broadening support claims | bash doc contract | `bash scripts/ci/verify_package_docs.sh` | ✅ | ⬜ pending |
| 94-02-01 | 02 | 1 | PROC-09 | T-94-01 / T-94-02 | Processor support matrix names the official slice, provider columns, and Stripe-only or out-of-slice labels | bash doc contract | `bash scripts/ci/verify_processor_support_matrix.sh` | ✅ | ⬜ pending |
| 94-03-01 | 03 | 2 | PROC-09 | T-94-01 / T-94-02 | ExUnit smoke harness proves the package-docs and processor-support verifiers run inside repo test lanes | ExUnit shell-out | `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs test/accrue/docs/processor_support_matrix_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `scripts/ci/verify_processor_support_matrix.sh`
- [x] `accrue/test/accrue/docs/processor_support_matrix_test.exs`
- [x] `scripts/ci/verify_package_docs.sh` pins for `.planning/STRATEGY.md`, `.planning/PROJECT.md`, and `accrue/guides/custom_processors.md`
- [x] `accrue/test/accrue/docs/package_docs_verifier_test.exs` drift coverage for the new package-docs pins
- [x] Strategy and matrix file literals finalized before verifier needles are locked

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Review that capability rows stay semantic rather than provider-jargon shaped | PROC-09 | Requires maintainer judgment about wording quality and scope honesty | Read the matrix and strategy artifact, then confirm rows describe contract semantics like `subscription.lifecycle_webhook_projection` rather than provider event names |
| Review that Fake remains the merge-blocking proof lane and provider-backed runs are described as fidelity checks only | PROC-09 | Repo truth can drift through nuanced copy even when literal verifier checks pass | Read the final strategy and docs diff, then confirm no prose implies provider-backed runs are the primary dev loop |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [x] Feedback latency < 30s on the quick bash path
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
