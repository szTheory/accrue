---
phase: 217-canonical-projection-and-compatibility
plan: 05
subsystem: billing
tags: [elixir, billing, gateway-provenance, telemetry, apple]
requires:
  - phase: 217-03
    provides: typed entitlement source outcomes
provides:
  - persisted processor gateway resolution for subscription lifecycle mutations
  - parent-subscription provenance routing for item mutations
  - Apple externally-managed billing guidance
affects: [billing, entitlements, subscription-lifecycle]
tech-stack:
  added: []
  patterns: [closed-gateway-registry, persisted-resource-dispatch, bounded-lifecycle-telemetry]
key-files:
  created: [accrue/lib/accrue/rails/gateway_registry.ex, accrue/test/accrue/billing/resource_dispatch_test.exs]
  modified: [accrue/lib/accrue/billing.ex, accrue/lib/accrue/billing/subscription_actions.ex, accrue/lib/accrue/billing/subscription_items.ex]
decisions:
  - Existing subscriptions and their items resolve adapters from stored processor provenance; configured processor remains for creation.
  - Apple management is a successful externally-managed source outcome, never a billing mutation.
metrics:
  tasks_completed: 2
  tests: 210
  completed: 2026-08-03
status: complete
requirements-completed: [ACCT-03]
coverage:
  - id: D1
    description: Persisted subscription processor provenance selects lifecycle adapters independently of current configuration.
    requirement: ACCT-03
    verification:
      - kind: integration
        ref: accrue/test/accrue/billing/resource_dispatch_test.exs
        status: pass
      - kind: integration
        ref: cd accrue && mix test test/accrue/entitlements test/accrue/billing/resource_dispatch_test.exs --exclude live_stripe
        status: pass
    human_judgment: false
  - id: D2
    description: Apple management returns the exact externally-managed guidance without a destructive adapter path.
    requirement: ACCT-03
    verification:
      - kind: unit
        ref: accrue/test/accrue/billing/resource_dispatch_test.exs#external management
        status: pass
    human_judgment: false
---

# Phase 217 Plan 05: Persisted Resource Dispatch Summary

Persisted subscription and item provenance now controls lifecycle dispatch, while Apple returns exact rail-owned management guidance rather than a billing mutation.

## Accomplishments

- Added a closed `GatewayRegistry.resolve/1` boundary with stable missing/unknown processor errors.
- Routed subscription lifecycle operations and item mutations through persisted parent provenance, preserving configured dispatch only for creation paths.
- Added Apple `Billing.management/2` guidance and bounded lifecycle/management spans; bang facades reuse their instrumented non-bang operations.
- Added deterministic Fake call capture plus an adapter/management injection seam, making all negative dispatch proof executable without external services.
- The eleven-action inventory now captures success, typed failure, and forced adapter exceptions, and verifies exactly one lifecycle span pair for both bang and non-bang paths.
- Lifecycle and management spans use the privacy-safe telemetry path: raw `:actor` is excluded and an actor identifier is SHA-256 hashed when present; recursively bounded telemetry metadata and lifecycle audit data reject seeded identity, receipt/JWS, token, and provider-payload evidence.
- Added zero-call provenance gates for missing, unknown, wrong, and unscoped resources; repeated operation IDs retain their Fake adapter/idempotency identity while global configuration flips.
- Added Apple zero-call coverage across success, typed error, repeat, and concurrent management calls for cancellation, retry/swap/proration, refund, invoice, payment-method, item, and dunning callback families.

## Verification

- `cd accrue && mix test test/accrue/billing/resource_dispatch_test.exs test/accrue/billing/subscription_actions_test.exs test/accrue/entitlements/provider_honesty_test.exs` — 36 tests, 0 failures.
- `cd accrue && mix test test/accrue/entitlements test/accrue/billing/resource_dispatch_test.exs --exclude live_stripe` — repeated twice, 210 tests, 0 failures each run.
- `mix compile --warnings-as-errors` and `mix format --check-formatted` passed for all plan-owned files.

## Task Commits

1. Task 1 (TDD RED): `3fe73ebb` — failing persisted-processor resolver contract.
2. Task 1: `4232be0e` — provenance-routed subscription lifecycle actions.
3. Task 2: `d6772b4b` — parent-provenance item routing, Apple management, and spans.
4. Task 2 verification hardening: `c92d5ba3` — item global-dispatch structural guard.
5. Reopened inventory coverage: `5cc4ca3e` — Fake-backed table-driven lifecycle facade and telemetry coverage.
6. Telemetry privacy closure: `f827d718` — raw actor removal and hashed actor IDs for lifecycle/management spans.
7. Contract completion hardening: `91412591` — deterministic Fake call capture, injected exception seams, all-action failure matrices, and zero-call isolation proof.
8. Recursive privacy closure: `81b236cd` — recursively reject forbidden telemetry keys and seeded values in every captured span phase.
9. Audit privacy closure: `357bff2a` — recursively reject forbidden values in lifecycle audit evidence.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Resume and unpause dropped an explicit operation ID
- **Found during:** rejected-plan contract completion
- **Fix:** forwarded `opts[:operation_id]` into their existing idempotency identity.
- **Files modified:** `accrue/lib/accrue/billing/subscription_actions.ex`
- **Commit:** `91412591`, `81b236cd`, `357bff2a`

2. [Rule 2 - Critical verification] Fake could count calls but could not prove a callback family was untouched
- **Found during:** Apple and scoping isolation matrix implementation
- **Fix:** added deterministic Fake call capture and test-only configuration seams that permit a direct adapter/management exception without network access.
- **Files modified:** `accrue/lib/accrue/processor/fake.ex`, `accrue/lib/accrue/processor/fake/state.ex`, `accrue/lib/accrue/rails/gateway_registry.ex`, `accrue/lib/accrue/billing.ex`
- **Commit:** `91412591`, `81b236cd`

## Issues Encountered

The full `mix test.all` command remains outside this plan's focused gate and would consume unrelated dirty documentation/property work in the shared checkout. The focused direct suite and the complete phase gate both pass without touching those files.

## Self-Check: PASSED

- Required gateway, billing, action, item, and dispatch-test files exist.
- Prior task commits plus `91412591`, `81b236cd`, and `357bff2a` exist.
