---
phase: 96-chosen-second-provider-thin-slice
plan: 02
subsystem: webhook
tags:
  - braintree
  - webhooks
  - normalization
  - billing
dependency_graph:
  requires:
    - 96-01
  provides:
    - Braintree webhook ingress verification
    - Braintree webhook payload normalization
    - Subscription and Invoice projection for Braintree
tech_stack:
  added: []
  patterns:
    - Webhook Signature Verification
    - Payload Normalization
    - Event Projection
key_files:
  created: []
  modified:
    - accrue/lib/accrue/webhook/signature.ex
    - accrue/lib/accrue/webhook/plug.ex
    - accrue/lib/accrue/webhook/default_handler.ex
    - accrue/lib/accrue/billing/invoice_projection.ex
    - accrue/test/accrue/webhook/plug_test.exs
    - accrue/test/accrue/webhook/default_handler_test.exs
    - accrue/test/accrue/billing/invoice_projection_test.exs
decisions_made:
  - "Decided to map Braintree subscription_charged_successfully to invoice.paid and map its transaction directly to an invoice via InvoiceProjection."
  - "Decided to use Braintree's standard SDK payload parsing inside Accrue.Webhook.Signature.parse_braintree! to ensure verifiable integrity."
metrics:
  duration_minutes: 10
  completed_date: "2024-05-15"
---

# Phase 96 Plan 02: Braintree Webhook Ingress and Lifecycle Normalization Summary

Added processor-aware Braintree webhook verification, parsing, and lifecycle normalization for the supported slice.

## Overview
This plan implements the real provider path in PROC-12 by handling the Braintree ingress seam. It ensures that webhook signatures and payloads from Braintree are verified and parsed using the Braintree SDK instead of Stripe-only assumptions. The lifecycle events from Braintree are normalized into the standard Accrue event vocabulary so they can be processed by the same reducer paths and projection logic as Stripe and Fake processors.

## Completed Tasks
- **Task 1:** Branched webhook ingress by processor in `Accrue.Webhook.Plug` and `Accrue.Webhook.Signature` to handle `bt_signature` and `bt_payload`.
- **Task 2:** Updated `Accrue.Webhook.DefaultHandler` to normalize Braintree events and refetch canonical objects. Extended `Accrue.Billing.InvoiceProjection.decompose/1` to correctly project Braintree subscription transactions into invoice attributes.

## Deviations from Plan
- None - plan executed exactly as written.

## Threat Flags
- None.

## Known Stubs
- None.
