---
phase: 254-recurring-quality-reviewed-fixes-and-curation
plan: "11"
subsystem: testing
tags: [accessibility, axe, keyboard, focus, target-size, contrast, text-spacing, motion, register, uxq-02]

requires:
  - phase: 254-recurring-quality-reviewed-fixes-and-curation
    provides: 254-09 frozen budget and the shared composition aggregate (allowances.a11y max added 180 s); 254-10 design review record at stage assessment and the recomposed storybook.css
provides:
  - phase254-a11y-probes.js, the axe runner, the disposition matcher, alpha-correct contrast and the six D-28 deep probes
  - an all-severity axe layer in every one of the 151 composition cells, each recording an a11y block
  - a11y-dispositions.json, a narrow register of 30 routed-defect entries, and verify_a11y_dispositions.mjs (register validator, owner source contract, --results-latest)
  - the mounted D-29 keyboard journey with asserted focus behavior
affects: [254-12, 254-13, 254-15, 254-17, 254-18]

actuals:
  tokens: 48000
  tasks: 3
  commits: 6

tech-stack:
  added: []
  patterns:
    - "A probe finding is an observation exactly like an axe finding (rule id, result type, exact stable target), so one register and one matcher decide both"
    - "A register entry that matches nothing in a cell that ran fails (the census zero-match idiom); a journey checkpoint is decided by the mounted spec reading the same register"
    - "Every injected positive control runs the very checker the cells use, then removes its node"
    - "Run-specific ids (LiveView ids, UUIDs inside ids) are normalized in targets so an exact target names the same node on every run"

key-files:
  created:
    - accrue_admin/e2e/phase254-a11y-probes.js
    - accrue_admin/e2e/a11y-dispositions.json
    - scripts/ci/verify_a11y_dispositions.mjs
    - scripts/ci/verify_a11y_dispositions.test.mjs
  modified:
    - accrue_admin/e2e/phase253-composition-helpers.js
    - accrue_admin/e2e/foundation-tokens.spec.js
    - accrue_admin/e2e/admin-interactions.spec.js

key-decisions:
  - "The cell result row carries an a11y block (observations, auto_resolved, matched_dispositions, probes, rules_evaluated, timing_ms) and leaves assertion_ids untouched, so verify_phase253_compositions.mjs and its exact assertion inventories needed no change."
  - "Probe findings share the register with axe findings: rule ids probe-names, probe-target-size, probe-focus-visible, probe-text-spacing, probe-text-scale, probe-motion-reduce, probe-focus-restore."
  - "The D-29 journey is decided by the same register through cell ids journey::D-29::<checkpoint>; the validator exempts those ids from the cell-ran rules because the mounted spec, not a composition cell, decides them."
  - "Focus return is judged against the invoking control: the Cancel immediately item while the action menu stays open, or the More actions button that owns it (the WAI-ARIA menu-button pattern)."

patterns-established:
  - "Observation targets are exact and stable: LiveView ids, UUIDs inside ids and data-phx-id values are replaced by tokens, motion findings name a kind of element (tag plus first class), geometry findings name a kind of failure (geometry:page-overflow)"

requirements-completed: []
requirements-advanced: [UXQ-02]

coverage:
  - id: E1
    description: "axe runs in every selected composition cell in the cell's own theme with tags wcag2a to wcag22aa, every severity, over the sandbox and any open overlay root, never the hidden test mirror; every violation and incomplete is auto-resolved or matched to a disposition"
    requirement: UXQ-02
    verification:
      - kind: integration
        ref: "node scripts/ci/verify_phase253_compositions.mjs passed (10 serial lanes, 151 browser cells, 3:04) and node scripts/ci/verify_a11y_dispositions.mjs --results-latest passed: 151 cells reported, every cell rules_evaluated between 61 and 63, 566 observations all matched, 924 incomplete contrast results auto-resolved by compositing, 30 register entries each matched in a cell that ran (or decided by the journey)"
        status: pass
    human_judgment: false
  - id: E2
    description: "The register validator rejects an unmatched observation, an entry matching zero nodes in a cell that ran, a broad target, a node-count mismatch, a wildcard cell id and an expired review_by; an empty register passes only when every cell evaluated a rule; an absent or unparsable register fails closed; the owner source contract rejects disableRules, exclude and impact filters"
    requirement: UXQ-02
    verification:
      - kind: unit
        ref: "node --test scripts/ci/verify_a11y_dispositions.test.mjs (86 tests, 0 failures) and node scripts/ci/verify_a11y_dispositions.mjs --self-test (15 scenarios, each with a passing control); the real owner files pass the source contract, and the same scan flags each seeded banned token (disableRules, exclude, impact, withRules, options, configure)"
        status: pass
    human_judgment: false
  - id: E3
    description: "Alpha-correct contrast, the encoding contract (whitespace-only normalization, code point comparison) and each D-28 deep probe, with its injected control detected"
    requirement: UXQ-02
    verification:
      - kind: unit
        ref: "contrast, encoding (NFC vs NFD, long Unicode identities differing in the last code point, duplicate row names), target-size, focus and deep-subset fixtures in verify_a11y_dispositions.test.mjs (40 deep-probe cells are exactly the named subset)"
        status: pass
      - kind: integration
        ref: "geometry::negative-controls::320::light recorded all seven injected controls as detected (unnamed button, overlapping undersized target, outline none, unapplied spacing, unapplied scaling, motion under reduce, undispositioned incomplete); cd accrue_admin && env -u NO_COLOR npx playwright test e2e/foundation-tokens.spec.js --project=chromium-desktop --workers=1 passed (2 tests)"
        status: pass
    human_judgment: false
  - id: E4
    description: "The mounted keyboard journey list to row link to detail h1 to Cancel immediately to drawer cycles Tab and Shift+Tab with wrap, dismisses on Escape and Back to subscription, reaches step-up with focus in #step-up-code, announces a role=status result, never leaves focus on body and returns to the list with its filter preserved"
    requirement: UXQ-02
    verification:
      - kind: e2e
        ref: "cd accrue_admin && env -u NO_COLOR npx playwright test e2e/admin-interactions.spec.js --workers=1 passed (14 tests: 7 per project, chromium-desktop and chromium-mobile); the journey alone passed 45 of 45 repeats on fresh servers (25 desktop, 10 desktop and 10 mobile). The focus-return checkpoints are routed defects A11Y-254-29 and A11Y-254-30 (see Routed defects)."
        status: pass
    human_judgment: false

human_judgment: false
duration: 1h 20m
completed: 2026-10-29
status: complete
commits: 6
plan_head_before: 835c4a1e1bf649635f69818a6a3fd9026fe75bad
plan_head_after: eefee2a62958dbdefe426d5434ed133e91b3e8ec
---

# Phase 254 Plan 11: Accessibility layer (W4, UXQ-02) Summary

**Every one of the 151 composition cells now runs all-severity axe plus an auto-resolving contrast check, the 40 named deep-probe cells run six measured probes (names, target size, focus, text spacing, 200% text, motion) each proved able to fail, the mounted keyboard journey asserts focus behavior, and 30 narrow routed-defect entries record what was found for 254-12 to fix.**

## Performance

- **Duration:** about 1 h 20 min
- **Tasks:** 3 (6 commits: RED and GREEN for each)
- **Files modified:** 7 (4 created)

## Accomplishments

- Task 01: `phase254-a11y-probes.js` with `runAxeForCell` (include the sandbox and any open overlay root, no exclude, no rule switched off, no severity filter, an assertion that axe never reaches the hidden test mirror, a wait for in-flight transitions so colours are not read mid-theme-change), `matchDispositions`, and the validator `verify_a11y_dispositions.mjs` with `--check`, `--results-latest`, `--results <path>` and `--self-test`. Incomplete `color-contrast` results are resolved by compositing the real ancestor background stack (gradient stops included, alpha honored); 924 of them resolved, none left as a silent pass.
- Task 02: alpha-correct colour (rgba, space-separated rgb, `color(srgb ... / a)`, `oklch`), then the six D-28 probes on the 40 named cells (collection `one_row`, `multiple_rows`, `page_boundary`, `unavailable`, `partial_cursor_error`, `filtered_empty`; page `active`, `review_cancel_now`, `awaiting_step_up`, `result_failed`; 320 and 1280, light and dark). The `filtered_empty` cell reports a result for every probe.
- Task 03: the journey "D-29 keyboard journey: list to drawer to step-up and back" in `admin-interactions.spec.js`, with the focus-escaped, escape-not-dismissed and keyboard-flow-incomplete conditions as `expect` assertions (the recorder rows and report output are kept) and every focus wait an `expect.poll`.

## A1 and A2 probe outcomes (each with its positive control)

- **A1, Page.setFontSizes scales rem text: yes.** CDP `Page.setFontSizes {standard: 32}` scaled a 1rem probe element and 30 sampled text elements by exactly 2.00x (`multiple_rows::viewport::1280::light`: `probe_scale 2`, `minimum_text_scale 2`), and the setting is reset afterwards. Positive control: `unapplied_scaling` (setting not applied) measured `probe_scale 1` and was detected. No root-font multiplier is used and no `unsupported-mechanism` entry was needed.
- **A2, constructed stylesheets under the admin CSP: not blocked.** An `adoptedStyleSheets` rule changed the computed letter-spacing to 1.68 px against 1.68 px expected (0.12em of 14 px). Positive control: `unapplied_spacing` (sheet never attached) measured 0 px and was detected. No `bypassCSP` context was created anywhere (T-254-23: nothing to mitigate).
- **CSP does block inline style attributes**, which affected the injected controls (see Deviations item 2).

## Injected positive controls

All seven run inside `geometry::negative-controls::320::light`, so the full-mode cell count stays 151, and the validator fails if any is not detected: unnamed button (axe `button-name`, undispositioned), overlapping undersized targets (2 defects), `outline:none` control (`no-focus-indicator`), unapplied spacing, unapplied scaling, a 300 ms transition under reduce, and an undispositioned incomplete (axe `color-contrast` over an image). The eighth control, **trap escape**, lives in the journey: with the trap's own focus listener held back, focus forced outside the drawer must make `assertFocusInside` reject with `focus-escaped` (`expect(...).rejects.toThrow(/focus-escaped/)` passed, so the assertion fails as expected when focus escapes). Register fixtures for unused, broad, expired, wildcard and count-mismatch entries are in the unit tests.

## Routed defects (for 254-12)

30 `routed-defect` entries, all with `review_by` 2026-12-31 and a `follow_up_assertion_id` naming the 254-12 fix. 254-12 fixes them and deletes the entries; the zero-match rule then fails any entry left behind (journey entries are decided by the journey instead).

| Entries | Rule and target | Follow-up id | Cells (inside / outside the D-36 16-cell bound) |
|---|---|---|---|
| A11Y-254-01, 02 | `aria-prohibited-attr` (incomplete, `noRoleSingular`): `.ax-audit-summary-row`, `.ax-detail-dunning-summary` carry a label without a naming role | 254-12-aria-label-without-role | 62 each (4 / 58) |
| A11Y-254-03 to 22 | `probe-motion-reduce`, 20 element signatures (`a.ax-button`, `div.ax-card`, `span.ax-status-badge`, `section.ax-overlay-shell (entering)`, ...): transitions of 180 ms (and the drawer enter transition) persist under `prefers-reduced-motion: reduce`. Cause: the reduce token block in `theme.css` is scoped to `html.accrue-admin`, while the Storybook sandbox puts `accrue-admin` on `.psb-sandbox`; the mounted shell is unaffected. 2.3.3 is an AAA project target. | 254-12-sandbox-reduced-motion | 4 to 40 each, 0 or 4 or 8 inside |
| A11Y-254-23 | `probe-names`: two rows each repeat a link named only "Customer details" (from `subscriptions_live.ex`) | 254-12-row-link-name-includes-identity | 4 (4 / 0): `multiple_rows` 320/1280 x light/dark |
| A11Y-254-24, 25 | `probe-text-scale`: at 200% text `geometry:page-overflow` (page root 682 against 608 wide at 1280, 368 against 176 at 320) and `geometry:document-overflow` (`filtered_empty` 441 against 320) | 254-12-text-200-percent-reflow | 16 (4 / 12) and 2 (0 / 2) |
| A11Y-254-26 | `probe-text-spacing`: `aside.ax-overlay-panel` text clipped under 1.4.12 spacing | 254-12-drawer-panel-text-spacing | 4 (0 / 4) |
| A11Y-254-27 | `scrollable-region-focusable`: `.ax-detail-drawer-body` scrolls but is not keyboard focusable | 254-12-drawer-scroll-region-focusable | 16 (0 / 16) |
| A11Y-254-28 | axe `target-size`: an undersized link (`a[data-phx-id]`) in `one_row` at 768 and 640 | 254-12-undersized-link-target | 4 (0 / 4) |
| A11Y-254-29, 30 | `probe-focus-restore`: after Escape, and after Back to subscription, focus lands on `main#main-content` instead of the Cancel immediately trigger or its More actions button. Escape is handled twice (the drawer's focus trap, and `dropdown.js` closing the menu and refocusing its button) and the drawer's restore runs later; after Back to subscription the trigger node is unchanged, connected and the menu still open, yet focus falls back to the page. `DetailDrawer` does not forward the overlay's `focus_return_to`. | 254-12-journey-focus-restore-to-trigger | `journey::D-29::...` (mounted review-open route, inside) |

D-36 bound classification of the composition cells (AMD-254-05 input for 254-13): 110 composition cells carry at least one routed defect; **8 are inside** the bound (the story-sourced capture cells `multiple_rows` and page `active`, 320/1280 x light/dark) and **102 are outside** (24 collection and 78 page cells). Both journey entries were observed on the mounted drawer route and count as inside. The register commit that still holds all 30 entries is `eefee2a62958dbdefe426d5434ed133e91b3e8ec`.

**DR-254-08 (disclosure summary affordance):** neither the target-size nor the focus probe routed a finding on `summary.ax-detail-section-head` (the focus probe reached 45 of 59 controls in `page::active::viewport::1280::light`; the rest sit in collapsed disclosures), so DR-254-08 stays deferred.

## Local cost of the layer (informs only; CI cost is compared with allowances.a11y in 254-15 and 254-18)

Recorded per cell in `a11y.timing_ms`: 151 cells, 60.3 s in total, mean 399 ms. The 111 other cells median 319 ms, p90 389 ms; the 40 deep-probe cells median 514 ms, p90 1193 ms, max 1470 ms (axe alone median 316 ms). The focused aggregate took 3:04 on three workers, 10 serial lanes. At about 60 s serial (about 20 s across three workers) this sits well inside the 180 s `allowances.a11y` maximum, though CI per-cell cost will differ.

## Task Commits

1. **Task 254-11-01:** `c6db77c5a` (test, RED: validator and source contract absent), `f88d2ff0d` (feat: probes module, validator, cell wiring, 28-entry register)
2. **Task 254-11-02:** `6210d4144` (test, RED: 12 results-bundle tests fail against the task 01 validator), `f597a6ac2` (feat: validator requires the deep probes, the seven controls and the unsupported-scale rule; foundation-tokens uses the alpha-correct module)
3. **Task 254-11-03:** `f59d02b0c` (test, RED: the journey fails on the real focus-return defect against the 28-entry register, verified by running it with the committed register), `eefee2a62` (feat: two journey entries, journey cells in the validator, cell timing)

**Plan metadata:** recorded in the docs commit that follows this summary.

## Decisions Made

See key-decisions. No Rule 4 decision arose; the one place the plan's text did not match behavior (focus return, below) is resolved by the plan's own mechanism (D-08 W4 routes defects to 254-12).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Colour parsing could not read the dark overlay pages' `oklch()` colours**
- **Found during:** Task 02 (first full run: 8 dark page cells threw `Unsupported colour: oklch(0.208 0.042 265.755)`)
- **Fix:** `parseColor` converts `oklab()` and `oklch()` to sRGB (Ottosson matrices, gamut clamp); `oklch(0.208 0.042 265.755)` reads as `[15, 23, 43]`, a unit fixture.
- **Commit:** `f88d2ff0d`

**2. [Rule 3 - Blocking] The admin CSP blocks inline `style` attributes, so injected controls were inert**
- **Found during:** Task 01 (the `outline:none` control was not detected because the inline style never applied)
- **Fix:** controls state their style in `data-phase254-style` and apply it through the CSSOM, which the policy does not restrict; the undispositioned-incomplete control uses a `url()` background (a gradient is resolvable and became a measured violation instead).
- **Commit:** `f88d2ff0d`

**3. [Rule 1 - Bug] axe read colours mid-transition in the dark synthetic cell**
- **Found during:** Task 01 (seven axe `color-contrast` violations appeared only in `one_row::synthetic-text::320::dark`, which scans right after the theme switch; the sandbox keeps 180 ms colour transitions, see A11Y-254-03 to 22)
- **Fix:** `runAxeForCell` waits until no finite transition or animation is running before measuring.

**4. [Rule 2 - Missing critical] Stable targets**
- **Found during:** Task 01 (axe targets carried `data-phx-id`, `#phx-...` and UUID-bearing ids that change on every mount, so no exact target could be matched twice)
- **Fix:** `stableTarget` normalizes them, probe selectors never use ids containing digits or hex runs, motion findings name an element kind, geometry findings name a failure kind (the sandbox root is refused by the register as too broad).

**5. [Rule 1 - Bug] Probe false positives removed**
- A target under an open modal or drawer is excluded from the target-size check (hit test at its centre; the breadcrumb links behind the step-up dialog were reported as blocked by dialog buttons), a 1x1 visually hidden submit button is classified `visually-hidden`, and the hidden test mirror is skipped by the motion probe. The drawer enter transition is measured by applying the `ax-drawer-entering` class the Overlay hook applies, because the drawer panel has no transition at rest.

**6. [Plan wording] "Cancel now" is "Cancel immediately" in the product copy**
- `Copy.subscription_action_cancel_now/0` returns "Cancel immediately" and the trigger is an item of the "More actions" menu, so the journey and its assertions use those names.

**7. [Plan assumption did not hold] Focus is not restored to the trigger**
- The plan asserts that Escape and Back to subscription restore focus to the trigger. On the real route they do not (A11Y-254-29 and 30). Per D-08 W4 this is routed to 254-12 through the register rather than fixed here; the journey stays green by requiring the routed entry to exist and the checkpoint to fail while it does. Once 254-12 fixes the behavior and deletes the two entries, the same checkpoints assert for real. 254-12's file list does not name `admin-interactions.spec.js`, and none is needed: only the register entries are deleted.

**8. [Plan scope] Eighth control placement**
- The "trap escape" control runs inside the journey (it needs an open drawer), not in the geometry cell, which holds the other seven; the validator requires the seven, the journey runs the eighth.

### TDD note

Each task has a RED commit and a GREEN commit. Task 01's RED is the validator test file against an absent module. Task 02's RED fails only on the 12 results-bundle tests; the pure helper fixtures (contrast, encoding, target size, focus, deep subset) passed at RED because the helper module already existed from task 01, so they act as regression fixtures there. Task 03's RED is the journey failing on the real defect.

### Noted, not changed

- **Local flake, environmental:** three early runs of the journey misbehaved (a desktop `toBeVisible` failure, a mobile page.evaluate that never returned, a long stall) while the e2e server on port 4017 had been left running by my own `timeout` and `pkill` wrappers and was being reused (`reuseExistingServer`). After removing that server, 45 of 45 repeats passed on fresh servers (25 desktop; 10 desktop and 10 mobile), and the full spec passed. No retry, skip or timeout widening was added; a CI run starts a fresh server.
- **Gate by-products:** this plan's gates created no untracked `.planning/phases/200-idempotent-verification-sign-off/` and no change to `accrue_admin/tmp/phase252/render-results.json`; the only uncommitted file throughout was the pre-existing `.planning/config.json`, left alone.
- **No Elixir file was touched**, so `mix format` had nothing to run; no `source_digests` input changed, and `phase254_selection.mjs project --check` and `phase254_budget.mjs check` stay green.

## Known Stubs

None.

## Threat Flags

None. T-254-22: the owner source contract scans the probes module, the composition helpers and the cells spec for `disableRules`, `.exclude(`, `impact`, `withRules`, `.options(` and `axe.configure` (seeded positives flagged, comments ignored), and the zero-match, broad-target and expired-entry rules reject silent narrowing. T-254-23: no `bypassCSP` context exists. T-254-SC: no dependency changed.

## Open flags for later plans

- **254-12 must fix and delete all 30 entries** (the table above names each fix tier; the likely owners are `theme.css` for the sandbox reduce-motion selector, `subscriptions_live.ex` copy for the row link name, the drawer component and `focus_trap.js`/`dropdown.js` for focus return, and the two `aria-label` summaries). `subscription_live.ex` and `subscriptions_live.ex` are `source_digests` inputs, so the FC-5 regeneration (`phase254_selection.mjs project --write` then `--check`) applies if a fix lands there. The journey entries are the only ones decided outside the cells; deleting them is what turns the two focus checkpoints strict.
- **254-13 (AMD-254-05):** the inside/outside split above (8 inside, 102 outside composition cells, journey entries inside) is computed from the register at `eefee2a62958dbdefe426d5434ed133e91b3e8ec`.
- **254-15 and 254-18:** compare CI per-cell cost with the local numbers above and with `allowances.a11y`. `--results-latest` reads the newest reconciled bundle under `accrue_admin/tmp/phase253`; in CI it needs the bundle the aggregate leaves there.
- **254-17:** the transparency prohibition (no description of automated axe or probe results as conformance, complete accessibility or aesthetic quality) is still unresolved and flagged for its bounded check; this plan's output labels 2.3.3 an AAA project target and makes no conformance claim.
- **Reduced-motion:** a11y probes are measured in the Storybook sandbox; `reduced-motion.spec.js` remains the proof for the mounted shell.

## Self-Check: PASSED

Created files exist (`phase254-a11y-probes.js`, `a11y-dispositions.json`, `verify_a11y_dispositions.mjs`, its test); commits `c6db77c5a`, `f88d2ff0d`, `6210d4144`, `f597a6ac2`, `f59d02b0c` and `eefee2a62` are ancestors of HEAD; `git rev-list --count 835c4a1e1bf649635f69818a6a3fd9026fe75bad..HEAD` measured 6 before this summary commit.
