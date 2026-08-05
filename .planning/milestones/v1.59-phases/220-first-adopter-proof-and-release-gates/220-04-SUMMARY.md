---
phase: 220-first-adopter-proof-and-release-gates
plan: 04
subsystem: entitlements
tags: [elixir, mix, jq, ci, markdown, conformance]
requires:
  - phase: 220-01
    provides: Versioned reference scenario corpus with closed evidence lanes
provides:
  - Versioned public-contract fixture and deterministic capability/limits matrix
  - Mix write/check task that rejects public-contract and generated-output drift
  - Pull-request CI gate for scenario, evidence-lane, privacy, and claim-boundary drift
affects: [220-05, 220-06, release-contracts, adoption-proof]
tech-stack:
  added: []
  patterns: [closed JSON public contract, fixture-derived Markdown, non-vacuous isolated CI mutation tests]
key-files:
  created:
    - accrue/priv/entitlements/v1.59-public-contract.json
    - accrue/lib/accrue/entitlements/reference_scenarios/markdown.ex
    - accrue/lib/mix/tasks/accrue.entitlements.reference_scenarios.ex
    - examples/accrue_host/docs/capability-limits-matrix.md
    - scripts/ci/verify_reference_scenario_contract.sh
  modified:
    - .github/workflows/ci.yml
    - accrue/test/accrue/entitlements/reference_scenarios_test.exs
key-decisions:
  - "Public support and limit cells are fixture-derived; procedural prose remains outside the generated matrix."
  - "Only deterministic_conformance has merge authority; Crosswake runtime capability remains feasibility_blocked."
patterns-established:
  - "Public-contract fixtures must exactly enumerate scenario IDs and closed evidence-lane/support/privacy values."
  - "CI claim-boundary gates run known-bad temporary copies before the byte-determinism check."
requirements-completed: [PROOF-05]
coverage:
  - id: D1
    description: Deterministic v1.59 capability/limits matrix generated from closed public facts and current scenario/report inputs.
    requirement: PROOF-05
    verification:
      - kind: unit
        ref: accrue/test/accrue/entitlements/reference_scenarios_test.exs#public contract renders a deterministic, evidence-lane-aware matrix
        status: pass
      - kind: integration
        ref: cd accrue && mix accrue.entitlements.reference_scenarios --check
        status: pass
    human_judgment: false
  - id: D2
    description: Pull-request gate rejects malformed inputs, stale output, evidence-lane inflation, prohibited public claims, and a removed CI invocation.
    requirement: PROOF-05
    verification:
      - kind: integration
        ref: bash scripts/ci/verify_reference_scenario_contract.sh
        status: pass
      - kind: unit
        ref: accrue/test/accrue/entitlements/reference_scenarios_test.exs#release gate fails closed on every prohibited public claim family
        status: pass
    human_judgment: false
metrics:
  duration: 6min
  completed: 2026-08-04
status: complete
---

# Phase 220 Plan 04: Public Contract and CI Gate Summary

**Fixture-derived v1.59 capability limits matrix with deterministic Mix checks and a merge-blocking public-contract drift gate.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-08-04T15:44:00Z
- **Completed:** 2026-08-04T15:50:31Z
- **Tasks:** 2/2
- **Files modified:** 7

## Accomplishments

- Added a closed versioned public-contract fixture and deterministic generated matrix that preserves legacy compatibility, Apple external management, no cross-rail lifecycle mutation, stale-study-only continuity, privacy exclusions, scenario IDs, and visible proof lanes.
- Added `mix accrue.entitlements.reference_scenarios --write|--check`, including strict schema, duplicate-key, scenario cross-reference, tracer evidence-inventory, and generated-byte checks.
- Added a `docs-contracts-shift-left` merge gate with isolated known-bad mutation coverage for unsupported runtime, lifecycle, cross-rail, stale-expansion, privacy, stale-output, and CI-wiring claims.

## Task Commits

1. **Task 1: Generate the exact capability and limits matrix from versioned facts** — `30d31c67` (RED test), `8f189fc2` (implementation)
2. **Task 2: Block release-contract drift and evidence-lane inflation in CI** — `765807cc` (RED test), `f1cb9296` (implementation)

## Files Created/Modified

- `accrue/priv/entitlements/v1.59-public-contract.json` — exact public v1.59 facts and required references.
- `accrue/lib/accrue/entitlements/reference_scenarios/markdown.ex` — strict fixture reader, validator, renderer, writer, and check mode.
- `accrue/lib/mix/tasks/accrue.entitlements.reference_scenarios.ex` — deterministic write/check command.
- `examples/accrue_host/docs/capability-limits-matrix.md` — generated compatibility and limits reference.
- `scripts/ci/verify_reference_scenario_contract.sh` — fail-closed public-contract and workflow gate.
- `.github/workflows/ci.yml` — merge-blocking `docs-contracts-shift-left` invocation.
- `accrue/test/accrue/entitlements/reference_scenarios_test.exs` — generator and non-vacuous gate mutation coverage.

## Decisions Made

- Generated material owns exact facts only; walkthroughs, App Review guidance, security explanation, runbooks, watchlists, and release narratives remain hand-authored.
- The fixture permits only `deterministic_conformance` as `merge_blocking`; the report-derived runtime capability is pinned to `feasibility_blocked` pending bridge and physical-device evidence.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected the new Mix task option dispatch.**
- **Found during:** Task 1
- **Issue:** `OptionParser` returns a keyword list, so an initial map-pattern dispatch rejected valid `--write` input.
- **Fix:** Used keyword-list option access in the task dispatch.
- **Files modified:** `accrue/lib/mix/tasks/accrue.entitlements.reference_scenarios.ex`
- **Verification:** write mode, check mode, and focused ExUnit coverage pass.
- **Committed in:** `8f189fc2`

**2. [Rule 1 - Bug] Corrected jq cardinality expressions in the new CI gate.**
- **Found during:** Task 2
- **Issue:** Initial jq expressions applied `length` to boolean results and used invalid array-length syntax.
- **Fix:** Parenthesized uniqueness comparisons and used a valid array pipeline.
- **Files modified:** `scripts/ci/verify_reference_scenario_contract.sh`
- **Verification:** clean gate and all isolated known-bad mutation tests pass.
- **Committed in:** `f1cb9296`

**Total deviations:** 2 auto-fixed (Rule 1).

## Known Stubs

None.

## Issues Encountered

None remaining.

## User Setup Required

None — the gate is credential-free and uses existing Mix and jq tooling only.

## Next Phase Readiness

Plan 05 can link its hand-authored adopter material to the generated matrix without duplicating exact support assertions. Plan 06 can extend the same deterministic gate bundle.

## Self-Check: PASSED

Verified all five declared generated/gate artifacts exist and task commits `30d31c67`, `8f189fc2`, `765807cc`, and `f1cb9296` are present.

*Phase: 220-first-adopter-proof-and-release-gates*
*Completed: 2026-08-04*
