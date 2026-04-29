---
phase: 095-official-processor-contract-conformance-harness
plan: 03
subsystem: testing
tags: [conformance, fake, docs, webhook]

# Dependency graph
requires:
  - phase: 095-official-processor-contract-conformance-harness
    provides: executable capability contract and public facade guards from Plans 01-02
provides:
  - Fake-first conformance proof for the staged processor slice
  - Updated lane wording for Fake merge-blocking vs provider-parity checks
  - Completed validation contract for Phase 95
affects: [phase-96, testing guides, validation tracking]

# Tech tracking
tech-stack:
  added: []
  patterns: [fake-first-conformance, advisory-provider-smoke]

key-files:
  created: []
  modified:
    - accrue/guides/testing.md
    - guides/testing-live-stripe.md
    - .planning/processor-support-matrix.md
    - .planning/phases/95-official-processor-contract-conformance-harness/095-VALIDATION.md
    - accrue/test/accrue/webhook/default_handler_phase3_test.exs

key-decisions:
  - "Fake remains the merge-blocking SSOT for the supported processor slice."
  - "Provider-backed Stripe checks stay explicitly advisory/provider-parity only."
  - "Validation status should reflect the real focused billing and webhook commands added in this phase."

requirements-completed: [PROC-10, PROC-11]

# Metrics
duration: ~20m
completed: 2026-04-29
---

# Phase 95 Plan 03: Close the conformance and docs loop

**Phase 95 now closes the proof loop around the staged processor contract: Fake is explicitly the merge-blocking conformance lane, provider-backed Stripe remains advisory, and the validation artifact reflects the focused capability, billing, checkout, webhook, and docs commands that keep the contract honest.**

## Accomplishments
- Updated `accrue/guides/testing.md` and `guides/testing-live-stripe.md` so the Fake-first vs provider-parity lane model is explicit.
- Tightened `.planning/processor-support-matrix.md` around staged first-party target wording and the merge-blocking Fake-first conformance set.
- Updated `095-VALIDATION.md` so the Wave 0 files exist, task rows are green, and the quick/full commands match the implemented test surface.
- Verified the staged slice across capability, billing, checkout, webhook, and package-doc contracts.

## Verification
- `bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_processor_support_matrix.sh`
- `cd accrue && mix test test/accrue/billing/subscription_actions_test.exs test/accrue/billing/payment_method_actions_test.exs test/accrue/processor/capabilities_test.exs test/accrue/webhook/default_handler_phase3_test.exs test/accrue/checkout/session_test.exs --max-cases 1`

## Task Commits

1. **Task 1: Add the Fake-first conformance harness and lifecycle proof coverage** — `1ca55ec`
2. **Task 2: Align provider-smoke docs and validation artifacts** — `1ca55ec`

## Self-Check: PASSED

---
*Phase: 095-official-processor-contract-conformance-harness*
*Completed: 2026-04-29*
