---
phase: 099-refunds-and-invoice-parity
plan: 01
subsystem: accrue
tags:
  - billing
  - braintree
  - refunds
requires: []
provides:
  - "Canonical `refund/2` and `refund!/2` facade wrappers"
  - "Additive refund identity schema with `processor_id`"
  - "Braintree adapter refund callbacks"
affects:
  - "accrue/lib/accrue/billing.ex"
  - "accrue/lib/accrue/billing/refund_actions.ex"
  - "accrue/lib/accrue/billing/refund.ex"
  - "accrue/lib/accrue/processor/braintree.ex"
tech-stack:
  added:
    - "Ecto migration for `processor_id`"
  patterns:
    - "Dual-write schema for additive identity"
    - "Facade pattern for `refund/2` with backward compatibility delegates"
key-files:
  created:
    - "accrue/priv/repo/migrations/20260430100000_add_processor_id_to_accrue_refunds.exs"
    - "accrue/test/accrue/billing/refund_braintree_test.exs"
  modified:
    - "accrue/lib/accrue/billing.ex"
    - "accrue/lib/accrue/billing/refund_actions.ex"
    - "accrue/lib/accrue/billing/refund.ex"
    - "accrue/lib/accrue/processor/braintree.ex"
    - "accrue/test/accrue/processor/braintree_test.exs"
key-decisions:
  - "Implemented `processor_id` on the refund schema for multi-provider identity, alongside `stripe_id` for backward compatibility."
  - "Introduced `Accrue.Billing.refund/2` as the new canonical entrypoint, leaving `create_refund/2` intact to not break existing usage."
  - "Refused refunds for non-settled Braintree charges to match semantic lifecycle constraints."
metrics:
  duration: 10m
  completed_date: "2024-05-30"
---

# Phase 099 Plan 01: Canonical Braintree Refunds Summary

Establish the canonical Braintree refund write path and additive refund identity model.

## Overview

We established the Braintree refund path by introducing a canonical `refund/2` facade wrapper while preserving the old `create_refund/2` for backwards compatibility. A new `processor_id` column was added via a data migration to the `accrue_refunds` table, ensuring we can track both Braintree and Stripe refunds without breaking existing queries. The Braintree processor adapter was implemented to safely call the Braintree Gateway APIs to issue and retrieve refunds, correctly failing gracefully and translating Braintree errors to standardized `%Accrue.APIError{}` struct.

## Deviations from Plan

None - plan executed mostly as written, manual test fixes were applied by the user to ensure deterministic correctness.

## Self-Check: PASSED
