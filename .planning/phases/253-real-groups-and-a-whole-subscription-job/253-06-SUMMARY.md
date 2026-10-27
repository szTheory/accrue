---
phase: 253-real-groups-and-a-whole-subscription-job
plan: "06"
subsystem: testing
tags: [phase253, CI, acceptance, ExUnit, Node, Playwright]

requires:
  - phase: 253-01 through 253-05
    provides: Production subscription collection, whole-page story, mounted journey, browser cells, and transparency controls
provides:
  - Ten-lane source-bound Phase 253 acceptance runner and current-run validator
  - Native-enforced descriptors for both truthful-presentation prohibitions
  - Generated executable UAT after all six completed summaries
affects: [CI, phase-253-verification, subscription-story-coverage]

actuals:
  tokens: 45513.25
  tasks: 3
  commits: 8
commits: 8
plan_head_before: c6b5f8fc1302cc96b8d0ff9e51cdad59d5a3649d
plan_head_after: ef93738b55a7a9a9695193ebb9b3af85fca305f0

tech-stack:
  added: []
  patterns:
    - Serial disposable lab lanes bind exact executed identities, run IDs, source digests, manifests, browser cells, and served assets.
    - Native prohibition descriptors require current and clean passes plus separate violation fixtures before promotion.
    - Automated UAT is generated from completed summary coverage after every plan summary exists.

key-files:
  created:
    - scripts/ci/generate_phase253_acceptance.mjs
    - scripts/ci/generate_phase253_acceptance.test.mjs
    - .planning/phases/253-real-groups-and-a-whole-subscription-job/253-UAT.md
  modified:
    - scripts/ci/verify_phase253_compositions.mjs
    - scripts/ci/verify_phase253_compositions.test.mjs
    - scripts/ci/phase252_paths.mjs
    - scripts/ci/verify_phase252_ci_contract.test.mjs
    - scripts/ci/verify_phase253_presentation.test.mjs
    - .planning/phases/253-real-groups-and-a-whole-subscription-job/253-05-PLAN.md
    - .planning/phases/253-real-groups-and-a-whole-subscription-job/253-VALIDATION.md
    - .gitignore

key-decisions:
  - "Keep both current and four historical unclassified assumptions unresolved; acceptance verifies their preservation instead of inferring runtime resolution."
  - "Promote the two Phase 05 prohibition descriptors only after native projection proves current and clean passes and two independent content violations fail."
  - "Keep presentation evidence explicitly separate from mounted dispatch, persistence, and provider-completion claims."

requirements-completed: [SBK-04, SBK-05, SBK-06, UXQ-01, UXQ-03]

coverage:
  - id: D1
    description: The existing required owner runs ten serial Phase 253 lanes and validates source-bound evidence for all five requirements, fourteen tasks, ten classified edges, and twenty-six UI predicates.
    requirement: UXQ-03
    verification:
      - kind: integration
        ref: "accrue_admin/tmp/phase253/ci-results/7707b484d6cfb0986a05ff0792dee8d2/results.json#bundle:all_required_commands_passed"
        status: pass
      - kind: integration
        ref: "node scripts/ci/generate_phase253_acceptance.mjs --latest (run 7707b484d6cfb0986a05ff0792dee8d2; 10 lanes; 151 browser cells)"
        status: pass
    human_judgment: false
  - id: D2
    description: Both truthful-presentation prohibitions use native test descriptors with current and clean GREEN evidence and separate static-claim and synthetic-attribution violation RED controls.
    requirement: UXQ-03
    verification:
      - kind: integration
        ref: "accrue_admin/tmp/phase253/ci-results/7707b484d6cfb0986a05ff0792dee8d2/results.json#commands:phase253-transparency-controls:phase253_current_green"
        status: pass
      - kind: integration
        ref: "accrue_admin/tmp/phase253/ci-results/7707b484d6cfb0986a05ff0792dee8d2/results.json#commands:phase253-transparency-controls:phase253_clean_green"
        status: pass
      - kind: integration
        ref: "accrue_admin/tmp/phase253/ci-results/7707b484d6cfb0986a05ff0792dee8d2/results.json#commands:phase253-transparency-controls:phase253_static_violation_red and phase253_synthetic_violation_red"
        status: pass
    human_judgment: false
  - id: D3
    description: CI root admission and imported test identities are enforced while the full existing Phase 252 regression gate remains green.
    requirement: UXQ-03
    verification:
      - kind: unit
        ref: "node --test scripts/ci/generate_phase253_acceptance.test.mjs scripts/ci/verify_phase253_compositions.test.mjs scripts/ci/verify_phase252_ci_contract.test.mjs scripts/ci/verify_executable_uat_contract.mjs (52 passed, 0 skipped)"
        status: pass
      - kind: integration
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793138051716-73986-ce960ba62d86/results.json (21 commands passed; cold compile and disposable database paths included)"
        status: pass
    human_judgment: false
  - id: D4
    description: Two current and four historical unclassified assumptions remain explicitly unresolved in accepted metadata.
    requirement: UXQ-03
    verification:
      - kind: unit
        ref: "node scripts/ci/generate_phase253_acceptance.mjs --latest (run 7707b484d6cfb0986a05ff0792dee8d2; six unresolved assumptions; zero unresolved prohibitions)"
        status: pass
    human_judgment: false

duration: 1h 44m
completed: 2026-10-27
status: complete
---

# Phase 253 Plan 06: Executable Acceptance Summary

**A source-bound ten-lane gate validates every Phase 253 requirement and generates automated UAT only after all six plan summaries exist.**

## Performance

- **Duration:** 1h 44m
- **Started:** 2026-10-27T20:35:01Z
- **Completed:** 2026-10-27T22:19:08Z
- **Tasks:** 3
- **Files modified:** 17

## Accomplishments

- Added a narrow acceptance generator that validates current runner evidence, all five requirements, fourteen tasks, ten classified edges, twenty-six UI predicates, source and browser digests, and all six unresolved assumptions.
- Completed a serial ten-lane Phase 253 run with 151 passing browser cells, then validated the exact run bundle with `human_judgment: false`.
- Generated 24 automated UAT entries from the six completed plan summaries; verified the output matches the project renderer when an independent verification fixture is present.
- Used native prohibition projection and enforcement to prove current/clean passes and independent violation failures before resolving the two descriptors.
- Preserved the full Phase 252 gate: all 21 commands passed, including cold compile, cold database startup, mounted regressions, isolation/kitchen controls, browser rendering, and transparency controls.
- Updated the validation record with real command counts and timings; its completion flags remain false until the post-summary UAT contract and independent phase review finish.

## Task Commits

1. **253-06-01: Run bounded composition acceptance with actual executed reporters** — RED `48ae02b70`, GREEN `f2b11bc14`.
2. **253-06-02: Admit every consumed root through the current merge-blocking owner** — RED `00b439f8e`, GREEN `0865392c3`.
3. **253-06-03: Validate current runtime evidence, prove descriptors and generate executable acceptance** — RED `4b4e872bd`, GREEN `9bb6f4e86`, follow-up fixes `88067190b` and `ef93738b5`.

The final plan metadata commit is recorded after post-summary UAT generation and state updates.

## Files Created/Modified

- `scripts/ci/verify_phase253_compositions.mjs` and its test — serial lane inventory, source-bound reporter checks, Playwright cell reconciliation, and exact executed identities.
- `scripts/ci/generate_phase253_acceptance.mjs` and its test — current evidence validation, complete mapping checks, native prohibition evidence, and post-summary UAT generation.
- `scripts/ci/verify_executable_uat_contract.mjs` — completion-date support for the existing `completed_date` summary convention and a renderer parity test.
- `scripts/ci/phase252_paths.mjs` and `scripts/ci/verify_phase252_ci_contract.test.mjs` — admission and reporter controls for the required existing CI owner.
- `scripts/ci/verify_phase253_presentation.test.mjs` — literal test identity for the source-derived native descriptor.
- `253-05-PLAN.md` — the two prohibition descriptors after native enforcement succeeded.
- `253-VALIDATION.md` — executed statuses, evidence counts, and measured Phase 252 timings.
- `.gitignore` — ignores generated Phase 253 CI result bundles.

## Decisions Made

- Kept static presentation proof separate from claims about mounted authorization, effects, persistence, or provider completion.
- Kept the two current and four historical assumptions unresolved while validating that none was silently relabeled.
- Required explicit per-variation responsive and stress assertions and the complete ten-file compiled-manifest source inventory.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Matched Playwright identity to the actual JSON reporter shape**
- **Found during:** Task 3 aggregate validation.
- **Issue:** Playwright identifies a test in the spec title and nested test result; the runner expected the identity in a nested test title and did not reject retried tests.
- **Fix:** Validate the spec title, one nested test, one passed result, and retry count zero; reject pooled, missing, failed, or retried identities.
- **Files modified:** `scripts/ci/verify_phase253_compositions.mjs`, `scripts/ci/verify_phase253_compositions.test.mjs`.
- **Verification:** The 151-cell browser lane and complete current-run acceptance passed.
- **Committed in:** `9bb6f4e86`.

**2. [Rule 1 - Bug] Bound browser evidence to exact responsive assertions and every manifest source**
- **Found during:** Task 3 aggregate validation.
- **Issue:** The assertion inventory omitted the one-row 767/768 transition, table-local scrolling, filtered-empty layout, and long-page stress controls; the browser digest map also omitted five compiled-manifest input files.
- **Fix:** Added the exact per-variation assertions and all ten compiled-manifest inputs to the browser source snapshot.
- **Files modified:** `scripts/ci/verify_phase253_compositions.mjs`, `scripts/ci/verify_phase253_compositions.test.mjs`.
- **Verification:** The current browser result reconciled all 151 cells and served assets against the compiled manifest and current source digests.
- **Committed in:** `9bb6f4e86`.

**3. [Rule 2 - Missing critical functionality] Admitted and counted imported CI/acceptance test identities**
- **Found during:** Task 3 aggregate validation.
- **Issue:** Both test entrypoints import `main_module.mjs`, so actual TAP output included five more tests than the lane inventory, and the imported root was not independently classified by the required owner.
- **Fix:** Added the imported module to both reporter/source inventories and added a positive/negative required-root admission control.
- **Files modified:** `scripts/ci/verify_phase253_compositions.mjs`, `scripts/ci/verify_phase253_compositions.test.mjs`, `scripts/ci/phase252_paths.mjs`, `scripts/ci/verify_phase252_ci_contract.test.mjs`.
- **Verification:** The exact combined Node suite passed 43/43 with zero skips; the ten-lane aggregate and Phase 200 guardrail contract passed.
- **Committed in:** `9bb6f4e86`.

**4. [Rule 1 - Bug] Preserved named process-marker assertion references**
- **Found during:** Task 3 `--latest` evidence validation.
- **Issue:** The generator treated an empty TAP-binding object as truthy and derived no assertion references for the transparency process-marker lane.
- **Fix:** Prefer non-empty TAP binding keys and otherwise validate the explicit marker list.
- **Files modified:** `scripts/ci/generate_phase253_acceptance.mjs`, `scripts/ci/generate_phase253_acceptance.test.mjs`.
- **Verification:** Added a regression assertion and reran all ten lanes; `--latest` accepted the current bundle.
- **Committed in:** `9bb6f4e86`.

**5. [Rule 1 - Bug] Accepted existing nested summary dates before UAT generation**
- **Found during:** Task 3 post-summary generation.
- **Issue:** Plans 253-02 and 253-03 store their completion date as `metrics.completed_date`; the generator only accepted top-level `completed` or `completed_date` keys.
- **Fix:** Accept the nested `completed_date` form and test a five-summary temporary fixture for the missing-summary negative case.
- **Files modified:** `scripts/ci/generate_phase253_acceptance.mjs`, `scripts/ci/generate_phase253_acceptance.test.mjs`.
- **Verification:** The 52-test contract suite passed, and `--latest --write-uat` produced 24 entries.
- **Committed in:** `88067190b`.

**6. [Rule 3 - Blocking issue] Aligned the project UAT contract with existing completion dates**
- **Found during:** Task 3 post-summary contract verification.
- **Issue:** The project UAT renderer also read only `completed`, so it would reject the existing `completed_date` fields after a verification artifact was added.
- **Fix:** Accept either date spelling and add a temporary synthetic-verification fixture that proves the generated Phase 253 UAT exactly matches the project renderer.
- **Files modified:** `scripts/ci/verify_executable_uat_contract.mjs`, `scripts/ci/generate_phase253_acceptance.mjs`, `scripts/ci/generate_phase253_acceptance.test.mjs`.
- **Verification:** The 52-test contract suite passed; the actual phase contract then reached its independent-verification prerequisite and reported only the missing `253-VERIFICATION.md`.
- **Committed in:** `ef93738b5`.

**Total deviations:** 6 auto-fixed (4 Rule 1, 1 Rule 2, 1 Rule 3).
**Impact on plan:** These fixes made the evidence inventory match actual reporter output and required CI admission. Scope remained within Plan 06.

## Issues Encountered

The disposable lab's process-list inspection was denied by the default sandbox (`EPERM`). Running the same existing verification commands with the permitted elevated process access succeeded; no application or test data was reset outside the existing disposable lab. The Phase 252 gate rewrote its tracked coverage guide as a side effect; that exact unrelated file was restored to its original contents.

## Post-Summary Verification

`node scripts/ci/generate_phase253_acceptance.mjs --latest --write-uat` passed on run `7707b484d6cfb0986a05ff0792dee8d2` and wrote 24 automated UAT entries. The project UAT contract command was run after generation and stops at the required missing `253-VERIFICATION.md`. It checks that artifact's `status: passed` and `behavior_unverified: 0`; independent phase verification owns the artifact. No verification report was pre-authored.

## User Setup Required

None.

## Next Phase Readiness

The six plan summaries, current automated evidence, and 24-entry UAT are ready for independent phase verification. The executable-UAT contract must be rerun after the independent verifier supplies `253-VERIFICATION.md`. The six unclassified assumptions remain visible as planning debt; acceptance made no provider-fidelity or real-adopter claim.

## Self-Check: PASSED

The summary and generated UAT exist. All eight task commits are ancestors of the current branch tip, the measured plan commit count is eight, and the latest task commit contains no deletions.

---
*Phase: 253-real-groups-and-a-whole-subscription-job*
*Completed: 2026-10-27*
