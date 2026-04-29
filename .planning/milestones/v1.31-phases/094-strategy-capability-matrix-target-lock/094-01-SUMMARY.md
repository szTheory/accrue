---
phase: 094-strategy-capability-matrix-target-lock
plan: 01
subsystem: planning
tags: [processor-support, strategy, braintree, docs]

# Dependency graph
requires:
  - phase: 093-hyg-mirror-inv-tag
    provides: v1.30 closeout and v1.31 milestone opening
provides:
  - Locked strategic posture for the official second-processor track
  - Project-level milestone wording aligned to the Braintree target and gateway subscription core
  - Custom-processor guide explicitly fenced outside first-party support
affects: [phase-94-02, phase-95, strategy docs, custom processor guidance]

# Tech tracking
tech-stack:
  added: []
  patterns: [strategy-ssot, capability-explicit support posture, fake-first proof lane]

key-files:
  created:
    - .planning/STRATEGY.md
  modified:
    - .planning/PROJECT.md
    - accrue/guides/custom_processors.md

key-decisions:
  - "Lock Braintree as the official second-provider target for the v1.31 track."
  - "Treat gateway subscription core as the only first official multi-provider slice."
  - "Keep Fake as the deterministic proof lane and leave checkout/billing portal Stripe-first."

requirements-completed: [PROC-09]

# Metrics
duration: ~30m
completed: 2026-04-29
---

# Phase 94 Plan 01: Lock the strategy and project truth

**Phase 94 now has a repo-level strategic SSOT: Braintree is locked as the second-provider target, the official support promise is gateway subscription core, and custom processors are explicitly outside first-party support unless named in the support matrix.**

## Accomplishments
- Rewrote `.planning/STRATEGY.md` around capability-explicit support, Fake-first proof, Braintree rationale, and explicit non-target providers.
- Updated `.planning/PROJECT.md` so v1.31 mirrors the locked provider, slice, and `Accrue.Billing.subscribe/3` thin-slice posture.
- Updated `accrue/guides/custom_processors.md` so extension-point guidance no longer implies first-party support or release-gated parity.

## Task Commits

1. **Task 1: Lock strategy + project truth** — `5cedca6`

## Decisions Made
- Support truth is a named first-party slice, not generic processor parity.
- Checkout and billing portal remain Stripe-first until another first-party processor proves them honestly.
- Merchant-of-record providers, `Adyen`, `PayPal direct subscriptions`, and `GoCardless` remain explicit non-targets.

## Self-Check: PASSED

---
*Phase: 094-strategy-capability-matrix-target-lock*
*Completed: 2026-04-29*
