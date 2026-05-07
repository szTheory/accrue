---
phase: 117-contract-promotion-preview-truth
plan: 01
subsystem: billing-contract
tags: [subscription-change, capabilities, braintree, preview]

# Dependency graph
requires:
  - phase: 117-contract-promotion-preview-truth
    provides: Phase context, research, and provider-honest contract decisions
provides:
  - Public `Accrue.Billing` docs for the official active-subscription-change facade
  - Fine-grained swap/preview capability labels with provider-specific support wording
  - Focused capability and admin proof for the promoted contract
affects: [phase-117-02, phase-117-03, processor support docs, admin copy]

# Tech tracking
tech-stack:
  added: []
  patterns: [capability-label-ssot, provider-honest-contracts, bounded-braintree]

key-files:
  created: []
  modified:
    - accrue/lib/accrue/billing.ex
    - accrue/lib/accrue/processor/capabilities.ex
    - accrue/test/accrue/processor/capabilities_test.exs
    - accrue/lib/accrue/billing/subscription_actions.ex
    - accrue_admin/lib/accrue_admin/copy/subscription.ex
    - accrue_admin/test/accrue_admin/live/subscription_live_test.exs

key-decisions:
  - "Treat `swap_plan/3` and `preview_upcoming_invoice/2` as the explicit public active-subscription-change facade."
  - "Separate public support labels from provider-specific swap/preview wording so code mirrors the support matrix exactly."
  - "Keep Braintree bounded: swap support depends on `:plan_resolver`, while preview stays explicitly unsupported."

requirements-completed: [SCM-01, SCM-02]

# Metrics
duration: ~1h
completed: 2026-05-07
---

# Phase 117 Plan 01: Promote the swap/preview contract in code

**The billing facade and capability map now expose one explicit active-subscription-change contract: `swap_plan/3` and `preview_upcoming_invoice/2` are documented as official entry points, provider-specific swap/preview labels are executable in code, and Braintree stays bounded and provider-honest.**

## Accomplishments
- Added public `@doc` text on `Accrue.Billing.swap_plan/3` and `preview_upcoming_invoice/2` that points maintainers back to `lifecycle_semantics.md` and the processor support matrix.
- Extended `Accrue.Processor.Capabilities` with dedicated swap/preview support labels plus provider-specific labels for `native`, `bounded first-party`, `testing/local-only`, and `unsupported`.
- Updated focused capability tests to prove the promoted swap/preview labels and Braintree preview boundary.
- Tightened admin copy so Braintree explicitly says preview is unavailable while bounded swap setup still points operators to `:plan_resolver`.

## Verification
- `cd accrue && mix test test/accrue/processor/capabilities_test.exs --warnings-as-errors`
- `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs --warnings-as-errors`

## Task Commits

No phase-local commits were created in this run because the workspace already contained overlapping user changes in the Phase 117 file set; the implementation was applied and verified inline instead.

## Self-Check: PASSED
