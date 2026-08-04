---
phase: 219-offline-study-contract
plan: "02"
subsystem: entitlements
tags: [offline, proof, continuity, streamdata, security]
requires:
  - phase: "219-01"
    provides: strict verified ES256 proof decisions and normalized claims
provides:
  - exact four-state proof classification at signed freshness and expiry boundaries
  - fail-closed offline action policies and typed learner guidance seeds
  - StreamData-backed boundary/order regression coverage without legacy-gate changes
affects: [219-03, 219-04, 219-05, mobile consumers, offline hosts]
tech-stack:
  added: []
  patterns: [closed proof-state/action separation, signed-claim action authorization, continuity-only stale policy]
key-files:
  created:
    - accrue/test/accrue/entitlements/offline_test.exs
  modified:
    - accrue/lib/accrue/entitlements/offline.ex
    - accrue/lib/accrue/entitlements/offline/proof.ex
key-decisions:
  - "D-01 remains exactly fresh | stale_offline | denied | invalid; reconnect_required is only a next action."
  - "Unknown actions and unsupported fresh actions fail closed with reconnect_required."
  - "Denied and invalid preserve local-progress handling without authorizing entitlement-gated study or value expansion."
patterns-established:
  - "Classify verified proof claims using exclusive freshness equality and explicit signed expiry only."
  - "Expose host UI policy through typed ActionPolicy and Guidance values rather than altering stable server gates."
requirements-completed: [OFF-02, OFF-03, OFF-04]
coverage:
  - id: D1
    description: Exact four-state time, ordering, and empty-authority proof classification.
    requirement: OFF-02
    verification:
      - kind: unit
        ref: accrue/test/accrue/entitlements/offline_test.exs#four-state proof classification
        status: pass
    human_judgment: false
  - id: D2
    description: Continuity-only stale action policy and closed learner guidance seeds.
    requirement: OFF-03
    verification:
      - kind: unit
        ref: accrue/test/accrue/entitlements/offline_test.exs#continuity action policy and guidance
        status: pass
    human_judgment: false
  - id: D3
    description: Existing boolean, list, and scalar entitlement gates retain their independent server contract.
    requirement: OFF-04
    verification:
      - kind: unit
        ref: accrue/test/accrue/entitlements/entitlements_test.exs
        status: pass
    human_judgment: false
metrics:
  duration: 4min
  completed: 2026-08-04
status: complete
---

# Phase 219 Plan 02: Offline Study Contract Summary

**Four-state offline proof classification with signed-boundary enforcement, continuity-only stale access, and typed learner guidance.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-08-04T00:15:00Z
- **Completed:** 2026-08-04T00:18:54Z
- **Tasks:** 2/2
- **Files modified:** 3

## Accomplishments

- Locked D-01 to `fresh | stale_offline | denied | invalid`; exact `fresh_until` equality is stale and only signed `exp` hard-expires a proof.
- Rejected empty allow authority and added deterministic StreamData coverage for signed time boundaries and high-water ordering failures.
- Added closed `ActionPolicy` and `Guidance` typed values that preserve stale continuity while rejecting all value expansion and unknown actions until reconnect.

## Task Commits

1. **Task 1: Lock four-state time, order, and empty-snapshot semantics** — `cd0c3ab5` (RED), `9fc6f323` (GREEN).
2. **Task 2: Enforce continuity-only stale actions and legacy gate compatibility** — `80cca143` (RED), `c51e5422` (GREEN).

## Files Created/Modified

- `accrue/lib/accrue/entitlements/offline/proof.ex` — closed proof states, empty-allow validation, action policy, and guidance structs.
- `accrue/lib/accrue/entitlements/offline.ex` — additive public `action_policy/2` and `guidance/1` delegates.
- `accrue/test/accrue/entitlements/offline_test.exs` — boundary, ordering, property, matrix, guidance, and continuity regressions.

## Decisions Made

- Applied the approved D-01 contract exactly; `reconnect_required` is never classified as a proof state.
- Left legacy entitlement gates untouched; offline policy is a client/host-facing additive seam.
- Defaulted unknown and unproven actions to restrictive reconnect-required policy.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 219 issuance, persistence, fixtures, and reconnect plans can consume the closed state/action/guidance surface without changing server authorization APIs.

## Self-Check: PASSED

- All three plan-owned artifacts exist on disk.
- RED and GREEN commits exist for both TDD tasks.
- Focused formatting and offline, protocol, and legacy-entitlement test suites passed (33 tests, including 1 StreamData property).
