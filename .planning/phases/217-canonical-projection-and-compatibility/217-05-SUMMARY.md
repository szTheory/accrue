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
  tests: 203
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
- Added a Fake-backed table inventory covering all eleven lifecycle non-bang/bang facade pairs under deliberately divergent global processor configuration.
- Lifecycle and management spans now use the privacy-safe telemetry path: raw `:actor` is excluded and an actor identifier is SHA-256 hashed when present.

## Verification

- `cd accrue && mix test test/accrue/billing/resource_dispatch_test.exs test/accrue/billing/subscription_actions_test.exs test/accrue/entitlements/provider_honesty_test.exs` — 29 tests, 0 failures.
- `cd accrue && mix test test/accrue/entitlements test/accrue/billing/resource_dispatch_test.exs --exclude live_stripe` — repeated twice, 203 tests, 0 failures each run.
- `mix format --check-formatted` passed for all plan-owned files.

## Task Commits

1. Task 1 (TDD RED): `3fe73ebb` — failing persisted-processor resolver contract.
2. Task 1: `4232be0e` — provenance-routed subscription lifecycle actions.
3. Task 2: `d6772b4b` — parent-provenance item routing, Apple management, and spans.
4. Task 2 verification hardening: `c92d5ba3` — item global-dispatch structural guard.
5. Reopened inventory coverage: `5cc4ca3e` — Fake-backed table-driven lifecycle facade and telemetry coverage.
6. Telemetry privacy closure: `f827d718` — raw actor removal and hashed actor IDs for lifecycle/management spans.

## Deviations from Plan

None - implementation followed the requested persisted-provenance and external-management boundaries.

## Issues Encountered

`mix test.all` could not start because the shared checkout has an unrelated unformatted dirty file: `accrue/test/accrue/docs/package_docs_verifier_test.exs`. It was deliberately left untouched per shared-worktree isolation instructions. Focused plan-owned and phase gates passed.

## Self-Check: PASSED

- Required gateway, billing, action, item, and dispatch-test files exist.
- Commits `3fe73ebb`, `4232be0e`, `d6772b4b`, and `c92d5ba3` exist.
