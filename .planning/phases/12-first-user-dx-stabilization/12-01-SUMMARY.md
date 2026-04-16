---
phase: 12-first-user-dx-stabilization
plan: 01
subsystem: testing
tags: [docs, exunit, shell, verification, dx]
requires:
  - phase: 10-host-app-dogfood-harness
    provides: host-facing billing, webhook, and admin integration boundaries
  - phase: 11-ci-user-facing-integration-gate
    provides: release-gate verification expectations for docs and package drift
  - phase: 11.1-hermetic-host-flow-proofs
    provides: deterministic host proof commands referenced by later docs contracts
provides:
  - skipped First Hour guide contract with ordered setup markers and public API boundaries
  - skipped troubleshooting guide contract with stable diagnostic codes, anchors, and matrix columns
  - executable package-doc verifier scaffold plus ExUnit wrapper
affects: [phase-12-docs, phase-12-package-metadata, validation]
tech-stack:
  added: [ExUnit doc contracts, bash verifier entrypoint]
  patterns: [skipped guide contracts, shell verifier wrapped by ExUnit]
key-files:
  created:
    - accrue/test/accrue/docs/first_hour_guide_test.exs
    - accrue/test/accrue/docs/troubleshooting_guide_test.exs
    - accrue/test/accrue/docs/package_docs_verifier_test.exs
    - scripts/ci/verify_package_docs.sh
  modified: []
key-decisions:
  - "Keep docs contract tests skipped with literal activation reasons until Phase 12 plans 06 and 07 land the referenced guides and strict checks."
  - "Make the package-doc verifier executable now, but constrain scaffold output to a single activation line so the command shape is stable without claiming real drift enforcement yet."
patterns-established:
  - "Guide contracts read future guide paths directly and reserve exact strings the later docs plans must satisfy."
  - "Repo-level shell verification commands should be callable from package-local ExUnit tests through System.cmd/3."
requirements-completed: [DX-03, DX-04, DX-05, DX-06]
duration: 2m
completed: 2026-04-16
---

# Phase 12 Plan 01: Summary

**Docs-verification scaffolds now lock First Hour ordering, troubleshooting diagnostic names, and the package-doc command surface before the user-facing docs are rewritten.**

## Performance

- **Duration:** 2m
- **Started:** 2026-04-16T21:52:19Z
- **Completed:** 2026-04-16T21:54:12Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments
- Added a skipped First Hour guide contract that reserves the host-first setup sequence and the D-21/D-22 public-vs-private API boundary.
- Added a skipped troubleshooting guide contract that reserves exact DX diagnostic codes, stable anchors, required matrix columns, and verification commands.
- Added an executable `scripts/ci/verify_package_docs.sh` scaffold and an ExUnit wrapper so later metadata hardening can reuse one stable entrypoint.

## Task Commits

1. **Task 1: Add the First Hour guide contract test scaffold** - `7d22247` (`test`)
2. **Task 2: Add the troubleshooting matrix contract test scaffold** - `666804e` (`test`)
3. **Task 3: Create the package-doc verifier command and ExUnit wrapper** - `7f04a59` (`test`)

## Files Created/Modified
- `accrue/test/accrue/docs/first_hour_guide_test.exs` - skipped guide contract for setup order, public surfaces, and forbidden private module mentions.
- `accrue/test/accrue/docs/troubleshooting_guide_test.exs` - skipped guide contract for stable diagnostic-code anchors, matrix headings, and host verification commands.
- `scripts/ci/verify_package_docs.sh` - executable package-doc verifier scaffold with the reserved target file list and future invariant checklist.
- `accrue/test/accrue/docs/package_docs_verifier_test.exs` - ExUnit wrapper that shells into the repo-level verifier and locks the scaffold activation output.

## Decisions Made
- Keep the guide contracts compile-safe and skipped until the actual guide files exist, using the exact activation reasons required by the plan.
- Keep the package-doc verifier fail-open only in scaffold mode, but reserve the final file targets and invariant list inside the script now.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Known Stubs

- `accrue/test/accrue/docs/first_hour_guide_test.exs:32` - intentionally skipped until Phase 12 plan 06 creates `guides/first_hour.md`.
- `accrue/test/accrue/docs/troubleshooting_guide_test.exs:34` - intentionally skipped until Phase 12 plan 06 creates `guides/troubleshooting.md`.
- `scripts/ci/verify_package_docs.sh:5` - intentionally exits 0 after the scaffold activation line until Phase 12 plan 07 activates real drift checks.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Later Phase 12 docs work now has grep-verifiable contracts for the exact setup order, public API boundaries, diagnostic names, and package-doc command it must satisfy.
- No blockers found for plan 12-02 or the later docs/package-metadata plans.

## Self-Check: PASSED

- Found `.planning/phases/12-first-user-dx-stabilization/12-01-SUMMARY.md`
- Found commit `7d22247`
- Found commit `666804e`
- Found commit `7f04a59`

---
*Phase: 12-first-user-dx-stabilization*
*Completed: 2026-04-16*
