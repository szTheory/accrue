---
phase: 254-recurring-quality-reviewed-fixes-and-curation
plan: "09"
subsystem: testing
tags: [ci, budget, playwright, fan-out, freeze, d-24, ciq-04, ciq-02, github-actions]

requires:
  - phase: 254-recurring-quality-reviewed-fixes-and-curation
    provides: 254-01 measure tooling and the provisional budget, 254-03 CI-observed lanes and triage, 254-05 the pure-story isolation capability, 254-07/08 the selection report and its CI step
provides:
  - phase254_budget.mjs, the read-only check (identity, universe, skip/retry/flaky, digest, fingerprint, summary fail; warn_at warns; ceiling fails), the maintainer-only freeze and restamp-manifest, and main-reference
  - the "Phase 254 recurring budget check" step in the required owner, pinned after Phase 253 by the shell and JS contracts
  - a frozen budget measured on three first-attempt ubuntu runs of one head, with four target evaluations, visual and a11y allowances, and every D-24 deviation resolved
  - one shared admin test build for the Phase 252 and Phase 253 aggregates, and the 151 composition cells on three bounded Playwright workers
affects: [254-15, 254-16, 254-17, 254-18]

actuals:
  tokens: 104626
  tasks: 3
  commits: 7

tech-stack:
  added: []
  patterns:
    - "Budget thresholds are derived from recorded multipliers (warn_at = p90 x 1.25, ceiling = value x 2.5) and the check emits a ::warning only strictly above warn_at, so a boundary fixture proves both sides"
    - "A shared directory is named by a validated hex id exported by the runner, never by a path taken from the environment"
    - "A pure-story fan-out is a Playwright --workers flag plus a project-level fullyParallel, not a second server: the review lane refuses reset and seed with 403 and every cell writes its own result file"

key-files:
  created:
    - scripts/ci/phase254_budget.mjs
    - scripts/ci/phase254_budget.test.mjs
  modified:
    - accrue_admin/storybook/phase254-budget.json
    - accrue_admin/playwright.phase252.config.js
    - scripts/ci/phase252_paths.mjs
    - scripts/ci/phase252_reporters.mjs
    - scripts/ci/phase252_reporters.test.mjs
    - scripts/ci/phase254_measure.mjs
    - scripts/ci/phase254_measure.test.mjs
    - scripts/ci/verify_phase200_admin_guardrails.sh
    - scripts/ci/verify_phase200_guardrail_contract.sh
    - scripts/ci/verify_phase252_ci_contract.test.mjs
    - scripts/ci/verify_phase252_stories.mjs
    - scripts/ci/verify_phase253_compositions.mjs
    - scripts/ci/verify_phase253_compositions.test.mjs

key-decisions:
  - "Critical-path delta is the owner job's end offset from the run's first job start (queue excluded) minus the main workflow wall (1376 s, run 40387584954), floored at 0. The owner job has no needs, so a longer owner job lengthens the workflow only past the longest existing chain; the owner job's own added time (959 s) is frozen separately as the named metric."
  - "The D-24 shard rule tripped (serial per-cell p90 1.039 s x 151 cells = 156.9 s against 60 s, isolation capability green), so the fan-out is enabled at three workers, capped at four. On a 4-vCPU runner that cut the lane from 118-126 s to 82-87 s, not to 60 s; the remaining gap is accepted in DEV-254-07 rather than chased with more workers."
  - "Dedupe is one shared admin test build for both aggregates; production-packages and heldout-cleanup keep their own isolated builds because sharing them would remove the isolated-build proof they exist to make."
  - "A frozen budget's in-run timing is runner elapsed + frozen.setup_s - the main job's duration, so the compared quantity is the frozen metric, not a proxy."

patterns-established:
  - "The freeze verb rejects every sample it cannot trust (attempt above 1, non-success, macOS, dirty, smoke, no cache object, mixed heads, manifest digest differing from the budget) and appends a refreeze-proposal deviation instead of overwriting a frozen value"
  - "ci-collect samples carry run_started_at and the Playwright lanes' durations, stats duration and cell counts, so a freeze needs no second download"

requirements-completed: []
requirements-advanced: [CIQ-04, CIQ-02]

coverage:
  - id: D1
    description: "The budget check fails closed on identity, universe, skip/retry/flaky, digest, fingerprint and summary rules, warns strictly above warn_at, and fails above the ceiling, with both boundary sides proved"
    requirement: CIQ-04
    verification:
      - kind: unit
        ref: "node --test scripts/ci/phase254_budget.test.mjs (32 tests, 0 failures) and node scripts/ci/phase254_budget.mjs --self-test (23 scenarios, including the warn_at boundary at 129.999, 130 and 130.001, the ceiling boundary and the hostile-title fixture)"
        status: pass
      - kind: integration
        ref: "frozen check against downloaded run evidence: --elapsed-s 1287 passes (976 s), 1800 warns (1489 s above warn_at 1221.25), 3000 fails (2689 s above ceiling 2397.5)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The required owner runs the budget check after Phase 253, unconditionally, and the digest follows the regenerated manifest only through a recorded restamp"
    requirement: CIQ-04
    verification:
      - kind: unit
        ref: "bash scripts/ci/verify_phase200_guardrail_contract.sh and node --test scripts/ci/verify_phase252_ci_contract.test.mjs (28 pass), including removed, moved-before, conditionally gated and renamed budget step mutations beside a passing control"
        status: pass
      - kind: integration
        ref: "node scripts/ci/phase254_budget.mjs restamp-manifest --check exits 0 with DEV-254-11 resolved (bd02091c9213 to d0cc29a5f69a, cause 254-09-02)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The budget is frozen from three first-attempt ubuntu runs of one head with a named metric, four target evaluations, allowances and every D-24 deviation resolved"
    requirement: CIQ-04
    verification:
      - kind: integration
        ref: "the plan's budget predicate over phase254-budget.json exits 0 (frozen.metric owner_job_added_s, three distinct attempt-1 success runs on head 4825e9fa0 with clean ubuntu24 fingerprints and cache objects, composition_cell, derived warn_at and ceiling, four evaluations, allowances, DEV-254-01/05/08/09/10)"
        status: pass
      - kind: integration
        ref: "node scripts/ci/phase254_budget.mjs check --evidence-latest accrue_admin/tmp/phase254/ci exits 0 on run 40832242001; the full guardrail runner passes locally with the frozen budget"
        status: pass
    human_judgment: false
  - id: D4
    description: "The Phase 252 and 253 aggregates share one admin test build and the composition cells run on three bounded workers with every cell, assertion and reconcile identity intact"
    requirement: CIQ-02
    verification:
      - kind: integration
        ref: "PHASE254_COMPOSITION_WORKERS=3 node scripts/ci/verify_phase253_compositions.mjs: 10 lanes, browser cells=151, 152 Playwright identities, composition lane 23.4 s locally (43 s serial); on the runner 80.1-86.6 s against 118-126 s serial"
        status: pass
      - kind: unit
        ref: "verify_phase253_compositions.test.mjs (21 pass: worker bound, default serial, flag position, config pins) and verify_phase252_ci_contract.test.mjs (shared-build id validation with hostile values)"
        status: pass
    human_judgment: false

duration: 3h
completed: 2026-10-29
status: complete
commits: 7
plan_head_before: 4cbf3442cd62dbc9a005c026e8a37e76440ba260
plan_head_after: 374ed078a95941d900b894bf83cdb9e89b039599
---

# Phase 254 Plan 09: Recurring budget check and freeze (W3) Summary

**The required owner now checks every recurring run against a budget frozen on three first-attempt ubuntu runs (owner job added 959 s, warn_at 1221.25 s, ceiling 2397.5 s), after the duplicated admin compile was removed and the 151 composition cells were fanned out on three workers; one provisional target (focused check, 84.4 s against 60 s) is accepted with a recorded rationale.**

## Performance

- **Duration:** about 3 h wall, mostly waiting on GitHub runs (three cycles of 25 to 30 min) and three 12 min local runner gates
- **Tasks:** 3 (7 commits)
- **Files modified:** 15 (2 created) plus the budget record

## Accomplishments

- Task 01: `phase254_budget.mjs` with `check`, `freeze`, `restamp-manifest` and `main-reference`, 23 self-test scenarios and 32 tests. Every fail rule, both `warn_at` sides, the ceiling, every freeze rejection, the allowance rules, both digest-rule sides, the restamp match/mismatch/exhausted-block/CI cases and the composition-cell freeze are each a named scenario beside a passing control.
- Task 02: the step "Phase 254 recurring budget check" is the last line of the guardrail runner; the shell contract and `assertCiContract` (`requirePhase254Budget`) fail when it is removed, moved before Phase 253, conditionally gated or renamed. DEV-254-11 re-stamped the digest.
- Task 03: two observation cycles on the runner, triage, the D-24 order, the freeze and the DEV-254-01 closure (below).

## Evidence values

- **Frozen:** metric `owner_job_added_s`, value 959 s (samples 977, 959, 909; median 959, p90 977), `critical_path_delta_s` 140 s, `setup_s` 245 s, main reference run 40387584954 (owner job 556 s, workflow wall 1376 s, queue excluded). `warn_at` 1221.25 = 977 x 1.25; `ceiling` 2397.5 = 959 x 2.5.
- **Freeze basis (head `4825e9fa0`, attempt 1, all `workflow_dispatch -f run_live_stripe=false`, success):** CI 40832241686, 40832250164, 40832258746 (job 1533, 1515, 1465 s; Xeon Platinum 8370C, EPYC 7763, Xeon 8370C; ubuntu24 20261026.354.1; cache hits 2/0 each). Same-head pull_request runs: CI 40832242001 (1444 s), Browser UAT 40832241996 (1144 s, success).
- **Composition cell (W-3):** lane `phase253-compositions-browser`, mode full, 151 cells, per-cell median 1.262 s, p90 1.794 s, three runs, `workers` 3. The numbers include contention; 254-16 reads `workers` beside `per_cell_p90_s`.
- **Target evaluations:** `warm_preview_s` 0.036 s of 10 (local, informs only), met. `focused_check_s` 84.398 s of 60 (`ci-full-mode:phase253-compositions-browser`, 151 cells, basis DEV-254-10), **unmet, accepted in DEV-254-07**. `additional_warm_browser_s` 109.541 s of 180 (summed Playwright `stats.duration` of the two browser lanes, 165 cells, basis DEV-254-10), met. `incremental_ci_critical_path_s` 140 s of 300, met.
- **Allowances:** visual `browser-uat` baseline p90 1144 s, n 1 (DEV-254-09), max added 180 s; a11y `admin-phase200-guardrails` baseline p90 977 s, max added 180 s.
- **Selection:** total 165 (14 Phase 252 cases + 151 Phase 253 cells), mode full, 8 sentinels, 0 exclusions, `curation_record_ids` `CUR-254-06` (the retired `populated` case; the 254-01 stamp was 166).

### D-24 resolution (in order)

- **DEV-254-03 attribute (resolved):** CI 40805796792, job 1736 s, runner 1479 s: pre-existing Phase 200 steps 413 s, Phase 252 aggregate 745 s (`production-packages` 347.7, `manifest-current` 156.5, `heldout-cleanup` 150.0), Phase 253 aggregate 321 s (transport proof 165.4, composition browser 125.7). The same admin test sources were cold-compiled three times (CI compile step 157 s, `manifest-current`, the Phase 253 transport proof).
- **DEV-254-04 dedupe (resolved):** one shared admin test build (`PHASE254_SHARED_BUILD_ID`). The Phase 253 transport proof fell from 165.4 s to under 10 s; job time 1736 s to 1583 s on the same CPU class. Observed on head `b1f8ff8ba` (CI 40825822696, 40825831419, 40825840077, 40825820845).
- **DEV-254-05 `ciq02-fanout-enabled` (resolved):** decision basis serial per-cell p90 1.039 s x 151 = 156.9 s against 60 s with the isolation capability green, so the rule says shard. Enabled at three workers. **`per_cell_p90_s` 1.794 (equal to `frozen.composition_cell.per_cell_p90_s`), cells 151, `lane_total_s` 84.398, workers 3.** Isolation test identities: the 403 test and the 200 control in `e2e_plug_isolation_test.exs`, the two-writer and dependency controls in `phase254_result_ledger.test.mjs`, and the mounted-spec rejection in `phase254_project_ownership.test.mjs`. Lane 118-126 s serial to 82-87 s on three workers (about 1.45x on four vCPUs).
- **DEV-254-06 broad sweep (resolved):** no work moved; the sweeps already run in full on push-to-main and dispatch (FC-3).
- **DEV-254-07 accept (accepted):** focused check 84.4 s against 60 s. What remains is isolated cold production and host compilation the production-boundary proof requires, plus Phase 200 steps that predate the phase. No cell, assertion or lane was dropped (D-06).
- **DEV-254-08 (accepted):** the CIQ-03 visual owner (`accrue_admin_browser.yml`) sits outside the `ci.yml` critical path; branch protection stays recorded assumption A7.
- **DEV-254-09 (accepted, owner decision 2026-10-28, verbatim):** "freeze allowances.visual from the available attempt-1 browser-uat run(s)"; n = 1, run 40832241996.
- **DEV-254-10 (accepted, owner decision 2026-10-28, verbatim):** "record as deviations; measure from named full-mode CI lanes"; lanes `phase253-compositions-browser` (151 cells) and `subscription-render-browser` (14 cells), runs 40832241686, 40832250164, 40832258746.
- **DEV-254-11 (resolved):** manifest re-stamp `bd02091c9213` to `d0cc29a5f69a`, cause 254-09-02, before 254-09-03's check was first exercised.
- **DEV-254-12 observation-triage (resolved):** see Deviations, item 3.
- **DEV-254-01 (accepted, closed by 254-09-03):** `closing_measurement` `{frozen_value_s 959, critical_path_delta_s 140, run_ids [40832241686, 40832250164, 40832258746], resolved_by [DEV-254-03..07]}`; `before` 165 cells / 2 owners (the first shaped-set observation), `after` 165 / 2 at the freeze; `baseline_before` keeps the 254-01 value 166; `curation_record_ids` `CUR-254-06`.
- **Local 415 s versus the 300 s target (DEV-254-01's origin):** the local Phase 252+253 figure no longer applies as a gate; the runner figure is the frozen one, and the compile that dominated both (262 s locally) is the part the dedupe halved.

## Owner answers (verbatim)

No escalation arose; no owner question was asked in this plan. The standing answers it relied on: push approval "Yeah, I approve the push." (254-03-01); KR-254-06 accept-known-red until 254-18; the 2026-10-28 measurement-basis decisions quoted under DEV-254-09 and DEV-254-10.

## Final-head CI observation

Head `374ed078a` (the frozen budget), pushed after the local runner gate, the prepush set and the docs-contracts simulation; attempt 1, nothing rerun:

- CI `40837009725` (pull_request): Admin Phase 200 deterministic guardrails **success**, 1517 s. The first real-runner execution of the frozen check printed `pass executed identities: 151 of 151 selected`, `case universe: 165 (frozen 165)`, `skip/retry/flaky: 31 lanes clean`, `manifest digest ... matches`, `machine fingerprint: ubuntu24 4 cores`, `step summary`, and `owner job added time: 967.667 s (warn_at 1221.25 s, ceiling 2397.5 s)`; the measured added time was 1517 - 556 = 961 s, so the in-run estimate was within 7 s. Release gate legs are green.
- Browser UAT `40837009556` (pull_request): success, the visual gate green.
- Reds: Docs and bash contracts (SL-G, KR-254-06) and the parked ratchet guardrails job (pre-existing on main); triage classified 0 in-scope, 1 environmental, 1 pre-existing. No new known_reds entry was needed.

## Task Commits

1. **Task 254-09-01: budget check, freeze and restamp** - `7fd17428f` (feat), with `762f36003` (workers field)
2. **Task 254-09-02: required-owner step and restamp** - `842089bb5` (feat)
3. **Task 254-09-03: dedupe `b1f8ff8ba`, fan-out `46967802f`, format fix `4825e9fa0`, freeze `374ed078a`**

**Plan metadata:** recorded in the docs commit that follows this summary.

## Decisions Made

See key-decisions. No Rule 4 decision arose: the fan-out decision and the DEV-254-01 closure were settled by the plan's rules.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] ci-collect samples needed the run start and the Playwright lane evidence**
- **Found during:** Task 01 (the freeze needs a queue-excluded critical path and per-cell durations)
- **Fix:** `collectCiSample` adds `run_started_at` and `browser_lanes`; the measure test's pinned key list gained the two keys; the lane evidence (`phase252_reporters.mjs`, `verify_phase253_compositions.mjs`) keeps `durations` and `stats_duration_ms` (the plan allowed this when the bundle lacked durations).
- **Commits:** `7fd17428f`, `b1f8ff8ba`

**2. [Rule 3 - Blocking] Shared build id and worker bound live in `phase252_paths.mjs`**
- **Fix:** `sharedAdminBuildPath` (validated id, never a path) sits in the already-guarded library both aggregates can import; the plan's file list named only the two aggregates. The guardrail runner exports the id and `PHASE254_COMPOSITION_WORKERS=3`.
- **Commit:** `b1f8ff8ba`, `46967802f`

**3. [Rule 1 - Bug] Release-gate `mix format --check-formatted` failed in all four admin legs**
- **Found during:** the first observation (CI 40825820845, head `b1f8ff8ba`); the 254-04..07 admin test files had never met the release-gate format step.
- **Fix:** `mix format` on four test files (whitespace only); then the whole release-gate admin sequence (compile with warnings as errors, 780 tests, credo, dialyzer, docs) ran locally and passed, and the next head's release gates were green. Recorded as DEV-254-12.
- **Commit:** `4825e9fa0`

**4. [Rule 2 - Missing critical] Budget selection names its curation record before the freeze**
- **Issue:** after DEV-254-11 the universe (165) was already below the 254-01 total (166), so the local budget check would have failed D-23 for a drop that CUR-254-06 explains.
- **Fix:** `selection.curation_record_ids = ["CUR-254-06"]` in the restamp commit; the freeze then re-stamped the total to 165.
- **Commit:** `842089bb5`

### TDD note

Tasks 01 and 02 were written code-and-test together (as 254-08 did), so there is no separate RED commit. Each rule's negative control sits beside a passing control, and the zero-style assertions were shown against a known positive (the stale-digest, over-ceiling and out-of-block fixtures).

### Noted, not changed

- `extractFailingPaths` (254-03 flag) was not needed: every triage entry matched by step name.
- The gate runs created `.planning/phases/200-idempotent-verification-sign-off/` three times (the Phase 200 scorecard writes there); it was deleted each time (untracked, regenerated, precedent `d0ea275be`). `accrue_admin/tmp/phase252/render-results.json` was rewritten once and restored with a single-file `git checkout` while no other uncommitted work existed.
- One `subscription-render-browser` failure ("Process from config.webServer was not able to start. Exit code: 2") occurred in a hand-run `phase252:check` while `mix format --check-formatted` ran in `accrue_admin` at the same time; the identical command passed on rerun and in every runner. Not reproduced, not explained; see Open flags.

## Known Stubs

None.

## Threat Flags

None. `main-reference` shells out to `gh` with an argument array (no shell), a numeric run id and an `owner/name` check; the budget is never written by CI (`freeze` and `restamp-manifest --write` refuse when `CI` is set, proved by test).

## Open flags for later plans

- **Runner heterogeneity:** the same job took 1054 s on an AMD EPYC 9V45 (CI 40825822696) and 1444-1583 s on EPYC 7763 and Xeon 8370C. The frozen median and p90 are unchanged whether that run is included or not, but a future run on the fast pool will sit well below warn_at and one on a slow pool near it.
- **Critical-path reading (owner awareness):** `incremental_ci_critical_path_s` is evaluated as the owner job's effect on the workflow wall (140 s against 300), not as the owner job's own added time (959 s, the frozen metric). Both are recorded; the reading follows the plan's "workflow critical-path delta versus main, queue excluded".
- **Focused check:** 84.4 s against the provisional 60 s; four workers were not tried because three already saturate four vCPUs (1.45x).
- **`webServer` exit 2:** possible rare lab-start flake in the Phase 252 render lane (retries stay 0); watch the next runs.
- **254-15 / 254-18:** compare measured visual and a11y added time against `allowances.visual` (n = 1, 180 s) and `allowances.a11y`; CIQ-04 is advanced here, not completed (254-15 and 254-18 also declare it); CIQ-02 likewise (254-17 and 254-18).
- **Budget size:** the budget record is now 485 KB because the collected CI samples keep their Playwright durations; trimming them is safe once 254-16 has read `composition_cell`.
- KR-254-06 (docs-contracts SL-G and Executable UAT) is untouched and owner-accepted; the parked ratchet guardrails job is red as on origin/main.

## Self-Check: PASSED

Created files exist (`phase254_budget.mjs`, its test, this summary) and the budget record; commits `7fd17428f`, `842089bb5`, `b1f8ff8ba`, `46967802f`, `4825e9fa0`, `762f36003` and `374ed078a` are ancestors of HEAD; `git rev-list --count 4cbf3442c..HEAD` measured 7 before this summary commit; the three task verifies, the budget predicate, the full guardrail runner (three times, the last with the frozen budget), the release-gate admin sequence, the prepush set and the docs-contracts simulation (only the known SL-G, Executable UAT and local-credential SL-F steps red) pass; CI `40837009725` and Browser UAT `40837009556` are green on the owner jobs.

---
*Phase: 254-recurring-quality-reviewed-fixes-and-curation*
*Completed: 2026-10-29*
