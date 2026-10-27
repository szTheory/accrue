---
phase: 252-production-backed-subscription-stories
fixed_at: 2026-10-27T12:16:53Z
review_path: .planning/phases/252-production-backed-subscription-stories/252-REVIEW.md
iteration: 1
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 252: Code Review Fix Report

**Fixed at:** 2026-10-27T12:16:53Z
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

**Supplemental light-accent re-audit verification:** Commit `3991d890` binds the real Storybook sandbox accent to the production root `--ax-accent`, with the established brandbook token and `#5d79f6` fallbacks. It removes the dark-only hardcoded shim so host overrides remain authoritative in either theme. The focused Playwright run `25208-accent-focus-20261027-1235` passed the active light story at 320px and 1280px (2 passed, 0 skipped); its browser ledger is `accrue_admin/tmp/phase252/render-results-25208-accent-focus-20261027-1235.json`. I inspected `accrue_admin/tmp/phase252/ci-results/25208-accent-focus-20261027-1235/screenshots/active-320-light.png` and `active-1280-light.png`. Both show the blue Change plan action and readable row links. The live DOM assertions require an opaque primary fill, at least 4.5:1 text contrast for the CTA and Plan / price Change action, and exact agreement with the resolved accent-readable token; both widths measured 5.9845:1 and 6.8392:1. A host-override mutation to `#26428b` verified that the sandbox and row action follow the new value.

The fresh owner run `25208-1793102721082-59067-6ba5536df2dd` passed all 18 commands, with 16 executed Playwright tests, zero skips/failures, 15 actual render rows, and 20/20 acceptance-contract TAP tests. I viewed all 12 canonical screenshots in `accrue_admin/tmp/phase252/ci-results/25208-1793102721082-59067-6ba5536df2dd/screenshots/`; each shows its requested variation and lifecycle/evidence rows. The 320px screenshots are vertical viewport slices, while DOM paint/contrast checks include the lower action band. The optional desktop summary/action width and copy-affordance audit notes remain deferred. No screenshot framing or golden image changed.

### CR-02: Passing exit codes turn skipped required tests into passing evidence

**Files modified:** `scripts/ci/phase252_reporters.mjs`, `scripts/ci/verify_phase252_stories.mjs`, `scripts/ci/generate_phase252_acceptance.mjs`, `scripts/ci/generate_phase252_acceptance.test.mjs`, the Phase 252 ExUnit test helpers/formatters, and relevant test setup files.

**Commits:** `42ad3265`, `becd7c18`, `d55dec7c`, `5fc0520a`, `ee895047`, `d9913906`.

**Applied fix:** Test lanes now parse their actual TAP, ExUnit, or Playwright reporter output, require the declared test identities and expected counts, reject skips, exclusions, missing/empty/truncated output and identity mismatches, and bind named assertion references to executed records. The acceptance generator independently verifies report digests and reporter evidence. Package and build lanes remain process/build evidence rather than being labeled as tests.

**Verification:** `node --test --test-reporter=tap scripts/ci/generate_phase252_acceptance.test.mjs` passed 20/20, including negative controls for skipped records, exclusions, mismatched or missing identities, empty/truncated output, fake assertion references, and digest changes, plus genuine TAP and Playwright positive controls. The final owner run recorded 20/20 acceptance-contract TAP tests, 0 skipped, 0 failed; all 18 owner commands exited zero. `node scripts/ci/generate_phase252_acceptance.mjs --results accrue_admin/tmp/phase252/ci-results/25208-1793100141333-35541-feacb3440bfa/results.json` independently validated the current bundle as passed.

**Fix status:** Fixed; requires human verification of the evidence-mapping logic during the parent-owned review recheck.

## Verification Run

`ERL_FLAGS='+S 4:4' npm --prefix accrue_admin run phase252:check` passed all 18 required commands with fresh run ID `25208-1793102721082-59067-6ba5536df2dd`. The result bundle is `accrue_admin/tmp/phase252/ci-results/25208-1793102721082-59067-6ba5536df2dd/results.json`; its direct-render ledger is `accrue_admin/tmp/phase252/render-results-25208-1793102721082-59067-6ba5536df2dd.json`. The browser lane parsed 16 executed Playwright test identities with zero skips or failures and reconciled all 15 render rows. The acceptance-contract TAP lane passed 20/20. The generator `--write` refreshed `252-UAT.md` from this bundle, and a separate no-write validation passed with `human_judgment: false`, four unresolved assumptions, and two unresolved prohibitions.

The historical `accrue_admin/tmp/phase252/render-results.json` remains byte-for-byte unchanged: its SHA-256 is `ebeb70f8d2d56e2555d766b5b14b43caf9fcf2abdf25f315810190f10a07f8bf`, matching the digest pinned before the owner run. The compiled manifest freshness contract passed; the manifest and generated coverage guide need no regeneration because their declared source-digest inputs do not include the changed CSS and browser helper. The owner bundle fingerprints those current source and asset bytes directly.

The generator retains four unresolved assumptions (`EDGE-CIQ-01-unclassified`, `EDGE-LAB-02-unclassified`, `EDGE-SBK-03-unclassified`, `EDGE-SCEN-01-unclassified`) and two unresolved prohibitions from Plans 252-01 and 252-04. Static Storybook evidence proves rendered presentation only; it does not prove mounted authorization, action completion, or persistence.

---

_Fixed: 2026-10-27T12:16:53Z_
_Fixer: the agent (gsd-code-fixer)_  
_Iteration: 1_
