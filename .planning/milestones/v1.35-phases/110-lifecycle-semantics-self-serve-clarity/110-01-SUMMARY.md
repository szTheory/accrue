---
phase: 110-lifecycle-semantics-self-serve-clarity
plan: 01
subsystem: docs
tags: [billing, lifecycle, docs, stripe, braintree, webhooks]
requires:
  - phase: 110-lifecycle-semantics-self-serve-clarity
    provides: canonical lifecycle predicates and action semantics from the billing core
provides:
  - one canonical lifecycle guide now defines action meaning, state vocabulary, and provider labels
  - adjacent portal and webhook guides link back to the lifecycle SSOT instead of redefining semantics
  - self-serve cancellation docs now prefer end-of-period renewal stop with paid-through access preserved
affects: [phase-110, billing-guides, portal-guides, webhook-guides, provider-honesty]
tech-stack:
  added: []
  patterns: [single lifecycle SSOT, provider-specific docs link back to shared glossary, immediate cancel framed as exceptional]
key-files:
  created: [accrue/guides/lifecycle_semantics.md, .planning/milestones/v1.35-phases/110-lifecycle-semantics-self-serve-clarity/110-01-SUMMARY.md]
  modified: [accrue/guides/braintree-local-portal.md, accrue/guides/portal_configuration_checklist.md, accrue/guides/webhooks.md, accrue/guides/webhook_gotchas.md]
key-decisions:
  - "Lifecycle meaning now lives in one guide grounded in subscription predicates and action semantics instead of being re-explained per provider guide."
  - "Self-serve cancellation defaults to cancel renewal at period end with paid-through access preserved; immediate cancel remains an exceptional path."
patterns-established:
  - "Provider-specific lifecycle docs should attach next-step guidance to the shared lifecycle glossary rather than inventing parallel terminology."
requirements-completed: [LIF-01]
duration: 1 wave
completed: 2026-05-06
---

# Phase 110 Plan 01: Lifecycle Semantics SSOT Summary

**Phase 110 now has one canonical lifecycle semantics guide, and adjacent docs were pulled back to it.**

## Performance

- **Completed:** 2026-05-06
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added `accrue/guides/lifecycle_semantics.md` as the SSOT for lifecycle actions, state vocabulary, provider labels, and least-surprise cancellation posture.
- Defined the canonical action strings `cancel_at_period_end`, `cancel/2`, `resume/2`, `pause/2`, and `unpause/2` alongside the state glossary `active`, `canceling`, `paused`, `past_due`, and `ended`.
- Documented provider labels `native`, `host-owned`, `unsupported`, and `testing/local-only` so downstream UI and support docs can reuse one taxonomy.
- Updated `braintree-local-portal.md` to link back to the lifecycle guide and removed the stale immediate-cancel-first self-serve example.
- Anchored `portal_configuration_checklist.md`, `webhooks.md`, and `webhook_gotchas.md` to the same lifecycle vocabulary and convergence framing.

## Verification

- Task 1 verifier passed: `test -f accrue/guides/lifecycle_semantics.md && rg -n "cancel_at_period_end|resume/2|pause/2|unpause/2|active|canceling|paused|past_due|ended|native|host-owned|unsupported|testing/local-only" accrue/guides/lifecycle_semantics.md`
- Task 2 verifier passed: `rg -n "lifecycle_semantics|at_period_end|cancel renewal|end at period end|convergence|local projection" accrue/guides/braintree-local-portal.md accrue/guides/portal_configuration_checklist.md accrue/guides/webhooks.md accrue/guides/webhook_gotchas.md && ! rg -n "Offer immediate cancellations using Accrue's cancel functions|Braintree supports immediate cancellation" accrue/guides/braintree-local-portal.md`
- Core semantic regression lane passed: `cd accrue && mix test test/accrue/billing/subscription_cancel_test.exs test/accrue/billing/subscription_predicates_test.exs test/accrue/billing/subscription_actions_test.exs`
- Result: `26 tests, 0 failures`

## Files Created/Modified

- `accrue/guides/lifecycle_semantics.md` - new canonical lifecycle guide
- `accrue/guides/braintree-local-portal.md` - aligned mounted Braintree guidance to the SSOT
- `accrue/guides/portal_configuration_checklist.md` - linked Stripe-hosted cancellation posture back to the shared lifecycle vocabulary
- `accrue/guides/webhooks.md` - tied webhook convergence framing to the lifecycle guide
- `accrue/guides/webhook_gotchas.md` - tied local projection cautions to the lifecycle glossary

## Issues Encountered

- The workflow's `gsd-sdk query` hooks were not available in this environment, so plan execution proceeded directly from the phase plan file rather than the usual query-driven wrapper.

## Self-Check: PASSED

- Found `accrue/guides/lifecycle_semantics.md` on disk.
- Verified the targeted billing semantics suite passed green after the doc alignment.
