---
phase: 252-production-backed-subscription-stories
plan: "06"
subsystem: testing
tags: [phoenix, phoenix-live-view, phoenix-storybook, playwright, responsive-ui]

requires:
  - phase: 252-03
    provides: guarded disposable browser and admin-test lanes
  - phase: 252-05
    provides: generated subscription variations, stable routes, and source-backed manifest
provides:
  - Twelve direct subscription render cases across exact mobile/desktop widths and light/dark themes
  - Twenty named UI predicate assertions with a reconciled browser evidence ledger
  - Storybook iframe access to the existing application hooks, CSS, JS, and Geist fonts
affects: [252-07, 253]

actuals:
  tokens: 337715
  tasks: 2
  commits: 4

commits: 4
plan_head_before: 307c118c474e8bd1896e9052415e2713a3175b1a
plan_head_after: 85ee42df92944f56b9aacfd29504cf6057597296

tech-stack:
  added: []
  patterns:
    - Storybook registers the application's existing LiveView hooks before its iframe socket starts.
    - Browser evidence matches the exact served CSS and JS bytes and records successful font responses.

key-files:
  created:
    - .planning/phases/252-production-backed-subscription-stories/252-06-01-red-evidence.json
    - .planning/phases/252-production-backed-subscription-stories/252-06-02-red-evidence.json
    - accrue_admin/assets/js/storybook_hooks.js
    - accrue_admin/tmp/phase252/render-results.json
  modified:
    - accrue_admin/assets/css/app.css
    - accrue_admin/e2e/phase252-story-helpers.js
    - accrue_admin/e2e/subscription-stories-phase252.spec.js
    - accrue_admin/lib/accrue_admin/router.ex
    - accrue_admin/playwright.config.js
    - accrue_admin/playwright.phase252.config.js
    - accrue_admin/priv/static/accrue_admin.css
    - accrue_admin/priv/static/storybook.css
    - accrue_admin/priv/static/storybook.js
    - guides/subscription-story-coverage.md
    - storybook/phase252-manifest.json

key-decisions:
  - "Reuse the application's LiveView hook modules in Storybook instead of duplicating clipboard or timestamp behavior."
  - "Treat the stories as static content evidence; mounted authority, provider completion, and persistence remain outside this plan."
  - "Fit the action menu inside the actual Storybook preview while preserving the application's viewport-aware positioning."

patterns-established:
  - "Canonical browser cases retain independent state, width, theme, URL, attribution, and assertion evidence."
  - "Generated results must reconcile to actual DOM content, current served assets, font responses, and exact manifest keys."

requirements-completed: [SBK-02, SBK-03, SCEN-04]

coverage:
  - id: D1
    description: "Generated subscription variations open directly with real DOM content and reconcile exactly; invalid routes, missing variations, and metadata-only rows are rejected."
    requirement: SBK-02
    verification:
      - kind: e2e
        ref: "accrue_admin/e2e/subscription-stories-phase252.spec.js (16 passed; 12 canonical cases, 3 compatibility cases, 1 reconciliation test)"
        status: pass
      - kind: other
        ref: "accrue_admin/tmp/phase252/render-results.json (15 passed result rows; current asset identity; all negative controls rejected)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The production subscription area satisfies all twenty UI predicates in 320/1280px light/dark cases, including responsive facts, action targets, keyboard focus, and current fonts."
    requirement: SBK-03
    verification:
      - kind: automated_ui
        ref: "accrue_admin/e2e/phase252-story-helpers.js#assertUiPredicateContract (all twelve canonical cases passed)"
        status: pass
      - kind: integration
        ref: "test/accrue_admin/live/subscription_live_test.exs (40 passed)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Separately labelled held-out customer names and IDs wrap within the narrow preview and the registered Clipboard hook copies the complete ID."
    requirement: SCEN-04
    verification:
      - kind: automated_ui
        ref: "accrue_admin/e2e/phase252-story-helpers.js#assertHeldOutLongText (active 320px light/dark cases passed)"
        status: pass
    human_judgment: false

metrics:
  duration: 80min
  completed: 2026-10-26
status: complete
---

# Phase 252 Plan 06: Subscription Story UI Predicate Summary

**Direct subscription stories now prove all twenty UI predicates with current assets, working copy hooks, and complete 320/1280px light/dark evidence.**

## Performance

- **Duration:** About 80 minutes
- **Started:** 2026-10-26T21:10:59-04:00
- **Completed:** 2026-10-26T22:31:09-04:00
- **Tasks:** 2
- **Files modified:** 15

## Accomplishments

- Added independent direct-render cases for each of the three canonical states at 320px and 1280px in light and dark themes, plus all three retained compatibility variations.
- Asserted the twenty named UI predicates against the actual Storybook render, including complete content, responsive layout, action/menu semantics, focus visibility, and full-ID clipboard behavior.
- Recorded 15 real render rows with `human_judgment: false`; the manifest reconciler rejects invalid routes, missing variations, and metadata-only content.
- Served PhoenixStorybook runtime assets, application hooks, and both self-hosted Geist font faces in the development Storybook iframe; verified exact served CSS/JS identity.
- Fixed action-menu clipping in the narrow Storybook preview while keeping the existing mounted Subscription LiveView regression green.

## Verification Evidence

- `node scripts/dev/phase252_lab.mjs browser -- --reporter=junit e2e/subscription-stories-phase252.spec.js` — 16 passed, 0 failures/errors in the guarded disposable Phase 252 browser lane.
- `node scripts/dev/phase252_lab.mjs exec --lane admin-test -- sh -c 'cd accrue_admin && env MIX_ENV=test mix test test/accrue_admin/live/subscription_live_test.exs'` — 40 passed, 0 failures in a fresh disposable admin-test database.
- The result ledger records 12 canonical cases, 3 compatibility cases, coverage for all 20 predicates, three rejected negative controls, two font responses with status 200, and zero browser console or request errors.
- `git diff --check` passed. No dependencies were installed and no screenshots or visual baselines were updated.

## Task Commits

1. **Task 1 — Visit generated direct variations** — `38d73758` (RED), `91e1b011` (GREEN).
2. **Task 2 — Enforce twenty UI predicates** — `86b24d6d` (RED), `85ee42df` (GREEN).

## Decisions Made

- Storybook uses the existing Accrue hook implementations and does not initialize a second application LiveSocket.
- Static story evidence establishes rendered content and presentation only. It makes no claim about action dispatch, mounted authorization, provider completion, or persistence.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 — Blocking issue] Pass the CSP nonce to the Storybook LiveView**
- **Found during:** Task 1
- **Issue:** The Storybook iframe's scripts and stylesheet did not receive the application's CSP nonce.
- **Fix:** Set the existing `:accrue_admin_csp_nonce` assign key on `live_storybook`.
- **Files modified:** `accrue_admin/lib/accrue_admin/router.ex`
- **Verification:** Direct renders loaded the current CSS/JS successfully.
- **Committed in:** `91e1b011`

**2. [Rule 3 — Blocking issue] Serve PhoenixStorybook and font assets from dev-only routes**
- **Found during:** Task 2
- **Issue:** The iframe requested PhoenixStorybook's default CSS/JS and the relative Geist font URLs from paths that had no matching routes.
- **Fix:** Mount `storybook_assets()` and add Storybook-scoped routes for the existing self-hosted font assets inside the `allow_live_reload`-gated route block.
- **Files modified:** `accrue_admin/lib/accrue_admin/router.ex`
- **Verification:** The final browser run received both fonts with status 200 and reported no failed requests.
- **Committed in:** `85ee42df`

**3. [Rule 2 — Missing critical functionality] Register the application hooks in the Storybook iframe**
- **Found during:** Task 2
- **Issue:** The iframe logged unknown `Clipboard` and `TimeDisplay` hooks, so the story's copy control did not use production behavior.
- **Fix:** Bundle the existing app hook exports into a Storybook-only entry and register them in `window.storybook.Hooks` before PhoenixStorybook starts its iframe socket.
- **Files modified:** `accrue_admin/assets/js/storybook_hooks.js`, `accrue_admin/priv/static/storybook.js`
- **Verification:** Ordinary and held-out IDs copied their complete values in the browser suite.
- **Committed in:** `85ee42df`

**4. [Rule 1 — UI clipping bug] Keep the action menu within the preview**
- **Found during:** Task 2
- **Issue:** A right-aligned panel with content-box sizing was clipped in the Storybook preview when a compatibility state exposed only destructive actions.
- **Fix:** Left-align the action menu panel and include its padding and border in the panel width.
- **Files modified:** `accrue_admin/assets/css/app.css`, `accrue_admin/priv/static/accrue_admin.css`, `accrue_admin/priv/static/storybook.css`
- **Verification:** All canonical and compatibility render cases passed the clipping checks.
- **Committed in:** `85ee42df`

**5. [Rule 1 — Browser assertion bug] Measure held-out content in the same preview and detect actual clipping**
- **Found during:** Task 2
- **Issue:** The initial helper treated a computed ellipsis style as truncation even when text wrapped completely, and a clone outside the Storybook preview's containing context produced misleading bounds.
- **Fix:** Check visible geometry and scroll dimensions, place the clone beside the original preview, and use a locator scoped directly to its fact row.
- **Files modified:** `accrue_admin/e2e/phase252-story-helpers.js`
- **Verification:** All twelve canonical cases passed; the held-out 320px cases also copied the complete synthetic ID.
- **Committed in:** `85ee42df`

**Total deviations:** 5 auto-fixed (2 Rule 1, 1 Rule 2, 2 Rule 3).
**Impact on plan:** Each fix was required for real browser evidence and stayed within the existing Storybook, asset, and CSS owners.

## Issues Encountered

PhoenixStorybook emitted non-fatal compile-time resolver warnings for the custom CSS/JS paths under its build-tree static directory. Its development routes served the exact committed bundles, and the browser verified their byte identity and successful responses. Direct-render tests did not establish full-page behavior or action persistence.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: dev_asset_routes | `accrue_admin/lib/accrue_admin/router.ex` | Added fixed Storybook asset routes for existing static files. They are emitted only when the existing `allow_live_reload` dev-route gate is enabled; production routes remain omitted. |

## User Setup Required

None.

## Next Phase Readiness

Plan 252-07 can build on the generated manifest and current direct-render evidence. Phase 253 remains the owner for full-page subscription detail and mounted action journeys.

---
*Phase: 252-production-backed-subscription-stories*
*Completed: 2026-10-26*

## Self-Check: PASSED

- Summary file exists at the expected phase path.
- All four task commits are ancestors of the current HEAD.
- `git diff --check` passed.

## Supplemental UI Verification after CR-01

- The final `ERL_FLAGS='+S 4:4' npm --prefix accrue_admin run phase252:check` run `25208-1793102721082-59067-6ba5536df2dd` passed all 18 commands. The browser reporter recorded 16 executed tests, zero skipped or failed tests, and 15 distinct render rows including all 12 canonical state × width × theme cells.
- Canonical viewport screenshots are in `accrue_admin/tmp/phase252/ci-results/25208-1793102721082-59067-6ba5536df2dd/screenshots/` (320 × 1100 and 1280 × 1100, light and dark). I inspected all 12: the production title/facts/actions use the live Geist and theme tokens, the 320px content uses one column, and the scheduled and incomplete variations visibly show their own cancellation and missing-evidence rows.
- Focused mobile positives `25208-focus-20261027-34785` passed 4/4 for scheduled cancellation and incomplete evidence at 320px, light/dark. The four images in its unique screenshot directory show the title and each variation’s distinguishing rows.
- The capture uses the declared `#<variation>-component` preview on the page containing all variations, aligns that preview below the Storybook toolbar, and records its identity with the viewport image. No golden image changed; historical `accrue_admin/tmp/phase252/render-results.json` and previous captures remain untouched.

## Supplemental UI Verification: Light Host Accent Binding

- Commit `3991d890` supplies the production host `--ax-accent` to the real `.psb-sandbox.accrue-admin` scope through the root token alias, preserving production host overrides and using the existing brandbook accent fallback for the direct Storybook route.
- Focused active-light browser checks passed at 320px and 1280px in run `25208-accent-focus-20261027-1235` (2 passed, 0 skipped). I inspected `accrue_admin/tmp/phase252/ci-results/25208-accent-focus-20261027-1235/screenshots/active-320-light.png` and `active-1280-light.png`; both show visible blue row links, and the desktop capture shows the filled Change plan CTA. Assertions check the resolved accent, opaque CTA paint, and effective-background contrast for the CTA and Plan / price Change action (5.9845:1 and 6.8392:1 at both widths). The host override mutation to `#26428b` also updates the sandbox and row action.
- Fresh owner run `25208-1793102721082-59067-6ba5536df2dd` passed all 18 commands and 16 executed browser tests with zero skips or failures, reconciling 15 render rows. I inspected its twelve direct light/dark screenshots for the active, scheduled-cancellation, and incomplete-evidence states at 320px and 1280px. The live DOM assertions cover the primary action below the mobile screenshot fold.
- The remaining visual audit notes about desktop summary/action width and copy-affordance discoverability are deferred; this fix made no screenshot framing or golden-image changes.
