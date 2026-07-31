---
phase: 213-stripe-native-advisory-entitlements-sync-observational-only
plan: "05"
subsystem: testing
tags: [elixir, exunit, entitlements, stripe, isolation-guard]
requires:
  - phase: 213-04
    provides: deterministic advisory sync gap closure prerequisites
provides:
  - Guard is included in the static entitlement sync isolation scan inventory
  - Hermetic Guard fixture proves executable advisory references fail the scanner
  - Guard prose allowance proves comments and moduledocs remain accepted
affects: [phase-213, phase-214, entitlement-sync-isolation, guard]
tech-stack:
  added: []
  patterns:
    - ROOT_DIR-backed hermetic shell-script regression fixtures
    - TDD red/green commits for isolation guard coverage
key-files:
  created:
    - .planning/phases/213-stripe-native-advisory-entitlements-sync-observational-only/213-05-SUMMARY.md
  modified:
    - scripts/ci/verify_entitlement_sync_isolation.sh
    - accrue/test/accrue/entitlements/entitlement_sync_isolation_guard_test.exs
key-decisions:
  - "Guard joins the always-on entitlement gate-path scan inventory without changing production Guard runtime behavior."
  - "The existing scanner's comment and triple-quoted doc filtering remains unchanged; coverage is strengthened by hermetic Guard fixtures instead of broadening an allowlist."
patterns-established:
  - "Each forbidden advisory token injected into Guard gets an independent fresh ROOT_DIR fixture and token assertion."
requirements-completed: [SYNC-02, SYNC-03]
coverage:
  - id: D1
    description: "Guard is part of the static isolation boundary for always-on grant decisions."
    requirement: SYNC-02
    verification:
      - kind: integration
        ref: "bash scripts/ci/verify_entitlement_sync_isolation.sh"
        status: pass
      - kind: unit
        ref: "accrue/test/accrue/entitlements/entitlement_sync_isolation_guard_test.exs#executable advisory references from guard fail the isolation guard"
        status: pass
    human_judgment: false
  - id: D2
    description: "Executable Guard references to list_active_entitlements, Reconcile, StripeSync, and EntitlementSummary each fail the isolation gate."
    requirement: SYNC-03
    verification:
      - kind: unit
        ref: "mix test test/accrue/entitlements/entitlement_sync_isolation_guard_test.exs --only guard_surface_red_path --trace"
        status: pass
    human_judgment: false
  - id: D3
    description: "Guard comments and moduledocs may name the forbidden advisory symbols without failing the gate."
    requirement: SYNC-03
    verification:
      - kind: unit
        ref: "mix test test/accrue/entitlements/entitlement_sync_isolation_guard_test.exs"
        status: pass
    human_judgment: false
duration: 8min
completed: 2026-07-31
status: complete
---

# Phase 213 Plan 05: Guard Isolation Coverage Summary

**Guard now participates in the observational-only entitlement sync isolation gate, with hermetic red-path proof for every forbidden advisory symbol.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-07-31T01:48:58Z
- **Completed:** 2026-07-31T01:56:00Z
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments

- Added `accrue/lib/accrue/entitlements/guard.ex` to the shell isolation script's documented always-on gate-path inventory and scan array.
- Extended the hermetic ExUnit fixture inventory with `Accrue.Entitlements.Guard`.
- Added a tagged `:guard_surface_red_path` regression proving executable `list_active_entitlements`, `Reconcile`, `StripeSync`, and `EntitlementSummary` references in Guard each fail with the isolation FAIL marker and the injected token.
- Added Guard-specific prose allowance coverage proving comments and moduledocs can still name all four forbidden symbols.

## Task Commits

Each TDD gate was committed atomically:

1. **RED:** `d33cabba` test(213-05): add failing Guard isolation proof
2. **GREEN:** `85bb9748` feat(213-05): scan Guard in entitlement isolation gate

## Files Created/Modified

- `scripts/ci/verify_entitlement_sync_isolation.sh` - Adds Guard to the documented and executable static scan inventory.
- `accrue/test/accrue/entitlements/entitlement_sync_isolation_guard_test.exs` - Adds Guard fixture setup, red-path coverage for four forbidden executable advisory references, and Guard prose allowance coverage.

## Decisions Made

- Guard production code remains unchanged; this plan strengthens the merge gate around it.
- The scanner's existing executable-source filtering remains the authority; tests prove the intended doc/comment allowance instead of changing the parser.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. The RED run failed for the expected reason: Guard fixture injections returned status 0 before the script inventory included `guard.ex`.

## Verification

- `cd accrue && mix test test/accrue/entitlements/entitlement_sync_isolation_guard_test.exs --only guard_surface_red_path --trace` - passed
- `cd accrue && mix test test/accrue/entitlements/entitlement_sync_isolation_guard_test.exs` - passed
- `bash scripts/ci/verify_entitlement_sync_isolation.sh` - passed with `verify_entitlement_sync_isolation: OK`

## Known Stubs

None.

## Threat Flags

None. This plan changes only a static CI scan inventory and hermetic tests; it introduces no network endpoint, auth path, file access boundary, schema change, or runtime trust-boundary surface.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 213's final Guard isolation gap is closed. Phase 214 can reconcile docs against the completed lattice_stripe 2.x bump and observational advisory sync behavior.

## Self-Check: PASSED

- Found `scripts/ci/verify_entitlement_sync_isolation.sh`
- Found `accrue/test/accrue/entitlements/entitlement_sync_isolation_guard_test.exs`
- Found `.planning/phases/213-stripe-native-advisory-entitlements-sync-observational-only/213-05-SUMMARY.md`
- Found commit `d33cabba`
- Found commit `85bb9748`

---
*Phase: 213-stripe-native-advisory-entitlements-sync-observational-only*
*Completed: 2026-07-31*
