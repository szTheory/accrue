---
phase: 95
slug: official-processor-contract-conformance-harness
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-29
---

# Phase 95 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + bash doc-contract verifiers |
| **Config file** | `accrue/mix.exs` and `.github/workflows/ci.yml` |
| **Quick run command** | `cd accrue && mix test test/accrue/processor/capabilities_test.exs test/accrue/checkout/session_test.exs test/accrue/billing/subscription_actions_test.exs` |
| **Full suite command** | `bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_processor_support_matrix.sh && cd accrue && mix test test/accrue/processor/capabilities_test.exs test/accrue/checkout/session_test.exs test/accrue/billing/subscription_actions_test.exs test/accrue/billing/payment_method_actions_test.exs test/accrue/webhook/default_handler_phase3_test.exs` |
| **Estimated runtime** | ~90 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd accrue && mix test test/accrue/processor/capabilities_test.exs test/accrue/checkout/session_test.exs test/accrue/billing/subscription_actions_test.exs`
- **After every plan wave:** Run `bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_processor_support_matrix.sh && cd accrue && mix test test/accrue/processor/capabilities_test.exs test/accrue/checkout/session_test.exs test/accrue/billing/subscription_actions_test.exs test/accrue/billing/payment_method_actions_test.exs test/accrue/webhook/default_handler_phase3_test.exs`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 95-01-01 | 01 | 1 | PROC-10 | T-95-01 / T-95-02 | Runtime capability truth matches the matrix and no longer defaults unsupported first-party rows to true. | unit | `cd accrue && mix test test/accrue/processor/capabilities_test.exs --max-cases 1` | ✅ | ✅ green |
| 95-01-02 | 01 | 1 | PROC-10 | T-95-01 | Matrix labels and executable support declarations stay co-updated. | bash + unit | `bash scripts/ci/verify_processor_support_matrix.sh && cd accrue && mix test test/accrue/processor/capabilities_test.exs --max-cases 1` | ✅ | ✅ green |
| 95-02-01 | 02 | 1 | PROC-11 | T-95-03 / T-95-04 | Non-bang public APIs return `{:error, %Accrue.APIError{code: "processor_operation_unsupported"}}` when outside slice. | unit | `cd accrue && mix test test/accrue/billing/subscription_actions_test.exs test/accrue/billing/payment_method_actions_test.exs --max-cases 1` | ✅ | ✅ green |
| 95-02-02 | 02 | 1 | PROC-11 | T-95-04 | Stripe-shaped subscribe assumptions are isolated only where needed for the staged thin slice. | unit | `cd accrue && mix test test/accrue/billing/subscription_actions_test.exs --max-cases 1` | ✅ | ✅ green |
| 95-03-01 | 03 | 2 | PROC-10 | T-95-05 | Fake-backed conformance suite proves the staged supported rows deterministically. | integration | `cd accrue && mix test test/accrue/processor/capabilities_test.exs test/accrue/billing/subscription_actions_test.exs test/accrue/webhook/default_handler_phase3_test.exs test/accrue/checkout/session_test.exs --max-cases 1` | ✅ | ✅ green |
| 95-03-02 | 03 | 2 | PROC-10, PROC-11 | T-95-02 / T-95-05 | Provider smoke posture and support labels stay aligned with docs and CI without becoming merge-blocking. | bash + docs | `bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_processor_support_matrix.sh` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `accrue/test/accrue/billing/subscription_actions_test.exs` — focused unsupported-operation and staged-slice tests
- [x] `accrue/test/accrue/billing/payment_method_actions_test.exs` — out-of-slice payment-method boundary coverage
- [x] shared conformance helper or fixture module if Fake/Stripe capability rows need one contract harness
- [x] existing docs verifiers cover matrix and package-doc drift
- [x] existing `capabilities_test.exs` and `checkout/session_test.exs` provide direct precedents for capability and unsupported-operation checks

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Review that staged/proven labeling is honest and does not over-claim Braintree support on this branch | PROC-10 | Requires maintainer judgment about wording honesty beyond literal needles | Read `.planning/processor-support-matrix.md` diff and confirm every Braintree-facing row is labeled as staged, target, or proven consistently with the implemented test coverage |
| Review that provider smoke wording stays advisory/protected-branch only | PROC-10 | CI text can drift while focused tests still pass | Read `accrue/guides/testing.md` and `guides/testing-live-stripe.md` after edits and confirm no provider lane is described as the merge-blocking source of truth |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** complete
