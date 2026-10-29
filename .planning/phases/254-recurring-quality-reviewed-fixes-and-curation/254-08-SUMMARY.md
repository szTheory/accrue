---
phase: 254-recurring-quality-reviewed-fixes-and-curation
plan: "08"
subsystem: testing
tags: [selection, playwright, ci, fail-closed, consumed-roots, d-10, d-11, d-14, ciq-02]

requires:
  - phase: 254-recurring-quality-reviewed-fixes-and-curation
    provides: 254-05 per-case result ledger and the dependent reconcile project; 254-07 the tracked 151-cell projection, sentinels and the fail-closed selector
provides:
  - PHASE254_SELECTION, a report path the composition helpers resolve and validate; unset means all 151 cells in mode full (reason no-selection-file)
  - A cells spec that registers only selected case ids (never test.skip) and a reconcile that expects exactly that set and rejects excluded-id and missing-selected rows
  - A results bundle field selection {report_sha256, mode, selected_count, total_count, reason}, checked against the browser result header
  - accrue_admin/e2e/phase254-selection-invariants.js, one CommonJS copy of the report invariants shared by the selector and the Playwright lane
  - ci.yml step "Phase 254 selection" in admin-phase200-guardrails with a fetch-depth 0 checkout, run before the guardrail runner
  - Seven consumed roots and an assertCiContract option requirePhase254Selection with mutation controls
affects: [254-09, 254-17, 254-18]

actuals:
  tokens: 11434
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "The executed identity set is the reported set: one resolveSelection function feeds registration, reconcile and the aggregate, so none of them can read a count back from the results they check"
    - "A shared CommonJS module for anything Playwright's loader must load, because it cannot require() an ES module (it rewrites .mjs and fails with 'exports is not defined')"
    - "A CI contract that rejects interpolation of event values into script text, the local-only flag, a shallow checkout and a misordered step, each paired with a passing control"

key-files:
  created:
    - accrue_admin/e2e/phase254-selection-invariants.js
  modified:
    - accrue_admin/e2e/phase253-composition-helpers.js
    - accrue_admin/e2e/subscription-compositions-phase253.spec.js
    - accrue_admin/e2e/subscription-compositions-reconcile-phase254.spec.js
    - scripts/ci/verify_phase253_compositions.mjs
    - scripts/ci/verify_phase253_compositions.test.mjs
    - scripts/ci/phase254_selection.mjs
    - scripts/ci/phase254_selection.test.mjs
    - .github/workflows/ci.yml
    - scripts/ci/phase252_paths.mjs
    - scripts/ci/verify_phase252_ci_contract.test.mjs

key-decisions:
  - "The selector's report invariants moved into accrue_admin/e2e/phase254-selection-invariants.js and the selector re-exports them. Requiring the ES-module selector from the helpers works in plain Node 22 but fails under Playwright's own loader, so a CommonJS module is the only way both sides can run the identical check without a duplicate that could drift."
  - "In mode affected, an assertion binding whose case kinds have no selected cell is skipped; in full mode it is never skipped. A collection-only selection holds no page_synthetic_text_stress cell, and failing it would make every narrowed run red."
  - "An affected result cannot be validated without its selection (acceptance evidence is a full sweep): validateLaneEvidence with no selection rejects a result whose selection block is not full. generate_phase253_acceptance therefore accepts full bundles and rejects affected ones without a code change."
  - "The unset run records the selection block on the bundle but not in execution_evidence, so the acceptance generator's evidence equality check is unchanged for full runs."

patterns-established:
  - "PHASE254_SELECTION is passed to every child through the inherited environment, validated once by the aggregate before the browser lane, and echoed into the result header the reconcile test then compares"
  - "The wave-boundary gate is two real lane runs (selected 58 cells, full 151 cells), not a unit approximation"

requirements-completed: []
requirements-advanced: [CIQ-02]

coverage:
  - id: D1
    description: "The composition lane registers and passes exactly the selected case ids, reconciliation expects exactly that set, and with no selection the lane runs all 151 cells in mode full"
    requirement: CIQ-02
    verification:
      - kind: integration
        ref: "PHASE254_SELECTION=accrue_admin/tmp/phase254/selection-local.json node scripts/ci/verify_phase253_compositions.mjs: 10 serial lanes passed, browser cells=58, bundle selection.mode affected, selected_count 58 equal to the report, below expected_case_count 151"
        status: pass
      - kind: integration
        ref: "env -u PHASE254_SELECTION node scripts/ci/verify_phase253_compositions.mjs: 10 serial lanes passed, browser cells=151, bundle selection.mode full reason no-selection-file"
        status: pass
      - kind: unit
        ref: "node --test verify_phase253_compositions.test.mjs: 19 tests, 0 failures (selection resolution, report rejections, reconcile excluded and missing rows, aggregate excluded row, missing row, forged block, full-sweep guard)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Reconciliation hard-fails on a row for an excluded case, a missing selected row, and a report whose projection digest differs from the committed projection"
    requirement: CIQ-02
    verification:
      - kind: unit
        ref: "verify_phase253_compositions.test.mjs: 'a selection report that is invalid, foreign or stale fails closed' (projection digest, omitted sentinel, other universe, path outside the repository, unreadable) and 'reconciliation expects exactly the selected set and rejects excluded and missing rows', each beside a passing control"
        status: pass
      - kind: integration
        ref: "generate_phase253_acceptance validatePhase253Evidence accepts the full bundle and rejects the affected bundle with 'requires a full sweep'"
        status: pass
    human_judgment: false
  - id: D3
    description: "CI computes the selection from full history before the guardrail runner, exports it, renders it to the step summary, and every new Phase 254 CI-read path is an admitted consumed root"
    requirement: CIQ-02
    verification:
      - kind: unit
        ref: "node --test verify_phase252_ci_contract.test.mjs: 26 tests, 0 failures, including the two Phase 254 tests (nine representative paths with removal controls, and eleven workflow mutations beside a passing control)"
        status: pass
      - kind: integration
        ref: "verify_ci_efficiency_contract.mjs --repo ., verify_phase200_guardrail_contract.sh, verify_phase200_ci_contract.sh, verify_ci_script_contract.mjs (guard coverage, non-vacuity, cohort floor) and actionlint ci.yml all exit 0"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-10-29
status: complete
commits: 2
plan_head_before: 94bb489f223ad2e7929381c16db79b085ecf7cdc
plan_head_after: 3ed559b8408346769b4feb842cf1dde7c712b086
---

# Phase 254 Plan 08: Selection-bound composition lane and CI selection on full history (W2 completion) Summary

**The Phase 253 browser lane now registers and reconciles exactly the cells a validated selection report names (58 of 151 on the collection-only fixture, all 151 when no report is given), and the required CI owner computes that report from full history before it runs.**

## Performance

- **Duration:** about 25 min, of which about 6 min was the two wave-boundary lane runs and 4 min the Phase 252 check
- **Tasks:** 2 (2 commits)
- **Files modified:** 11 (10 modified, 1 created)

## Accomplishments

- Task 01: `resolveSelection(definitions)` in the helpers reads `PHASE254_SELECTION` (a path inside the repository), applies the selector's `assertSelectionInvariants`, compares the report's `projection_sha256` to the digest of the committed `phase254-selection.json`, and requires the report's `total_ids` to equal the compiled cell universe. Unset or empty is mode full with reason `no-selection-file`. The cells spec filters the case lists and the three extra keys by the selected set, so an unselected case is never registered. The reconcile spec expects the selected keys, checks the header's `selection` block, and compares per-kind row counts against the selected definitions while still pinning the full universe counts (40, 8, 4, 2, 90, 6, 1). `reconcileResults` takes the selection and reports `result row for an excluded case`, `missing browser cell: <key> (selected)` and a widened header. The aggregate resolves the selection once after the manifest lane, stops on a bad report, records `bundle.selection`, passes it to `validateLaneEvidence`, and rejects an excluded row, a missing row, a forged block and an affected result validated without its selection.
- Task 02: `admin-phase200-guardrails` checks out with `fetch-depth: 0`, then runs "Phase 254 selection" (event, base, head and run id through `env`, report to `accrue_admin/tmp/phase254/selection-<run_id>.json`, `--summary`, `PHASE254_SELECTION` through `GITHUB_ENV`) before the unchanged guardrail runner step. A push or `workflow_dispatch` has no pull-request base and yields mode full (probed locally with `--event push --base ""`). Seven roots were added to `CONSUMED_ROOTS` and `REQUIRED_ROOT_IDS`; `assertCiContract` gained `requirePhase254Selection`.

## Evidence values (plan verification record)

- **Selected run:** report `accrue_admin/tmp/phase254/selection-local.json` from `collection-only.txt` (event `pull_request` with `--changed-paths-file`, recorded as `local-fixture`): mode `affected`, 58 selected, 93 excluded. Aggregate `a1f55fcc35ea2cc47dc22abfcdc6f73c`: 10 serial lanes passed, `browser cells=58`, bundle `selection` `{report_sha256: 6055e7fd...4cb8d, mode: affected, selected_count: 58, total_count: 151, reason: selection-report}`. The gate predicate (mode affected, count equal to the report, below `expected_case_count` 151) exited 0.
- **Unset run:** aggregate `7e04f343ac60da251d4fc49463071bdd`: 10 serial lanes passed, `browser cells=151`, bundle `selection` `{report_sha256: null, mode: full, selected_count: 151, total_count: 151, reason: no-selection-file}`. Playwright `--list` agrees: 59 tests with the report (58 cells plus the reconcile), 152 without.
- **Contract mutation list (all fail beside a passing control):** checkout without `fetch-depth: 0`; `fetch-depth: 1`; selection step moved after the guardrail runner; selection step removed; `--changed-paths-file` added to the step; the same flag in another job (a comment naming it is accepted); `--summary` dropped; event value interpolated into the script (`${{ github.event_name }}`); `PHASE254_SELECTION` export dropped; report path not `selection-<run_id>.json`; `PHASE254_BASE` env entry dropped.
- **Aggregate and helper rejections (all fail beside a passing control):** projection digest differs (and null); a report that omits a sentinel; a report whose universe differs from the compiled one; a report path outside the repository; an unreadable report; a result row for an excluded id (helper and aggregate); a missing selected row; a header that widens the selection; a forged or absent selection block; a selection naming a case outside the universe; an affected result validated without its selection.
- **Roots added:** `phase254-ci-scripts` (prefix `scripts/ci/phase254_`), `phase254-verifiers` (prefix `scripts/ci/verify_phase254_`), `phase254-budget`, `phase254-selection-projection`, `subscription-curation-ledger` (the three storybook JSON files as exact roots; no `accrue_admin/storybook/` prefix, asserted by `accrue_admin/storybook/unrelated.json` staying null), `phase254-selection-fixtures` (prefix), `playwright-default-config` (exact `accrue_admin/playwright.config.js`). Each has a positive path and a removal-must-fail control; `phase254-result-ledger.js`, `phase254-selection-invariants.js`, `phase253-cell-universe.js` and `e2e_plug_isolation_test.exs` are asserted admitted by the existing `browser-specs` and `admin-test-support` prefixes.
- **Wave-boundary and regression checks:** `phase252:check` 21 of 21; `project --check` and the selector `--self-test` (8 scenarios) pass after the edits; 189 Node tests across the selector, ledger, curation, measure, ownership, runner and acceptance files pass; the sensitive-token census and `verify_no_home_paths.sh` pass. The tracked `accrue_admin/tmp/phase252/render-results.json` was not rewritten (`git status` clean apart from the untouched `.planning/config.json`).

## Task Commits

1. **Task 254-08-01: the composition lane executes exactly the reported selection** - `83a702825` (feat)
2. **Task 254-08-02: CI computes the selection on full history; new Phase 254 paths are admitted roots** - `3ed559b84` (feat)

**Plan metadata:** recorded in the docs commit that follows this summary.

## Decisions Made

See key-decisions. No Rule 4 decision arose.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] The helpers cannot require() the ES-module selector under Playwright**
- **Found during:** Task 01, `playwright test --list` with a selection set (the Node unit tests had passed).
- **Issue:** `require("scripts/ci/phase254_selection.mjs")` works in plain Node 22 but Playwright's loader rewrites it and fails with `ReferenceError: exports is not defined` / `Cannot require() ES Module ... in a cycle`, so `assertSelectionInvariants` was unreachable from the lane.
- **Fix:** moved `assertSelectionInvariants`, `sentinelsDigest`, `REPORT_KIND`, `MODES` and the error class into the new side-effect-free `accrue_admin/e2e/phase254-selection-invariants.js`; the selector loads it with `createRequire` and re-exports the same function (identity asserted by a new selector test). Error codes and messages are unchanged.
- **Files modified:** accrue_admin/e2e/phase254-selection-invariants.js (new), scripts/ci/phase254_selection.mjs, scripts/ci/phase254_selection.test.mjs. **Commit:** 83a702825

**2. [Rule 2 - Missing critical] Affected-mode assertion bindings and the full-sweep guard**
- A selection can hold no cell of a kind (the collection-only fixture has no `page_synthetic_text_stress` cell), which made the existing "no reporter-bound cell identity" check fail every narrowed run. In affected mode a binding with no selected kind is skipped; full mode is strict.
- An affected result validated without its selection is now rejected, so a narrowed run can never be mistaken for acceptance evidence. The acceptance generator needed no change (full accepted, affected rejected, both shown on real bundles). **Commit:** 83a702825

**3. [Rule 3 - Blocking] New lane sources**
- `phase253-cell-universe.js` and `phase254-selection-invariants.js` were added to the aggregate's `COMMON_SOURCES` and the browser lane's `sources` so the source identity covers every file the lane now executes. **Commit:** 83a702825

**4. The plan's `--changed-paths-file` event name.** The plan's verify command passes `--event pull_request` with the fixture; the selector records that run as `local-fixture` (254-07 design), which is why the sample report's event is `local-fixture`.

### TDD note

Task 01 and Task 02 were written code-first and tested in the same sitting, so there is no separate RED commit. Their negative controls are built in and each sits beside a passing control: eleven selection and reconcile rejections and an excluded-row, missing-row and forged-block set at the aggregate level; eleven workflow mutations and nine removal controls for Task 02. Zero-result style assertions (an excluded id absent from the registered set, a flag absent from a workflow) were shown against a known positive (the flag in a second job is caught; a comment naming it is not).

### Noted, not changed

- Paths read by the browser lane that stay unmapped and therefore broaden to full (fail closed): `accrue_admin/test/support/e2e_plug.ex`, `accrue_admin/test/support/e2e_server.ex`, `scripts/ci/phase252_reporters.test.mjs`, `accrue_admin/lib/accrue_admin/router.ex` (a global root in the selector instead). Mapping them was not in the plan and changes no selection outcome.
- The budget record's `manifest_sha256` restamp stays with 254-09-02. KR-254-06 (docs-contracts SL-G and Executable UAT red until 254-18) is untouched and owner-accepted.
- `PHASE254_SELECTION` is validated by the aggregate and the Playwright lane, not by a unit that runs the real Playwright loader; that path is covered by the two real lane runs above and by `playwright --list` counts (59 and 152).

## Known Stubs

None.

## Threat Flags

None. T-254-16 mitigated (event values enter through `env`, the contract rejects `${{` in the script body, no `pull_request_target`), T-254-17 mitigated (`fetch-depth: 0` pinned by the contract; shallow and missing-base cases yield full per 254-07), T-254-SC held (no installs or dependency changes, D-01).

## Open flags for later plans

- **254-09:** the three-run CI freeze will observe this step on the runner for the first time; the step needs the base commit reachable, which `fetch-depth: 0` provides. If the runner image has no `node` before `actions/setup-node` ran, the step ordering already places it after "Set up Node".
- **254-17/254-18:** CIQ-02 is advanced, not completed. The transparency prohibition ("a selection is not the full sweep") is asserted by the step summary and the full-sweep guard but is not yet an independently proved prohibition (254-17).
- This PR touches `ci.yml`, `phase252_paths.mjs` and `accrue_admin/e2e/`, all global roots, so its own CI run will select mode full; the narrowing is first observable on a later docs-only or story-only PR.

## Self-Check: PASSED

Created and modified files exist (the new `accrue_admin/e2e/phase254-selection-invariants.js` and the ten modified files above); commits 83a702825 and 3ed559b84 are ancestors of HEAD; `git rev-list --count 94bb489f2..HEAD` measured 2 before this summary commit; the two task verifies, both wave-boundary lane runs (58 and 151 cells), `phase252:check` (21 of 21), the contract verifiers, actionlint, the sensitive-token census and the no-home-paths check all pass.

---
*Phase: 254-recurring-quality-reviewed-fixes-and-curation*
*Completed: 2026-10-29*
