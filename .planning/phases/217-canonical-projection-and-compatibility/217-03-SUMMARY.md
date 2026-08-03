---
phase: 217-canonical-projection-and-compatibility
plan: 03
subsystem: entitlements
tags: [elixir, entitlements, purchase-decision, telemetry, idempotency]
requires:
  - phase: 217-01
    provides: revisioned canonical snapshots
provides:
  - typed revision-bound purchase preflight and warning override boundary
  - exact source logical-plan provenance for safe cross-rail equivalence
affects: [billing, canonical-snapshot, purchase-flows]
tech-stack:
  added: []
  patterns: [typed-values, bounded-telemetry, qualified-logical-plan-equivalence]
key-files:
  created: [accrue/lib/accrue/entitlements/purchase_decision.ex, accrue/test/accrue/entitlements/purchase_decision_test.exs]
  modified: [accrue/lib/accrue/entitlements.ex, accrue/lib/accrue/entitlements/snapshot.ex, accrue/test/accrue/entitlements/snapshot_test.exs]
decisions:
  - Source summaries expose bounded logical_plan provenance so preflight compares exact live qualified plans without provider identifiers.
metrics:
  tasks_completed: 2
  tests: 32
  completed: 2026-08-03
status: complete
---

# Phase 217 Plan 03: Purchase Decision Summary

Typed purchase preflight blocks only a live different-rail source carrying the same bounded logical plan, with revision-bound override, bounded telemetry, and a Stripe continuation guard.

## Completed Tasks

1. Added `PurchaseDecision` with closed `eligible|block|warn` outcomes, actionable fail-closed snapshot reasons, exact Apple warning copy, revision recheck, and bounded override audit callback.
2. Added public purchase-decision and override telemetry facades, source-plan-qualified equivalence, and Stripe-only continuation protection.

## Verification

`cd accrue && mix test test/accrue/entitlements/purchase_decision_test.exs test/accrue/entitlements/snapshot_test.exs test/accrue/entitlements/projector_test.exs test/property/entitlement_projection_property_test.exs test/accrue/billing/subscription_actions_test.exs`

Result: 4 properties, 32 tests, 0 failures.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 2 - Missing critical functionality] Added bounded `logical_plan` provenance to every snapshot source summary.
- **Found during:** Task 1 final review.
- **Issue:** rail/environment source summaries could not prove that the exact live grant mapped to the target logical plan; a rail-wide catalog scan would over-block a different plan on the same rail.
- **Fix:** include deterministic `logical_plan` provenance in snapshot sources and authorization signatures; compare the target only to exact different-rail source plans.
- **Files modified:** `accrue/lib/accrue/entitlements/snapshot.ex`, `accrue/lib/accrue/entitlements/purchase_decision.ex`, focused snapshot/purchase tests.
- **Commit:** ed4c8003

## Self-Check: PASSED

- Required source and focused test files exist.
- Commits `7033458a` and `ed4c8003` exist.
