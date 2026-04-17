---
phase: 18
slug: stripe-tax-core
status: complete
started: 2026-04-17T17:35:00Z
updated: 2026-04-17T17:35:00Z
source_summaries:
  - .planning/phases/18-stripe-tax-core/18-SUMMARY.md
  - .planning/phases/18-stripe-tax-core/18-SECURITY.md
  - .planning/phases/18-stripe-tax-core/18-VALIDATION.md
---

# Phase 18 - Automated UAT

## Current Test

[testing complete]

## Acceptance Results

| ID | Scenario | Expected Result | Verification | Result |
|----|----------|-----------------|--------------|--------|
| UAT-18-01 | Subscription callers enable, disable, or omit automatic tax | Public subscription contracts normalize tax intent without breaking existing callers | `cd accrue && mix test test/accrue/billing/subscription_test.exs` | pass |
| UAT-18-02 | Stripe and Fake processors receive automatic-tax inputs | Stripe preserves request shape and Fake emits deterministic enabled/disabled parity | `cd accrue && mix test test/accrue/processor/stripe_test.exs test/accrue/processor/fake_test.exs` | pass |
| UAT-18-03 | Checkout callers enable or disable automatic tax | Checkout sessions expose deterministic automatic-tax and amount-tax projection fields | `cd accrue && mix test test/accrue/checkout_test.exs` | pass |
| UAT-18-04 | Billing projections persist tax observability | Subscription and invoice projections preserve enabled/status state, tax amount fallback behavior, and raw payload compatibility | `cd accrue && mix test test/accrue/billing/invoice_projection_test.exs test/accrue/billing/subscription_projection_tax_test.exs` | pass |
| UAT-18-05 | Phase 18 verification shifts left into CI | Push and pull-request CI run a required deterministic Stripe Tax gate without human sign-off | `.github/workflows/ci.yml` job `phase18-tax-gate` | pass |

## Automated Gate

Required command:

```bash
cd accrue && mix test test/accrue/billing/invoice_projection_test.exs test/accrue/billing/subscription_projection_tax_test.exs test/accrue/billing/subscription_test.exs test/accrue/checkout_test.exs test/accrue/processor/fake_test.exs test/accrue/processor/stripe_test.exs
```

Latest local result: `74 tests, 0 failures`.

CI status: shifted left into `.github/workflows/ci.yml` as required job `phase18-tax-gate`, and included in the release-facing annotation sweep.

## Advisory Provider Parity

Live Stripe parity remains advisory because it depends on account-level Stripe configuration and tax registrations. The existing `live-stripe` workflow runs only on `workflow_dispatch` and the daily schedule with `continue-on-error: true`; it is not a Phase 18 release blocker and does not require human approval.

## Summary

| Metric | Count |
|--------|-------|
| Passed | 5 |
| Issues | 0 |
| Pending | 0 |
| Skipped | 0 |
| Blocked | 0 |

## Gaps

None. Phase 18 has no manual UAT or manual verification remaining.
