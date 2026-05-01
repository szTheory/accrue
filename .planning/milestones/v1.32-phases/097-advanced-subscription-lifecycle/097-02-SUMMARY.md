---
phase: 097-advanced-subscription-lifecycle
plan: 02
subsystem: accrue
tags:
  - webhook
  - braintree
  - projection
dependency_graph:
  requires:
    - 097-01
  provides:
    - Braintree lifecycle webhook normalization
    - subscription-backed invoice convergence
    - converged local projection proof
  affects:
    - accrue/lib/accrue/webhook/default_handler.ex
    - accrue/lib/accrue/billing/invoice_projection.ex
    - accrue/lib/accrue/billing/subscription_projection.ex
    - accrue/test/accrue/webhook/default_handler_test.exs
    - accrue/test/accrue/webhook/default_handler_phase3_test.exs
    - accrue/test/accrue/billing/subscription_projection_provider_test.exs
key_files:
  created: []
  modified:
    - accrue/lib/accrue/webhook/default_handler.ex
    - accrue/lib/accrue/billing/invoice_projection.ex
    - accrue/lib/accrue/billing/subscription_projection.ex
decisions:
  - Normalize Braintree lifecycle notifications onto the shared reducer event families, then refetch canonical subscription state instead of trusting webhook payload snapshots.
  - Project Braintree invoice truth from the latest subscription transaction because the converged fetch object is a subscription, not a standalone invoice payload.
metrics:
  completed_date: 2026-04-30
---

# Phase 097 Plan 02 Summary

Validated the mutation-convergence slice for Braintree by routing additional lifecycle notifications through the existing webhook reducer path and proving the resulting subscription and invoice projection behavior with the focused integration suites.

## Deviations from Plan

- No per-task git commits were created. The repository remained a shared dirty main tree with overlapping phase work, so isolating Plan 02-only commits was not safe.

## Threat Flags

None found during the webhook/projection verification runs.

## Known Stubs

None added in this plan.

## Verification

```bash
cd accrue && mix test test/accrue/billing/subscription_projection_provider_test.exs test/accrue/webhook/default_handler_test.exs test/accrue/webhook/default_handler_phase3_test.exs --max-cases 1
bash scripts/ci/verify_processor_support_matrix.sh && cd accrue && mix test test/accrue/processor/braintree_test.exs test/accrue/processor/capabilities_test.exs test/accrue/billing/subscription_actions_test.exs test/accrue/billing/subscription_projection_provider_test.exs test/accrue/webhook/default_handler_test.exs test/accrue/webhook/default_handler_phase3_test.exs
```
