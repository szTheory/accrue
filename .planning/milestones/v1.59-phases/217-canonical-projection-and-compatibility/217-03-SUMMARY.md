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
  created: [accrue/lib/accrue/entitlements/purchase_decision.ex, accrue/lib/accrue/entitlements/purchase_operation.ex, accrue/priv/repo/migrations/20260803010000_create_accrue_entitlement_purchase_operations.exs, accrue/test/accrue/entitlements/purchase_decision_test.exs]
  modified: [accrue/lib/accrue/entitlements.ex, accrue/lib/accrue/entitlements/snapshot.ex, accrue/lib/accrue/billing/subscription_actions.ex, accrue/lib/accrue/processor/fake.ex]
requirements-completed: [ACCT-05]
coverage:
  - id: D1
    description: Purchase preflight permits eligible first purchases, blocks exact live cross-rail equivalents, and safely rechecks durable override and Stripe continuation state before dispatch.
    requirement: ACCT-05
    verification:
      - kind: integration
        ref: "cd accrue && mix test test/accrue/entitlements/purchase_decision_test.exs test/accrue/billing/subscription_actions_test.exs --exclude live_stripe"
        status: pass
    human_judgment: false
decisions:
  - Source summaries expose bounded logical_plan provenance so preflight compares exact live qualified plans without provider identifiers.
  - Ambiguous Stripe creates persist an account-scoped operation and reconcile the same provider idempotency key before any retry dispatch.
metrics:
  tasks_completed: 2
  tests: 197
  completed: 2026-08-03
status: complete
---

# Phase 217 Plan 03: Purchase Decision Summary

Typed preflight provisions only authenticated first-purchase accounts, blocks exact live cross-rail equivalence, and persists/reconciles Stripe continuation operations without cross-rail lifecycle authority.

## Completed Tasks

1. Added `PurchaseDecision` with closed `eligible|block|warn` outcomes, qualified-plan-only equivalence negatives, first-purchase authorization/provision/fetch, revision-bound override audit, and recursive privacy-negative evidence across start/stop/exception telemetry.
2. Added the durable account-scoped Stripe operation record, Fake provider idempotency/reconciliation, and a recheck-before-dispatch continuation path. A concurrent Apple completion records bounded diagnostic evidence only; Apple continuation cannot dispatch a lifecycle action.

## Verification

`cd accrue && mix test test/accrue/entitlements test/accrue/billing/subscription_actions_test.exs test/property/entitlement_projection_property_test.exs`

Result: repeated twice — 4 properties, 197 tests, 0 failures each run. Focused purchase suite: 20 tests, 0 failures.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 2 - Missing critical functionality] Added bounded `logical_plan` provenance to every snapshot source summary.
- **Found during:** Task 1 final review.
- **Issue:** rail/environment source summaries could not prove that the exact live grant mapped to the target logical plan; a rail-wide catalog scan would over-block a different plan on the same rail.
- **Fix:** include deterministic `logical_plan` provenance in snapshot sources and authorization signatures; compare the target only to exact different-rail source plans.
- **Files modified:** `accrue/lib/accrue/entitlements/snapshot.ex`, `accrue/lib/accrue/entitlements/purchase_decision.ex`, focused snapshot/purchase tests.
- **Commit:** ed4c8003

2. [Rule 2 - Missing critical functionality] Added durable ambiguous-operation reconciliation.
- **Found during:** Task 2 completion review.
- **Issue:** a provider success followed by an ambiguous response had no durable retry barrier or completed-result lookup.
- **Fix:** persist account-scoped operation state, reconcile before retry, and make Fake return the completed provider result by idempotency key.
- **Files modified:** `purchase_operation.ex`, migration, `purchase_decision.ex`, `subscription_actions.ex`, `processor/fake.ex`, focused tests.
- **Commits:** 26564f5c, 4c221aad, c71cd2fa

3. [Rule 2 - Missing critical functionality] Recorded concurrent Apple-completion conflicts without granting lifecycle authority.
- **Found during:** Final contract audit.
- **Issue:** a changed preflight blocked safely but failed to retain bounded conflict evidence.
- **Fix:** emit an opt-in bounded diagnostic callback and prove zero cancel/refund/transfer/update provider calls; expanded telemetry, stale-override, unmapped/incidental equivalence tests.
- **Files modified:** `purchase_decision.ex`, `purchase_decision_test.exs`.
- **Commit:** 867ca2ac

## Self-Check: PASSED

- Required source and focused test files exist.
- Commits `7033458a`, `ed4c8003`, `cbe12a45`, `26564f5c`, `4c221aad`, `480cb435`, `36e9dffb`, `c71cd2fa`, and `867ca2ac` exist.
