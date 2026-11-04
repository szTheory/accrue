---
phase: 254-recurring-quality-reviewed-fixes-and-curation
plan: "02"
subsystem: testing
tags: [ci, node-test, playwright, module-boundary-guard, spec-ownership, classifier]

requires:
  - phase: 254-recurring-quality-reviewed-fixes-and-curation
    provides: 254-01 guarded phase252_reporters.mjs, so this plan clears the last offender of the guard contract
  - phase: 252-production-backed-subscription-stories
    provides: phase252_paths, production boundary, stories, transparency, acceptance generator and lab specs now guarded or re-owned
  - phase: 253-real-groups-and-a-whole-subscription-job
    provides: generate_phase253_acceptance, verify_phase253_compositions and the composition spec now guarded or re-owned
provides:
  - seven Phase 252/253 CI scripts conforming to the shared module-boundary guard with real node:test fixture tests
  - default Playwright projects that no longer load launcher-owned lab specs (listing recovered from Total 0 to 140 tests in 23 files)
  - scripts/ci/phase254_project_ownership.test.mjs static spec-ownership and mounted vs pure-story classifier contract
affects: [254-03, 254-07, 254-09]

actuals:
  tokens: 9447
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Guard idiom with an argument discriminator: register fixture tests only when invokedAsEntrypoint, NODE_TEST_CONTEXT is set and process.argv.length <= 2; a spawn with arguments is a real CLI run (precedent: accrue_host_preview_custody_test_entry.mjs)"
    - "Ownership is evaluated from the real config objects (RegExp testMatch/testIgnore against the e2e listing), non-RegExp patterns and unknown project names fail closed"

key-files:
  created:
    - scripts/ci/phase254_project_ownership.test.mjs
  modified:
    - scripts/ci/phase252_paths.mjs
    - scripts/ci/verify_phase252_production_boundary.mjs
    - scripts/ci/verify_phase252_stories.mjs
    - scripts/ci/verify_phase252_transparency.mjs
    - scripts/ci/generate_phase252_acceptance.mjs
    - scripts/ci/generate_phase253_acceptance.mjs
    - scripts/ci/verify_phase253_compositions.mjs
    - accrue_admin/playwright.config.js

key-decisions:
  - "Test registration requires process.argv.length <= 2 in addition to NODE_TEST_CONTEXT, because verify_phase252_ci_contract.test.mjs spawns verify_phase252_transparency.mjs --self-test from inside a node --test run (NODE_TEST_CONTEXT inherited) and must still get the CLI path."
  - "Registered tests call pure exports on inline or committed fixtures only; the nested node --test self-test controls and the aggregates stay CLI-only."
  - "The two default projects share one LAUNCHER_OWNED_AND_VISUAL_SPECS constant instead of two duplicated arrays, keeping the original two entries and adding the two lab specs."
  - "Owner group membership of default-config projects is an explicit map, so a new project name fails the contract until it is assigned a group."

patterns-established:
  - "Seeded positive controls for a source-scan classifier: reset route, seed template, helper import and one-level local import are mounted; a 'Reset filters' link text is not"

requirements-completed: [CIQ-02, CIQ-04]

coverage:
  - id: D1
    description: "Seven Phase 252/253 CI scripts import the shared isMainModule guard inside try/catch and register real fixture tests, so the guard contract no longer names them; CLI entrypoints behave as before"
    requirement: CIQ-04
    verification:
      - kind: unit
        ref: "assertGuardCoverage positive control (guardless scratch file throws) then PASS on the four and the three files; node --test --test-reporter=tap on the modules plus verify_phase252_ci_contract.test.mjs 57/57, generators and compositions suites 77/77"
        status: pass
      - kind: integration
        ref: "node scripts/ci/verify_ci_script_contract.mjs --repo . --expected-repository szTheory/accrue --require-guard-coverage --require-non-vacuity (PASS, whole cohort)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Default Playwright projects ignore the launcher-owned Phase 252/253 lab specs so a default run lists real tests and reaches the Phase 211 visual gate; visual-desktop is unchanged"
    requirement: CIQ-04
    verification:
      - kind: integration
        ref: "cd accrue_admin && npx playwright test --list --project=chromium-desktop (Total: 140 tests in 23 files, no Error); --project=chromium-mobile (140 in 23); --project=visual-desktop (1 test, admin-visual-regression-phase211, unchanged)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Static spec-ownership contract (exactly one owner group per e2e spec across both configs) and pure-story classifier with seeded positive controls and the mounted-in-lab rejection"
    requirement: CIQ-02
    verification:
      - kind: unit
        ref: "node --test --test-reporter=tap scripts/ci/phase254_project_ownership.test.mjs (14 tests, 0 fail); RED at d31a73e95 named phase252-review and subscription-compositions-phase253 as double-owned"
        status: pass
    human_judgment: false

duration: 14min
completed: 2026-10-28
status: complete
commits: 4
plan_head_before: bdaf5076aa80d060d2a5e01294a7880b5c942863
plan_head_after: f2f16d728f0acd5a446c021c375acedcc11f96fd
---

# Phase 254 Plan 02: CI Readiness (W1) Summary

**Seven Phase 252/253 verifiers now carry the shared module-boundary guard with real fixture tests, the default Playwright projects stop crashing on launcher-owned lab specs (Total 0 to 140 tests), and a static contract enforces one owner group per spec plus the mounted vs pure-story split.**

## Performance

- **Duration:** 14 min
- **Started:** 2026-10-28T15:03:00Z
- **Completed:** 2026-10-28T15:13:00Z
- **Tasks:** 3
- **Files modified:** 9 (1 created, 8 modified)

## Baselines and outcomes (verification evidence)

| Item | Before (HEAD bdaf5076a) | After (f2f16d728) |
|---|---|---|
| `verify_ci_script_contract --require-guard-coverage` offenders | `generate_phase252_acceptance`, `generate_phase253_acceptance`, `phase252_paths`, `verify_phase252_production_boundary`, `verify_phase252_stories`, `verify_phase252_transparency`, `verify_phase253_compositions` (the eighth, `phase252_reporters`, was already fixed by 254-01) | PASS; with `--require-non-vacuity` also PASS (whole cohort, 2 min 58 s) |
| `npx playwright test --list --project=chromium-desktop` | `Error: Phase 253 browser run has no owned launcher identity` at `subscription-compositions-phase253.spec.js:20`, `Total: 0 tests in 0 files` | `Total: 140 tests in 23 files`, no `Error:` line (mobile: 140 in 23) |
| `--project=visual-desktop` | 1 test (Phase 211) | 1 test (Phase 211), unchanged |
| spec ownership contract | RED: `phase252-review.spec.js` and `subscription-compositions-phase253.spec.js` owned by default-browser and lab | 14/14 green; 27 spec files each in exactly one group |

## Accomplishments

- `phase252_paths.mjs` (library, no CLI), `verify_phase252_production_boundary.mjs`, `verify_phase252_stories.mjs`, `verify_phase252_transparency.mjs`, `generate_phase252_acceptance.mjs`, `generate_phase253_acceptance.mjs` and `verify_phase253_compositions.mjs` assign `invokedAsEntrypoint` through `isMainModule` inside try/catch and register named fixture tests (one positive and one negative per area). `verify_phase253_compositions.mjs` under `node --test` completes in seconds and never touches the lab.
- CLI behavior preserved: usage errors still exit 2 for both generators, `verify_phase252_production_boundary.mjs --self-test` exits 0 and a bad argument still exits 1, `verify_phase252_transparency.mjs --self-test --only lab` still passes.
- `playwright.config.js`: both default projects ignore the Phase 211 visual spec, the Phase 252 stories spec and the two lab specs through one shared constant; `visual-desktop`, workers, thresholds, webServer and the absent `retries` key are untouched (D-06).
- `phase254_project_ownership.test.mjs` exports `OWNER_GROUPS`, `classifySpecSource`, `ownerGroupsForSpec`, `assertSpecOwnership`, `assertLabSpecsArePure` and evaluates the real `playwright.config.js` and `playwright.phase252.config.js` (the latter imported in-process with a scratch `PHASE252_E2E_*` env restored afterwards).

## Task Commits

1. **254-02-01: Guard the four Phase 252 path/boundary/story/transparency verifiers** - `3d1bc8780` (feat)
2. **254-02-02: Guard the two acceptance generators and the Phase 253 aggregate** - `f47f17c1a` (feat)
3. **254-02-03 RED: failing ownership and classifier contract** - `d31a73e95` (test)
4. **254-02-03 GREEN: default projects stop loading lab specs** - `f2f16d728` (fix)

**Plan metadata:** committed with this SUMMARY (docs: complete plan).

## Decisions Made

See `key-decisions`. The main one: the plan text said to register tests "when invokedAsEntrypoint and NODE_TEST_CONTEXT is set", but a naive condition broke `verify_phase252_ci_contract.test.mjs`, which spawns the transparency CLI from inside a node:test run. Adding `process.argv.length <= 2` keeps `node --test <file>` (no arguments) on the test path and any real argument-bearing invocation on the CLI path, with no edits needed outside this plan's files.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Guard registration swallowed an argument-bearing CLI spawn under node --test**
- **Found during:** Task 1 verify (`new reporter lanes bind named target assertions and six independent control markers` failed: `missing executed control marker lab_static_current_green`)
- **Issue:** The spawned `verify_phase252_transparency.mjs --self-test` inherited `NODE_TEST_CONTEXT`, took the test-registration branch and printed no control markers.
- **Fix:** Registration condition is `invokedAsEntrypoint && NODE_TEST_CONTEXT && process.argv.length <= 2` in the six CLI-bearing modules (same discriminator already used in `accrue_host_preview_custody_test_entry.mjs`).
- **Files modified:** verify_phase252_production_boundary.mjs, verify_phase252_stories.mjs, verify_phase252_transparency.mjs (applied from the start in the three files of Task 2)
- **Verification:** `verify_phase252_ci_contract.test.mjs` 57/57 with the four modules in one run.
- **Committed in:** 3d1bc8780

### Process notes (not code deviations)

- TDD for Tasks 1 and 2: the module guard and its registered tests live in the same file, so no separate RED commit exists. The RED evidence is the recorded baseline (`assertGuardCoverage` naming all seven files at HEAD) plus the positive control, which fires on a guardless scratch file in the same command as each GREEN check. Task 3 has a real RED commit (`d31a73e95`, 2 failing tests naming the double-owned lab specs); no `tdd-red-evidence` classifier run was recorded for it.
- This plan fixed seven of the eight offenders as scoped prerequisite work for CIQ-04's first CI observations, as the plan's deviation note anticipated; every CLI entrypoint keeps its behavior.

---

**Total deviations:** 1 auto-fixed (1 bug). **Impact on plan:** none beyond the discriminator; no scope creep.

## Issues Encountered

None blocking. The plan's `chromium-desktop` listing verify prints the full test list (tee to stderr), which is noisy but passes.

## Deferred Issues

None. `.planning/config.json` carries a pre-existing uncommitted user edit and was never staged, read for modification or committed.

## Known Stubs

None.

## Threat Flags

None. No workflow triggers, permissions, endpoints or dependencies changed (T-254-SC: no installs, D-01). T-254-03 mitigated by named positive and negative fixtures plus the unchanged existing suites; T-254-04 mitigated by the ownership contract with seeded fixtures.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- 254-03 can observe a docs-contracts-shift-left job that is no longer red from the guard contract, and a browser UAT job whose `npm run e2e` lists tests and reaches the Phase 211 visual gate. Nothing was pushed in this plan.
- 254-07 will export `normalizeRepoPath` from `phase252_paths.mjs`; the new guard block there is append-only and does not interfere.

## Self-Check: PASSED

All nine changed paths exist, all four task commits (`3d1bc8780`, `f47f17c1a`, `d31a73e95`, `f2f16d728`) are ancestors of HEAD, `git rev-list --count` from the recorded base is 4, and the three task verify commands plus the whole-cohort guard-coverage and non-vacuity contract passed.

---
*Phase: 254-recurring-quality-reviewed-fixes-and-curation*
*Completed: 2026-10-28*
