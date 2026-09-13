---
phase: 229-repository-truth-recovery-safety
plan: 09
subsystem: repository-safety
tags: [git-bundle, github-api, deterministic-evidence, recovery, ci-monitor]
requires:
  - phase: 229-07
    provides: Independent all-ref recovery verification and executable deterministic rendering
  - phase: 229-08
    provides: Supported bounded exact-SHA CI watcher and executable documentation contract
provides:
  - Final recovery-backed canonical repository and CI inventory
  - Deterministic privacy-safe Markdown projection with ten current ship windows
  - Complete green preservation, inventory, watcher, and documentation regression handoff
affects: [230-reviewable-history-integration, 231-exact-sha-release-gate-proof]
actuals:
  tokens: 10782
  tasks: 2
  commits: 2
plan_head_before: dbbe2d07152bae7e81c71d39dc8711b5b4885110
commits: 2
tech-stack:
  added: []
  patterns: [additive private attestation, point-in-time repository evidence, active-branch recovery continuity]
key-files:
  created: []
  modified:
    - .planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.json
    - .planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.md
    - scripts/ci/verify_repository_inventory.mjs
key-decisions:
  - "Final capture uses a new additive mode-0600 private attestation while the original manifest, bundle, and prior private records remain immutable."
  - "Strict all-ref verification permits only the checked-out execution branch to advance after its frozen recovery point; every other original ref remains exact."
patterns-established:
  - "Final evidence capture: verify immutable private authorities first, attempt four fixed GitHub GET categories, then atomically publish validated JSON and its deterministic Markdown projection."
  - "Recovery continuity: exact frozen mappings remain proven through bundle heads and encoded refs while ordinary plan commits may advance only the active branch."
requirements-completed: [REPO-01, REPO-02, REPO-03]
coverage:
  - id: D1
    description: "The final canonical pair records all 218 refs, 109 recovery mappings, every worktree, all ten open ship windows, and four bounded remote categories with honest provenance."
    requirement: REPO-01
    verification:
      - kind: integration
        ref: "node scripts/ci/verify_repository_inventory.mjs --records .planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.json --rendered .planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.md --expected-repository szTheory/accrue --require-recovery --require-all-ref-recovery --require-typed-artifacts --require-complete-categories --require-edge-cases --require-command-provenance --require-privacy-controls --require-determinism --require-workflow-metadata-authorization"
        status: pass
    human_judgment: false
  - id: D2
    description: "The original recovery capsule and user-owned artifacts remain unchanged, with one restrictive additive final-capture attestation and exact active-branch continuity rules."
    requirement: REPO-02
    verification:
      - kind: integration
        ref: "bash scripts/ci/preserve_repository_state.sh --self-test && node --test scripts/ci/verify_repository_inventory.mjs"
        status: pass
    human_judgment: false
  - id: D3
    description: "The supported repository-bound CI list, inspect, and bounded watch path passes executable wrapper, failure-exit, and documentation verification."
    requirement: REPO-03
    verification:
      - kind: integration
        ref: "node scripts/ci/ci_monitor.cjs --self-test --verify-wrapper scripts/ci/watch_ci.sh --verify-docs scripts/ci/README.md && node --test scripts/ci/ci_monitor.cjs"
        status: pass
    human_judgment: false
duration: 40min
completed: 2026-09-13
status: complete
---

# Phase 229 Plan 09: Final Recovery-Backed Repository Truth Summary

**A sealed point-in-time inventory now combines exact recovery authority, complete local repository truth, ten ship windows, and bounded live GitHub observations without crossing Phase 229's read-only boundary.**

## Performance

- **Duration:** 40 min
- **Started:** 2026-09-13T15:26:29Z
- **Completed:** 2026-09-13T16:06:06Z
- **Tasks:** 2
- **Files modified:** 3 tracked files plus one additive private mode-0600 attestation

## Accomplishments

- Recaptured the canonical JSON with all 218 current refs, all 109 independently recoverable original mappings, every worktree, and the exact ten open ship windows.
- Attempted each of the four fixed repository-bound GitHub GET categories: remote `main` was observed at `d30fc25dbf6ba551792c66ff451b4b93c0af4bf1`, pull requests and release branches were confirmed empty, and Actions retained an honest `unavailable:network` record.
- Rendered Markdown solely from validated JSON and passed the complete recovery, strict-inventory, wrapper, CI monitor, and documentation regression chain.
- Preserved the immutable v1.61 tag, every non-active ref and worktree identity, all six user-owned artifacts, and every original private capsule byte; the only private addition is the new final-capture attestation.

## Task Commits

Each task was committed atomically:

1. **Task 1: Regenerate the canonical inventory behind the original recovery barrier** — `207c0f2e` (fix)
2. **Task 2: Run the full Phase 229 regression and preservation handoff** — `8a99dc89` (test)

## Files Created/Modified

- `.planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.json` — final schema-v2 repository, recovery, planning, worktree, artifact, and remote authority.
- `.planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.md` — byte-reproducible privacy-safe maintainer projection and executable recovery procedure.
- `scripts/ci/verify_repository_inventory.mjs` — exact frozen recovery proof with a narrowly bounded active execution-branch continuity exception and regression coverage.
- Private additive `phase229-final-capture-attestation-229-09.json` — mode-0600 before/after invariant record; its location and contents remain outside committed evidence.

## Decisions Made

- Kept all original private capsule files byte-identical and created one uniquely named additive attestation rather than replacing the earlier capture record.
- Treated the current execution branch as the only ref allowed to advance after freezing. Its original object remains recoverable through the unchanged bundle and encoded preservation ref, while all other original refs remain exact.
- Retained the actual failed Actions read as typed unavailable evidence instead of substituting cached or local state.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Allowed legitimate active plan-branch advancement in strict recovery verification**

- **Found during:** Task 1 (strict canonical inventory verification)
- **Issue:** `--require-all-ref-recovery` required the live active milestone branch object to equal its pre-phase frozen object, so Phase 229's own commits made final verification impossible even though the frozen object remained exactly recoverable.
- **Fix:** Preserved exact map equality across the private manifest, bundle heads, committed recovery rows, and encoded preservation refs; required exact canonical ref names and objects for every non-active ref; and allowed only the symbolic active branch to match the recorded point-in-time milestone object.
- **Files modified:** `scripts/ci/verify_repository_inventory.mjs`
- **Verification:** Four verifier tests pass, including a positive active-branch advance and a negative non-active branch drift control; the real strict canonical command passes.
- **Committed in:** `207c0f2e`

---

**Total deviations:** 1 auto-fixed (1 Rule 1 bug).
**Impact on plan:** The correction is required for reproducible point-in-time evidence and narrows, rather than weakens, the allowed post-freeze ref change to the executing branch only.

## Issues Encountered

- The bounded GitHub Actions observation attempt was unavailable due to a network-class failure. The canonical record preserves the actual attempted GET, timestamp, repository identity, and typed unavailable reason; no cached substitute or provider-proof claim was introduced.

## Verification

- `bash scripts/ci/preserve_repository_state.sh --self-test` — passed, including collision, physical-path, atomic publication, exact restore, and cleanup controls.
- `node --test scripts/ci/collect_repository_inventory.mjs` — passed (2 tests).
- `node scripts/ci/ci_monitor.cjs --self-test --verify-wrapper scripts/ci/watch_ci.sh --verify-docs scripts/ci/README.md` — passed.
- `node --test scripts/ci/ci_monitor.cjs` — passed (2 tests).
- Full strict fixture command — passed, including one-of-many rejection and exact restore coverage.
- Full strict real canonical JSON/Markdown command with the anchored original manifest and unchanged bundle — passed.
- Before/after preservation comparison — passed for all non-active refs, worktree identities, v1.61 tag, six typed user artifacts, and original capsule digests.
- `COVERAGE.md` — exactly four authorized read capabilities and six reasoned mutation/publication/integration opt-outs.

## Known Stubs

None.

## Authentication Gates

None. GitHub reads were attempted with the available environment; the unavailable Actions category was recorded honestly by the collector.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 230 can consume the committed canonical pair and unchanged recovery capsule as a reviewable point-in-time handoff.
- No integration, cleanup, CI execution/mutation, PR/ref mutation, ship-window resolution, merge, push, or publication occurred in Phase 229.

## Self-Check: PASSED

- All three tracked plan outputs exist and task commits `207c0f2e` and `8a99dc89` are present in Git history.
- Coverage classification reports all three deliverables automatically covered by passing executable evidence.
- The complete real and fixture regression chain passed before summary creation.

---
*Phase: 229-repository-truth-recovery-safety*
*Completed: 2026-09-13*
