---
phase: 220-first-adopter-proof-and-release-gates
plan: 05
subsystem: entitlements
tags: [documentation, exdoc, release-contract, runbooks, offline, apple]
requires:
  - phase: 220-03
    provides: Bounded host-authorized repair actions and stable outcomes
  - phase: 220-04
    provides: Generated capability/limits matrix and deterministic contract gate
provides:
  - Compact first-adopter route from reference host to deterministic check, generated matrix, and runbook ID
  - Hand-authored App Review, privacy, threat, release, and scenario-linked incident procedures
  - Dated v1.59 watchlist ownership for Phase 220 release and operational triggers
affects: [220-06, release-contracts, adoption-proof, entitlements]
tech-stack:
  added: []
  patterns: [generated-facts-with-hand-authored-procedure, bounded-repair-runbooks, evidence-lane-labeling]
key-files:
  created:
    - accrue/guides/multi-rail-offline-release.md
  modified:
    - accrue/guides/entitlements.md
    - examples/accrue_host/docs/adoption-proof-matrix.md
    - examples/crosswake_tracer/README.md
    - accrue/guides/operator-runbooks.md
    - accrue/guides/release-notes.md
    - accrue/mix.exs
    - .planning/research/v1.59-WATCHLIST.md
key-decisions:
  - "The generated capability matrix remains the sole exact-fact authority; public prose links to it rather than copying support cells."
  - "Runbooks name bounded repair actions and explicit stop conditions while forbidding provider, financial, and ownership mutation."
patterns-established:
  - "First-adopter guidance follows recipe → mix verify and reference-scenario check → generated matrix → scenario/runbook ID."
  - "Published runbooks use job, reason, bounded target, authorization, dry-run, safe correlation, and post-convergence language."
requirements-completed: [PROOF-01, PROOF-02, PROOF-03, PROOF-04, PROOF-05]
coverage:
  - id: D1
    description: Compact first-adopter proof path preserves lane labels, generated authority, and blocked Crosswake runtime status.
    requirement: PROOF-01
    verification:
      - kind: integration
        ref: bash scripts/ci/verify_adoption_proof_matrix.sh && bash scripts/ci/verify_reference_scenario_contract.sh
        status: pass
    human_judgment: false
  - id: D2
    description: Published release guide, ExDoc grouping, scenario-linked incident procedures, and watchlist retain the v1.59 authority contract.
    requirement: PROOF-05
    verification:
      - kind: unit
        ref: cd accrue && mix test test/accrue/docs/release_notes_contract_test.exs test/accrue/docs/v159_authority_docs_test.exs
        status: pass
      - kind: integration
        ref: bash scripts/ci/verify_v159_authority.sh
        status: pass
    human_judgment: false
metrics:
  duration: 3min
  completed: 2026-08-04
status: complete
---

# Phase 220 Plan 05: First-adopter proof and release contract Summary

**First-adopter recipe, bounded incident runbooks, and a v1.59 release guide that preserve generated facts and honest Crosswake evidence lanes.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-08-04T16:04:25Z
- **Completed:** 2026-08-04T16:07:02Z
- **Tasks:** 2/2
- **Files modified:** 8

## Accomplishments

- Published one discoverable route from the reference-host recipe through `mix verify`, the deterministic reference-scenario check, the generated matrix, and stable scenario/runbook IDs.
- Preserved evidence-lane truth: semantic conformance is merge-blocking, browser and advisory proof are complementary, and Crosswake stays `feasibility_blocked` without bridge and physical-device evidence.
- Added the ExDoc release guide, App Review/privacy/STRIDE boundary, eight bounded incident procedures, and Phase-220 watchlist ownership with dated reassessment actions.

## Task Commits

1. **Task 1: Publish the compact first-adopter recipe and honest evidence lanes** — `11e6d50b`
2. **Task 2: Author App Review, threat, watchlist, incident, and release procedures** — `aa7f7831`
3. **Documentation-link correction** — `47155add`

## Files Created/Modified

- `accrue/guides/entitlements.md` — public recipe, evidence-lane, compatibility, and privacy handoff.
- `examples/accrue_host/docs/adoption-proof-matrix.md` — compact reference-host path to the generated matrix and runbooks.
- `examples/crosswake_tracer/README.md` — explicit semantic/runtime boundary and first-adopter links.
- `accrue/guides/multi-rail-offline-release.md` — App Review, STRIDE, evidence collection, and release checklist.
- `accrue/guides/operator-runbooks.md` — bounded procedures for all required v1.59 incidents.
- `accrue/guides/release-notes.md` and `accrue/mix.exs` — release contract and ExDoc grouping.
- `.planning/research/v1.59-WATCHLIST.md` — dated Phase-220 trigger ownership and reassessment actions.

## Decisions Made

- Exact capability facts remain generated; hand-authored documents explain procedures and link to the matrix.
- Cross-rail finance, lifecycle, ownership, and automatic reconstruction actions remain forbidden in operational procedures.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Replaced package-relative links to repository-only proof artifacts with public source links.**

- **Found during:** Task 2
- **Issue:** ExDoc reported missing-file warnings for the new links because the reference-host matrix is outside the published package.
- **Fix:** Linked to the repository sources, preserving the same generated-authority handoff without broken HexDocs references.
- **Files modified:** `accrue/guides/entitlements.md`, `accrue/guides/multi-rail-offline-release.md`, `accrue/guides/release-notes.md`
- **Verification:** `cd accrue && mix docs` completed; only pre-existing unrelated guide warnings remain.
- **Committed in:** `47155add`

**Total deviations:** 1 auto-fixed (Rule 1).

## Known Stubs

None.

## Issues Encountered

`mix docs` retains pre-existing warnings for an older repository-relative processor-support link and hidden internal API references. The new v1.59 external proof links introduced no documentation warnings.

## User Setup Required

None — all proof commands and released documents use existing credential-free fixtures and host-owned procedures.

## Next Phase Readiness

Plan 220-06 can consume the public prose, matrix handoff, stable runbook IDs, and watchlist owners as the coordinated release-contract gate input.

## Self-Check: PASSED

Verified all eight declared documentation artifacts exist and commits `11e6d50b`, `aa7f7831`, and `47155add` are present in git history.

*Phase: 220-first-adopter-proof-and-release-gates*
*Completed: 2026-08-04*
