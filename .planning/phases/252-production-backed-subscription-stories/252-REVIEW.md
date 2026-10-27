---
phase: 252-production-backed-subscription-stories
reviewed: 2026-10-27T08:30:51Z
depth: standard
files_reviewed: 54
files_reviewed_list:
  - .github/workflows/ci.yml
  - .gitignore
  - accrue/config/prod.exs
  - accrue_admin/assets/css/app.css
  - accrue_admin/assets/js/storybook_hooks.js
  - accrue_admin/config/test.exs
  - accrue_admin/e2e/phase252-review.spec.js
  - accrue_admin/e2e/phase252-story-helpers.js
  - accrue_admin/e2e/subscription-stories-phase252.spec.js
  - accrue_admin/lib/accrue_admin/components/detail.ex
  - accrue_admin/lib/accrue_admin/live/subscription_live.ex
  - accrue_admin/lib/accrue_admin/router.ex
  - accrue_admin/package.json
  - accrue_admin/playwright.config.js
  - accrue_admin/playwright.phase252.config.js
  - accrue_admin/priv/static/accrue_admin.css
  - accrue_admin/priv/static/storybook.css
  - accrue_admin/priv/static/storybook.js
  - accrue_admin/storybook/_support/subscription_manifest.ex
  - accrue_admin/storybook/_support/subscription_scenarios.ex
  - accrue_admin/test/accrue_admin/components/subscription_area_test.exs
  - accrue_admin/test/accrue_admin/dev/storybook_asset_test.exs
  - accrue_admin/test/accrue_admin/dev/storybook_coverage_test.exs
  - accrue_admin/test/accrue_admin/dev/subscription_manifest_test.exs
  - accrue_admin/test/accrue_admin/dev/subscription_production_boundary_test.exs
  - accrue_admin/test/accrue_admin/dev/subscription_scenario_repo_test.exs
  - accrue_admin/test/accrue_admin/dev/subscription_scenarios_test.exs
  - accrue_admin/test/accrue_admin/dev/subscription_story_slice_test.exs
  - accrue_admin/test/support/e2e_plug.ex
  - accrue_admin/test/support/e2e_server.ex
  - accrue_admin/test/support/subscription_scenario_repo.ex
  - accrue_admin/tmp/phase252/render-results.json
  - dev_support/ui_scenarios/cadence_subscriptions.exs
  - examples/accrue_host/priv/repo/seeds/edge_states.exs
  - examples/accrue_host/priv/repo/seeds/phase248_cleanup_edge.exs
  - examples/accrue_host/priv/repo/seeds/phase252_subscription_scenarios.exs
  - examples/accrue_host/test/accrue_host/phase252_scenario_cleanup_test.exs
  - guides/subscription-story-coverage.md
  - guides/ui-story-lab.md
  - scripts/ci/generate_phase252_acceptance.mjs
  - scripts/ci/generate_phase252_acceptance.test.mjs
  - scripts/ci/phase248_heldout_isolation.test.mjs
  - scripts/ci/phase252_paths.mjs
  - scripts/ci/verify_phase200_admin_guardrails.sh
  - scripts/ci/verify_phase200_guardrail_contract.sh
  - scripts/ci/verify_phase252_ci_contract.test.mjs
  - scripts/ci/verify_phase252_production_boundary.mjs
  - scripts/ci/verify_phase252_production_boundary.test.mjs
  - scripts/ci/verify_phase252_stories.mjs
  - scripts/dev/phase252_isolation.test.mjs
  - scripts/dev/phase252_lab.mjs
  - scripts/dev/phase252_lab.test.mjs
  - storybook/components/subscription_detail.story.exs
  - storybook/phase252-manifest.json
findings:
  critical: 2
  warning: 0
  info: 0
  total: 2
status: issues_found
---

# Phase 252: Code Review Report

**Reviewed:** 2026-10-27T08:30:51Z
**Depth:** standard
**Files Reviewed:** 54
**Status:** issues_found

## Summary

The Phase 252 source scope was reviewed for behavior, input handling, cleanup ownership, production routing and packaging, CI admission, and acceptance evidence. Two blockers remain: the browser helper alters the actual Storybook document before checking its theme, and the command runner can report skipped ExUnit cases as passed evidence. This was a read-only source review; no tests or browser runs were performed.

## Narrative Findings (AI reviewer)

### Critical Issues

#### CR-01: Storybook theme check adds the missing application scope

**Severity:** BLOCKER  
**File:** `accrue_admin/e2e/phase252-story-helpers.js:628`

**Issue:** Immediately before measuring theme tokens, the helper adds `accrue-admin` to the real document root. The Storybook route applies that class to its `.psb-sandbox` element (`accrue_admin/lib/accrue_admin/dev/storybook.ex:18`), while the light semantic token set and root typography/background rules are scoped to `html.accrue-admin` (`accrue_admin/assets/css/theme.css:12`, `accrue_admin/assets/css/app.css:39`). The direct Storybook document does not use the normal admin root layout that supplies this root class. As a result, the browser check tests a modified document and passes even though the actual light-theme Storybook route lacks the expected Accrue root styling; the static review story is visibly rendered with fallback styling.

**Reproduction:** Open a direct subscription variation in the normal Storybook route without modifying the root element. Inspect `document.documentElement.classList` and the computed `--ax-base` value on `.psb-sandbox.accrue-admin`. The helper currently masks the route state by adding the root class before asserting `--ax-base` at lines 300-329.

**Fix:** Make the complete light token and root styling available in the Storybook document’s real scope (or render the story under the same root layout as the admin app), then remove this class mutation. Keep the browser assertion against the unmodified route.

#### CR-02: Passing exit codes turn skipped required tests into passing evidence

**Severity:** BLOCKER  
**File:** `scripts/ci/verify_phase252_stories.mjs:268`

**Issue:** The runner copies planned `commandSpec.assertions` into each result and marks the entire sequence passed whenever commands return exit code 0 (lines 268-274). The acceptance generator only requires these assertion reference arrays to be non-empty and checks command exit codes (`scripts/ci/generate_phase252_acceptance.mjs:176-184)); it does not verify that named test assertions ran. Several Phase 252 ExUnit formatters explicitly print skipped tests as successful TAP records (`ok … # SKIP`), for example `accrue_admin/test/accrue_admin/dev/subscription_scenarios_test.exs:17-22`. If a required test is skipped or excluded, ExUnit can exit successfully, so the runner still attaches the static assertion labels and the acceptance bundle can claim coverage that was not executed. This can make the required CI owner green without the behavior its evidence claims.

**Reproduction:** Mark a test in one of the Phase 252 ExUnit files with `@tag :skip` (or exclude that required test), then run its planned command. The formatter emits `ok … # SKIP`; the command can exit zero, and this runner records its predeclared assertion references as if they had executed.

**Fix:** Parse and validate each test command’s actual TAP output. Require the expected test IDs/counts, reject any `# SKIP` record or missing assertion, and derive evidence references from the executed records instead of copying the static plan labels.

### Warnings

None.

### Info

None.

---

_Reviewed: 2026-10-27T08:30:51Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_

