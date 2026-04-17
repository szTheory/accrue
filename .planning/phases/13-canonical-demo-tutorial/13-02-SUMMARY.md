---
phase: 13-canonical-demo-tutorial
plan: 02
subsystem: testing
tags: [elixir, exunit, docs-contract, shell-verifier, tutorial]
requires:
  - phase: 13-canonical-demo-tutorial
    provides: canonical demo command manifest, host verify aliases, repo-root wrapper delegation
provides:
  - manifest-backed docs contracts for the canonical demo tutorial
  - narrow shell verification for package doc labels, links, anchors, and versions
  - temp-tree failure coverage for docs drift in ExUnit
affects: [phase-13-docs-parity, examples/accrue_host, accrue-docs, scripts/ci]
tech-stack:
  added: []
  patterns: [manifest-backed docs parity, temp-tree shell verifier coverage, narrow fixed-invariant release gate]
key-files:
  created:
    - accrue/test/accrue/docs/canonical_demo_contract_test.exs
  modified:
    - accrue/test/accrue/docs/first_hour_guide_test.exs
    - accrue/test/accrue/docs/package_docs_verifier_test.exs
    - scripts/ci/verify_package_docs.sh
    - examples/accrue_host/README.md
    - accrue/guides/first_hour.md
    - accrue/README.md
key-decisions:
  - "The ExUnit layer is the authoritative drift guard for command order, public boundaries, and label parity; the shell script only checks fixed invariants."
  - "The docs contract reads canonical labels from examples/accrue_host/demo/command_manifest.exs instead of duplicating a stale ordered-step list."
  - "Temp-tree failure tests stay in place for both the parity contract and the shell verifier so docs drift reports stay reproducible."
patterns-established:
  - "When tutorial labels are shared across docs and scripts, lock them in a small manifest and assert parity from ExUnit."
  - "Keep shell verification deterministic by checking versions, links, anchors, and command labels rather than prose semantics."
requirements-completed: [DEMO-05, DEMO-06]
duration: 3min
completed: 2026-04-17
---

# Phase 13 Plan 02: Drift Guard Summary

**Manifest-backed tutorial parity tests plus a narrow shell verifier for command labels, links, anchors, and package versions**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-17T01:51:34Z
- **Completed:** 2026-04-17T01:54:13Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- Replaced the hand-maintained first-hour ordered-step contract with manifest-backed label and boundary assertions.
- Added `canonical_demo_contract_test.exs` to lock parity across the host README, package guide, and repo-root wrapper references.
- Narrowed `verify_package_docs.sh` to fixed invariants and proved both green and temp-tree drift paths through ExUnit.

## Task Commits

Each task was committed atomically:

1. **Task 1: Replace hardcoded ordered-step assertions with manifest-backed docs contracts**
   - `74bfee4` (`test`)
   - `dff967a` (`feat`)
2. **Task 2: Extend the shell verifier for fixed invariants only**
   - `e6376e6` (`test`)
   - `d8058fa` (`feat`)

## Files Created/Modified

- `accrue/test/accrue/docs/canonical_demo_contract_test.exs` - Locks demo label parity and temp-tree drift reporting.
- `accrue/test/accrue/docs/first_hour_guide_test.exs` - Reads canonical labels and command modes from the shared manifest.
- `accrue/test/accrue/docs/package_docs_verifier_test.exs` - Proves the shell verifier's green path and a targeted host-README failure mode under `ROOT_DIR`.
- `scripts/ci/verify_package_docs.sh` - Checks versions, links, anchors, and required labels without owning tutorial semantics.
- `examples/accrue_host/README.md` - Aligned with the `First run` / `Seeded history` / verification-mode labels the new contracts expect.
- `accrue/guides/first_hour.md` - Mirrors the canonical labels and verification split for package docs.
- `accrue/README.md` - Stays a compact orientation surface while referencing the focused and full verification commands.

## Decisions Made

- ExUnit owns order and boundary semantics; shell stays narrow.
- Shared tutorial labels come from the command manifest, not duplicated test constants.
- The shell verifier's temp-tree mode must cover the host README as well as package docs so release drift stays reproducible outside the main worktree.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Aligned current docs to the new parity contract**
- **Found during:** Task 1
- **Issue:** The new manifest-backed parity tests could not pass against the still-pre-Phase-13 docs shape because the required labels and verification-mode references were absent.
- **Fix:** Updated `examples/accrue_host/README.md`, `accrue/guides/first_hour.md`, and `accrue/README.md` just enough to match the locked labels and command references the new tests enforce.
- **Files modified:** `examples/accrue_host/README.md`, `accrue/guides/first_hour.md`, `accrue/README.md`
- **Verification:** `cd accrue && mix test test/accrue/docs/first_hour_guide_test.exs test/accrue/docs/canonical_demo_contract_test.exs`
- **Committed in:** `dff967a`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The deviation was required to make the new drift guard truthful against the current docs surfaces. It pulled a small amount of label-alignment work forward without changing the contract itself.

## Issues Encountered

- The first parity-test draft tried to reload the manifest module from a temp tree, which caused module redefinition noise. The failure-path test now uses the repo manifest and mutates only the copied docs.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 13-03 can now refine the tutorial prose on top of enforced labels instead of relying on manual drift checks.
- Future docs work already has temp-tree regression coverage for the narrow shell gate and the manifest-backed ExUnit contract.

## Self-Check: PASSED

- Verified `.planning/phases/13-canonical-demo-tutorial/13-02-SUMMARY.md` exists.
- Verified task commits `74bfee4`, `dff967a`, `e6376e6`, and `d8058fa` exist in git history.
