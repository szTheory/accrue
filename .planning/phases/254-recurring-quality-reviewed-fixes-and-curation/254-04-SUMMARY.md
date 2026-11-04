---
phase: 254-recurring-quality-reviewed-fixes-and-curation
plan: "04"
subsystem: testing
tags: [curation, storybook, ledger, node-test, exunit, phase252, d-39, amd-254-01]

requires:
  - phase: 254-recurring-quality-reviewed-fixes-and-curation
    provides: 254-02 guarded CI scripts (shared module-boundary idiom) and 254-03 CI-runner observation of the Phase 252/253 lanes
  - phase: 252-production-backed-subscription-stories
    provides: the six-entry tracked manifest, the 15-row browser contract and the caller-map guide this plan curates
provides:
  - a compiled curation ledger (SubscriptionManifest.curation_ledger/0) generated to accrue_admin/storybook/subscription-curation.json and rendered into guides/subscription-story-coverage.md
  - a pinned frozen_baseline (26 subjects at source_commit 986f68b71) that later retirements cannot change
  - scripts/ci/verify_phase254_curation.mjs, a fail-closed ledger verifier with 19 self-test scenarios, expectedPhase252Cells(ledger) and referenceScan
  - the five pinned Phase 252 count sites (stories verifier, acceptance validator, reporter bindings, acceptance test regex, manifest ExUnit) derived from the ledger
  - CUR-254-01..05 (three primitive retains, two reclassifications) and amendment AMD-254-01
affects: [254-06, 254-07, 254-09, 254-17, 254-18]

actuals:
  tokens: 36149
  tasks: 3
  commits: 5

tech-stack:
  added: []
  patterns:
    - "Generated JSON ledger with a pinned frozen baseline re-derived from git history by its verifier (git show <source_commit>:<path>) and a named fail-closed error when the commit is unreachable"
    - "Subject digests are computed over a list-of-lists JSON form because BEAM map key order is not alphabetical"
    - "Duplicate evidence is the subject and survivor fact/expected blocks themselves, deep-compared by the verifier and cross-checked against the frozen manifest, never a boolean flag"

key-files:
  created:
    - accrue_admin/storybook/subscription-curation.json
    - scripts/ci/verify_phase254_curation.mjs
    - scripts/ci/verify_phase254_curation.test.mjs
  modified:
    - accrue_admin/storybook/_support/subscription_manifest.ex
    - accrue_admin/test/accrue_admin/dev/subscription_manifest_test.exs
    - storybook/phase252-manifest.json
    - guides/subscription-story-coverage.md
    - scripts/ci/verify_phase252_stories.mjs
    - scripts/ci/generate_phase252_acceptance.mjs
    - scripts/ci/generate_phase252_acceptance.test.mjs
    - scripts/ci/phase252_reporters.mjs
    - scripts/ci/phase252_reporters.test.mjs

key-decisions:
  - "The ledger carries an additive current block (entries, compatibility ids, registry counts, kitchen test digests) so the verifier can reject registry counts below baseline and changed kitchen digests from data, not by re-deriving them in Node."
  - "Primitive story retains use reason_class null (the enum is reserved for removals) with reason_evidence kind retained_primitive_regression; reason_class duplicate is rejected for any retain or reclassify."
  - "Reclassify records carry a classification string; manifest entries gain curation_record and curation_classification (null for unaffected entries) so the guide and manifest agree without renaming any variation."
  - "The ledger JSON is written through Jason.OrderedObject so its bytes are stable across builds; the tracked manifest keeps its existing decoded-equality freshness contract."

patterns-established:
  - "A removal record is checked against the frozen manifest: its duplicate blocks must equal what the frozen entries produce, so a hand-written equal pair is rejected"
  - "referenceScan filters git grep -F candidates through an identifier-boundary regex so UI-E2-populated and prefixed ids never count, and a seeded positive is found before any zero is accepted"

requirements-completed: []
requirements-advanced: [CURATE-01]

coverage:
  - id: D1
    description: "A maintainer can read retain and reclassify records with reachability, reason, survivor and preserved regressions, generated from the compiled manifest and mechanically verified"
    requirement: CURATE-01
    verification:
      - kind: unit
        ref: "node scripts/ci/verify_phase254_curation.mjs --self-test (19 scenarios) and node --test scripts/ci/verify_phase254_curation.test.mjs (32 pass)"
        status: pass
      - kind: integration
        ref: "node scripts/ci/verify_phase254_curation.mjs (regenerates through mix, decoded equality with the committed ledger, frozen subjects re-derived from source_commit) and --results-latest (survivors present in rendered results)"
        status: pass
      - kind: unit
        ref: "accrue_admin/test/accrue_admin/dev/subscription_manifest_test.exs via mix run --no-start (19 ExUnit tests including ledger shape, byte-identical regeneration and the injected-writer interruption)"
        status: pass
    human_judgment: false
  - id: D2
    description: "No pinned Phase 252 count can silently contradict the ledger; the frozen 15/12/3 and 6 entries survive as positive controls"
    requirement: CURATE-01
    verification:
      - kind: unit
        ref: "node --test scripts/ci/generate_phase252_acceptance.test.mjs scripts/ci/phase252_reporters.test.mjs scripts/ci/verify_phase254_curation.test.mjs (99 pass, mutation fixtures: 15 rows against a one-retirement ledger and 14 against frozen-only fail at every site; a missing ledger throws)"
        status: pass
      - kind: integration
        ref: "npm --prefix accrue_admin run phase252:check (21 commands passed, 15 browser rows from the ledger-derived expectation)"
        status: pass
    human_judgment: false
  - id: D3
    description: "braintree_pruned and dunning_active are retained and reclassified with the Phase 195 recovery-claim drift and the page-tier uncovered state recorded; the guide lists CUR-254-01 through CUR-254-05 deterministically"
    requirement: CURATE-01
    verification:
      - kind: unit
        ref: "subscription_manifest_test.exs: braintree_pruned and dunning_active are retained and reclassified..., the regenerated guide lists every curation record..."
        status: pass
    human_judgment: false

duration: 40min
completed: 2026-10-29
status: complete
commits: 5
plan_head_before: 986f68b71bae643ce24f0906c39d072fe5ea117b
plan_head_after: a431adf83643eca1fa54890cc93fa2aa84d8fa27
---

# Phase 254 Plan 04: Curation ledger, derived counts and reclassifications (W2) Summary

**SubscriptionManifest now compiles a curation ledger with a pinned 26-subject frozen baseline, a fail-closed verifier re-derives that baseline from git history, and all five pinned Phase 252 count sites follow the ledger instead of the literal 15.**

## Performance

- **Duration:** about 40 min
- **Tasks:** 3 (5 commits: 3 feat, 2 RED test)
- **Files modified:** 12 (3 created)

## Accomplishments

- `SubscriptionManifest.curation_ledger/0`, `frozen_baseline/0`, `write_curation!/2` (temp file plus rename, injectable writer) and `verify_curation!/1`; the ledger is generated to `accrue_admin/storybook/subscription-curation.json` and rendered as a "Curation ledger" section of the existing guide (path unchanged).
- `scripts/ci/verify_phase254_curation.mjs`: regenerates through mix and compares decoded JSON, re-derives `frozen_baseline.subjects` from `git show <source_commit>:<path>`, rejects every D-39 rule listed in the plan (grep-absence and screenshot-similarity evidence, near-equal duplicates, absent subjects, drifted subjects and digests, absent survivors, missing or off-lane regressions, registry counts below baseline, changed kitchen digests, `/dev/components` subjects, missing baseline or AMD-254-01, unsorted records, count mismatches), with a positive control per scenario.
- Five count sites derive from `expectedPhase252Cells(ledger)`: `verify_phase252_stories.mjs` (`assertRenderRowCounts`), `generate_phase252_acceptance.mjs` (`assertEvidenceRowCounts`), `phase252_reporters.mjs` (`browserBindings`), the acceptance test regex and the manifest ExUnit entry count. Assertion id strings are unchanged.
- CUR-254-04 and CUR-254-05 reclassify `braintree_pruned` (provider-boundary negative) and `dunning_active` (recovery-claim drift: Phase 195 "recovery drill open" now only a Dunning row; page-tier past-due recovery uncovered, gated on retry/campaign-history integrity).

## Evidence values (plan verification record)

- Records: CUR-254-01 detail, CUR-254-02 overlay, CUR-254-03 page_header (retain); CUR-254-04 braintree_pruned, CUR-254-05 dunning_active (reclassify). No retire or merge record exists yet (254-06).
- frozen_baseline: `source_commit` 986f68b71bae643ce24f0906c39d072fe5ea117b; entries 6; compatibility ids `braintree_pruned`, `dunning_active`, `populated`; registry 30 families, 42 entries, 75 specimens; manifest_sha256 e321f5210f3d2e1604eb4f14e52a67dc52362d35f400309ea5247ee61164adbf (the manifest at source_commit); 26 subjects (5 action_menu, 4 detail, 5 overlay, 6 page_header, 6 subscription_detail) with subjects_sha256 1082c32dfd875980f87ca450f77bbe70c26c039d6c61c429a60aaa6ac2a80905; four kitchen test digests pinned.
- AMD-254-01: decisions D-06, D-14, D-39, D-40; original "15/151 live full-mode count"; amended "15 kept as frozen_baseline fixture positive control, live count ledger-derived (14 after 254-06)"; owner_ack `{date: 2026-10-28, status: owner-accepted at plan time}`; evidence markers in the five count sites.
- Regenerated manifest digest after the final commit: `storybook/phase252-manifest.json` sha256 3379adeed6c20705c417c5d585330cc03d3ac68f0bda265b142307be2f77daf8 (ledger b25f53f9ecdd3fb5a7a6c1d0730b96085fb93f96de7e5126c501dd5b27bfc157).
- Wave-boundary gate: `npm --prefix accrue_admin run phase252:check` passed 21 of 21 commands (cold compile 84 s, browser lane 13 s) and `node scripts/ci/verify_phase254_curation.mjs` plus `--results-latest` passed.

## Task Commits

1. **Task 254-04-01: ledger, JSON, guide, verifier, three retain records** - `022d42765` (feat)
2. **Task 254-04-02: derive the five count sites** - RED `e1d230e21` (test), GREEN `413bb6bd5` (feat)
3. **Task 254-04-03: reclassify braintree_pruned and dunning_active** - RED `87e4f1b5c` (test), GREEN `a431adf83` (feat)

**Plan metadata:** recorded in the docs commit that follows this summary.

## Files Created/Modified

- `accrue_admin/storybook/_support/subscription_manifest.ex` - ledger, frozen baseline, duplicate evidence, atomic writer, guide section, entry curation metadata
- `accrue_admin/storybook/subscription-curation.json` - generated ledger
- `scripts/ci/verify_phase254_curation.mjs` and `.test.mjs` - verifier, 19 scenarios, 32 node tests
- `scripts/ci/verify_phase252_stories.mjs`, `generate_phase252_acceptance.mjs`, `phase252_reporters.mjs` (and their tests) - ledger-derived counts
- `storybook/phase252-manifest.json`, `guides/subscription-story-coverage.md` - regenerated through their owners in the same commits as every edit to subscription_manifest.ex (B-1)

## Decisions Made

See key-decisions. The D-06/D-14 versus D-40 conflict is closed as AMD-254-01, owner-accepted at plan time; no checkpoint was raised.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] The plan's lab verification command cannot run the manifest ExUnit file**
- **Found during:** Task 254-04-01 baseline
- **Issue:** `phase252_lab.mjs exec ... -- mix test <file>` runs from the repository root (no Mix project) and, with the lab's repo started, fails the file's own `Process.whereis(AccrueAdmin.TestRepo) == nil` DB-free assertion. The Phase 252 aggregate runs this file as `cd accrue_admin && MIX_ENV=test mix run --no-start test/accrue_admin/dev/subscription_manifest_test.exs` (a db-free lane).
- **Fix:** every ExUnit verification here uses that db-free form (19 tests, 0 failures, 0 skips); no lab is needed for this file.
- **Files modified:** none (verification command only)

**2. [Rule 2 - Missing critical] Additive `current` block in the ledger**
- **Issue:** the plan lists the ledger keys as `schema_version, frozen_baseline, records, amendments, source_digests`, but "registry counts below baseline" and "changed kitchen digest" need the current values as data.
- **Fix:** an additive `current` block (entries, compatibility ids, registry counts, kitchen test digests), also compared against the tracked manifest by the verifier.
- **Files modified:** subscription_manifest.ex, verify_phase254_curation.mjs
- **Commit:** 022d42765

**3. [Rule 2 - Missing critical] Duplicate evidence is the blocks, cross-checked against the frozen manifest**
- **Issue:** the plan says "fact/expected-block equality flags"; a flag could be hand-written true.
- **Fix:** records carry the subject and survivor `fact`/`expected` blocks, the verifier deep-compares them and re-derives them from the frozen manifest at `source_commit`, so a forged equal pair is rejected (scenario "duplicate blocks that do not match the frozen manifest entry").
- **Commit:** 022d42765

**4. [Rule 3 - Blocking] Co-author trailer**
- The harness attribution reminder names `Claude Sonnet 5.5` while the orchestrator prompt names `Claude Opus 5.5` (and the six previous commits used Opus). I followed the harness attribution, so all five commits of this plan carry `Co-Authored-By: Claude Sonnet 5.5` (the first commit was amended once, locally, before any push, to correct its trailer).

### TDD note

Task 254-04-01 wrote the verifier and ledger before the tests that exercise them, so it has no separate RED commit; the substitute is that every verifier rule has a scenario that must throw and a paired scenario that must pass, run against the same code (19 scenarios). Tasks 02 and 03 have genuine RED commits (`e1d230e21`, `87e4f1b5c`), each failing on the intended assertion before the GREEN commit.

### Noted, not changed

- Regenerating `storybook/phase252-manifest.json` reorders the keys inside each entry (BEAM map key order), producing a large reorder-only diff next to the real digest changes. The freshness contract compares decoded JSON, so it is correct; the ledger itself avoids the problem through `Jason.OrderedObject`.
- The Phase 252 evidence bundle's source snapshot does not include the ledger or the new verifier. A stale bundle still fails closed (its row count would disagree with the ledger), so no hole exists, but 254-07 may want both under `CONSUMED_ROOTS` so a PR touching only them is classified.
- `accrue_admin/tmp/phase252/render-results.json` stayed unmodified in this run.

## Known Stubs

None.

## Threat Flags

None. No new network endpoint, auth path or trust-boundary file access was added; T-254-07 (repudiation) and T-254-08 (tampering) are mitigated as planned and T-254-SC held (no installs, D-01).

## Open flags for later plans

- 254-06 owns the retire and merge records (`subscription_detail||populated`, `action_menu/provider_pruned`), the literal removal edits, the stale gap-row corrections and the `15 -> 14` browser count; the ledger-derived sites already follow without further edits.
- The `manifest_sha256` restamp of the budget record is still deferred to 254-09-02; the recipe step R3 and R4 do not exist yet.
- CURATE-01 is advanced, not completed: 254-06, 254-17 and 254-18 also declare it.

## Self-Check: PASSED

Created files exist (subscription-curation.json, verify_phase254_curation.mjs and its test, this summary); commits 022d42765, e1d230e21, 413bb6bd5, 87e4f1b5c and a431adf83 are ancestors of HEAD; `git rev-list --count 986f68b71..HEAD` measured 5 before this summary commit; the three task verifies, the curation verifier (default and `--results-latest`), the 99 node tests, the 19 ExUnit tests, the script-guard contract, the census and the no-home-paths check all pass; `phase252:check` passed 21/21.

---
*Phase: 254-recurring-quality-reviewed-fixes-and-curation*
*Completed: 2026-10-29*
