---
phase: 18
slug: stripe-tax-core
status: verified
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-17
---

# Phase 18 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Ecto SQL Sandbox + Fake processor |
| **Config file** | `accrue/test/test_helper.exs` |
| **Quick run command** | `cd accrue && mix test test/accrue/billing/invoice_projection_test.exs test/accrue/billing/subscription_projection_tax_test.exs test/accrue/billing/subscription_test.exs test/accrue/checkout_test.exs test/accrue/processor/fake_test.exs test/accrue/processor/stripe_test.exs` |
| **CI gate** | `.github/workflows/ci.yml` job `phase18-tax-gate` |
| **Full suite command** | `cd accrue && mix test` |
| **Estimated runtime** | ~1 second targeted, ~120 seconds full suite |

---

## Sampling Rate

- **After every task commit:** Run the task-scoped ExUnit file listed in the verification map below.
- **After every plan wave:** Run `cd accrue && mix test test/accrue/billing/invoice_projection_test.exs test/accrue/billing/subscription_projection_tax_test.exs test/accrue/billing/subscription_test.exs test/accrue/checkout_test.exs test/accrue/processor/fake_test.exs test/accrue/processor/stripe_test.exs`
- **Before `$gsd-verify-work`:** Phase 18 targeted suite must be green locally and in CI through `phase18-tax-gate`; full-suite coverage remains enforced by the general `release-gate`.
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 18-02-01 | 02 | 1 | TAX-01 | T-18-04, T-18-05 | Stripe adapter preserves normalized `automatic_tax` request shape for subscription and checkout calls via `stringify_keys(params)` | unit | `cd accrue && mix test test/accrue/processor/stripe_test.exs` | yes | green |
| 18-02-02 | 02 | 1 | TAX-01 | T-18-06 | Fake emits deterministic enabled/disabled automatic-tax state for subscription, invoice, and checkout payloads | unit | `cd accrue && mix test test/accrue/processor/fake_test.exs` | yes | green |
| 18-01-01 | 01 | 2 | TAX-01 | T-18-01, T-18-03 | Public `subscribe/3` accepts only boolean automatic-tax intent and normalizes it before the processor boundary | integration | `cd accrue && mix test test/accrue/billing/subscription_test.exs` | yes | green |
| 18-01-02 | 01 | 2 | TAX-01 | T-18-01, T-18-02 | Existing subscription callers without tax options remain backward-compatible while explicit enabled/disabled cases stay observable | integration | `cd accrue && mix test test/accrue/billing/subscription_test.exs` | yes | green |
| 18-04-01 | 04 | 2 | TAX-01 | T-18-10, T-18-11 | Checkout callers can enable automatic tax through the public API and returned sessions expose projected tax fields | integration | `cd accrue && mix test test/accrue/checkout_test.exs` | yes | green |
| 18-04-02 | 04 | 2 | TAX-01 | T-18-12 | Checkout enabled and disabled tax flows remain deterministic and observable in Fake-backed regression coverage | integration | `cd accrue && mix test test/accrue/checkout_test.exs` | yes | green |
| 18-03-01 | 03 | 3 | TAX-01 | T-18-09 | Subscription and invoice rows persist narrow automatic-tax observability fields without expanding local schema parity | integration | `cd accrue && mix test test/accrue/billing/invoice_projection_test.exs test/accrue/billing/subscription_projection_tax_test.exs` | yes | green |
| 18-03-02 | 03 | 3 | TAX-01 | T-18-07, T-18-08 | Subscription and invoice projections preserve automatic-tax enabled/status state, tax amount fallback behavior, and raw payload data | unit | `cd accrue && mix test test/accrue/billing/invoice_projection_test.exs test/accrue/billing/subscription_projection_tax_test.exs` | yes | green |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

- [x] `accrue/test/accrue/billing/subscription_tax_test.exs` or explicit subscription tax cases in `accrue/test/accrue/billing/subscription_test.exs` cover enabled and disabled subscription tax behavior.
- [x] `accrue/test/accrue/checkout_tax_test.exs` or explicit checkout tax cases in `accrue/test/accrue/checkout_test.exs` assert automatic-tax and amount-tax projection fields.
- [x] `accrue/test/accrue/billing/invoice_projection_tax_test.exs` or explicit invoice tax cases in `accrue/test/accrue/billing/invoice_projection_test.exs` cover automatic-tax status and forward-compatible invoice payload handling.
- [x] `accrue/test/accrue/billing/subscription_projection_tax_test.exs` covers subscription projection automatic-tax enabled/status parity for string-keyed, atom-keyed, and omitted tax payloads.
- [x] `accrue/test/accrue/processor/fake_test.exs` and `accrue/test/accrue/processor/stripe_test.exs` cover Fake parity and Stripe passthrough as separate task-level checks for Plan 18-02.

---

## Manual-Only Verifications

No manual-only verification remains for Phase 18.

Optional live Stripe provider parity is advisory because it depends on account-level Stripe configuration and tax registrations. The repository already runs the `live-stripe` workflow only on `workflow_dispatch` and the daily schedule with `continue-on-error: true`, so it is not a Phase 18 release blocker or human sign-off requirement.

---

## Validation Sign-Off

- [x] All tasks have automated verify commands or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter
- [x] Required deterministic Phase 18 gate shifted left into CI as `phase18-tax-gate`

**Approval:** verified 2026-04-17 after targeted run `cd accrue && mix test test/accrue/billing/invoice_projection_test.exs test/accrue/billing/subscription_projection_tax_test.exs test/accrue/billing/subscription_test.exs test/accrue/checkout_test.exs test/accrue/processor/fake_test.exs test/accrue/processor/stripe_test.exs` returned `74 tests, 0 failures`. No manual Phase 18 verification remains.
