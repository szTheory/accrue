---
phase: 216-additive-rail-and-persistence-foundation
plan: 04
subsystem: testing
tags: [elixir, ecto, entitlements, rails, installer, documentation]
requires:
  - phase: 216-02
    provides: additive rail configuration and qualified catalog validation
  - phase: 216-03
    provides: durable entitlement persistence schemas and migration
provides:
  - deterministic fake-first rail, record, and scenario fixtures
  - opt-in host installer rail/catalog example and migration propagation proof
  - executable Apple observer and persistence-boundary documentation contract
affects: [217-account-projection, apple-observation, offline-entitlements]
tech-stack:
  added: []
  patterns: [deterministic privacy-bounded test fixtures, literal guide authority contracts]
key-files:
  created:
    - accrue/test/support/entitlements/fixtures.ex
    - accrue/test/accrue/entitlements/fake_fixture_test.exs
    - accrue/test/accrue/docs/entitlements_guide_test.exs
  modified:
    - accrue/priv/accrue/templates/install/runtime_config.exs.eex
    - accrue/guides/entitlements.md
    - accrue/test/mix/tasks/accrue_install_test.exs
key-decisions:
  - "Keep generated hosts on the active legacy Stripe processor example; present concurrent Stripe and Apple registration as an explicitly commented opt-in block."
  - "Use fixed normalized IDs, timestamps, digests, and bounded metadata for persistence fixtures rather than provider payloads."
patterns-established:
  - "Multi-rail fixtures expose all supported rail/environment pairs through named deterministic maps."
  - "Guide contracts use literal required and forbidden authority claims to prevent documentation drift."
requirements-completed: [RAIL-01, RAIL-02, RAIL-03]
coverage:
  - id: D1
    description: Deterministic multi-rail config, record, and persistence-history fixtures.
    requirement: RAIL-01
    verification:
      - kind: integration
        ref: test/accrue/entitlements/fake_fixture_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Generated host retains legacy configuration while exposing opt-in rails and persistence migration exactly once.
    requirement: RAIL-02
    verification:
      - kind: integration
        ref: test/mix/tasks/accrue_install_test.exs
        status: pass
      - kind: unit
        ref: test/accrue/config_entitlements_test.exs
        status: pass
    human_judgment: false
  - id: D3
    description: Entitlement guide declares Apple observer boundaries, qualified tuple semantics, privacy limits, and Phase-216 exclusions.
    requirement: RAIL-03
    verification:
      - kind: unit
        ref: test/accrue/docs/entitlements_guide_test.exs
        status: pass
    human_judgment: false
duration: 14min
completed: 2026-08-02
status: complete
---

# Phase 216 Plan 04: Fixture, Installer, and Guide Contract Summary

**Deterministic multi-rail persistence fixtures, opt-in generated host configuration, and executable Apple observer boundaries.**

## Performance

- **Duration:** 14 min
- **Completed:** 2026-08-02
- **Tasks:** 2/2
- **Files modified:** 6

## Accomplishments

- Added stable Stripe/Apple production and sandbox config and record fixtures with real persistence constraint proofs for duplicate observations, grant supersession, and device revocation history.
- Kept the legacy processor configuration active in generated hosts while adding a coherent commented Stripe-plus-Apple rail/catalog example and asserting migration propagation remains repeat-safe.
- Documented qualified tuple matching, four-table privacy boundaries, and explicit Apple observer/non-processor and Phase-216 authority exclusions behind guide contract tests.

## Task Commits

1. **Task 1: Ship deterministic multi-rail record fixtures and scenario proofs** — `492619b3` (RED), `14007a01` (GREEN)
2. **Task 2: Propagate the additive contract through installer and host guidance** — `c08a0929` (RED), `107b3bdc` (GREEN)

## TDD Gate Compliance

Both tasks recorded an intentional failing `test(...)` commit before their matching passing `feat(...)` commit.

## Decisions Made

- Legacy generated hosts remain compatible by keeping the current Stripe processor snippet active; adopters explicitly uncomment the concurrent rail example.
- Fixtures retain only fixed, opaque normalized values and never encode provider evidence or identity payloads.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

- All six plan artifacts exist.
- Task commits `492619b3`, `14007a01`, `c08a0929`, and `107b3bdc` exist.
- The complete plan verification command passed 60 tests.

## Next Phase Readiness

Later projection, Apple observation, and offline work can reuse one deterministic vocabulary and host-facing rail contract without live services.
