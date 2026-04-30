---
phase: 96-chosen-second-provider-thin-slice
plan: 01
subsystem: accrue
tags:
  - processor
  - braintree
  - subscription
dependency_graph:
  requires:
    - 095-03
  provides:
    - Braintree adapter
    - explicit braintree seam in SubscriptionActions
  affects:
    - accrue/lib/accrue/billing/subscription_actions.ex
    - accrue/lib/accrue/processor/braintree.ex
    - accrue/lib/accrue/billing/subscription_projection.ex
tech_stack:
  added:
    - braintree library
  patterns:
    - explicit capability branching
key_files:
  created:
    - accrue/lib/accrue/processor/braintree.ex
    - accrue/test/accrue/processor/braintree_test.exs
    - accrue/test/accrue/billing/subscription_projection_provider_test.exs
  modified:
    - accrue/mix.exs
    - accrue/lib/accrue/billing/subscription_actions.ex
    - accrue/lib/accrue/billing/subscription_projection.ex
    - accrue/test/accrue/billing/subscription_actions_test.exs
    - accrue/test/accrue/billing/subscription_test.exs
decisions:
  - Branch Braintree logic at the request seam in SubscriptionActions instead of public Billing module.
metrics:
  duration: 40m
  completed_date: 2026-04-29
---

# Phase 96 Plan 01: Add the Braintree first-party adapter and capability truth Summary

Implemented Braintree adapter with direct subscription creation and added a Braintree seam into the SubscriptionActions request path without exposing it to the public facade.

## Deviations from Plan

None - plan executed exactly as written.

## Threat Flags

None found.

## Known Stubs

None found.

## TDD Gate Compliance

All TDD gates completed successfully.

## Verification
```bash
cd accrue && mix test test/accrue/billing/subscription_test.exs test/accrue/billing/subscription_actions_test.exs test/accrue/billing/subscription_projection_provider_test.exs test/accrue/processor/braintree_test.exs && mix test test/accrue/billing/subscription_test.exs test/accrue/billing/payment_method_actions_test.exs test/accrue/processor/capabilities_test.exs test/accrue/webhook/default_handler_phase3_test.exs test/accrue/checkout/session_test.exs --max-cases 1
```