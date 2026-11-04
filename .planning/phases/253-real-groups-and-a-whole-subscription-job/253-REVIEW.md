---
phase: 253-real-groups-and-a-whole-subscription-job
reviewed: 2026-10-27T22:40:16Z
depth: standard
files_reviewed: 38
files_reviewed_list:
  - .github/workflows/ci.yml
  - .gitignore
  - accrue_admin/assets/css/app.css
  - accrue_admin/e2e/phase253-composition-helpers.js
  - accrue_admin/e2e/subscription-compositions-phase253.spec.js
  - accrue_admin/lib/accrue_admin/live/subscription_live.ex
  - accrue_admin/lib/accrue_admin/live/subscriptions_live.ex
  - accrue_admin/playwright.phase252.config.js
  - accrue_admin/priv/static/accrue_admin.css
  - accrue_admin/priv/static/storybook.css
  - accrue_admin/storybook/_support/subscription_collection.ex
  - accrue_admin/storybook/_support/subscription_compositions_manifest.ex
  - accrue_admin/storybook/_support/subscription_page_scenarios.ex
  - accrue_admin/test/accrue_admin/components/data_table_test.exs
  - accrue_admin/test/accrue_admin/dev/subscription_collection_transport_test.exs
  - accrue_admin/test/accrue_admin/dev/subscription_compositions_manifest_test.exs
  - accrue_admin/test/accrue_admin/dev/subscription_page_slice_test.exs
  - accrue_admin/test/accrue_admin/live/subscription_journey_test.exs
  - accrue_admin/test/accrue_admin/live/subscription_live_test.exs
  - accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs
  - guides/subscription-story-coverage.md
  - scripts/ci/fixtures/phase253-transparency/attribution-violation.json
  - scripts/ci/fixtures/phase253-transparency/clean.json
  - scripts/ci/fixtures/phase253-transparency/presentation-violation.json
  - scripts/ci/generate_phase253_acceptance.mjs
  - scripts/ci/generate_phase253_acceptance.test.mjs
  - scripts/ci/phase252_paths.mjs
  - scripts/ci/verify_executable_uat_contract.mjs
  - scripts/ci/verify_phase200_admin_guardrails.sh
  - scripts/ci/verify_phase200_guardrail_contract.sh
  - scripts/ci/verify_phase252_ci_contract.test.mjs
  - scripts/ci/verify_phase252_transparency.mjs
  - scripts/ci/verify_phase253_compositions.mjs
  - scripts/ci/verify_phase253_compositions.test.mjs
  - scripts/ci/verify_phase253_presentation.test.mjs
  - storybook/groups/subscriptions_collection.story.exs
  - storybook/pages/subscription.story.exs
  - storybook/phase252-manifest.json
findings:
  critical: 2
  warning: 0
  info: 0
  total: 2
status: issues_found
---

# Phase 253: Code Review Report

**Reviewed:** 2026-10-27T22:40:16Z  
**Depth:** standard  
**Files Reviewed:** 38  
**Status:** issues_found

## Narrative Findings (AI reviewer)

The reviewed collection/page rendering and CI changes include extensive current-run evidence checks, but two gaps allow the acceptance pipeline to report a passing result without binding the whole-page renderer and each collection browser cell to the source and test identity it claims. These undermine the source-bound evidence contract and should be fixed before relying on Phase 253 acceptance.

### Critical Issues

#### CR-01: Whole-page renderer is absent from source identity inventories

**Classification:** BLOCKER  
**File:** `accrue_admin/storybook/_support/subscription_compositions_manifest.ex:21-31`; `scripts/ci/verify_phase252_transparency.mjs:29-40`; `scripts/ci/verify_phase253_compositions.mjs:35-60, 307-325`; `scripts/ci/verify_phase253_compositions.test.mjs:355-367`

**Issue:** The page story calls `SubscriptionLive.subscription_page/1` at `storybook/pages/subscription.story.exs:97-100`, but `accrue_admin/lib/accrue_admin/live/subscription_live.ex` is missing from the manifest `@source_paths`, the transparency compiled-source list, and both the runner's common and browser source inventories. Consequently, a change to the production page renderer can be compiled and represented in browser output without its bytes appearing in the source digests that establish current manifest/run identity. The test asserting browser source coverage repeats the same omission, so it does not catch this gap.

**Fix:** Add `accrue_admin/lib/accrue_admin/live/subscription_live.ex` to the manifest source paths, `PHASE253_COMPILED_SOURCES`, `COMMON_SOURCES`, and the browser lane's source list. Extend the manifest and command-plan contract tests to require that path so page-renderer changes make the manifest and run evidence stale until regenerated.

#### CR-02: Browser cells are not bound to their own test and collection attribution

**Classification:** BLOCKER  
**File:** `scripts/ci/verify_phase253_compositions.mjs:675-702`; `accrue_admin/e2e/phase253-composition-helpers.js:282-319`

**Issue:** The lane validator checks that each cell has a nonempty `source_identity`, then compares only the unordered set of `row.executed_test` titles with Playwright's report. It never binds a cell key to its expected test title. The result reconciliation validates page-row attribution, but for collection rows it only checks that `variation_id` appears in either the collection or page manifest; it does not compare the row key, URL, scenario, renderer, proof lane, or facts with that exact collection entry. A misattributed collection cell, or test-title swaps between cells, can therefore retain a complete report identity set and pass without proving which test rendered which source-backed case.

**Fix:** Build expected cell records with the exact title and matching compiled manifest entry. For every row, derive the expected entry from its full key and require equality for variation/scenario, route, renderer, fact source, proof lane, expected facts, and `executed_test`; retain the aggregate report-set check as an additional completeness check. Add negative controls that alter one cell's route/source identity or swap two executed test titles and require rejection.

---

_Reviewed: 2026-10-27T22:40:16Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
