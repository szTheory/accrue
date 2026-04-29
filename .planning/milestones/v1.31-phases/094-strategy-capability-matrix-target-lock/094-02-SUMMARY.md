---
phase: 094-strategy-capability-matrix-target-lock
plan: 02
subsystem: planning
tags: [processor-support, matrix, ci, bash]

# Dependency graph
requires:
  - phase: 094-strategy-capability-matrix-target-lock
    provides: locked support posture and provider decision from Plan 01
provides:
  - Canonical processor-support matrix for Fake, Stripe, and Braintree
  - Dedicated bash verifier for matrix drift
  - Docs-contracts-shift-left CI hook for the new contract
affects: [phase-94-03, phase-95, ci, docs contracts]

# Tech tracking
tech-stack:
  added: []
  patterns: [canonical-matrix-plus-verifier, shift-left-doc-contracts]

key-files:
  created:
    - .planning/processor-support-matrix.md
    - scripts/ci/verify_processor_support_matrix.sh
  modified:
    - scripts/ci/verify_package_docs.sh
    - .github/workflows/ci.yml

key-decisions:
  - "Name semantic capability rows instead of provider event jargon."
  - "Keep checkout and billing portal visible but labeled Stripe-only."
  - "Make processor-support drift merge-visible through a dedicated CI gate."

requirements-completed: [PROC-09]

# Metrics
duration: ~35m
completed: 2026-04-29
---

# Phase 94 Plan 02: Add the canonical matrix and CI contract

**Accrue now has one canonical processor-support matrix and one dedicated bash gate for it, wired directly into `docs-contracts-shift-left`.**

## Accomplishments
- Created `.planning/processor-support-matrix.md` with Fake/Stripe/Braintree capability rows, support labels, and explicit out-of-slice surfaces.
- Added `scripts/ci/verify_processor_support_matrix.sh` to pin the required matrix literals.
- Extended `verify_package_docs.sh` with strategy, project, and custom-processor drift needles.
- Wired the new matrix verifier into `.github/workflows/ci.yml`.

## Task Commits

1. **Task 1: Add matrix + bash/CI contract** — `8e405d3`

## Decisions Made
- `Accrue.Billing.subscribe/3` is the primary public-facade candidate for the second-provider slice.
- `Accrue.Billing.create_checkout_session/2` and `Accrue.Billing.create_billing_portal_session/2` remain labeled `Stripe-only`.
- Unsupported surfaces must fail clearly and early rather than imply near-parity.

## Self-Check: PASSED

---
*Phase: 094-strategy-capability-matrix-target-lock*
*Completed: 2026-04-29*
