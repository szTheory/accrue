---
phase: 18
slug: stripe-tax-core
status: draft
nyquist_compliant: true
wave_0_complete: false
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
| **Quick run command** | `cd accrue && mix test test/accrue/checkout_test.exs test/accrue/billing/subscription_test.exs test/accrue/billing/invoice_projection_test.exs` |
| **Full suite command** | `cd accrue && mix test.all` |
| **Estimated runtime** | ~120 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd accrue && mix test test/accrue/checkout_test.exs test/accrue/billing/subscription_test.exs`
- **After every plan wave:** Run `cd accrue && mix test.all`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 18-01-01 | 01 | 1 | TAX-01 | T-18-01 | Public callers can only provide tax enablement intent, not trusted tax totals | integration | `cd accrue && mix test test/accrue/billing/subscription_test.exs` | yes | pending |
| 18-01-02 | 01 | 1 | TAX-01 | T-18-01 | Existing subscription callers without tax options remain backward-compatible | integration | `cd accrue && mix test test/accrue/billing/subscription_test.exs` | yes | pending |
| 18-02-01 | 02 | 1 | TAX-01 | T-18-02 | Fake emits deterministic enabled/disabled automatic-tax state without leaking Stripe-only implementation into tests | unit | `cd accrue && mix test test/accrue/processor/fake_test.exs` | yes | pending |
| 18-03-01 | 03 | 3 | TAX-01 | T-18-03 | Subscription and invoice projections preserve automatic-tax observability while retaining raw payload data | unit | `cd accrue && mix test test/accrue/billing/invoice_projection_test.exs` | yes | pending |
| 18-04-01 | 04 | 2 | TAX-01 | T-18-01 | Checkout callers can enable automatic tax and observe returned session tax fields | integration | `cd accrue && mix test test/accrue/checkout_test.exs` | yes | pending |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

- [ ] `accrue/test/accrue/billing/subscription_tax_test.exs` or explicit subscription tax cases in `accrue/test/accrue/billing/subscription_test.exs` cover enabled and disabled subscription tax behavior.
- [ ] `accrue/test/accrue/checkout_tax_test.exs` or explicit checkout tax cases in `accrue/test/accrue/checkout_test.exs` assert automatic-tax and amount-tax projection fields.
- [ ] `accrue/test/accrue/billing/invoice_projection_tax_test.exs` or explicit invoice tax cases in `accrue/test/accrue/billing/invoice_projection_test.exs` cover automatic-tax status and forward-compatible invoice payload handling.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Optional live Stripe parity for automatic-tax request shape | TAX-01 | Required phase validation is Fake-backed; live Stripe calls depend on account configuration and tax registrations | Run any existing live Stripe check only after ExUnit is green; compare request/response tax fields against Fake shape without making live Stripe parity a release blocker |

---

## Validation Sign-Off

- [x] All tasks have automated verify commands or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
