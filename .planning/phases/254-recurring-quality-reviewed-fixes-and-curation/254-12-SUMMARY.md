---
phase: 254-recurring-quality-reviewed-fixes-and-curation
plan: "12"
subsystem: testing
tags: [css, design-review, red-evidence, accessibility, focus, reflow, uxq-04, uxq-02]

requires:
  - phase: 254-recurring-quality-reviewed-fixes-and-curation
    provides: 254-10 design review record at stage assessment; 254-11 all-severity axe layer, the 30 routed-defect register entries and the strict-able keyboard journey
provides:
  - subscription-design-phase254.spec.js, the lab-owned D-35 computed-style and source tests (13 tests, keys DR-254-01/02/03)
  - parseRedReport, --record-red and --check-red (Playwright JSON and ExUnit text), and the AMD-254-04 and AMD-254-05 stage-corrected rules with fixtures
  - 254-12-01-red-evidence.json, written only by --record-red from the parsed pre-fix report
  - the D-34 CSS corrections, the amended Typography contract rows and all 30 routed accessibility defects fixed with their register entries deleted
affects: [254-13, 254-15, 254-17, 254-18]

actuals:
  tokens: 18664
  tasks: 2
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Red evidence is derived from a parsed report (assertion errors only; a setup crash, timeout, skip, compile error or missing result is rejected), and --check-red re-parses the report and requires it to reproduce the evidence file"
    - "Token-side values in computed tests are resolved by the browser through a probe element, never hard-coded; readiness waits use locator.waitFor so a setup problem cannot be mistaken for red"
    - "Text-resize reflow without a breakpoint: auto-fit grids with a rem minimum, a container query on the field list, and overflow-wrap anywhere scoped to the detail page"
    - "A delayed focus return only runs when focus is lost (body, a detached node, the closed overlay, or the page container the hook parks focus on)"

key-files:
  created:
    - accrue_admin/e2e/subscription-design-phase254.spec.js
    - .planning/phases/254-recurring-quality-reviewed-fixes-and-curation/254-12-01-red-evidence.json
  modified:
    - accrue_admin/playwright.phase252.config.js
    - accrue_admin/playwright.config.js
    - scripts/ci/verify_phase254_design_review.mjs
    - scripts/ci/verify_phase254_design_review.test.mjs
    - scripts/ci/verify_a11y_dispositions.test.mjs
    - accrue_admin/assets/css/app.css
    - accrue_admin/assets/css/theme.css
    - accrue_admin/priv/static/accrue_admin.css
    - accrue_admin/priv/static/storybook.css
    - accrue_admin/assets/js/hooks/focus_trap.js
    - accrue_admin/priv/static/accrue_admin.js
    - accrue_admin/lib/accrue_admin/components/overlay.ex
    - accrue_admin/lib/accrue_admin/live/subscription_live.ex
    - accrue_admin/lib/accrue_admin/live/subscriptions_live.ex
    - accrue_admin/e2e/a11y-dispositions.json
    - .planning/phases/253-real-groups-and-a-whole-subscription-job/253-UI-SPEC.md

key-decisions:
  - "A key in --expect-fail matches a test by exact key (DR-254-01:computed) or by finding id when it has no kind; a key is red when at least one of its tests fails, the failing key set must equal the expected set, and every --expect-pass key must pass in full."
  - "Red tests count only with parsable Expected and Received lines, so the evidence file always carries real expected and actual values."
  - "DR-254-01 asserts the stacks and lists against the component tokens: .ax-stack-md and .ax-stack-sm resolve --ax-space-md (the global .ax-stack-sm value is deliberately unchanged), .ax-field-list and .ax-field resolve --ax-space-xs."
  - "The raw 0 0.25rem field gap became the single value var(--ax-space-xs), so the field row gap changes from 0 to 4px (only visible if a label/value pair wraps)."
  - "At stage assessment a contract that already carries amended_text satisfies the contract check, because the batch edits the contract here and moves the record to corrected in 254-13."

patterns-established:
  - "A routed accessibility defect is fixed where it lives (token scope, component markup, hook, page CSS), its entry is deleted, and the zero-match rule plus a strict journey prove the fix"

requirements-completed: []
requirements-advanced: [UXQ-04, UXQ-02]

coverage:
  - id: F1
    description: "The D-35 design tests are shown red on the pre-fix commit from a parsed Playwright report: the failing keys are exactly DR-254-01:computed, DR-254-02:source and DR-254-03:computed, the DR-254-02:computed tests at 767 and 768 pass on both sides, and the evidence file equals the parsed failures and passes"
    requirement: UXQ-04
    verification:
      - kind: unit
        ref: "node --test scripts/ci/verify_phase254_design_review.test.mjs (parseRedReport/evaluate/record/check fixtures: setup crash, timeout, skip, missing result, unexpected failure, unkeyed test, assertion without values, expect-pass failure and bare finding keys each rejected beside a passing control; AMD-254-04 and AMD-254-05 scenarios) and node scripts/ci/verify_phase254_design_review.mjs --self-test (20 scenarios)"
        status: pass
      - kind: e2e
        ref: "PLAYWRIGHT_JSON_OUTPUT_FILE=accrue_admin/tmp/phase254/design-red.json node scripts/dev/phase252_lab.mjs browser -- e2e/subscription-design-phase254.spec.js --reporter=json exited 1 on 073e33792 (9 failing, 4 passing); --record-red wrote 254-12-01-red-evidence.json and --check-red reproduced it"
        status: pass
    human_judgment: false
  - id: F2
    description: "The spacing, field-label and heading corrections ship in app.css, accrue_admin.css and storybook.css together and the design spec passes; the spacing scan fires on the pre-fix app.css (5 findings) and is clean on the corrected one"
    requirement: UXQ-04
    verification:
      - kind: e2e
        ref: "node scripts/dev/phase252_lab.mjs browser -- e2e/subscription-design-phase254.spec.js: 13 passed; two consecutive mix accrue_admin.assets.build runs gave sha256 63fbca43...f299; recompose_storybook_css.mjs --check, verify_package_docs.sh (FND-01, FND-05) and the theme and component ExUnit suites (195 tests) pass"
        status: pass
    human_judgment: false
  - id: F3
    description: "All 30 routed accessibility defects are fixed at their lowest owning tier and their register entries are deleted; the 151 composition cells report 0 observations and the mounted keyboard journey asserts its two focus-restore checkpoints strictly"
    requirement: UXQ-02
    verification:
      - kind: integration
        ref: "node scripts/ci/verify_phase253_compositions.mjs passed (10 serial lanes, 151 browser cells) and node scripts/ci/verify_a11y_dispositions.mjs --results-latest passed: 151 cells reported, 40 deep-probe cells, 0 observations, 0 register entries"
        status: pass
      - kind: e2e
        ref: "cd accrue_admin && env -u NO_COLOR npx playwright test e2e/admin-interactions.spec.js passed (14 tests); the D-29 journey with the empty register passed 80 of 80 repeats on chromium-desktop and 40 of 40 on chromium-mobile on fresh servers"
        status: pass
      - kind: unit
        ref: "node --test test/js/focus_trap_test.mjs (15 tests; the closed-menu, closed-disclosure and no-steal tests each fail against the pre-fix module) and overlay_components_test.exs (drawer body region, modal and popover untouched)"
        status: pass
    human_judgment: false
  - id: F4
    description: "The Typography contract carries the responsive Page heading row and the Section title row verbatim from the record, with the introductory sentence consistent with its rows"
    requirement: UXQ-04
    verification:
      - kind: unit
        ref: "grep checks on 253-UI-SPEC.md (one Section title row, Page heading row naming --ax-type-xl and --ax-type-2xl) and node scripts/ci/verify_phase254_design_review.mjs --check --stage assessment (the real record still passes against the amended contract)"
        status: pass
    human_judgment: false

human_judgment: false
duration: about 5 h
completed: 2026-10-29
status: complete
commits: 3
plan_head_before: 073e33792d7fd55810f7afd12908ff247caca206
plan_head_after: df17d29b0f3e3bce207b30128ba63a1a3e8b791b
---

# Phase 254 Plan 12: Correction batch, CSS and contract part Summary

**The D-34 spacing, field-label and heading corrections are tested red-then-green from a parsed report, shipped in all three CSS artifacts with the amended Typography rows, and all 30 accessibility defects routed from 254-11 are fixed at their lowest tier with their register entries deleted (151 cells now report 0 observations).**

## Performance

- **Duration:** about 5 h (most of it iterating the 200% reflow and focus-return fixes against measured offenders)
- **Tasks:** 2 (3 commits: the RED step, the CSS GREEN step, the accessibility fix step)
- **Files modified:** 21 in the commits plus the generated manifests (25 files in the range)

## Accomplishments

- Task 254-12-01: `subscription-design-phase254.spec.js` (13 tests, lab project `phase254-design`, ignored by both default projects) with browser-resolved token probes; `parseRedReport`, `--record-red`, `--check-red` (Playwright JSON and ExUnit text for 254-13) and the two stage-corrected amendment rules with fixtures. On `073e33792` the spec exited 1 with 9 failures (DR-254-01:computed x4 `16px` expected / `3px` received, DR-254-03:computed x4 `12px` / `14px`, DR-254-02:source `var(--ax-type-xl)` / `1.5rem`) and 4 passes (DR-254-02:computed at 767px and 768px, light and dark).
- Task 254-12-02: the D-34 CSS, the amended Typography rows, and the routed accessibility fixes below. The spec is green (13 of 13).

## Evidence for 254-13 (record update)

- **Red evidence:** `.planning/phases/254-recurring-quality-reviewed-fixes-and-curation/254-12-01-red-evidence.json` (commit `073e33792d7fd55810f7afd12908ff247caca206`, spec sha256 recorded, one command with exit code 1, `expect_fail` DR-254-01:computed, DR-254-02:source, DR-254-03:computed, `expect_pass` DR-254-02:computed).
- **Fix commits:** `81ea61825` (CSS and contract) and `df17d29b0` (accessibility fixes and regenerated digests); `fix_commit` for the record is `df17d29b0f3e3bce207b30128ba63a1a3e8b791b` unless 254-13 adds a later correction commit.
- **CSS artifact sha256 at the fix commit:** `app.css` `25d18c954f3c95b4e0f22b01ecde4d0c8168b655e4800da149fb4283f897ee1a`; `theme.css` `fbf78dee8fb3982b2157f1db8a4be9c16f6b6fe83ef5b6ce89bc7527db602bc7`; `accrue_admin.css` `63fbca439ae348fbd4ac14b40dbc7fe8ddb48e1d4a6dc3564c0e7eb7d227f299`; `storybook.css` `4253796170bc68e8bf398b12b3a1e9df0321798f511c5ff1bb5962f2bad84fbe`.
- **Test keys per fixed finding:** DR-254-01 `DR-254-01:computed` (4 tests: 320 and 1280 px, light and dark) plus the `scanSubscriptionDetailSpacing` guard; DR-254-03 `DR-254-03:computed` (4 tests); DR-254-02 (contract-amended) `DR-254-02:source` (1 test, red) and `DR-254-02:computed` (4 tests at 767 and 768 px, passing before and after); DR-254-04 has no CSS and no test.
- **Contract rows written verbatim from the record:** `| Page heading | Responsive: ... |` (amend-row, DR-254-02) and `| Section title | 20px (--ax-type-lg) | Semibold 600 | 1.2 |` (add-row, DR-254-04); the introductory sentence now lists the size steps and the two weights, and a one-sentence note cites DR-254-02 and DR-254-04.
- **AMD-254-05 input:** `register_commit` `eefee2a62958dbdefe426d5434ed133e91b3e8ec` (the commit that still holds all 30 entries). Routed cells: 112 distinct = 110 composition cells + 2 journey cells. **Inside the bound: 8 composition cells** (`multiple_rows::viewport::{320,1280}::{light,dark}` and `page::active::viewport::{320,1280}::{light,dark}`) **plus both journey cells** (`journey::D-29::escape-restores-focus`, `journey::D-29::back-restores-focus`). **Outside: 102 composition cells.** `affected_cells` is exactly the outside set; recompute it with the exported `routedA11yCells(register).outside` (verify_phase254_design_review.mjs) on `git show eefee2a62:accrue_admin/e2e/a11y-dispositions.json`, which is what `requireRoutedA11yAmendment` does when it checks the record.
- **AMD-254-04 input:** the red evidence above has a failing `DR-254-02:source` and passing `DR-254-02:computed` tests named `...at 767px light/dark` and `...at 768px light/dark`; the shapes are pinned by the verifier fixtures.

## Routed defects: what fixed each

| Entries | Fix (tier) |
|---|---|
| A11Y-254-01, 02 | `role="group"` on the two aria-label summaries (page markup, `subscription_live.ex`) |
| A11Y-254-03 to 22 | the reduced-motion token block in `theme.css` now also names `.psb-sandbox.accrue-admin` (token tier); 20 element signatures stop reporting transitions under reduce |
| A11Y-254-23 | the row Customer details link carries `aria-label="Customer details for <customer>"` (`subscriptions_live.ex`; visible text and Floki text unchanged) |
| A11Y-254-24, 25 | 200% text reflow (app.css): `.ax-field-list` columns are `repeat(auto-fit, minmax(min(100%, 16rem), 1fr))` instead of a 640 px viewport media rule; `.ax-audit-row` uses `auto-fit` too; on the detail page `overflow-wrap: anywhere`, `min-width: 0` for grid and flex items (zero-specificity `:where`), a single-column `.ax-page-header` grid, a container query that stacks a label/value pair when its list is narrower than 12rem, wrapping audit-summary spans; the filter chip may shrink and its value breaks anywhere |
| A11Y-254-26 | the drawer panel's single column is pinned (`grid-template-columns: minmax(0, 1fr)`) and the body breaks long text, so spaced text wraps instead of clipping |
| A11Y-254-27 | the drawer body is a labelled focusable region (`tabindex="0"`, `role="region"`, `aria-labelledby` the dialog title) in `overlay.ex`; modal and popover bodies are unchanged |
| A11Y-254-28 | `.ax-data-table-identity-secondary` row gap is `var(--ax-space-xs)` so a wrapped Customer details link keeps its 24 px target spacing |
| A11Y-254-29, 30 | `focus_trap.js`: a closed `<details>` content is never a focus target, focus returns to the owning `<summary>` (menu button), and every delayed return runs only when focus is lost |

## Task Commits

1. **254-12-01 RED:** `fcbe48f80` (spec, lab and default config admission, red evidence, verifier and fixtures)
2. **254-12-02 GREEN (CSS and contract):** `81ea61825`
3. **254-12-02 GREEN (accessibility fixes):** `df17d29b0`

**Plan metadata:** recorded in the docs commit that follows this summary.

## Decisions Made

See key-decisions. No Rule 4 decision arose: the plan settled the CSS, the contract text and the amendment shapes, and every routed defect had a lowest owning tier inside the shipped component, hook, token or page CSS.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Files outside the plan's file list had to change to fix routed defects**
- **Found during:** Task 02. The plan lists only CSS, the register and the contract, but 254-11 routed defects whose lowest owning tier is `theme.css` (sandbox reduced motion), `overlay.ex` (drawer region), `subscription_live.ex` and `subscriptions_live.ex` (names and roles), and `focus_trap.js` plus its built bundle (focus return).
- **Fix:** edited those files, added tests beside the existing owners (`overlay_components_test.exs`, `focus_trap_test.mjs`), and applied the B-1 digest regeneration recipe because `subscription_live.ex` and `subscriptions_live.ex` are `source_digests` inputs: R1 `storybook/phase252-manifest.json` and `guides/subscription-story-coverage.md`, R2 the curation ledger, R3 the selection projection, R4 `restamp-manifest --write --cause 254-12-02 --block 20-29` (DEV-254-20 `d0cc29a5f69a` to `e29aeda0382c`). `project --check` and `restamp-manifest --check` pass.
- **Commits:** `81ea61825`, `df17d29b0`

**2. [Rule 1 - Bug] The delayed focus return could take focus from a control the user had already moved to**
- **Found during:** Task 02, repeating the D-29 journey: 1 failure in about 70 desktop runs at the "Back to list" step (focus parked on `main` between the Tab and the Enter). The page-container fallback of `restoreFocus` ran two animation frames after the overlay closed unconditionally.
- **Fix:** `focusIsLost` guard on every delayed return; with it 80 of 80 desktop and 40 of 40 mobile repeats passed. Unit tests prove the guard (the no-steal test fails without it) and its positive control.
- **Commit:** `df17d29b0`

**3. [Rule 1 - Bug] Content of a closed `<details>` looks visible to the focus helpers**
- **Found during:** Task 02 (Escape returned focus to `main`). A closed disclosure keeps boxes for its content, so the hidden menu item passed `isVisibleForFocus` and its `focus()` was a silent no-op.
- **Fix:** `insideClosedDisclosure` makes it not visible; the owning `<summary>` becomes the return target.
- **Commit:** `df17d29b0`

**4. [Rule 1 - Bug] The assessment-stage contract check rejected the batch's own contract edit**
- **Found during:** Task 02. After the Typography rows were amended (this plan), `verify_phase254_design_review.mjs --check --stage assessment` failed because the add-row finding's row already existed; the record only moves to corrected in 254-13.
- **Fix:** an assessment record accepts a contract that already contains `amended_text` (fixtures: amended row and added row accepted, the original rejections kept).
- **Commit:** `df17d29b0`

**5. [Plan wording] The Typography row text is verbatim from the record, not the plan's `<action>` paraphrase**
- The plan's must_haves and the task instruction require the record's `amended_text`; the action's looser wording would not satisfy `checkContract` at stage corrected. The grep checks in the plan's verify pass with the verbatim rows.

**6. [Plan assumption] The `a11y-dispositions.json` test for the committed journey entries had to change**
- `verify_a11y_dispositions.test.mjs` asserted the two journey entries exist; deleting them is this plan's purpose, so the test now asserts the committed register holds no routed defect and no journey entry (with a seeded positive control).

### Noted, not changed

- **Accidental aggregate start:** I invoked `verify_phase253_compositions.mjs --help` once expecting a usage line; it ignores flags and started a full run. I killed that run and the orphaned lab browser lane and server it had spawned (identified by their `accrue_admin` command lines and sub-minute age); nothing it wrote was kept, and `--results-latest` still reads the earlier complete bundle `8fba211b...`.
- **Stale local Phase 253 manifest:** after editing `subscription_live.ex` the ignored `accrue_admin/tmp/phase253/manifest.json` was stale and made every lab run throw at import, so I moved it aside (copy in the session scratchpad) and the aggregate regenerated it.
- **Gate by-products:** no untracked `.planning/phases/200-idempotent-verification-sign-off/` and no change to `accrue_admin/tmp/phase252/render-results.json` appeared; the only uncommitted file at the end is the pre-existing `.planning/config.json`, never staged.
- **`css:census` reports 156 orphan selectors.** It is an informational tool outside CI and none are selectors this plan introduced.
- **Same defects elsewhere, not routed and not touched:** `charges_live.ex` has the same repeated "Customer details" link text, and `component_kitchen_live.ex` has two more `aria-label`-without-role summaries. Neither appeared in a measured cell.

## Known Stubs

None.

## Threat Flags

None. T-254-24 (shared label cascade): the label rule is scoped to `.ax-field-list`; the spec asserts a bare form label keeps `--ax-type-sm` and the values keep tabular figures. T-254-37 (hand-authored red evidence): evidence is written only by `--record-red` and re-checked by `--check-red`; fixtures reject every setup-crash shape. T-254-SC: no dependency changed.

## Open flags for later plans

- **254-13 (record update):** write AMD-254-04 and AMD-254-05 in the shapes pinned by the verifier fixtures (decisions, original, amended, rationale, `evidence` including `254-12-01-red-evidence.json` and the register path, `register_commit`, `affected_cells`, `owner_ack {2026-10-28, owner-accepted at plan time}`). The `restamp-manifest` block 20-29 now has DEV-254-20 used; the tool takes the next free id. The spec file must not change after the red evidence (`--check-red` compares its sha256).
- **254-14 and 254-15 (baselines):** the label rule and the field-list change alter the subscription detail, invoice detail and component-kitchen pixels (expected, DR-254-03 and the 200% reflow), and 254-15 asserts `subscriptions.png` and `subscriptions-dark.png` stay byte-identical. Two changes can touch the list page only when content wraps: the identity secondary row gap (A11Y-254-28; in the Storybook story at 1280 two of four rows wrap, the mounted full-width list may not) and the filter chip shrink rule. If the mint shows a list change, trace it to A11Y-254-28 before dispositioning.
- **254-15:** the container query (`@container (max-width: 12rem)`) needs a Chromium that supports container queries; it is already required by the pinned Playwright browser.
- **254-17:** unchanged from 254-11 (the transparency prohibition for automated results).

## Self-Check: PASSED

Created files exist (`subscription-design-phase254.spec.js`, `254-12-01-red-evidence.json`); commits `fcbe48f80`, `81ea61825` and `df17d29b0` are ancestors of HEAD; `git rev-list --count 073e33792d7fd55810f7afd12908ff247caca206..HEAD` measured 3 before this summary commit.
