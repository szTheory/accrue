---
phase: 218-apple-observation-and-repair
plan: 08
subsystem: entitlements
tags: [apple, entitlements, telemetry, privacy, stripe-isolation]
requires:
  - phase: 218-06
    provides: bounded Apple lifecycle normalization
  - phase: 218-07
    provides: Apple reconciliation and repair persistence
provides:
  - typed host reconciliation and policy-deferral outcomes
  - exact Apple external-management guidance
  - merge-blocking Apple-to-Stripe isolation coverage
affects: [220-support-tooling, apple-host-integrations]
tech-stack:
  added: []
  patterns: [bounded Apple context outcomes, hashed Apple telemetry correlation]
key-files:
  created: [accrue/test/accrue/entitlements/apple_source_isolation_test.exs]
  modified:
    - accrue/lib/accrue/entitlements.ex
    - accrue/lib/accrue/entitlements/decision_cases.ex
    - accrue/test/support/entitlements/fixtures.ex
key-decisions:
  - "Apple management delegates to the Registry's exact externally-managed outcome."
  - "Family Sharing and offer authoring return explicit policy deferrals rather than implementation claims."
requirements-completed: [AAPL-05]
coverage:
  - id: D1
    description: Typed Apple management, deferred-policy, observation, and reconciliation host outcomes.
    requirement: AAPL-05
    verification:
      - kind: integration
        ref: "mix test test/accrue/entitlements/apple_source_isolation_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: Apple paths remain isolated from Stripe lifecycle callbacks.
    requirement: AAPL-05
    verification:
      - kind: integration
        ref: "mix test test/accrue/entitlements/apple_source_isolation_test.exs test/accrue/billing/resource_dispatch_test.exs"
        status: pass
    human_judgment: false
duration: 6m
completed: 2026-08-03
status: complete
---

# Phase 218 Plan 08: Apple Host Outcomes and Isolation Summary

**Bounded Apple host reconciliation, explicit policy deferrals, exact management guidance, and Stripe-lifecycle isolation proof.**

## Accomplishments

- Added a typed, authorization-bound reconciliation facade that queues local repair work without exposing Apple history state.
- Reused the Registry's exact externally-managed Apple guidance and made Family Sharing and offer authoring explicit policy deferrals.
- Added deterministic coverage for public result privacy and zero reachability to Stripe mutation callbacks.

## Verification

- `cd accrue && mix test test/accrue/entitlements/apple_source_isolation_test.exs test/accrue/billing/resource_dispatch_test.exs` — passed (22 tests).
- `cd accrue && mix test test/accrue/entitlements/apple_lineage_test.exs test/accrue/entitlements/apple_observation_tracer_test.exs test/accrue/entitlements/apple_source_isolation_test.exs` — passed (10 tests).

## Decisions Made

- Apple telemetry uses a hashed account correlation instead of a raw account identifier.
- Family Sharing and offer authoring remain visible, typed deferrals; no ownership or offer policy was implemented.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

- Required context and isolation test files exist.
- Targeted Apple and resource-dispatch suites passed.
