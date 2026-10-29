---
phase: 254-recurring-quality-reviewed-fixes-and-curation
plan: "07"
subsystem: testing
tags: [selection, depends_on, projection, sentinels, fail-closed, step-summary, phase253, d-09, d-10, d-11, d-12, d-14, ciq-02]

requires:
  - phase: 254-recurring-quality-reviewed-fixes-and-curation
    provides: 254-05 the per-case result ledger and dependent reconcile project the selected set will bind to; 254-06 the ledger-derived Phase 252 count of 14 and the 151-cell Phase 253 universe this plan projects
  - phase: 253-real-groups-and-a-whole-subscription-job
    provides: the compiled collection and whole-page manifests and the 151-cell browser universe
provides:
  - depends_on on every entry of both compiled manifests (detail 6 paths, collection 8, page 8), a sorted non-empty subset of that module's source_digests, enforced by validate_depends_on!/2 and verify!/1
  - accrue_admin/e2e/phase253-cell-universe.js, the side-effect-free shared cell builders and one cellKey function used by the Playwright lane and the selector
  - accrue_admin/storybook/phase254-selection.json, a drift-checked projection of the 151 composition cells, the 14 ledger-derived Phase 252 cases, 8 digest-pinned sentinels, global roots and the irrelevant allowlist
  - scripts/ci/phase254_selection.mjs with project --write|--check, select, --self-test, selectCases, readChangedPaths, assertSelectionInvariants and renderSelectionSummary
  - scripts/ci/fixtures/phase254-selection/collection-only.txt, the fixture 254-08 binds the lane to
affects: [254-08, 254-09, 254-14, 254-15, 254-16, 254-17, 254-18]

actuals:
  tokens: 26348
  tasks: 3
  commits: 2

tech-stack:
  added: []
  patterns:
    - "A tracked projection of a gitignored run-time manifest, digest-bound to the files it was derived from, so a stale or forged projection hard-fails instead of narrowing a run"
    - "Fail-closed classification: a path is irrelevant only when an explicit allowlist names it and nothing else claims it; unmapped, unsafe, owner-mapped-without-scope and conflicting paths all broaden to full"
    - "git diff --name-status -z --no-renames so renames and deletions map their old path and hostile names (newline) are read intact"

key-files:
  created:
    - accrue_admin/e2e/phase253-cell-universe.js
    - accrue_admin/storybook/phase254-selection.json
    - scripts/ci/phase254_selection.mjs
    - scripts/ci/phase254_selection.test.mjs
    - scripts/ci/fixtures/phase254-selection/collection-only.txt
  modified:
    - accrue_admin/storybook/_support/subscription_manifest.ex
    - accrue_admin/storybook/_support/subscription_compositions_manifest.ex
    - accrue_admin/test/accrue_admin/dev/subscription_manifest_test.exs
    - accrue_admin/test/accrue_admin/dev/subscription_compositions_manifest_test.exs
    - accrue_admin/e2e/phase253-composition-helpers.js
    - scripts/ci/phase252_paths.mjs
    - storybook/phase252-manifest.json
    - accrue_admin/storybook/subscription-curation.json
    - guides/subscription-story-coverage.md

key-decisions:
  - "The projection is built from the compositions module's public discovery functions (source_digests/0, collection_variation_entries/0, page_entries/0), not write!/1, because write!/1 also requires the gitignored run-time transport proof that a fresh CI checkout does not have."
  - "depends_on precision is honest and group level: storybook.ex, the routers and cadence_subscriptions.exs are in every case's depends_on but are also global roots, so they broaden to full. Only subscriptions_live.ex, subscription_collection.ex, the collection story (collection tier) and subscription_live.ex, the page scenarios and the page story (page tier) can narrow a run."
  - "An empty diff is ambiguous and broadens to full (extra rule beyond D-10), and the select verb never trusts a projection whose source_digests, Phase 252 manifest or curation ledger digest changed (FC-5)."
  - "Sentinels (8): geometry::negative-controls::320::light, one_row::breakpoint::767::light, one_row::synthetic-text::320::dark, one_row::viewport::1280::light, page::active::breakpoint::768::dark, page::active::viewport::1280::light, page::review_cancel_now::viewport::320::dark, partial_cursor_error::viewport::320::dark."

patterns-established:
  - "One cellKey(entry, width, theme, kind, page) function is the only place a browser cell id is built; the selector and the lane cannot disagree"
  - "A report records mode, selected/total counts and every excluded id; the step summary says an affected selection is not the full sweep"

requirements-completed: []
requirements-advanced: [CIQ-02]

coverage:
  - id: D1
    description: "Every compiled manifest entry carries a sorted depends_on that is a subset of that module's source_digests, enforced in verify!/1 and by tests; a path outside source_digests fails"
    requirement: CIQ-02
    verification:
      - kind: unit
        ref: "subscription_manifest_test.exs (22 tests) and subscription_compositions_manifest_test.exs (9 tests) via mix run --no-start, 0 failures, 0 skips: sorted subset and tier-split tests, plus an injected out-of-digest path failing validate_depends_on!/2 and verify!/1 in all three compositions sections"
        status: pass
    human_judgment: false
  - id: D2
    description: "A tracked, drift-checked projection lists every composition cell id (same key function as the lane), tier, fixture class, depends_on, the ledger-derived always-run Phase 252 cases, the sentinel set and its pinned sha256"
    requirement: CIQ-02
    verification:
      - kind: integration
        ref: "node scripts/ci/phase254_selection.mjs project --check (151 cases equal the shared universe, 14 Phase 252 cases, 8 sentinels), re-run after the Phase 252 and Phase 253 aggregates regenerated their manifests"
        status: pass
      - kind: unit
        ref: "phase254_selection.test.mjs: identical-151-keys with a pinned key digest, committed projection equals the universe, stale-projection with a removed case, sentinel D-12 coverage with a seeded gap, pinned sentinels_sha256"
        status: pass
    human_judgment: false
  - id: D3
    description: "The selector is fail-closed and transparent: FC-1..FC-5 and every D-14 control are named tests, invariants hard-fail, and hostile path names are escaped in the rendered step summary"
    requirement: CIQ-02
    verification:
      - kind: unit
        ref: "node --test scripts/ci/phase254_selection.test.mjs scripts/ci/verify_phase252_ci_contract.test.mjs (57 tests, 0 failures) and node scripts/ci/phase254_selection.mjs --self-test (8 scenarios, hostile-path fixture named)"
        status: pass
      - kind: integration
        ref: "npm --prefix accrue_admin run phase252:check (21 of 21) and node scripts/ci/verify_phase253_compositions.mjs (10 serial lanes, browser cells=151) after the extraction and the manifest change"
        status: pass
    human_judgment: false

duration: 3h
completed: 2026-10-29
status: complete
commits: 2
plan_head_before: 9db6e70e47d1df6c75c93477e3ea6cb5422d55a0
plan_head_after: 29f7586008f2f9bd09ab2c37738fb7dd990014b6
---

# Phase 254 Plan 07: depends_on metadata, tracked case universe and fail-closed selector (W2) Summary

**Both compiled manifests now declare verified per-case dependencies, a drift-checked projection publishes the 151-cell universe with 8 digest-pinned sentinels, and a fail-closed selector turns any diff into a transparent report (mode, counts, every excluded id) or broadens to full.**

## Performance

- **Duration:** about 3 h, of which about 25 min was the wave-boundary gate
- **Tasks:** 3 (2 commits: tasks 02 and 03 share one, see Deviations)
- **Files modified:** 14 (9 hand-written, 5 generated or fixtures)

## Accomplishments

- Task 01: `depends_on` on every entry, with the tier mapping documented in module attributes. Detail tier: the story, the production renderer, the scenario facts and the builder (6 paths, never the caller-map sources). Collection and page tiers share storybook.ex, the router, queries/subscriptions.ex (subscription_live.ex aliases it), the compositions manifest and cadence_subscriptions.exs, and each adds its own renderer, support module and story. `validate_depends_on!/2` runs inside both `verify!/1` bodies before entry equality, so a forged path reports itself. Manifest, guide and ledger regenerated through their owners (R1, R2).
- Task 02: the pure cell builders moved to `phase253-cell-universe.js` with one `cellKey` function; the helpers import them. The 151 keys are byte-identical before and after (compared against a copy of the HEAD helpers, then pinned by digest). `project` builds the tracked projection from the compositions module's public discovery functions and the shared universe; `--check` regenerates in memory and compares decoded, key-sorted JSON.
- Task 03: `select` with FC-1..FC-5, the D-11 report, `assertSelectionInvariants`, the escaped Markdown summary, and a named test for every D-14 control and FC rule. Real diffs are exercised in scratch repositories (rename, delete, newline path, shallow clone, unreachable base, non-repository).

## Evidence values (plan verification record)

- **Sentinel ids (8):** `geometry::negative-controls::320::light`, `one_row::breakpoint::767::light`, `one_row::synthetic-text::320::dark`, `one_row::viewport::1280::light`, `page::active::breakpoint::768::dark`, `page::active::viewport::1280::light`, `page::review_cancel_now::viewport::320::dark`, `partial_cursor_error::viewport::320::dark`. `sentinels_sha256` `30d80bffd87e109e01e2853e1a8fbe92270634a3a2a4f3403e8eccf721f6b862` (pinned in the test; a coverage checker is shown to find a seeded gap).
- **Projection:** `accrue_admin/storybook/phase254-selection.json` sha256 `ff49e8c91a13c8d753747a7cc1febb8874742a510d2c980ffaabd9a072ed1def`; `manifest_sha256` `56a0a9e7a776f6d0ce58a28f9e68f9c50816101db0f5b50a8046955545d5a20d`. Sorted-key digest of the 151 cell ids `5f108b264b77a014dcceae480291c384a0f9739afbc855d39b9afad229440027`.
- **Derived counts:** 151 cases (55 collection tier, 96 page tier), `expected_case_count` 151, `always_run` 14 (= `expectedPhase252Cells(ledger).total`; 12 canonical + 2 compatibility). No literal in the code: both counts are derived.
- **Regenerated hashes:** `storybook/phase252-manifest.json` `d0cc29a5f69a38fd731f71dc7c8e6c1ca6969551d362dda195076b7b0d0f73c8`; `accrue_admin/storybook/subscription-curation.json` `9f4dd2de45fa213e7a55a51a1cbf48fe68f34a7ce372fe8a97a16055e5b90267`.
- **Sample report, `collection-only.txt` (one modified collection story):** event `local-fixture` (fixture source recorded in `mode_reasons`), mode `affected`, 58 of 151 selected (55 collection cells by `changed:depends_on`, 8 sentinels of which 3 are page cells, reasons merged), 93 excluded (all page cells that are not sentinels), changed path class `case-scoped`, rule `depends_on`, 55 case ids. Other controls on the committed projection: `docs/x.md` selects exactly the 8 sentinels; `accrue/lib/accrue/x.ex`, `mix.lock`, `accrue_admin/assets/css/app.css` each select all 151 (`full`).
- **Wave-boundary gate:** `npm --prefix accrue_admin run phase252:check` 21 of 21 commands; `verify_phase253_compositions.mjs` 10 serial lanes, browser cells=151; `project --check` pass afterwards; curation verifier default and `--results-latest` pass; script-guard contract (`--require-guard-coverage`), sensitive-token census and no-home-paths pass. The gate did not rewrite the tracked `accrue_admin/tmp/phase252/render-results.json`; `git status` was clean afterwards.

## Task Commits

1. **Task 254-07-01: depends_on in both compiled manifests** - `bad914d22` (feat)
2. **Tasks 254-07-02 and 254-07-03: shared cell universe, projection, fail-closed selector, tests, fixture** - `29f758600` (feat)

**Plan metadata:** recorded in the docs commit that follows this summary.

## Decisions Made

See key-decisions. No Rule 4 decision arose.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] write!/1 cannot generate the projection source on a fresh checkout**
- **Found during:** Task 02 design.
- **Issue:** `SubscriptionCompositionsManifest.write!/1` raises unless the gitignored run-time proof `accrue_admin/tmp/phase253/transport.json` exists; CI consumers of the projection (the selector on a fresh checkout) never have it.
- **Fix:** `project` runs `mix run --no-start -e` and writes only `source_digests`, `collection_variation_entries/0` and `page_entries/0` (the three sections the cell universe reads) to a temp file. No transport dependency, no change to `write!/1`.
- **Files modified:** scripts/ci/phase254_selection.mjs. **Commit:** 29f758600

**2. [Rule 3 - Blocking] The plan's lab ExUnit command cannot run these files**
- Same finding as 254-04, 254-05 and 254-06: `phase252_lab.mjs exec --lane admin-test -- mix test <file>` runs from the repo root, which has no Mix project, and the files assert no TestRepo. Verification used `cd accrue_admin && MIX_ENV=test mix run --no-start <file>` (the aggregate's own db-free form): 22 and 9 tests, 0 failures, 0 skips.

**3. [Rule 2 - Missing critical] Extra fail-closed rules and a stricter escaper**
- An empty diff broadens to full (`empty-diff`); `invalid-base`, `invalid-head` and `unreachable-head` are named FC-3 reasons; base and head must be hex SHAs (no option injection into git). `escapeMarkdown` was copied from `render_provider_summary.mjs` and extended with `$`, `(` and `)` so `$(...)` is inert. Every one has a paired positive control. **Commit:** 29f758600

**4. [Rule 3 - Blocking] Projection fields and exports the plan did not list**
- The projection also records `phase252_manifest_sha256`, `phase252_source_digests`, `curation_ledger_sha256` and per-case `case_kind`, `variation_id`, `page_role`, `width`, `theme`: the first three make a stale always-run list detectable, the rest let the D-12 coverage test decide from data. `phase252_paths.mjs` also exports `matchesRule` (with `normalizeRepoPath`); `classifyPath` semantics are unchanged. `cellKey` takes optional `kind` and `page` arguments on top of `(entry, width, theme)`. **Commit:** 29f758600

**5. Tasks 02 and 03 are one commit.** `phase254_selection.mjs` is one module whose project and select halves share the classifier, the projection shape guard and the test file, so splitting would have committed a projection verb without its guard. The task verifies were run for both tasks on the combined commit.

### TDD note

Task 01 was strictly RED then GREEN: the two new tests failed with `KeyError: :depends_on` before the manifest edit and passed after. Tasks 02 and 03 add a new module; its tests were written after the module in the same sitting, so there is no separate RED commit. Their negative controls are built in (a seeded sentinel gap, a removed case, an out-of-digest path, hostile paths, each paired with a passing control), and a known-positive was shown for every zero-result style assertion (an allowlisted path stays affected; the classifier finds a consumed root).

### Noted, not changed

- Regenerating `storybook/phase252-manifest.json` reordered keys inside entries (as in 254-06); the freshness contracts compare decoded JSON.
- The budget record's `manifest_sha256` still lags the regenerated manifest; its restamp stays with 254-09-02.

## Known Stubs

None.

## Threat Flags

None. T-254-13 mitigated (`escapeMarkdown` plus the hostile-path fixture in the self-test and the unit tests), T-254-14 mitigated (the projection is digest-bound to `source_digests`, the Phase 252 manifest and the ledger; stale or forged projections hard-fail; the sentinel digest is pinned), T-254-15 mitigated (`normalizeRepoPath` null is unmapped, never irrelevant), T-254-SC held (no installs, D-01).

## Open flags for later plans

- **254-08:** `PHASE254_SELECTION` consumers should read the report fields `mode`, `selected[].id`, `excluded[].id`, `projection_sha256`, `counts` and call `assertSelectionInvariants`. The new CI-read paths still need `CONSUMED_ROOTS` entries (254-08's must-have already lists the selector, its test and the three storybook JSON files). Note that `phase254-selection.json` is a *global root inside the selector* but not yet in `CONSUMED_ROOTS`.
- **By design the projection is hard-stale on any `source_digests` edit, any Phase 252 manifest edit and any curation ledger edit.** Every task that regenerates those must end with `project --write` (recipe R3) in the same commit, then `project --check`.
- **Precision is low by construction (D-09):** a change to `queries/subscriptions.ex` or the compositions manifest module selects all 151 cells in mode `affected` (no exclusions), because they sit in both tiers' depends_on and are not global roots. The report says so (selected equals total). Narrowing needs finer metadata, which D-09 deliberately defers.
- The CIQ-02 transparency prohibition stays flagged-unverified until 254-17, as the plan accepts.
- KR-254-06 (docs-contracts SL-G and Executable UAT red until 254-18) is untouched and owner-accepted. CIQ-02 is advanced, not completed: 254-08, 254-09, 254-17 and 254-18 also declare it.

## Self-Check: PASSED

Created and modified files exist (the five created files and nine modified files above); commits bad914d22 and 29f758600 are ancestors of HEAD; `git rev-list --count 9db6e70e4..HEAD` measured 2 before this summary commit; the three task verifies, the wave-boundary gate (21/21, 10 lanes with 151 cells, `project --check`), the curation verifier, the 57 node tests, the 8-scenario self-test, the script-guard contract, the sensitive-token census and the no-home-paths hook all pass.

---
*Phase: 254-recurring-quality-reviewed-fixes-and-curation*
*Completed: 2026-10-29*
