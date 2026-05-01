---
phase: 97
slug: advanced-subscription-lifecycle
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-30
---

# Phase 97 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + bash doc-contract verifiers |
| **Config file** | `accrue/mix.exs` and `.github/workflows/ci.yml` |
| **Quick run command** | `cd accrue && mix test test/accrue/processor/braintree_test.exs test/accrue/processor/capabilities_test.exs test/accrue/billing/subscription_actions_test.exs test/accrue/billing/subscription_projection_provider_test.exs` |
| **Full suite command** | `bash scripts/ci/verify_processor_support_matrix.sh && cd accrue && mix test test/accrue/processor/braintree_test.exs test/accrue/processor/capabilities_test.exs test/accrue/billing/subscription_actions_test.exs test/accrue/billing/subscription_projection_provider_test.exs test/accrue/webhook/default_handler_test.exs test/accrue/webhook/default_handler_phase3_test.exs` |
| **Estimated runtime** | ~120 seconds |

---

## Sampling Rate

- **After every task commit:** Run the quick command.
- **After every plan wave:** Run the full suite command.
- **Before `$gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** 120 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 97-01-01 | 01 | 1 | PROC-14 | T-97-01 / T-97-02 | Braintree mutation callbacks exist with explicit capability truth and typed failure handling. | unit | `cd accrue && mix test test/accrue/processor/braintree_test.exs test/accrue/processor/capabilities_test.exs` | ✅ | ⬜ pending |
| 97-01-02 | 01 | 1 | PROC-14 | T-97-03 | Every lifecycle family in PROC-14 has explicit Braintree semantics or typed-error coverage at the billing-action layer. | unit | `cd accrue && mix test test/accrue/billing/subscription_actions_test.exs test/accrue/billing/subscription_projection_provider_test.exs` | ✅ | ⬜ pending |
| 97-01-03 | 01 | 1 | PROC-14 | T-97-01 / T-97-03 | Focused adapter/billing suites pass together without widening the public facade. | unit | `cd accrue && mix test test/accrue/processor/braintree_test.exs test/accrue/processor/capabilities_test.exs test/accrue/billing/subscription_actions_test.exs test/accrue/billing/subscription_projection_provider_test.exs` | ✅ | ⬜ pending |
| 97-02-01 | 02 | 2 | PROC-15 | T-97-04 | Mutation-related Braintree lifecycle events normalize through the shared reducer path and refetch canonical subscription state. | integration | `cd accrue && mix test test/accrue/webhook/default_handler_test.exs test/accrue/webhook/default_handler_phase3_test.exs --max-cases 1` | ✅ | ⬜ pending |
| 97-02-02 | 02 | 2 | PROC-14, PROC-15 | T-97-05 | Local subscription rows persist converged Braintree mutation state across all required lifecycle families or documented typed-error boundaries. | integration | `cd accrue && mix test test/accrue/billing/subscription_projection_provider_test.exs test/accrue/webhook/default_handler_test.exs test/accrue/webhook/default_handler_phase3_test.exs --max-cases 1` | ✅ | ⬜ pending |
| 97-03-01 | 03 | 3 | PROC-14 | T-97-06 | Example-host proof exercises at least one hermetic Braintree lifecycle mutation through the generic facade. | host | `cd examples/accrue_host && mix test test/accrue_host/billing_facade_test.exs test/accrue_host/braintree_subscribe_test.exs` | ✅ | ⬜ pending |
| 97-03-02 | 03 | 3 | PROC-14 | T-97-06 | The required Phase 97 Braintree proof is fully hermetic and requires no runtime provider credentials or network access. | host/hermetic | `cd examples/accrue_host && mix test test/accrue_host/braintree_subscribe_test.exs` | ✅ | ⬜ pending |
| 97-03-03 | 03 | 3 | PROC-14, PROC-15 | T-97-07 | Support matrix and docs mirror the actual supported Braintree mutation slice without over-claiming parity and keep any provider-backed lane advisory only. | bash + docs | `bash scripts/ci/verify_processor_support_matrix.sh` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `accrue/test/accrue/processor/braintree_test.exs` — existing adapter-focused seed coverage
- [x] `accrue/test/accrue/billing/subscription_actions_test.exs` — billing mutation contract test home
- [x] `accrue/test/accrue/billing/subscription_projection_provider_test.exs` — provider projection test home
- [x] `accrue/test/accrue/webhook/default_handler_test.exs` — Braintree webhook normalization test home
- [x] `examples/accrue_host/test/accrue_host/braintree_subscribe_test.exs` — hermetic host/provider proof lane

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Confirm the chosen Braintree mapping for pause/resume semantics is honest and documented | PROC-14 | Provider semantics may diverge from Stripe and require maintainer judgment | Read the adapter/tests/docs diff and confirm `pause`, `unpause`, and `resume` wording matches what the implementation actually does |
| Confirm quantity semantics are not over-claimed | PROC-14 | `update_quantity/3` may require a bounded Braintree-specific interpretation | Review the final docs + tests and ensure they describe the supported quantity path concretely |
| Confirm the hermetic host proof does not over-claim real-provider parity | PROC-14 | Mock-backed tests can drift into over-broad claims even when green | Review `examples/accrue_host/test/accrue_host/braintree_subscribe_test.exs`, `.planning/processor-support-matrix.md`, and the README wording to confirm the proof is described as hermetic/advisory rather than live-provider parity |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or explicit manual dependency.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all planned test homes.
- [x] No watch-mode flags.
- [x] Feedback latency < 120s.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending
