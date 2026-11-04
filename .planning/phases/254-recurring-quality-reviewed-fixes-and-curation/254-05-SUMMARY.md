---
phase: 254-recurring-quality-reviewed-fixes-and-curation
plan: "05"
subsystem: testing
tags: [playwright, project-dependencies, e2e-plug, result-ledger, phase252-lab, d-13, d-14, ciq-02]

requires:
  - phase: 254-recurring-quality-reviewed-fixes-and-curation
    provides: 254-02 spec-ownership contract and pure-story classifier, 254-03 CI-observed Phase 252/253 lanes, 254-04 ledger-derived Phase 252 counts
  - phase: 253-real-groups-and-a-whole-subscription-job
    provides: the 151-cell composition aggregate whose result ledger this plan reworks
provides:
  - AccrueAdmin.E2E.Plug.refuse_in_review_lane/2, a 403 refusal of every reset, seed and phase240 mutator POST in the admin-review lane (admin-test and the identity-less legacy server stay permissive)
  - accrue_admin/e2e/phase254-result-ledger.js with caseResultPath, writeCaseResult and mergeCaseResults (one atomic file per case, no import-time side effects)
  - a dependent Playwright project phase254-reconcile (dependencies ["phase252-owned-review"]) that merges the per-case files and applies every reconcileResults invariant over the full compiled cell universe
  - an aggregate assertion that the reconcile identity executed in the reconcile project and every cell in the cells project
affects: [254-06, 254-07, 254-09, 254-17, 254-18]

actuals:
  tokens: 13200
  tasks: 3
  commits: 6

tech-stack:
  added: []
  patterns:
    - "A function plug ahead of plug(:match) with one mutator route-prefix list; the /__e2e__ forward prefix is normalised away so both spellings are one set"
    - "Per-case result files written with pid-suffixed temp plus rename, encoded with encodeURIComponent so distinct keys never share a file, merged by a dependent Playwright project"
    - "A spec that is loaded as a dependency by another lane's run registers no tests when it has no owned run identity, and the aggregate's exact identity inventory keeps the real run fail-closed"

key-files:
  created:
    - accrue_admin/test/accrue_admin/e2e_plug_isolation_test.exs
    - accrue_admin/e2e/phase254-result-ledger.js
    - accrue_admin/e2e/subscription-compositions-reconcile-phase254.spec.js
    - scripts/ci/phase254_result_ledger.test.mjs
  modified:
    - accrue_admin/test/support/e2e_plug.ex
    - accrue_admin/test/support/e2e_server.ex
    - scripts/dev/phase252_isolation.test.mjs
    - accrue_admin/e2e/phase253-composition-helpers.js
    - accrue_admin/e2e/subscription-compositions-phase253.spec.js
    - accrue_admin/playwright.phase252.config.js
    - accrue_admin/playwright.config.js
    - scripts/ci/verify_phase253_compositions.mjs
    - scripts/ci/verify_phase253_compositions.test.mjs
    - scripts/ci/phase254_project_ownership.test.mjs
    - .gitignore

key-decisions:
  - "The project the reconcile step depends on holds only the composition cells; the story and review specs moved to a new phase252-owned-stories project, because Playwright runs a dependency project in full regardless of file filters."
  - "The lab config now loads the composition specs in every run, so an unowned load (no hex run nonce or no compiled manifest) registers no tests instead of throwing; the aggregate's exact 151-cell-plus-reconcile identity inventory keeps real runs fail-closed."
  - "Review-lane refusal assertions in the live isolation test are inline, not a nested subtest, because the Phase 252 aggregate pins that file's top-level test inventory."

patterns-established:
  - "Mutator detection: POST to a path under /reset, /seed/ or /phase240/ after stripping a leading __e2e__ segment; GET /phase240/action-status and /counts stay readable in the review lane"
  - "Dependency semantics are proved on a scratch two-project fixture (upstream failing: dependent skipped; upstream passing: dependent passed) and by a static assertion on the real config with in-memory mutations"

requirements-completed: []
requirements-advanced: [CIQ-02]

coverage:
  - id: D1
    description: "In the admin-review lane every reset, seed and phase240 mutator route variant answers 403 and leaves review data unchanged, while the admin-test lane still answers 200 and the identity-less legacy server stays permissive"
    requirement: CIQ-02
    verification:
      - kind: unit
        ref: "node scripts/dev/phase252_lab.mjs exec --lane admin-test -- sh -c 'cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/e2e_plug_isolation_test.exs' (6 tests, 0 failures, 0 skips; 22 declared POST routes read from the plug source, 24 distinct spellings asserted 403)"
        status: pass
      - kind: e2e
        ref: "node scripts/dev/phase252_lab.mjs isolation (5 pass, 0 fail, 0 skipped): 12 mutator routes return 403 on the live review server and its marker snapshot is byte-identical in the same test whose admin-test server returns 200 on /__e2e__/reset"
        status: pass
    human_judgment: false
  - id: D2
    description: "Composition results are written one file per case and merged by a dependent reconcile project; the old read-modify-write ledger loses a row under an interleaved write and the new layout loses none"
    requirement: CIQ-02
    verification:
      - kind: unit
        ref: "node --test scripts/ci/phase254_result_ledger.test.mjs (16 pass): old-algorithm control loses case-one, per-case layout keeps both, two concurrent writer processes keep 120 of 120 rows, merge rejects foreign run or manifest, duplicate key, misnamed file and unparsable file, key sanitization rejects separators and dot segments"
        status: pass
    human_judgment: false
  - id: D3
    description: "Reconciliation keeps every existing invariant and full mode still expects exactly 151 composition cells, with the reconcile identity executing in the dependent project"
    requirement: CIQ-02
    verification:
      - kind: integration
        ref: "node scripts/ci/verify_phase253_compositions.mjs: 10 serial lanes passed, browser cells=151, Playwright report 152 identities (151 cells plus 'reconciles every compiled collection and whole-page cell against this run and served assets' in project phase254-reconcile)"
        status: pass
      - kind: unit
        ref: "node --test scripts/ci/verify_phase253_compositions.test.mjs (14 pass) including a reconcile identity in the wrong project, a cell in the reconcile project and a missing projectName"
        status: pass
    human_judgment: false
  - id: D4
    description: "Playwright project dependency semantics are proved automatically and the real lab config declares phase254-reconcile with dependencies [phase252-owned-review]"
    requirement: CIQ-02
    verification:
      - kind: unit
        ref: "phase254_result_ledger.test.mjs: scratch two-project fixture (failing upstream gives the dependent status skipped; passing upstream gives passed), real-config assertion, four in-memory mutations that must throw, and a project-membership test"
        status: pass
    human_judgment: false

duration: 4h
completed: 2026-10-29
status: complete
commits: 6
plan_head_before: 7ce00d6c618ace7839ccf666a63f5904dccd8f30
plan_head_after: bedead76b83271e8c0cdde646a557b52897763b7
---

# Phase 254 Plan 05: Safe pure-story scheduling capability (W2) Summary

**The admin-review lane now refuses every reset, seed and phase240 mutator with 403, and composition results are written one atomic file per case and merged by a dependent `phase254-reconcile` Playwright project, so independent pure-story scheduling can neither reset shared fixtures nor lose a ledger row.**

## Performance

- **Duration:** about 4 h, most of it waiting on four full lab aggregates
- **Tasks:** 3 (6 commits: 2 RED test, 3 feat, 1 fix)
- **Files modified:** 15 (4 created)

## Accomplishments

- `refuse_in_review_lane/2` ahead of `plug(:match)`; one prefix list (`/reset`, `/seed/`, `/phase240/`); `:lane` is retained in the stored `:phase252_e2e_identity` while the `/health` payload shape is unchanged.
- The ExUnit file reads the plug's own `post "..."` declarations (22) and asserts 403 for both spellings (24 distinct paths), with an unchanged customer row and count, plus positive controls (admin-test `/__e2e__/reset` 200, `/__e2e__/seed/edge-states` 200, identity-less legacy 200, read-only `/counts` and `/phase240/action-status` not refused).
- The live two-server isolation test hits 12 mutator routes on the review server (403, body names the lane) in the same test where the admin-test server resets with 200, then compares the review marker snapshot byte for byte.
- `phase254-result-ledger.js`: injective filename encoding, atomic write, identity-enforcing merge; the race is shown on an inline copy of the old algorithm (loses a row) and cleared by the new layout and by two real concurrent writer processes.
- `phase254-reconcile` merges the per-case files, applies every `reconcileResults` invariant over the full compiled universe from `createExpectedBrowserCellDefinitions` (151), checks the per-kind counts against both rows and definitions, and only then writes the results file the aggregate reads.

## Evidence values (plan verification record)

- 403 route counts: 22 declared POST routes in `e2e_plug.ex`, 24 distinct path spellings asserted in ExUnit, 12 routes on the live review server.
- Race control: old algorithm interleaved read A, read B, write A, write B leaves `["case-two"]` (case-one lost); new layout returns `["case-one", "case-two"]`; two writer processes of 60 cases each merge to 120 unique rows with no temp file left.
- Dependency control: failing upstream gives upstream `failed`, dependent `skipped` (no results), exit non-zero; passing upstream gives both `passed`, exit 0.
- Reconcile identity: `reconciles every compiled collection and whole-page cell against this run and served assets`, executed in project `phase254-reconcile`; aggregate bundle `accrue_admin/tmp/phase253/ci-results/29a5820259673d15eb5a300e6baec5c5/results.json` (gitignored), `browser cells=151`, 152 reporter identities.
- Wave-boundary gate: `e2e_fixtures_test.exs` 17 tests, 0 failures; `verify_phase253_compositions.mjs` passed 10 lanes; `npm --prefix accrue_admin run phase252:check` passed 21 of 21; `playwright test --list --project=chromium-desktop` still lists 140 tests in 23 files.

## Task Commits

1. **Task 254-05-01: review-lane 403** - RED `743926251` (test), GREEN `97b50948d` (feat), follow-up `709d87f3d` (fix, inline assertions)
2. **Task 254-05-02: per-case ledger** - RED `d17b22ca5` (test, module absent), GREEN `71d68f696` (feat)
3. **Task 254-05-03: per-case writes and dependent reconcile** - `bedead76b` (feat)

**Plan metadata:** recorded in the docs commit that follows this summary.

## Decisions Made

See key-decisions. No Rule 4 decision arose.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Playwright runs a dependency project in full, so the cells project was split from the story and review project**
- **Found during:** Task 254-05-03, first aggregate run (browser lane reported 169 identities, expected 152)
- **Issue:** with `phase254-reconcile` depending on a project that also owned `phase252-review` and `subscription-stories-phase252`, selecting the reconcile spec ran those 17 other tests. The plan fixes the dependency name to `phase252-owned-review`.
- **Fix:** `phase252-owned-review` now matches only `subscription-compositions-phase253.spec.js`; the other two specs moved to a new project `phase252-owned-stories`. A test pins project membership; the project name was used nowhere else.
- **Files modified:** accrue_admin/playwright.phase252.config.js, scripts/ci/phase254_result_ledger.test.mjs
- **Commit:** bedead76b

**2. [Rule 3 - Blocking] Dependency loads threw in the Phase 252 stories lane**
- **Found during:** wave-boundary `phase252:check` (`subscription-render-browser`: "Phase 253 browser run has no owned launcher identity")
- **Issue:** Playwright loads a dependency project's spec files in every run of that config even when file filters select other specs; the composition spec threw at import in the stories lane.
- **Fix:** `isOwnedPhase253Run()` in the helpers; both composition specs register no tests when there is no hex run nonce or no compiled manifest. The aggregate's exact identity inventory (151 cells plus reconcile) still fails a real run that registers none.
- **Files modified:** phase253-composition-helpers.js, both composition specs
- **Commit:** bedead76b

**3. [Rule 3 - Blocking] Files outside the plan's list**
- `accrue_admin/playwright.config.js` (default projects must ignore the reconcile spec or the default listing crashes, P8), `.gitignore` (`render-cases-*/` run directory), and `scripts/ci/phase254_project_ownership.test.mjs` (the plan's own acceptance asserts the reconcile spec is lab-owned only).

**4. [Rule 1 - Bug] Nested subtest broke the Phase 252 isolation lane**
- **Found during:** `phase252:check` (`isolation-reset`)
- **Issue:** the first version wrapped the 403 loop in `t.test(...)`; the lane derives its expected identities from every `test(` in the file, so the nested title was an unexecuted identity.
- **Fix:** the refusals are asserted inline in the existing test, ahead of the unchanged-marker comparison that is the `review_data_unchanged_negative_control` binding. Consequence: the plan's wording "TAP output includes the new review-lane 403 assertion name" is met by the pre-existing top-level test identity, not a new TAP line; adding a named assertion id would touch four Phase 252 verifier files plus archived UAT text.
- **Commit:** 709d87f3d

**5. [Rule 3 - Blocking] Plan verification command form**
- `phase252_lab.mjs exec ... -- mix test <file>` runs from the repository root where there is no Mix project (same finding as 254-04). Every ExUnit run here uses `-- sh -c "cd accrue_admin && MIX_ENV=test mix test <file>"`, the form `verify_phase253_compositions.mjs` uses.

**6. [Rule 3 - Blocking] Co-author trailer**
- Commits carry `Co-Authored-By: Claude Sonnet 5.5`, following the harness attribution as in 254-04.

### TDD note

Task 1 has a genuine RED (1 of 6 failing before the plug change, `red.log`) then GREEN. Task 2's RED commit holds the test with the module absent. Task 3 carries no `tdd` attribute and was driven by the aggregate; the first aggregate run was its RED (169 vs 152).

### Noted, not changed

- `recordNegativeControls` still does a read-modify-write on the results header, but nothing calls it (verified by search); left untouched.
- `extractFailingPaths` in `phase254_measure.mjs` (254-03 flag) is not touched by this plan and was left alone.
- The tracked `accrue_admin/tmp/phase252/render-results.json` was rewritten by `phase252:check` and restored from git, as in 254-04.
- This plan delivers the isolation capability only; no fan-out is enabled. Whether to fan out is decided on CI measurement in 254-09-03.

## Known Stubs

None.

## Threat Flags

None. `refuse_in_review_lane` adds no endpoint, it narrows existing test-support routes (T-254-09 mitigated); the per-case ledger is gitignored run output (T-254-10 mitigated); no installs (T-254-SC, D-01).

## Open flags for later plans

- The `manifest_sha256` restamp of the budget record is still deferred to 254-09-02.
- KR-254-06 (docs-contracts SL-G and Executable UAT red until 254-18) is untouched and owner-accepted.
- CIQ-02 is advanced, not completed: 254-07, 254-08, 254-09, 254-17 and 254-18 also declare it.
- Any lane that runs the lab config now loads `subscription-compositions-phase253.spec.js` and the reconcile spec; both stay inert without an owned run.

## Self-Check: PASSED

Created files exist (the ExUnit file, the ledger module, the reconcile spec, the ledger test, this summary); commits 743926251, 97b50948d, d17b22ca5, 71d68f696, 709d87f3d and bedead76b are ancestors of HEAD; `git rev-list --count 7ce00d6c6..HEAD` measured 6 before this summary commit; the three task verifies, the wave-boundary gate, the script-guard contract, the sensitive-token census and the no-home-paths hook all pass.

---
*Phase: 254-recurring-quality-reviewed-fixes-and-curation*
*Completed: 2026-10-29*
