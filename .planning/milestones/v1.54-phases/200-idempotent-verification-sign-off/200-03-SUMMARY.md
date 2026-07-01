---
phase: 200-idempotent-verification-sign-off
plan: "03"
subsystem: verification
tags: [scorecard, verifier, union-baseline, phase200, regression-gate]
requires:
  - phase: 200-idempotent-verification-sign-off
    provides: Plan 200-02 rendered Storybook and page-flow browser evidence
  - phase: 187-audit-baseline
    provides: archived component/group scored-cell baseline
  - phase: 193-research-re-baseline-pattern-lock
    provides: archived page-flow baseline cells
provides:
  - Phase 200 union baseline artifact with 30,348 unique cells
  - Fail-closed Phase 200 scorecard generator
  - Strict Phase 200 structured artifact verifier
affects: [phase-200, verification, ci-guardrails, sign-off]
tech-stack:
  added: []
  patterns:
    - TDD self-test CLI gates for generated verification artifacts
    - Phase-local structured JSON/NDJSON artifacts as canonical scorecard data
    - Manifest-bound evidence refs limited to generated repo roots
key-files:
  created:
    - accrue_admin/e2e/phase200-scorecard.mjs
    - scripts/ci/verify_phase200_scorecard.mjs
    - .planning/phases/200-idempotent-verification-sign-off/baseline.union.cells.json
  modified: []
key-decisions:
  - "Phase 200 scorecard outputs are restricted to .planning/phases/200-idempotent-verification-sign-off/ and never to archived Phase 187 or Phase 192 paths."
  - "The verifier rejects any full-mode evidence ref that is absolute, contains .., points outside allowed generated roots, or is absent from artifacts.manifest.json."
  - "p193 page-flow rows remain pending in the union baseline but must close as covered with score >= 2 and evidence refs in final artifacts."
patterns-established:
  - "Use --baseline-only for deterministic union baseline generation and validation before final scorecard artifacts exist."
  - "Use self-tests to prove duplicate IDs, downgrades, missing evidence, stale p193 rows, malformed JSON, and non-empty regressions fail closed."
requirements-completed: [VER-01, VER-02]
duration: 10m 4s
completed: 2026-06-30
status: complete
---

# Phase 200 Plan 03: Union Scorecard Generator and Verifier Summary

**Phase 200 union scorecard machinery with a 30,348-cell baseline, fail-closed generator, and strict manifest-bound verifier**

## Performance

- **Duration:** 10m 4s
- **Started:** 2026-06-30T16:33:15Z
- **Completed:** 2026-06-30T16:43:19Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Created `baseline.union.cells.json` as the immutable derived union of the archived component/group baseline and archived page-flow baseline.
- Added `phase200-scorecard.mjs` with `--self-test`, `--baseline-only`, `--dry-run`, and normal write modes.
- Added `verify_phase200_scorecard.mjs` with `--self-test`, `--baseline-only`, and strict full artifact validation.
- Proved full generator/verifier integration in a temporary Phase 200 artifact subdirectory without persisting final scorecard artifacts reserved for Plan 200-06.

## Task Commits

1. **Task 1 RED: Generator self-tests** - `8899c2ba` (`test`)
2. **Task 1 GREEN: Union scorecard generator** - `8ca7a268` (`feat`)
3. **Task 2 RED: Verifier self-tests** - `20aee7cb` (`test`)
4. **Task 2 GREEN: Strict scorecard verifier** - `ed04f3ac` (`feat`)

## Files Created/Modified

- `accrue_admin/e2e/phase200-scorecard.mjs` - Generates the Phase 200 union baseline and scorecard artifacts, compares final cells against the union baseline, and emits structured regressions.
- `scripts/ci/verify_phase200_scorecard.mjs` - Validates baseline-only and full Phase 200 scorecard packages, including manifest-bound evidence refs and p193 closure rules.
- `.planning/phases/200-idempotent-verification-sign-off/baseline.union.cells.json` - Derived union baseline with 21,276 p187 rows and 9,072 p193 rows.

## Verification

- `node accrue_admin/e2e/phase200-scorecard.mjs --self-test` - passed.
- `node accrue_admin/e2e/phase200-scorecard.mjs --baseline-only` - passed; wrote 30,348 union cells.
- `node scripts/ci/verify_phase200_scorecard.mjs --self-test` - passed.
- `node scripts/ci/verify_phase200_scorecard.mjs --baseline-only` - passed.
- Temporary full integration under `.planning/phases/200-idempotent-verification-sign-off/.tmp-full-*` - passed; generated 30,348 final cells, 30,348 delta rows, 0 regressions, and verifier accepted the package.
- `node --check accrue_admin/e2e/phase200-scorecard.mjs` - passed.
- `node --check scripts/ci/verify_phase200_scorecard.mjs` - passed.

## Decisions Made

- Kept archived v1.53/Phase 187 inputs read-only and wrote only derived Phase 200 artifacts.
- Filtered generator evidence refs to allowed generated roots so custom browser labels such as `route:` and `storybook:` do not leak into final verifier-bound artifacts.
- Made baseline-only validation independent from full final artifacts so CI/closeout can validate the union baseline before Plan 200-06 produces `final.cells.json`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- A temporary full integration run under `/tmp` failed because the verifier correctly rejects manifest refs outside allowed generated roots. The integration check was rerun under a temporary Phase 200 artifact subdirectory and passed; the scratch directory was removed.

## Threat Notes

- T-200-09 mitigated by treating archived baselines as read-only inputs and guarding output paths against archive/prior-phase directories.
- T-200-10 mitigated by requiring empty `regressions.ndjson` in full verification.
- T-200-11 mitigated by rejecting absolute refs, backslashes, `..`, refs outside allowed roots, and unmanifested evidence refs.
- T-200-12 mitigated by requiring final p193 rows to be covered with score >= 2 and evidence refs.
- T-200-SC unchanged: no package-manager installs were performed.

## Auth Gates

None.

## Known Stubs

None. Stub-pattern scan found only CLI helper defaults and null-score handling, not placeholder UI data or unwired artifact output.

## TDD Gate Compliance

- RED commits present: `8899c2ba`, `20aee7cb`
- GREEN commits present after RED commits: `8ca7a268`, `ed04f3ac`
- No refactor commits were needed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 200-04 can consume the scorecard verifier contract. Plan 200-06 can run normal scorecard generation to produce the final structured artifacts and sign-off package.

## Self-Check: PASSED

- Created/modified source and artifact files exist.
- Summary file exists.
- Task commits `8899c2ba`, `8ca7a268`, `20aee7cb`, and `ed04f3ac` are reachable in git history.
- No tracked file deletions were introduced by the plan task commits.
- Unrelated `.planning/research/.cache/` remains untracked and untouched.

---
*Phase: 200-idempotent-verification-sign-off*
*Completed: 2026-06-30*
