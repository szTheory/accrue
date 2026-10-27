---
phase: 253
fixed_at: 2026-10-27T23:22:04Z
review_path: .planning/phases/253-real-groups-and-a-whole-subscription-job/253-REVIEW.md
iteration: 1
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 253: Code Review Fix Report

**Fixed at:** 2026-10-27T23:22:04Z  
**Source review:** `.planning/phases/253-real-groups-and-a-whole-subscription-job/253-REVIEW.md`  
**Iteration:** 1

**Summary:**
- Findings in scope: 2
- Fixed: 2
- Skipped: 0

## Fixed Issues

### CR-01: Whole-page renderer is absent from source identity inventories

**Files modified:** `accrue_admin/storybook/_support/subscription_compositions_manifest.ex`, `accrue_admin/test/accrue_admin/dev/subscription_compositions_manifest_test.exs`, `scripts/ci/verify_phase252_transparency.mjs`, `scripts/ci/verify_phase253_compositions.mjs`, `scripts/ci/verify_phase253_compositions.test.mjs`, `scripts/ci/verify_phase253_presentation.test.mjs`  
**Commit:** `1da078d8c`  
**Applied fix:** Added `accrue_admin/lib/accrue_admin/live/subscription_live.ex` to the compiled manifest, transparency inventory, aggregate common source inventory, and browser source inventory. Added contract assertions for the manifest digest and both aggregate inventories so omission or stale renderer bytes fail closed.

### CR-02: Browser cells are not bound to their own test and collection attribution

**Files modified:** `accrue_admin/storybook/_support/subscription_compositions_manifest.ex`, `accrue_admin/test/accrue_admin/dev/subscription_compositions_manifest_test.exs`, `accrue_admin/e2e/phase253-composition-helpers.js`, `accrue_admin/e2e/subscription-compositions-phase253.spec.js`, `scripts/ci/verify_phase253_compositions.mjs`, `scripts/ci/verify_phase253_compositions.test.mjs`  
**Commit:** `285918126`  
**Applied fix:** Added validated expected facts to each compiled collection variation. Each browser cell now carries and must match its exact test title, case kind, variation, scenario, width/theme, route, renderer, fact source, proof lane, and expected facts. Synthetic and geometry controls explicitly reuse the `one_row` entry. Added title-swap and attribution mutation controls while retaining the aggregate Playwright report-set check and all 151 browser cells.

## Integration Follow-up

### Regenerated Phase 252 guide retains current Phase 253 composition evidence

**Files modified:** `accrue_admin/storybook/_support/subscription_manifest.ex`, `accrue_admin/test/accrue_admin/dev/subscription_manifest_test.exs`, `guides/subscription-story-coverage.md`, `scripts/ci/verify_phase253_compositions.mjs`, `scripts/ci/verify_phase253_compositions.test.mjs`, `storybook/phase252-manifest.json`  
**Commit:** `09195121f`  
**Applied fix:** The Phase 252 guide writer now adds a deterministic supplement from the compiled Phase 253 collection and whole-page manifests, including direct and iframe routes, renderer, scenario, facts, proof lane, and explicit presentation-only limits. It replaces stale future-tense wording while preserving the original six Phase 252 canonical entries and their coverage assertions. The writer-owned Phase 252 manifest digest was refreshed without changing its six entries or 12 digest keys. The Phase 253 common source inventory and contract test now include the generator, its regression test, and generated guide.

## Verification

Verification ran in the main checkout because `.planning/config.json` sets `workflow.use_worktrees` to `false`. Mutable tests ran serially through the disposable Phase 252 lab partitions.

- Generator regression: 12 ExUnit tests passed, including regeneration of all 10 collection routes and 9 whole-page routes, their compiled source attribution, unchanged Phase 252 entry count, proof limits, and removal of stale future-tense wording.
- Composition contract and negative controls: 9 Node tests passed, including title swaps and case, scenario, variation, route, renderer, fact source, proof lane, and expected-fact mutations. JavaScript syntax checks and `git diff --check` passed.
- Phase 252 source manifest was regenerated after the guide writer change; only the `subscription_manifest.ex` source digest changed. Its six canonical entries and 12 digest keys remained identical. The full Phase 252 focused gate passed all 21 commands after the final edits (`25208-1793142852503-81090-a9dacf28d367`).
- Final fresh Phase 253 focused aggregate passed all 10 serial lanes (`862a8694378aec0695891213952c58dd`), with 151 browser cells across 152 Playwright tests and no failures or skips.
- `generate_phase253_acceptance.mjs --latest` passed for run `862a8694378aec0695891213952c58dd` with 10 commands and 151 browser cells. Summary coverage did not change, so the generated UAT was not rewritten. Six unresolved assumptions remain preserved.
- `verify_executable_uat_contract.mjs --phase 253` remains pending because the required independent `VERIFICATION.md` is not present; that phase artifact was left untouched.

---

_Fixed: 2026-10-27T23:22:04Z_  
_Fixer: the agent (gsd-code-fixer)_  
_Iteration: 1_
