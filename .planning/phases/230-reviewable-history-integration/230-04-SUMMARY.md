---
phase: 230-reviewable-history-integration
plan: 04
subsystem: infra
tags: [git, integration, evidence, ci, excluded-commit-ledger, patch-id]

requires:
  - phase: 230-reviewable-history-integration
    plan: 02
    provides: refs/heads/integration/v1.62-candidate (single --no-ff merge, never pushed) and the collect/render/verify disposition triad
  - phase: 230-reviewable-history-integration
    plan: 03
    provides: the hazard-universe half of the disposition triad this plan extends with a second artifact pair
provides:
  - "230-DISPOSITIONS.{json,md}: an evidence-backed, machine-checked ledger recording exactly one row for every commit reachable from local main and not reachable from the candidate (80 rows: 27 excluded-rejected, 53 excluded-superseded), plus an explicit carried-on-candidate row (afddc87c, D-12) and a published_elsewhere row (5da8e6b8, D-13)."
  - "--require-excluded-ledger and --dispositions on verify_integration_disposition.mjs: exact sorted-multiset completeness (assertSameMultiset) between the live recomputed excluded set and the committed rows, a literal-integer excluded_commit_count assertion, duplicate-commit-key rejection, and the STALE_BINDING refusal -- independently provable with no other --require-* flag present."
  - "PR #44's live facts recorded without closing it: head is local main plus 4 commits (0 behind, 4 ahead), all 4 recomputed live and patch-id-matched to the milestone branch's 2de4389b/9eae363a/173607d9/5653216c; disposition close-unmerged-cite-superseding, closure deferred to Plan 230-06 (D-10/D-11)."
  - "renderExcludedLedger: leads with excluded-rejected and carried-on-candidate (the dispositions that change a reader's mental model), collapses excluded-superseded into one shared-evidence group, and renders every commit's full 40-hex id so grep <sha> answers where a commit went in under a minute."
affects: [230-06, 230-07, 231-exact-sha-release-gate-proof, 232-bounded-hygiene-release-handoff]

actuals:
  tokens: 63946
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "A file-descriptor-piped git log -p | git patch-id --stable bulk pass (bulkPatchIdFrequency) instead of one spawnSync per commit -- computing patch-id occurrence counts over a ~500-commit, ~350MB candidate history through Node's spawnSync input/stdout string buffers hits OS pipe limits (ENOBUFS) well before any maxBuffer ceiling; routing both legs through temp-file file descriptors avoids ever holding that diff text as one JS string."
    - "superseded_by is the literal sentinel no-equivalent for every wholesale-excluded row (D-07's exclusion is at tree/requirement level, not a per-commit 1:1 cherry-pick mapping) except the carried-on-candidate row, whose superseded_by is [itself] since it is already present on the candidate unchanged."
    - "The excluded-commit ledger and PR #44's ledger entry share one collector/validator/renderer module (collect_integration_disposition.mjs / render_integration_disposition.mjs), a third artifact-pair instance of the established collect->render->verify triad, distinct from Plan 230-03's hazard-universe disposition pair."
    - "disposition classification (excluded-rejected vs excluded-superseded) is recomputed live via a `git log <candidate>..<local-main> --format=%H -- <salvage-paths>` path filter, never a hardcoded SHA list -- D-15's 'never transcribe' discipline extended to a second dimension of the same fact set."

key-files:
  created:
    - .planning/phases/230-reviewable-history-integration/230-DISPOSITIONS.json
    - .planning/phases/230-reviewable-history-integration/230-DISPOSITIONS.md
  modified:
    - scripts/ci/collect_integration_disposition.mjs
    - scripts/ci/verify_integration_disposition.mjs
    - scripts/ci/render_integration_disposition.mjs

key-decisions:
  - "superseded_by is the literal no-equivalent sentinel for all 80 excluded rows rather than an attempted per-commit successor mapping: D-07's exclusion is proven wholesale at tree level (3 known files absent from the candidate, superseded by the .mjs triad) and requirement level (BASE-01/BASE-02 Complete), not by matching any individual abandoned commit to a specific candidate-side commit -- no such 1:1 mapping exists, and asserting one would be false precision."
  - "Excluded-rejected classification (D-08's salvage candidates) is computed by a live path filter over the 4 files a maintainer would recognize as the rejected shell-baseline implementation (capture_ci_baseline.sh, verify_ci_baseline_contract.sh, ci_baseline_workflow_policy.json, .github/workflows/ci.yml), recomputed at execution time -- 27 of the 80 excluded commits touch these paths and are excluded-rejected; the remaining 53 are excluded-superseded."
  - "ledger.candidate.committed_at was added to the schema (not in the original plan's field list) so the renderer could stay a pure validate-then-render function per D-38's discipline, sourcing its timestamp from a value already embedded in the collected JSON (git show --format=%cI at collection time) rather than calling git itself or Date.now() at render time."
  - "The empty excluded-commit fixture and the PR-branch matching fixture required two distinct local-main refs (main with 2 excluded commits, and empty-main pointing at their shared base) plus two distinct PR-branch refs, so the PR ahead/behind computation in each scenario measures unique commits relative to the SAME local-main ref the ledger itself uses -- a mismatch there produced a spurious 'no patch-id match' failure during development, caught and fixed before this plan's tests were finalized."

requirements-completed: []

coverage:
  - id: T1
    description: "Every commit in the live git rev-list <local-main> ^<candidate> output (80 commits) has exactly one ledger row, keyed by 40-hex commit id, classified excluded-superseded or excluded-rejected from a live path-filter recomputation (never transcribed); superseded_by is always present (no-equivalent sentinel or an array of candidate-side commit ids); patch_id_occurrences_main/candidate are recomputed integers via a bulk git log -p | git patch-id pass; the 5da8e6b8 row carries published_elsewhere naming origin/phase-226-baseline-5da8e6b88735; the afddc87c row carries disposition carried-on-candidate; tree-level evidence records existence-on-candidate for all three abandoned shell-baseline files; requirement-level evidence cites BASE-01/BASE-02 Complete rows from v1.61-REQUIREMENTS.md; git cherry is never used as supersession proof."
    requirement: "INTG-02"
    verification:
      - kind: unit
        ref: "node --test scripts/ci/collect_integration_disposition.mjs (15/15 pass, incl. the excluded-commit-ledger fixture, structural row-validation fixtures, and PR44-validation fixtures)"
        status: pass
      - kind: integration
        ref: "node -e (collectExcludedCommitLedger against the real repository): 81 rows (80 excluded + 1 carried), 27 excluded-rejected / 53 excluded-superseded / 1 carried-on-candidate, patch-id occurrences all integers via node -e type-check"
        status: pass
      - kind: unit
        ref: "grep -n 'git cherry' scripts/ci/collect_integration_disposition.mjs returns nothing"
        status: pass
    human_judgment: false
  - id: T2
    description: "--require-excluded-ledger asserts exact sorted-multiset equality between the live recomputed excluded set and the committed rows, a literal-integer excluded_commit_count, rejects a duplicate commit key, passes on an empty excluded set with a recorded count of 0, and is independently provable with no other --require-* flag present."
    requirement: "INTG-03"
    verification:
      - kind: unit
        ref: "node --test scripts/ci/verify_integration_disposition.mjs (1/1 suite pass, incl. clean pass, empty-set pass, missing row, obsolete/extra row, duplicate key, null/omitted superseded_by, and boolean patch_id_occurrences_main fixtures)"
        status: pass
      - kind: integration
        ref: "node scripts/ci/verify_integration_disposition.mjs --fixtures --require-excluded-ledger (no other --require-* flag) -- fixtures: PASS, exit 0"
        status: pass
      - kind: integration
        ref: "node scripts/ci/verify_integration_disposition.mjs --fixtures --expected-repository szTheory/accrue --require-excluded-ledger -- fixtures: PASS, exit 0"
        status: pass
    human_judgment: false
  - id: T3
    description: "230-DISPOSITIONS.md leads with excluded-rejected and carried-on-candidate, collapses excluded-superseded into one shared-evidence group, renders every excluded/carried commit's full 40-hex id (grep-verified against all 81 committed rows, 0 missing), renders published_elsewhere for the 5da8e6b8 row, re-renders byte-identically from the committed JSON regardless of input row order, uses no Date.now(), and leaves scripts/ci/README.md untouched (Plan 230-06 owns it)."
    requirement: "INTG-02"
    verification:
      - kind: unit
        ref: "node --test scripts/ci/render_integration_disposition.mjs (12/12 pass, incl. section-order, grep-verbatim-sha, published_elsewhere, and shuffle-determinism fixtures)"
        status: pass
      - kind: integration
        ref: "node scripts/ci/verify_integration_disposition.mjs --dispositions .../230-DISPOSITIONS.json --dispositions-rendered .../230-DISPOSITIONS.md --expected-repository szTheory/accrue --require-excluded-ledger --require-determinism (real repository) -- PASS"
        status: pass
      - kind: integration
        ref: "node scripts/ci/verify_integration_disposition.mjs --records .../230-INTEGRATION-DISPOSITION.json --rendered .../230-INTEGRATION-DISPOSITION.md --dispositions .../230-DISPOSITIONS.json --candidate integration/v1.62-candidate --expected-repository szTheory/accrue --require-excluded-ledger --require-determinism (real repository) -- PASS"
        status: pass
      - kind: unit
        ref: "grep -n 'Date.now()' scripts/ci/render_integration_disposition.mjs returns nothing; git status --short scripts/ci/README.md returns nothing (untouched)"
        status: pass
    human_judgment: false

duration: ~110 min
completed: 2026-09-15
status: complete
commits: 3
plan_head_before: f8103f72a58050770d19b00c9d2b23ffe4f19214
---

# Phase 230 Plan 4: Excluded-Commit Ledger and PR #44 Disposition Summary

**Recomputes the live 80-commit excluded set (`git rev-list <local-main> ^<candidate>`), gives every commit an evidence-backed disposition proved at tree and requirement level (never `git cherry`), and records PR #44's live ahead/behind and patch-id-matched facts without closing it -- committed as `230-DISPOSITIONS.{json,md}` with exact-multiset completeness and byte-deterministic rendering.**

## Performance

- **Duration:** ~110 min
- **Started:** 2026-09-15
- **Completed:** 2026-09-15
- **Tasks:** 3
- **Files modified:** 5 (3 scripts, 2 new evidence artifacts)

## Accomplishments

- `scripts/ci/collect_integration_disposition.mjs` gained `collectExcludedCommitLedger`: recomputes `git rev-list <local-main> ^<candidate>` live (80 commits on the real repository), classifies each as `excluded-rejected` (27, via a live path filter over the four files that constitute D-08's rejected shell-baseline salvage candidate) or `excluded-superseded` (53), records `afddc87c` as `carried-on-candidate` and `5da8e6b887354eded1b6dc25968ad7679d6bbd83` with `published_elsewhere: "origin/phase-226-baseline-5da8e6b88735"`, and proves supersession at tree level (existence sweep over `capture_ci_baseline.sh`/`verify_ci_baseline_contract.sh`/`ci_baseline_workflow_policy.json` plus a live plan-inventory count: abandoned line reached plan 11, milestone line reached plan 21) and requirement level (`BASE-01`/`BASE-02` Complete rows cited verbatim from `v1.61-REQUIREMENTS.md`). Patch-id occurrence counts are recomputed integers via a new `bulkPatchIdFrequency` helper that pipes `git log -p | git patch-id --stable` through temporary file descriptors rather than Node's string-based `spawnSync` buffers -- the candidate's ~500-commit, ~350MB diff history overflowed the OS pipe (`ENOBUFS`) under the naive approach.
- PR #44's live facts are recorded via `collectPr44Ledger`: head `3f8338cd` is local main plus 4 commits (0 behind, 4 ahead), and all 4 are recomputed patch-id matches against the milestone branch's `5653216c`/`2de4389b`/`9eae363a`/`173607d9` -- exactly reproducing D-10's measured claim independently. Disposition `close-unmerged-cite-superseding`; the PR is not closed (D-11 defers closure to Plan 230-06).
- `scripts/ci/verify_integration_disposition.mjs` gained `--require-excluded-ledger` and `--dispositions`: recomputes the live excluded set and asserts exact sorted-multiset equality against the committed rows (reusing `assertSameMultiset`), asserts `excluded_commit_count` as a literal integer, rejects duplicate commit keys via `exactMap`, and reuses the `STALE_BINDING` refusal. Independently provable with no other `--require-*` flag present.
- `scripts/ci/render_integration_disposition.mjs` gained `renderExcludedLedger`: leads with `excluded-rejected` and `carried-on-candidate` (the dispositions that change a reviewer's mental model), collapses the 53 `excluded-superseded` rows into one shared-evidence group, renders every excluded/carried commit's full unescaped 40-hex id (grep-verified: 0 of 81 committed rows missing from the rendered Markdown), and renders `published_elsewhere` prominently for the `5da8e6b8` row. Timestamps come from `ledger.candidate.committed_at` (captured via `git show --format=%cI` at collection time, a new schema field added so the renderer stays a pure validate-then-render function), never `Date.now()`.
- `.planning/phases/230-reviewable-history-integration/230-DISPOSITIONS.{json,md}` regenerated and committed against the real repository; `--require-excluded-ledger --require-determinism` PASS both standalone (against the ledger pair alone) and alongside `--require-ancestry`/`--require-scope`/`--require-hazard-universe`/`--require-post-merge-scope` (against the full disposition triad). `scripts/ci/README.md` is untouched (Plan 230-06 owns it, per this plan's own acceptance criteria).

## Task Commits

1. **Task 1: Recompute the excluded-commit set and prove supersession at tree and requirement level** - `ecd61837` (feat)
2. **Task 2: Exact-multiset ledger completeness with empty-set and equal-key semantics** - `5c1eabe0` (feat)
3. **Task 3: Render the ledger and prove it answers "where did commit X go?"** - `6e1dbf8e` (feat)

**Plan metadata:** (this commit) - `docs(230-04): complete plan`

## Files Created/Modified

- `scripts/ci/collect_integration_disposition.mjs` - `collectExcludedCommitLedger`, `collectPr44Ledger`, `bulkPatchIdFrequency`, `collectTreeLevelEvidence`, `collectRequirementLevelEvidence`, full excluded-row/PR-44/ledger validators
- `scripts/ci/verify_integration_disposition.mjs` - `--require-excluded-ledger`, `--dispositions`, `--dispositions-rendered`, `--local-main-ref`, `assertExcludedLedgerLive`, ledger determinism wiring
- `scripts/ci/render_integration_disposition.mjs` - `renderExcludedLedger`, ledger CLI mode (`--ledger-input`/`--ledger-out`)
- `.planning/phases/230-reviewable-history-integration/230-DISPOSITIONS.json` - new: 81 rows (80 excluded + 1 carried), PR #44 facts
- `.planning/phases/230-reviewable-history-integration/230-DISPOSITIONS.md` - new: deterministic rendered ledger

## Decisions Made

See `key-decisions` in frontmatter. Summarized: (1) `superseded_by` is the literal `no-equivalent` sentinel for every wholesale-excluded row rather than an invented per-commit successor mapping, since D-07's exclusion is proven at tree/requirement level, not commit-for-commit; (2) `excluded-rejected` vs `excluded-superseded` classification is a live path-filter recomputation over the four files that constitute D-08's rejected salvage candidate, never a hardcoded SHA list; (3) `ledger.candidate.committed_at` was added to the schema (a small extension beyond the plan's literal field list) so the renderer could stay pure per D-38; (4) the empty-excluded-set and PR-matching test fixtures needed two distinct local-main refs and two distinct PR-branch refs to keep the ahead/behind computation consistent with whichever local-main ref a given scenario exercises.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `bulkPatchIdFrequency`'s initial string-buffered `spawnSync` pipeline overflowed on the real repository**
- **Found during:** Task 1, first end-to-end run against the real repository
- **Issue:** `git log -p --format=%H <candidateObject>` over the ~500-commit candidate produces ~350MB of diff text; piping that through Node's `spawnSync({ input: ... })` and reading it back via `{ encoding: "utf8" }` stdout hit an OS-level pipe buffer limit (`ENOBUFS`) well before any `maxBuffer` ceiling was reached, regardless of how large `maxBuffer` was set.
- **Fix:** Rewrote the pipeline to route both legs through temporary file descriptors (`git log -p` writes directly to a temp file via `stdio: [..., fd, ...]`; `git patch-id` reads from that file via `stdio: [fd, ...]`) so no multi-hundred-MB string is ever held in the Node process or pushed through a pipe -- only the small (~one line per commit) `git patch-id` output is read back as a string.
- **Files modified:** scripts/ci/collect_integration_disposition.mjs
- **Verification:** `node --input-type=module -e` invocation against the real repository completed in ~5.6s (was previously erroring with `ENOBUFS`); `node --test scripts/ci/collect_integration_disposition.mjs` still 15/15 after the rewrite.
- **Committed in:** `ecd61837` (Task 1 commit)

**2. [Rule 2 - Missing Critical] Renderer needed a non-`Date.now()` timestamp source not in the original field list**
- **Found during:** Task 3
- **Issue:** D-38 requires the renderer to source timestamps from `git show --format=%cI`, never `Date.now()`, but the plan's own field enumeration for `230-DISPOSITIONS.json`'s `candidate` object (`ref`/`object` only) had no timestamp field, and the renderer must stay a pure validate-then-render function (no git calls of its own) per the established pattern in `render_integration_disposition.mjs`.
- **Fix:** Added `ledger.candidate.committed_at`, populated at collection time via `git show -s --format=%cI <candidateObject>` (the same call the existing `collectIntegrationDisposition` already makes for its own `candidate.committed_at`), and consumed it in `renderExcludedLedger`.
- **Files modified:** scripts/ci/collect_integration_disposition.mjs, scripts/ci/verify_integration_disposition.mjs (fixture updates), scripts/ci/render_integration_disposition.mjs
- **Verification:** `grep -n "Date.now()" scripts/ci/render_integration_disposition.mjs` returns nothing; re-render of the real-repository JSON byte-equals the committed Markdown.
- **Committed in:** `6e1dbf8e` (Task 3 commit)

---

**Total deviations:** 2 auto-fixed (1 bug, 1 missing critical)
**Impact on plan:** Both auto-fixes were needed for the collector/renderer to function correctly against the real repository's actual scale and the plan's own determinism requirement (D-38). No scope creep; both stayed inside this plan's own files.

## Issues Encountered

None beyond the two deviations above (both auto-fixed and documented there).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `230-DISPOSITIONS.{json,md}` are committed and evidence-backed; Plan 230-06 can now correct `.planning/STATE.md`'s PR #44 description (D-10 notes it as "intent, not the pushed branch") and close PR #44 unmerged citing the four superseding SHAs recorded in `pr_44.matched_commits`, and add the `scripts/ci/README.md` evidence-table row this plan deliberately left untouched.
- INTG-02 and INTG-03 are also declared by Plans 230-03 (already summarized), 230-05 (already summarized), 230-06, and 230-07 (not yet summarized) -- the shared-ID gate (`requirements.ready-ids` reported `0/1 ready`) correctly keeps them `In Progress` in REQUIREMENTS.md until all declaring plans finish.
- No blockers identified for Plans 230-06 or 230-07 from this plan's work.

---
*Phase: 230-reviewable-history-integration*
*Completed: 2026-09-15*

## Self-Check: PASSED

- FOUND: scripts/ci/collect_integration_disposition.mjs (modified)
- FOUND: scripts/ci/verify_integration_disposition.mjs (modified)
- FOUND: scripts/ci/render_integration_disposition.mjs (modified)
- FOUND: .planning/phases/230-reviewable-history-integration/230-DISPOSITIONS.json (new)
- FOUND: .planning/phases/230-reviewable-history-integration/230-DISPOSITIONS.md (new)
- FOUND commit: ecd61837 (Task 1)
- FOUND commit: 5c1eabe0 (Task 2)
- FOUND commit: 6e1dbf8e (Task 3)
- Re-ran the plan-level `<verification>` items 1-5: all PASS (28/28 unit tests across the three scripts, 0 fail; `--require-excluded-ledger` proved independently pass/fail via fixtures for missing/obsolete/duplicate/empty-set/null-superseded_by/boolean-patch-id scenarios; `--require-determinism` proved both `230-INTEGRATION-DISPOSITION.{json,md}` and `230-DISPOSITIONS.{json,md}` byte-equal a fresh render against the real repository; `grep` of every one of the 81 committed rows' 40-hex commit id over `230-DISPOSITIONS.md` returned its row, 0 missing).
