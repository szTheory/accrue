---
phase: 229-repository-truth-recovery-safety
plan: 15
subsystem: repository-safety
tags: [inventory-schema, github-provenance, deterministic-rendering, git-capture, tdd]
requires:
  - phase: 229-11
    provides: "Bounded terminal-page GitHub facts with ordered producing-request sequences"
  - phase: 229-14
    provides: "Canonical repository inventory and strict verification harness"
provides:
  - "Exact non-coercive singleton and plural remote-fact schemas"
  - "Deterministic complete plural request provenance in Markdown"
  - "Sanitized point-in-time active-ref and primary-worktree capture authority"
affects: [229-17, 229-19, 229-20, repository-inventory-verification]
actuals:
  tokens: 9264
  tasks: 2
  commits: 4
plan_head_before: ed6286a0f60b9665a2f5fc0eb0bd201b3a08fced
commits: 4
tech-stack:
  added: []
  patterns: [exact discriminated evidence rows, detached normalization, ordered provenance projection, captured-at authority]
key-files:
  created: []
  modified:
    - scripts/ci/collect_repository_inventory.mjs
    - scripts/ci/render_repository_inventory.mjs
    - scripts/ci/verify_repository_inventory.mjs
key-decisions:
  - "Remote availability is a literal boolean discriminator: observed rows carry only their exact SHA shape, while unavailable rows carry only one allowlisted reason."
  - "Plural provenance renders every producing request in collection order separated by a stable ` ; ` delimiter; only remote_main uses a singleton request."
  - "Capture authority records one active full symbolic ref and commit duplicated as the sanitized primary-worktree identity, with internal equality to the captured active row."
patterns-established:
  - "Canonical validation returns newly normalized remote rows so caller aliases and coercive defaults cannot survive validation."
  - "Captured-at authority contains only timestamp, symbolic ref, and full object IDs; later-live ancestry is intentionally delegated to independent strict verification."
requirements-completed: [REPO-01]
coverage:
  - id: D1
    description: "Singleton and plural remote facts reject omitted/non-boolean availability, fabricated state, and mixed observed/unavailable value fields."
    requirement: REPO-01
    verification:
      - kind: unit
        ref: "scripts/ci/collect_repository_inventory.mjs#CR-09 remote facts require exact non-coercive availability and state"
        status: pass
    human_judgment: false
  - id: D2
    description: "Plural zero, one, many, unavailable, and multi-page facts preserve every ordered request in deterministic Markdown bytes."
    requirement: REPO-01
    verification:
      - kind: unit
        ref: "scripts/ci/render_repository_inventory.mjs#CR-04 plural remote rows retain every ordered producing request"
        status: pass
    human_judgment: false
  - id: D3
    description: "Inventory capture binds the active symbolic ref and full commit to a sanitized primary-worktree identity and captured active row."
    requirement: REPO-01
    verification:
      - kind: integration
        ref: "scripts/ci/collect_repository_inventory.mjs#captured-at anchor binds the active ref and primary worktree without paths"
        status: pass
      - kind: integration
        ref: "node --test scripts/ci/verify_repository_inventory.mjs"
        status: pass
    human_judgment: false
duration: 11min
completed: 2026-09-13
status: complete
---

# Phase 229 Plan 15: Exact Remote Truth and Capture Authority Summary

**Remote evidence now uses an exact non-coercive schema, preserves complete ordered request provenance in Markdown, and carries a sanitized point-in-time active-ref/worktree anchor.**

## Performance

- **Duration:** 11 min
- **Started:** 2026-09-13T20:54:53Z
- **Completed:** 2026-09-13T21:05:30Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Replaced availability/state defaults with an exact boolean discriminator and mutually exclusive observed/unavailable field sets.
- Made `validateInventory` retain detached canonical remote rows rather than the caller's original mutable objects.
- Rendered all ordered plural producing requests for empty, one-result, many-result, unavailable, and multi-page evidence without absent-field serialization.
- Added an internally consistent capture object binding the active full symbolic ref, captured commit, primary-worktree identity, milestone role, active ref row, and sanitized worktree row.

## Task Commits

Each task followed an intentional RED then GREEN TDD cycle:

1. **Task 1 RED: Reject malformed remote facts through public validation/rendering** - `7711dbe0`
2. **Task 1 GREEN: Enforce exact remote fact states and normalized return rows** - `bd7e3170`
3. **Task 2 RED: Expose discarded plural provenance and missing capture authority** - `827a6c72`
4. **Task 2 GREEN: Preserve plural request bytes and captured-at authority** - `9ce20002`

## Files Created/Modified

- `scripts/ci/collect_repository_inventory.mjs` - Exact remote normalization, canonical validated rows, capture schema/collection, and adversarial fixtures.
- `scripts/ci/render_repository_inventory.mjs` - Category-aware singleton/plural request projection and captured-at authority section.
- `scripts/ci/verify_repository_inventory.mjs` - Synthetic strict-inventory fixture aligned with the required capture schema.

## Decisions Made

- Used property-presence checks in addition to type checks so an explicitly present `undefined` field cannot masquerade as field absence in programmatic callers.
- Kept plural request order exactly as collected and used one category-independent ` ; ` separator; object-result ordering remains independently deterministic.
- Represented primary-worktree branch identity as the full symbolic ref so the capture's branch and active-ref identity compare directly without persisting a filesystem path.

## TDD Gate Compliance

- RED `7711dbe0` failed only the named CR-09 assertion because `validateInventory` returned the original remote row; `check tdd-red-evidence` returned `RED_EVIDENCE_OK` with `target_test_failed`.
- GREEN `bd7e3170` passed the CR-09 target plus all seven then-current collector tests.
- RED `827a6c72` failed only the named CR-04 assertion because plural rows rendered literal `undefined`; `check tdd-red-evidence` returned `RED_EVIDENCE_OK` with `target_test_failed`.
- GREEN `9ce20002` passed 8/8 collector tests, 1/1 renderer test, and 2/2 strict verifier tests.

## Verification

- `node --check scripts/ci/collect_repository_inventory.mjs` - PASS.
- `node --test scripts/ci/collect_repository_inventory.mjs` - PASS, 8/8 tests.
- `node --check scripts/ci/render_repository_inventory.mjs` - PASS.
- `node --test scripts/ci/render_repository_inventory.mjs` - PASS, 1/1 test.
- `node --test scripts/ci/verify_repository_inventory.mjs` - PASS, 2/2 tests.
- `git diff --check` - PASS.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Aligned the strict verifier's synthetic inventory fixture with the new required capture schema**

- **Found during:** Task 2 required verification
- **Issue:** The verifier fixture predated the new exact top-level `capture` field, so both required verifier tests stopped at schema validation.
- **Fix:** Added the internally consistent capture row to the fixture and kept its existing synthetic active-advance case internally consistent. Plan 229-17 retains ownership of later-live ancestry semantics.
- **Files modified:** `scripts/ci/verify_repository_inventory.mjs`
- **Verification:** `node --test scripts/ci/verify_repository_inventory.mjs` passes 2/2.
- **Committed in:** `9ce20002`

**2. [Rule 3 - Blocking] Prevented imported modules from auto-registering unrelated embedded tests**

- **Found during:** Task 2 focused RED/GREEN execution
- **Issue:** Running the renderer as a Node test imported the collector and registered its complete embedded suite, while dynamic renderer imports nested its test inside collector tests.
- **Fix:** Register each embedded suite only when that source file is the direct Node test entry point.
- **Files modified:** `scripts/ci/collect_repository_inventory.mjs`, `scripts/ci/render_repository_inventory.mjs`
- **Verification:** Direct collector and renderer test commands report their own stable 8-test and 1-test suites.
- **Committed in:** `9ce20002`

---

**Total deviations:** 2 auto-fixed blocking issues.
**Impact on plan:** Both changes were required to exercise the exact new schema reliably; no production capability or remote authority was widened.

## Issues Encountered

- The broader `phase229_gap_closure.test.mjs` still contains a pre-capture synthetic inventory and therefore cannot consume the new exact schema yet. That file is explicitly owned by dependent Plan 229-19; it was left untouched here to avoid crossing the dependency boundary.

## Authentication Gates

None.

## Known Stubs

None. Empty plural SHA arrays and empty planning/window collections are explicit validated evidence states, not placeholders.

## User Setup Required

None.

## Next Phase Readiness

- Plan 229-17 can now replace live-equality checks with same-ref ancestor proof against the explicit capture anchor.
- Plan 229-19 can update real-chain fixtures and final attestation binding around the stable capture and plural provenance schemas.
- The original private recovery capsule and all unrelated/untracked user files remained untouched.

## Self-Check: PASSED

- All three modified source/test files and this summary exist.
- Task commits `7711dbe0`, `bd7e3170`, `827a6c72`, and `9ce20002` are present in git history.
- Focused CR-09, capture-anchor, and CR-04 rendering tests pass after the final implementation.
- The plan ledger measures four task commits from base `ed6286a0f60b9665a2f5fc0eb0bd201b3a08fced`.

---
*Phase: 229-repository-truth-recovery-safety*
*Completed: 2026-09-13*
