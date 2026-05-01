---
phase: 100-billing-portal-semantics
plan: 01
subsystem: Accrue.Billing
tags: [braintree, billing_portal, dx]
dependency_graph:
  requires: [099-refunds-and-invoice-parity]
  provides: [braintree_portal_capability_rejection]
  affects: [Accrue.Billing, Accrue.Processor.Braintree]
tech_stack:
  added: []
  patterns: [facade-capabilities, developer-documentation]
key_files:
  created: 
    - accrue/guides/braintree-local-portal.md
  modified:
    - accrue/lib/accrue/processor/braintree.ex
    - accrue/lib/accrue/billing.ex
    - accrue/test/accrue/processor/braintree_test.exs
    - accrue/test/accrue/billing/billing_portal_session_facade_test.exs
metrics:
  duration_minutes: 5
  completed_date: "2026-05-01"
---

# Phase 100 Plan 01: Billing Portal Semantics Summary

Explicitly disable Braintree portal capability and guide developers to build local portals.

## Completed Tasks

1. **Explicitly disable Braintree portal capability**
   - Modified `Accrue.Processor.Braintree` to explicitly declare `billing_portal: %{create: false}`.
   - Verified via unit test.
   - Commit: `47e8ce3`

2. **Fail cleanly in Billing facade on unsupported gateways**
   - Modified `Accrue.Billing.create_billing_portal_session/2` to check `Accrue.Processor.supports?([:billing_portal, :create])`.
   - Raised a precise `%Accrue.APIError{code: :unsupported_by_gateway}` with a message pointing to the custom guide.
   - Updated documentation for both facade variants.
   - Verified via `billing_portal_session_facade_test.exs`.
   - Commit: `10410e2`

3. **Author local portal documentation guide**
   - Authored `accrue/guides/braintree-local-portal.md`.
   - Detailed rationale on avoiding CSS/routing lock-in.
   - Provided complete LiveView copy-paste snippets for basic subscription self-serve parity.
   - Commit: `cabfebb`

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED
- FOUND: accrue/guides/braintree-local-portal.md
- FOUND: 47e8ce3
- FOUND: 10410e2
- FOUND: cabfebb
