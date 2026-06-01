---
phase: 159-linked-release-readiness-publish-proof
plan: "02"
subsystem: release
tags: [release-please, hex, github-actions, linked-release-proof]
requires:
  - phase: 159-01
    provides: deterministic release readiness scaffolding and the preserved blocker ledger
provides:
  - Release Please linked-release-proof job after ordered package publishes
  - auto-derived PR/version/run identifiers for linked proof capture
  - host Hex smoke wait loop covering accrue, accrue_admin, and accrue_portal
  - append-only ledger handoff to the future CI proof artifact
affects: [release-process, ci-gates, linked-publish-proof]
tech-stack:
  added: []
  patterns: [CI-owned publish proof, append-only release ledger, lockstep three-package Hex smoke]
key-files:
  created:
    - .planning/phases/159-linked-release-readiness-publish-proof/159-02-SUMMARY.md
  modified:
    - .github/workflows/release-please.yml
    - scripts/ci/capture_linked_release_proof.sh
    - scripts/ci/accrue_host_hex_smoke.sh
    - .planning/phases/159-linked-release-readiness-publish-proof/159-VERIFICATION.md
key-decisions:
  - "Do not mark REL-01 or REL-03 complete from automation wiring alone; require a real post-1.3.0 linked-release-proof artifact."
  - "Let the primary Release Please workflow fail on proof disagreement instead of routing post-publish proof to manual UAT."
patterns-established:
  - "Release proof identifiers can be derived in GitHub Actions from GITHUB_RUN_ID, GITHUB_SHA, and the lockstep release manifest."
  - "The linked proof job is gated on all three ordered publish jobs succeeding before public-surface reconciliation runs."
requirements-completed: []
duration: 22m
completed: 2026-05-31
---

# Phase 159 Plan 02: Linked Release Proof Automation Summary

**Release Please now owns the future linked-release proof gate, deriving identifiers in CI and failing the run if GitHub, Hex, HexDocs, release notes, or host smoke disagree.**

## Performance

- **Duration:** 22m
- **Started:** 2026-05-31T20:15:12Z
- **Completed:** 2026-05-31T20:37:37Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Added `--auto` mode to `capture_linked_release_proof.sh`, deriving `RUN_ID` from `GITHUB_RUN_ID`, `PR_NUMBER` from the merged Release Please PR associated with `GITHUB_SHA`, and `TARGET_VERSION` from the lockstep manifest.
- Added a `linked-release-proof` job after `release`, `publish-accrue`, `publish-accrue-admin`, and `publish-accrue-portal`, with proof capture, host Hex smoke, release-notes verification, step summary, and artifact upload.
- Extended host Hex smoke so GitHub Actions waits for `accrue`, `accrue_admin`, and `accrue_portal` Hex releases before running the host smoke.
- Appended a Plan 02 handoff block to the Phase 159 ledger preserving the current blocker state until a real post-`1.3.0` proof artifact exists.

## Task Commits

1. **Task 1: Derive live release identifiers in CI** - `67a3f933` (feat)
2. **Task 2: Run linked proof automatically after ordered publish** - `67a3f933` (feat)
3. **Task 3: Shift Host Hex smoke to all three linked packages** - `67a3f933` (feat)

## Files Created/Modified

- `.github/workflows/release-please.yml` - Adds the gated `linked-release-proof` job and `actions: read` permission for run inspection.
- `scripts/ci/capture_linked_release_proof.sh` - Adds `--auto`, manifest lockstep derivation, PR lookup from commit, pending-current-run allowance, and default proof artifact output.
- `scripts/ci/accrue_host_hex_smoke.sh` - Waits for all three linked package releases on Hex in GitHub Actions.
- `.planning/phases/159-linked-release-readiness-publish-proof/159-VERIFICATION.md` - Records the CI proof handoff without changing prior blocker rows into success claims.
- `.planning/phases/159-linked-release-readiness-publish-proof/159-02-SUMMARY.md` - Captures Plan 02 outcome and verification evidence.

## Verification

- `bash scripts/ci/capture_linked_release_proof.sh --help` - PASS
- `bash -n scripts/ci/capture_linked_release_proof.sh` - PASS
- `bash -n scripts/ci/accrue_host_hex_smoke.sh` - PASS
- `actionlint .github/workflows/release-please.yml` - PASS
- `yq eval '.jobs."linked-release-proof".name' .github/workflows/release-please.yml` - PASS (`Linked release proof`)
- `bash scripts/ci/verify_release_notes_contract.sh` - PASS (`verify_release_notes_contract: OK (1.3.0)`)
- `GITHUB_ACTIONS=true GITHUB_RUN_ID=1 GITHUB_SHA=$(git rev-parse HEAD) bash scripts/ci/capture_linked_release_proof.sh --auto --output /tmp/linked-release-proof.md` - EXPECTED FAIL on current manifest: target version must be greater than `1.3.0`.

## Decisions Made

- The plan is complete as automation wiring, not as public release proof. REL-01 and REL-03 still require one real post-`1.3.0` linked release artifact.
- The proof job uses CI failure as the escalation mechanism when identifiers or public surfaces disagree.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Full `bash scripts/ci/accrue_host_hex_smoke.sh` was not run locally during close-out because it performs the example-host install/test flow and prior Phase 159 evidence already recorded local host workspace drift. The CI proof job runs it in a clean GitHub Actions context after publish.
- The `--auto` path cannot complete locally while `.release-please-manifest.json` remains at the already-published `1.3.0` line. This was verified as the intended guard against stale proof.

## User Setup Required

None - no external service configuration required beyond the existing release workflow secrets.

## Next Phase Readiness

- Future Release Please publish runs now produce a `linked-release-proof` artifact when all three package publishes succeed.
- REL-01 and REL-03 remain incomplete until that artifact exists for a real post-`1.3.0` linked release and verification confirms the public surfaces agree.

## Self-Check: PASSED

---
*Phase: 159-linked-release-readiness-publish-proof*
*Completed: 2026-05-31*
