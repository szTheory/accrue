---
phase: 254-recurring-quality-reviewed-fixes-and-curation
plan: "06"
subsystem: testing
tags: [curation, storybook, ledger, retire, merge, caller-map, phase252, d-39, d-40, amd-254-01]

requires:
  - phase: 254-recurring-quality-reviewed-fixes-and-curation
    provides: 254-04 curation ledger, frozen baseline, ledger-derived Phase 252 counts and the verifier this plan extends; 254-05 the admin-test lab lane ordering (wave 5)
  - phase: 253-real-groups-and-a-whole-subscription-job
    provides: the page and collection story keys and the SBK-06 mounted journey the corrected gap rows cite
provides:
  - CUR-254-06, a retire of subscription_detail||populated backed by commit-anchored duplicate evidence, and CUR-254-07, a merge of action_menu/provider_pruned backed by story-source shape evidence
  - duplicateEvidenceAtCommit(record, { root }) and actionMenuShape in scripts/ci/verify_phase254_curation.mjs, plus per-record reference-scan contexts, additional survivors and the AMD-254-01 record_ids link
  - ledger-aware compatibility-id tests, so the retirement commit changed no test expectation
  - the stale detail-page, list and mounted-journey caller rows corrected to reachable with Phase 253 and SBK-06 covering keys
  - a live Phase 252 browser count of 14 (12 canonical + 2 compatibility), derived from the ledger, with the Phase 253 universe unchanged at 151
affects: [254-07, 254-09, 254-17, 254-18]

actuals:
  tokens: 22645
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "A removal record carries pinned historical evidence blocks; the verifier re-derives them from git show at provenance.origin_commit, so evidence for a deleted entry cannot be forged and cannot rot when the survivor later changes"
    - "A reference-scan context pattern is proven against the tree as it was at origin_commit before its zero result is accepted (a pattern that matches nothing cannot be evidence of anything)"
    - "Story-level duplicates are decided on a declared mechanical shape (story state, group label sequence, item kinds) parsed from story source, never on visuals"

key-files:
  created: []
  modified:
    - accrue_admin/test/accrue_admin/dev/subscription_scenarios_test.exs
    - accrue_admin/test/accrue_admin/dev/subscription_story_slice_test.exs
    - accrue_admin/test/accrue_admin/dev/subscription_manifest_test.exs
    - dev_support/ui_scenarios/cadence_subscriptions.exs
    - storybook/components/subscription_detail.story.exs
    - storybook/components/action_menu.story.exs
    - accrue_admin/e2e/phase252-story-helpers.js
    - accrue_admin/storybook/_support/subscription_manifest.ex
    - storybook/phase252-manifest.json
    - accrue_admin/storybook/subscription-curation.json
    - guides/subscription-story-coverage.md
    - scripts/ci/verify_phase254_curation.mjs
    - scripts/ci/generate_phase252_acceptance.test.mjs

key-decisions:
  - "Retire populated: verified before editing that its expected block, and its fact block, equal active at the origin commit (key, url, variation_id, scenario_id and route_variation_id are the only differing fields) and that fetch!(:populated) delegated to fetch!(:active). The decision held, so no retain record was needed."
  - "The CUR-254-06 evidence blocks are pinned literals in the ledger source; the verifier re-derives them from git show at the origin commit and also against the frozen manifest, so a wrong literal fails."
  - "The reference scan for a removed id uses per-record context patterns, because the bare token populated also appears in about 40 unrelated list-state markers across accrue_admin/test and e2e (data-ax-state, test titles)."
  - "A merge record may name additional survivors; CUR-254-07 names action_menu danger (story survivor with variation) and subscription_detail braintree_pruned (manifest survivor)."

patterns-established:
  - "AMD-254-01 carries record_ids; the verifier fails when a retired compatibility id's record is not linked there"

requirements-completed: []
requirements-advanced: [CURATE-01]

coverage:
  - id: D1
    description: "populated is retired as a duplicate with mechanical, commit-anchored evidence and absent from discovery, facts, tests and e2e, with active and the page active story as survivors"
    requirement: CURATE-01
    verification:
      - kind: integration
        ref: "node scripts/ci/verify_phase254_curation.mjs (duplicate blocks and the fetch!(:populated) -> fetch!(:active) alias re-derived from git show at 9b40acc8e, frozen-manifest cross-check, per-record context scan) and --results-latest (survivors present in the newest rendered Phase 252 results)"
        status: pass
      - kind: unit
        ref: "node scripts/ci/verify_phase254_curation.mjs --self-test (24 scenarios): commit-anchored evidence passes where blocks and alias held and fails for differing blocks, a missing alias, forged evidence and an unreachable commit; contexts; additional survivors; AMD link"
        status: pass
      - kind: unit
        ref: "scenarios, story-slice and manifest ExUnit files via mix run --no-start (13, 5 and 20 tests, 0 failures, 0 skips), including a synthetic-ledger test that follows a retirement"
        status: pass
    human_judgment: false
  - id: D2
    description: "provider_pruned is merged into action_menu danger and subscription_detail braintree_pruned with preserved regressions in required lanes; registry counts and kitchen test digests equal the frozen baseline"
    requirement: CURATE-01
    verification:
      - kind: unit
        ref: "verify_phase254_curation.mjs shape evidence (actionMenuShape at origin commit fdcd6c4eb for provider_pruned and danger, survivor re-parsed in the current story, subject and helper absent) and the 24-scenario self-test; subscription_manifest_test.exs 'populated is retired and provider_pruned merged...'"
        status: pass
    human_judgment: false
  - id: D3
    description: "The detail-page, list and mounted-journey caller rows are reachable with Phase 253 page/collection keys and SBK-06 evidence while the whole-page limit claim is kept; counts are 14 Phase 252 cells and 151 Phase 253 cells"
    requirement: CURATE-01
    verification:
      - kind: integration
        ref: "npm --prefix accrue_admin run phase252:check (21 of 21 commands, newest bundle 14 browser rows: 12 canonical, 2 compatibility, no populated) and node scripts/ci/verify_phase253_compositions.mjs (10 serial lanes, browser cells=151)"
        status: pass
      - kind: unit
        ref: "subscription_manifest_test.exs 'current caller map reconciles production sources...' asserts the three rows reachable, page keys equal the compiled Phase 253 page entries, list keys equal the collection entries, journey keys a subset of the page keys, and the journey test file exists"
        status: pass
    human_judgment: false

duration: 3h
completed: 2026-10-29
status: complete
commits: 3
plan_head_before: 7284de521ee5624a9a3746f46755d9529055fae5
plan_head_after: ee6eace3173789f2d1217a54389255e89d2cb91c
---

# Phase 254 Plan 06: Retire populated, merge provider_pruned and correct stale gap rows (W2) Summary

**subscription_detail||populated is retired as a commit-anchored duplicate of active and action_menu/provider_pruned is merged into danger and braintree_pruned, both with verifier-re-derived evidence; the live Phase 252 browser count is 14 and the Phase 253 universe stays 151.**

## Performance

- **Duration:** about 3 h, of which about 25 min was the wave-boundary gate (cold compile, 21 Phase 252 lanes, 10 Phase 253 lanes)
- **Tasks:** 3 (3 commits, no separate RED commits: see TDD note)
- **Files modified:** 13

## Accomplishments

- Tests first: the ordinary-scenario list, the fetch! alias check and the story variation ids derive from `frozen_baseline.compatibility_ids` minus the ledger's removals, and a synthetic-ledger test shows a retired id must be absent and the rest present. The retirement commit changed no expectation.
- CUR-254-06 (retire, duplicate, reachability historic_supported): removes the `:populated` fact and alias, the story variation and a dead helper branch. Survivors are `/components/subscription_detail||active` and the `/pages/subscription` active story; AMD-254-01 now lists `record_ids: ["CUR-254-06"]` and the verifier requires that link whenever a compatibility id is retired.
- CUR-254-07 (merge, duplicate plus stale story-local provider rule): removes the `provider_pruned` variation and its `provider_pruned_groups` helper. Survivors are `/components/action_menu` danger (story survivor with a variation) and `/components/subscription_detail||braintree_pruned` (provider claim). Preserved regressions: the DropdownMenu disclosure test (Danger zone last, danger-styled items) and the production Braintree test "provider-pruned empty action groups are omitted for a valid Braintree subscription".
- The three stale caller rows (detail page, list, mounted journey) are reachable with the compiled Phase 253 page and collection keys and SBK-06 evidence (`subscription_journey_test.exs`); the page row and the guide keep "does not prove a whole page".
- Verifier additions (all with positive and negative self-test scenarios, now 24): `duplicateEvidenceAtCommit`, `actionMenuShape`, `reference_scan.contexts` proven at the origin commit, `additional_survivors`, and the AMD record link.

## Evidence values (plan verification record)

- **origin_commit:** CUR-254-06 `9b40acc8e53ca4d2eeb9a984dbc744097f92bc98` (HEAD before the edit); CUR-254-07 `fdcd6c4ebf57543b9ba7df5a40e5b8271fb79bf1`.
- **Pre-edit check (populated):** at the origin commit, populated and active `expected` blocks and `fact` blocks were equal (717 characters of expected JSON); the only differing entry fields were key, url, variation_id, scenario_id and route_variation_id; `def fetch!(:populated), do: fetch!(:active)` was at line 60. The same equality holds at the frozen commit 986f68b71.
- **Derived counts:** `expectedPhase252Cells(ledger)` = canonical 12, compatibility 2, total 14. Newest Phase 252 bundle (`ci-results/25208-1793247823821-95186-77f01e89e4c5`): 14 rows (12 canonical, 2 compatibility, no populated key). Phase 253: browser cells=151, 10 serial lanes. The check `total == compatibility_ids + canonical - retired compat records` returned true.
- **Registry and kitchen:** `current.registry` equals `frozen_baseline.registry` (30 families, 42 entries, 75 specimens); the four kitchen test digests are unchanged; `frozen_baseline` is byte-identical (the verifier re-derives its 26 subjects from `git show 986f68b71`).
- **Scan, positive then zero:** the seeded positive (`proveReferenceScan`) found 1 hit. At the origin commit the CUR-254-06 context patterns found 10 references in 5 files (per pattern: `:populated` 3, `||populated` 1, `variation_id=populated` 1, variation_id-with-populated 3, scenario_id/route_variation_id 2). In the working tree the same contexts find 0 references outside the two allowed paths (the frozen-literal manifest source and its test). For `provider_pruned` the bare scan finds only those same two allowed frozen-literal files (the story hit is gone).
- **Regenerated hashes:** `storybook/phase252-manifest.json` sha256 `f93ee88a21f46e7d8fa5ee8e463e11a4008dcc9bb1f51ccab6fdb68ae5f0b3aa`; `accrue_admin/storybook/subscription-curation.json` sha256 `ed156716821ff2a2997b8165507da6f0f17a9d4372b4ca8533a60b49ec204164`. The budget record's `manifest_sha256` (`bd02091c...`) now lags; its restamp stays with 254-09-02.
- **Wave-boundary gate:** three ExUnit files (13, 5, 20 tests, 0 failures, 0 skips), `phase252:check` 21 of 21, `verify_phase253_compositions.mjs` passed, `verify_phase254_curation.mjs` and `--results-latest` passed, 104 node tests (acceptance generator, reporters, curation, CI contract) passed, script-guard contract and sensitive-token census passed.

## Task Commits

1. **Task 254-06-01: ledger-aware tests** - `9b40acc8e` (test)
2. **Task 254-06-02: retire populated, commit-anchored evidence** - `fdcd6c4eb` (feat)
3. **Task 254-06-03: merge provider_pruned, correct caller rows** - `ee6eace31` (feat)

**Plan metadata:** recorded in the docs commit that follows this summary.

## Decisions Made

See key-decisions. No Rule 4 decision arose; the one judgement worth the owner's attention is under Open flags (the shape definition used for the merge).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] The plan's lab ExUnit command cannot run these files**
- **Issue:** `phase252_lab.mjs exec --lane admin-test -- mix test <file>` runs from the repo root where there is no Mix project (same finding as 254-04 and 254-05), and these files assert `Process.whereis(AccrueAdmin.TestRepo) == nil`. The Phase 252 aggregate runs them db-free.
- **Fix:** every ExUnit verification here uses `cd accrue_admin && MIX_ENV=test mix run --no-start <file>` (the aggregate's own form): 0 failures, 0 skips.

**2. [Rule 2 - Missing critical] Reference scan needed per-record contexts**
- **Found during:** Task 254-06-02 baseline. The bare `populated` token has 58 hits, about 40 of them unrelated list-state markers (`data-ax-state="populated"`, "distinguishes ... populated, ..." test titles, a ratchet ledger, a budget record). Allowing them by path would have been a broad suppression.
- **Fix:** `reference_scan.contexts` (regex patterns for real variation references: atom, `||id` key, `variation_id=id`, variation_id/scenario_id lines). Each context must find a reference at the origin commit before its zero result counts; two frozen-literal files (the manifest source and its test) are allowed by path. Self-test scenario added.
- **Files modified:** verify_phase254_curation.mjs, subscription_manifest.ex. **Commit:** fdcd6c4eb

**3. [Rule 2 - Missing critical] Verifier schema extensions the plan did not list**
- `additional_survivors` (the merge and the retire name two survivors each), `alias_evidence`, `shape_evidence` (story-source duplicate evidence for a record whose subject is not a manifest entry) and `record_ids` on AMD-254-01. The plan's `duplicateEvidenceAtCommit` is implemented as specified for manifest subjects; the shape variant is the same function. All additive, all with negative controls. **Commits:** fdcd6c4eb, ee6eace31

**4. [Rule 3 - Blocking] Files outside the plan's list**
- `subscription_manifest_test.exs` changed in Task 1 as well as Task 3 (entry count, duplicate-evidence test, origin-commit assertion and curation_record loop all depended on populated being a live entry), `scripts/ci/generate_phase252_acceptance.test.mjs` (its fixture copied the committed ledger and renders 15 rows, so it now carries the ledger with records cleared as the frozen-baseline positive control), and `accrue_admin/e2e/phase252-story-helpers.js` (a dead `populated` branch in `assertActionAvailability` that the exact-token scan flagged).
- `scripts/ci/fixtures/phase252-transparency/heldout-clean.json` was not edited: it embeds a stripped `CadenceSubscriptionFacts.list()` block with no ordinary list, so removing `:populated` does not change what it evaluates; `verify_phase252_transparency.mjs --self-test` passes unchanged. `storybook/phase252-manifest.json` freshness is still checked by decoded JSON.

**5. [Rule 3 - Blocking] Stale local build**
- `CadenceSubscriptionFacts` is compiled into the `subscription_scenarios` BEAM from `dev_support`, which is not an external resource, so after the facts edit a warm local `_build` served the old list. `MIX_ENV=test mix compile --force` fixed it locally; the Phase 252 aggregate builds cold and CI is clean, so no source change.

**6. [Rule 3 - Blocking] Co-author trailer**
- Commits carry `Co-Authored-By: Claude Sonnet 5.5`, following the harness attribution as in 254-04 and 254-05.

### TDD note

Task 254-06-01 changes tests only and its behaviour (follows the ledger) cannot go RED against unchanged sources, so it has a built-in mutation control (a synthetic ledger in the same file) instead of a RED commit. Tasks 02 and 03 add verifier behaviour whose scenarios were written alongside it (24-scenario self-test, each with a paired passing control); there is no separate RED commit, as in 254-04 Task 01.

### Noted, not changed

- Regenerating `storybook/phase252-manifest.json` can reorder keys inside entries; this run produced only the real removal and digest changes. The freshness contract compares decoded JSON.
- The tracked `accrue_admin/tmp/phase252/render-results.json` was not rewritten by this run and still lists the retired populated cells (15 rows). It is a historic tracked artifact; the gate reads the per-run bundle (14 rows). Not touched.

## Known Stubs

None.

## Threat Flags

None. T-254-11 held (held-out refute assertions unchanged; transparency self-test passes), T-254-12 mitigated (both survivors exist in discovery and the preserved regressions are in required lanes, checked by the verifier), T-254-SC held (no installs, D-01).

## Open flags for later plans

- **Owner awareness, merge shape definition:** CUR-254-07's duplicate evidence compares story state, group label sequence and item kinds (danger or standard). provider_pruned has one item and danger has two, and their description text differs; those are not part of the shape. This follows the plan's "group-shape equality with danger", but a stricter reading (item-for-item equality) would have kept the variation. The reason text on the record states the difference.
- The `manifest_sha256` restamp of the budget record is still deferred to 254-09-02 (the tracked manifest changed twice in this plan).
- 254-07 may want the ledger, the curation verifier and the story sources under `CONSUMED_ROOTS` (noted by 254-04); unchanged here.
- KR-254-06 (docs-contracts SL-G and Executable UAT red until 254-18) is untouched and owner-accepted.
- CURATE-01 is advanced, not completed: 254-17 and 254-18 also declare it.

## Self-Check: PASSED

Modified files exist; commits 9b40acc8e, fdcd6c4eb and ee6eace31 are ancestors of HEAD; `git rev-list --count 7284de521..HEAD` measured 3 before this summary commit; the three task verifies, the wave-boundary gate (21/21 and 10 lanes with 151 cells), the curation verifier (default and `--results-latest`), the 104 node tests, the 24-scenario self-test, the script-guard contract, the sensitive-token census and the no-home-paths hook all pass.

---
*Phase: 254-recurring-quality-reviewed-fixes-and-curation*
*Completed: 2026-10-29*
