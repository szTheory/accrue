---
phase: 252-production-backed-subscription-stories
fixed_at: 2026-10-27T11:35:54Z
review_path: .planning/phases/252-production-backed-subscription-stories/252-REVIEW.md
iteration: 1
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 252: Code Review Fix Report

**Fixed at:** 2026-10-27T11:35:54Z  
**Source review:** `.planning/phases/252-production-backed-subscription-stories/252-REVIEW.md`  
**Iteration:** 1

**Summary:**
- Findings in scope: 2
- Fixed: 2
- Skipped: 0

## Fixed Issues

### CR-01: Storybook theme check adds the missing application scope

**Files modified:** `accrue_admin/assets/css/app.css`, `accrue_admin/assets/css/theme.css`, `accrue_admin/e2e/phase252-story-helpers.js`, `accrue_admin/e2e/phase200-storybook-helpers.js`, generated static CSS, the subscription story and its UI assertions, `storybook/phase252-manifest.json`, and `guides/subscription-story-coverage.md`.

**Commits:** `959866e3`, `30dcd69c`, `3aef99a1`, `0c82f97d`, `e44ae190`, `64df91ef`, `c8398890`, `99377fc9`, `62285f55`.

**Applied fix:** Production theme and typography tokens now resolve from Storybook's real `.psb-sandbox.accrue-admin` scope in light and dark themes. Removed the helper's document-root class mutation. The supported theme control drives the theme check, which asserts the unmodified route's scope, tokens, Geist fonts, type scale, contrast, and responsive geometry. The story uses a one-column preview to provide usable width beside the Storybook source pane; direct captures target and identify each declared variation.

**Verification:** Focused mobile controls passed 4/4 for `scheduled_cancellation` and `incomplete_evidence` at 320px in both themes (run `25208-focus-20261027-34785`). I inspected all four images at `accrue_admin/tmp/phase252/ci-results/25208-focus-20261027-34785/screenshots/` and confirmed each shows the requested variation's title and distinguishing cancellation or unavailable-evidence rows. The final owner run `25208-1793100141333-35541-feacb3440bfa` passed all 18 commands and 16 executed Playwright tests with no skips or failures. I inspected all 12 canonical desktop/mobile, light/dark captures in `accrue_admin/tmp/phase252/ci-results/25208-1793100141333-35541-feacb3440bfa/screenshots/`; the requested preview IDs, lifecycle facts, typography, contrast, and layout were visible. `node -c accrue_admin/e2e/phase252-story-helpers.js` and `git diff --check` passed. No golden images were updated.

### CR-02: Passing exit codes turn skipped required tests into passing evidence

**Files modified:** `scripts/ci/phase252_reporters.mjs`, `scripts/ci/verify_phase252_stories.mjs`, `scripts/ci/generate_phase252_acceptance.mjs`, `scripts/ci/generate_phase252_acceptance.test.mjs`, the Phase 252 ExUnit test helpers/formatters, and relevant test setup files.

**Commits:** `42ad3265`, `becd7c18`, `d55dec7c`, `5fc0520a`, `ee895047`, `d9913906`.

**Applied fix:** Test lanes now parse their actual TAP, ExUnit, or Playwright reporter output, require the declared test identities and expected counts, reject skips, exclusions, missing/empty/truncated output and identity mismatches, and bind named assertion references to executed records. The acceptance generator independently verifies report digests and reporter evidence. Package and build lanes remain process/build evidence rather than being labeled as tests.

**Verification:** `node --test --test-reporter=tap scripts/ci/generate_phase252_acceptance.test.mjs` passed 20/20, including negative controls for skipped records, exclusions, mismatched or missing identities, empty/truncated output, fake assertion references, and digest changes, plus genuine TAP and Playwright positive controls. The final owner run recorded 20/20 acceptance-contract TAP tests, 0 skipped, 0 failed; all 18 owner commands exited zero. `node scripts/ci/generate_phase252_acceptance.mjs --results accrue_admin/tmp/phase252/ci-results/25208-1793100141333-35541-feacb3440bfa/results.json` independently validated the current bundle as passed.

**Fix status:** Fixed; requires human verification of the evidence-mapping logic during the parent-owned review recheck.

## Verification Run

`ERL_FLAGS='+S 4:4' npm --prefix accrue_admin run phase252:check` passed with run ID `25208-1793100141333-35541-feacb3440bfa`. The result bundle is `accrue_admin/tmp/phase252/ci-results/25208-1793100141333-35541-feacb3440bfa/results.json`; its direct-render ledger is `accrue_admin/tmp/phase252/render-results-25208-1793100141333-35541-feacb3440bfa.json`. `252-UAT.md` was regenerated from this bundle, then the generator validated it without writing. The historical `accrue_admin/tmp/phase252/render-results.json` was preserved; its SHA-256 matches the pre-run digest recorded in the new bundle.

The generator retains four unresolved assumptions (`EDGE-CIQ-01-unclassified`, `EDGE-LAB-02-unclassified`, `EDGE-SBK-03-unclassified`, `EDGE-SCEN-01-unclassified`) and two unresolved prohibitions from Plans 252-01 and 252-04. Static Storybook evidence proves rendered presentation only; it does not prove mounted authorization, action completion, or persistence.

---

_Fixed: 2026-10-27T11:35:54Z_  
_Fixer: the agent (gsd-code-fixer)_  
_Iteration: 1_
