---
phase: 215-research-contracts-and-crosswake-feasibility
plan: 04
subsystem: entitlements
tags: [elixir, entitlement-sources, provider-honesty, conformance, ci]
requires:
  - phase: 215-01
    provides: Phase 215 research contract boundaries
provides:
  - Typed, ordered entitlement-source inspection registry
  - Runtime-aligned source fixture, matrix, HexDocs, and leakage gate
affects: [216-multi-rail-projection, 217-apple-runtime, 219-offline]
tech-stack:
  added: []
  patterns: [closed source vocabulary, processor-free inspection, literal drift gates]
key-files:
  created: [accrue/lib/accrue/entitlements/source.ex, accrue/lib/accrue/entitlements/source/registry.ex, scripts/ci/verify_entitlement_source_matrix.sh]
  modified: [accrue/guides/entitlements.md, .planning/entitlement-source-capability-matrix.md]
key-decisions:
  - "Entitlement source capability is a closed, processor-free inspection boundary."
  - "Apple management returns stable external guidance; unavailable control remains a typed error."
requirements-completed: [RAIL-04]
coverage:
  - id: D1
    description: Typed source registry exposes stable ordered capabilities and actionable Apple outcomes.
    requirement: RAIL-04
    verification:
      - kind: unit
        ref: accrue/test/accrue/entitlements/source_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Runtime source contract mirrors into fixture and host guidance without gateway leakage.
    requirement: RAIL-04
    verification:
      - kind: integration
        ref: bash scripts/ci/verify_entitlement_source_matrix.sh
        status: pass
      - kind: unit
        ref: accrue/test/accrue/entitlements/entitlement_source_matrix_guard_test.exs
        status: pass
    human_judgment: false
metrics:
  duration: 18min
  completed: 2026-08-01
status: complete
---

# Phase 215 Plan 04: Entitlement Source Capability Contract Summary

**Typed, ordered entitlement-source inspection with actionable Apple management guidance and CI-enforced processor separation.**

## Accomplishments

- Added `Accrue.Entitlements.Source` and its deterministic registry, outcomes, and typed capability errors without processor dispatch.
- Published ordered runtime conformance tuples and host-facing source guidance, separate from the processor support matrix.
- Added a literal drift/leakage shell gate plus mutation-sensitive ExUnit coverage for all forbidden Apple gateway paths.

## Task Commits

1. **Task 1: Implement closed source registry and typed outcomes** — `cc9b21c3`, `fb101f83`
2. **Task 2: Mirror runtime source truth into fixture, matrix, and HexDocs** — `d965eec9`, `540de697`
3. **Task 3: Add mutation-sensitive matrix drift and gateway-leakage gates** — `ec7b2fa0`, `e4692b70`, `7784c6e6`

## Verification

- `cd accrue && mix test test/accrue/entitlements/source_test.exs test/accrue/entitlements/entitlement_source_matrix_guard_test.exs` — passed (8 tests).
- `bash scripts/ci/verify_entitlement_source_matrix.sh` — passed.

## Decisions Made

- Source inspection uses explicit ordered lists and typed structs, so equal or adjacent states are never coalesced into booleans.
- Apple control is unavailable and management is externally managed; neither path can dispatch a Stripe mutation.

## Deviations from Plan

### Auto-fixed Issues

1. **[Rule 1 - Bug] Inspection needed to represent unavailable capabilities without failing the whole source view.**
- **Found during:** Task 1
- **Fix:** Kept direct unavailable operations as typed errors while returning a typed `:unavailable` inspection outcome.
- **Verification:** Source contract tests pass.

2. **[Rule 2 - Correctness] The fixture now carries the full closed vocabulary as well as observed tuples.**
- **Found during:** Task 3
- **Fix:** Added ordered capability/state arrays so `:deferred` remains an auditable public state even when no built-in source currently emits it.
- **Verification:** Drift gate passes.

## Known Stubs

None.

## Next Phase Readiness

Phase 216 can consume the registry as the provider-honest inspection contract. Apple runtime behavior remains deliberately deferred to its owning phase.

## Self-Check: PASSED

- Source modules, fixture, matrix, guide, verifier, and both test files exist.
- All seven task commits are present in git history.
