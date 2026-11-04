---
phase: 252-production-backed-subscription-stories
reviewed: 2026-10-27T15:14:51Z
depth: standard
files_reviewed: 14
files_reviewed_list:
  - guides/ui-story-lab.md
  - scripts/ci/fixtures/phase252-transparency/heldout-clean.json
  - scripts/ci/fixtures/phase252-transparency/heldout-violation.json
  - scripts/ci/fixtures/phase252-transparency/lab-clean.json
  - scripts/ci/fixtures/phase252-transparency/lab-violation.json
  - scripts/ci/generate_phase252_acceptance.mjs
  - scripts/ci/generate_phase252_acceptance.test.mjs
  - scripts/ci/phase252_paths.mjs
  - scripts/ci/phase252_reporters.mjs
  - scripts/ci/verify_phase252_ci_contract.test.mjs
  - scripts/ci/verify_phase252_heldout_attribution.test.mjs
  - scripts/ci/verify_phase252_lab_presentation.test.mjs
  - scripts/ci/verify_phase252_stories.mjs
  - scripts/ci/verify_phase252_transparency.mjs
findings:
  critical: 2
  warning: 0
  info: 0
  total: 2
status: issues_found
---

# Phase 252: Code Review Report

**Reviewed:** 2026-10-27T15:14:51Z
**Depth:** standard
**Files Reviewed:** 14
**Status:** issues_found

## Summary

The 09/10 increment adds useful named reporter checks and source-backed transparency controls, but two gaps can still let acceptance evidence omit prohibition metadata or drift from the phase plan used to define coverage. The prior 01–08 review context is retained below and is not included in this increment’s finding counts. No tests or aggregate suites were rerun for this review.

## Narrative Findings (AI reviewer)

### Critical Issues

### CR-03: Extra malformed prohibition entries are silently ignored

**Severity:** BLOCKER
**File:** `scripts/ci/generate_phase252_acceptance.mjs:419-463`

**Issue:** `collectProhibitions` counts only list rows containing `statement:`. After finding the expected statement, it limits field validation to the chunk before the next list item, but never rejects or parses that next item. A plan can therefore add a second malformed entry such as `- status: unresolved` without a `statement:` field; the generator ignores it, returns only the original resolved descriptor, and reports no unresolved prohibitions. This is a fail-open path for the prohibition inventory.

**Fix:** Parse and validate every item in the `prohibitions` list, and reject extra or malformed entries. For the two original plans, require exactly one list item with the expected flat descriptor fields; add a regression case with a second item missing `statement:` and require acceptance to fail.

### CR-04: Plans 09/10 used for coverage are absent from the freshness snapshot

**Severity:** BLOCKER
**File:** `scripts/ci/verify_phase252_stories.mjs:48-64`; `scripts/ci/generate_phase252_acceptance.mjs:272-282, 466-496`

**Issue:** The runner fingerprints `ORIGINAL_PROHIBITION_PLANS` (plans 01 and 04), but `inspectPlanSources` reads all ten plan files and derives task IDs from plans 09 and 10. `validateSourceSnapshot` only verifies paths already present in the bundle digest map. A change to either newly consumed plan during the aggregate run therefore does not change the before/after source fingerprint, while the final acceptance step reads the changed plan and can bind the run’s results to metadata from a different plan state. Matching task IDs do not establish that the task criteria remained unchanged.

**Fix:** Include every plan and validation artifact read to construct acceptance metadata in the runner’s source snapshot, and require those digests during acceptance validation. Preserve the logical phase paths while resolving their bytes through the archive-aware phase evidence resolver. Add a contract test that edits a 09/10 plan after fixture bundle creation and expects stale-source rejection.

## Historical Review Context (pre-09 increment)

The earlier review covered 54 files and reported two findings. They are retained here as history, not rescored in the 09/10 increment:

- **CR-01 — Storybook theme check adds the missing application scope** (`accrue_admin/e2e/phase252-story-helpers.js:628`): the prior report said the helper mutated the document root before checking theme tokens, masking the direct Storybook route’s styling. Its suggested fix was to correct the real Storybook styling scope and remove the mutation. This increment did not re-review that browser implementation.
- **CR-02 — Passing exit codes turn skipped required tests into passing evidence** (`scripts/ci/verify_phase252_stories.mjs`, prior version): the prior report said the runner accepted zero exit codes and copied planned assertion labels without validating executed identities. The 09/10 reporter changes now parse TAP and bind required assertions to source-derived executed test names; this historical finding is not counted as current.

---

_Reviewed: 2026-10-27T15:14:51Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
