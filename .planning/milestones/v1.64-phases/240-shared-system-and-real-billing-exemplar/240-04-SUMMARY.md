---
phase: 240-shared-system-and-real-billing-exemplar
plan: "04"
subsystem: ui
tags: [phoenix-liveview, theme, focus, playwright, node-test]
requires:
  - phase: 240-01
    provides: Admin invoice identity and keyboard target geometry
  - phase: 240-02
    provides: Mounted Admin component and guard test owners
provides:
  - LiveView-patched theme controls reflect the stored preference while effective System colors follow the OS.
  - Keyboard invoice review coverage for containment, associated validation, correction, submission, and teardown.
  - FocusTrap and command-palette Node harnesses provide browser focus APIs; prior nine-test harness failures are resolved.
affects: [phase-240, admin-theme, admin-overlays, keyboard-accessibility]
actuals:
  tokens: 96684
  tasks: 2
  commits: 5
  plan_head_before: ea1ff2e83fa0f783f35392140a369568cacd8665
  plan_head_after: aec79f5231154faccc78066f757d8c7c5605d502
tech-stack:
  added: []
  patterns:
    - MutationObserver resynchronizes theme controls after LiveView replaces their DOM.
    - Node hook tests install and restore a minimal window focus API around each document fixture.
key-files:
  created:
    - .planning/phases/240-shared-system-and-real-billing-exemplar/240-04-SUMMARY.md
  modified:
    - accrue_admin/assets/js/hooks/accrue_theme.js
    - accrue_admin/priv/static/accrue_admin.js
    - accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js
    - accrue_admin/test/accrue_admin/components/theme_picker_test.exs
    - accrue_admin/test/accrue_admin/theme_test.exs
    - examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js
    - accrue_admin/test/js/focus_trap_test.mjs
    - accrue_admin/test/js/command_palette_test.mjs
    - .planning/phases/240-shared-system-and-real-billing-exemplar/deferred-items.md
key-decisions:
  - Keep stored theme preference and computed appearance as independent assertions, including host-forced precedence.
  - Keep the FocusTrap implementation unchanged; provide its actual browser focus APIs in the Node harness.
patterns-established:
  - Assert preference selection separately from effective computed colors after LiveView patches and OS changes.
  - Verify focus restoration against both a surviving replacement target and a logical page fallback.
requirements-completed: [DSN-03, DSN-05, EVR-02]
coverage:
  - id: D1
    description: Stored System preference remains selected as effective colors follow OS light/dark/light through patch and reload; forced host theme retains precedence.
    requirement: DSN-03
    verification:
      - kind: integration
        ref: "mix test test/accrue_admin/components/theme_picker_test.exs test/accrue_admin/theme_test.exs (19 passed)"
        status: pass
      - kind: e2e
        ref: "Playwright Phase 199 theme cases (3 passed); Phase 238 host-forced Admin theme case (1 passed)"
        status: pass
    human_judgment: false
  - id: D2
    description: Keyboard review contains focus, associates invalid-code feedback, permits corrected submission, and safely dismisses overlays with reduced motion.
    requirement: DSN-05
    verification:
      - kind: unit
        ref: "node --test --test-reporter=tap test/js/*.mjs (41 passed)"
        status: pass
      - kind: e2e
        ref: "Playwright Phase 199 @keyboard invoice review case (1 passed)"
        status: pass
    human_judgment: false
  - id: D3
    description: Existing Node browser-hook suite executes with focus globals and the earlier nine FocusTrap/command-palette harness failures are resolved.
    requirement: EVR-02
    verification:
      - kind: unit
        ref: "node --test --test-reporter=tap test/js/*.mjs (41 passed)"
        status: pass
    human_judgment: false
duration: 23min
completed: 2026-10-09
status: complete
---

# Phase 240 Plan 04: Theme and Keyboard Review Summary

**Stored System theme stays distinct from effective OS colors across LiveView replacement, while keyboard invoice review now has mounted coverage for focus wrapping, validation, correction, and teardown.**

## Performance

- **Duration:** 23 minutes including the acceptance follow-up
- **Started:** 2026-10-09T21:10:49Z
- **Completed:** 2026-10-09T21:34:18Z
- **Tasks:** 2
- **Files modified:** 23 including durable acceptance evidence and plan metadata

## Accomplishments

- Added mounted assertions for selected System preference and computed light/dark/light colors across OS changes, LiveView patches, and reload; included absent/invalid preference fallback and a stale-style negative control.
- Fixed a reproduced LiveView replacement defect: the effective stored preference was correct, but replaced theme controls continued to show the cookie-derived choice. A small observer synchronizes their selected state from the effective theme.
- Added keyboard invoice review coverage for Tab and Shift+Tab wrapping, accessible invalid-code feedback, corrected keyboard submission, rapid reduced-motion dismissal, and logical focus fallback after the opener disappears.
- Added FocusTrap regression cases for replacement return targets and rapid reduced-motion teardown. The whole Admin Node hook suite now passes 41/41 after supplying missing browser focus APIs in the FocusTrap and command-palette test harnesses.
- Rebuilt and committed the pinned Admin browser asset. Impeccable detection returned no findings.

## Task Commits

1. **Task 1: Prove stored preference and effective theme through OS and host changes** - `65c1b80f` (test), `2a79b390` (feat)
2. **Task 2: Complete keyboard review, correction and focus restoration** - `d185347c` (test)

Original task commit count: 3. Acceptance follow-up commit: `aec79f52`. Total commits measured from the persisted plan ledger at follow-up summary write: 5, including the original plan metadata commit. Plan head before: `ea1ff2e83fa0f783f35392140a369568cacd8665`. Plan head after acceptance fix: `aec79f5231154faccc78066f757d8c7c5605d502`.

## Files Created/Modified

- `accrue_admin/assets/js/hooks/accrue_theme.js` - Resynchronizes selected theme controls after LiveView child replacement.
- `accrue_admin/priv/static/accrue_admin.js` - Rebuilt package asset containing the theme observer.
- `accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js` - Adds System lifecycle and keyboard review scenarios.
- `accrue_admin/test/accrue_admin/components/theme_picker_test.exs` and `accrue_admin/test/accrue_admin/theme_test.exs` - Verify observer behavior and stored/effective separation.
- `examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js` - Verifies forced host appearance while retaining a conflicting stored value.
- `accrue_admin/test/js/focus_trap_test.mjs` and `accrue_admin/test/js/command_palette_test.mjs` - Provide browser focus APIs to the test harness; cover replacement target and reduced-motion teardown.
- `.planning/phases/240-shared-system-and-real-billing-exemplar/deferred-items.md` - Resolves the nine Node harness failures and records unrelated Phase 199 failures.

## Decisions Made

- Theme assertions distinguish the persisted choice, effective `data-theme`, and computed consumer color; host-forced appearance takes precedence.
- FocusTrap production code required no change after browser-backed coverage; the prior Node failures were test harness omissions.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Keep replacement theme controls aligned with the effective stored preference**
- **Found during:** Task 1
- **Issue:** LiveView replacement controls showed the cookie-derived selection even though localStorage correctly controlled the effective theme.
- **Fix:** Observe child replacements under the document root and synchronize theme control state from the effective theme value.
- **Files modified:** `accrue_admin/assets/js/hooks/accrue_theme.js`, `accrue_admin/priv/static/accrue_admin.js`
- **Verification:** Theme ExUnit (19 passed), mounted Phase 199 theme cases (3 passed), Phase 238 host-forced theme case (1 passed).
- **Committed in:** `2a79b390`

**2. [Rule 3 - Blocking] Supply missing browser APIs to Node focus harnesses**
- **Found during:** Task 2
- **Issue:** Nine existing FocusTrap/command-palette tests failed in cleanup because the Node harness omitted `window` and `requestAnimationFrame`.
- **Fix:** Install and restore minimal browser focus globals for those tests; preserve focus behavior assertions and add replacement-target and reduced-motion teardown cases.
- **Files modified:** `accrue_admin/test/js/focus_trap_test.mjs`, `accrue_admin/test/js/command_palette_test.mjs`
- **Verification:** `node --test --test-reporter=tap test/js/*.mjs` passes 41/41.
- **Committed in:** `d185347c`

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking harness issue). The plan also authorized resolving the known Node harness deferral; no focus-trap production change or dependency was needed.

## TDD Gate Compliance

- **Task 1:** Preserved the native failing Phase 199 JUnit report and JSON record under ignored `accrue_admin/test-results/phase240-04-red-evidence/`; `gsd_run check tdd-red-evidence` returned `RED_EVIDENCE_OK` for the selected-preference assertion. The failure demonstrated replaced controls lacked the stored selection. The tests and report were committed in `65c1b80f`, followed by the observer implementation and rebuilt asset in `2a79b390`.
- **Task 2:** Added tests for established FocusTrap behavior and corrected a newly authored browser test sequence after the first runs exposed test choreography mistakes, not a production defect. No production implementation step was required. The existing removed-trigger behavior was verified with a replacement-target regression test and the mounted keyboard case passed. No synthetic RED evidence was created for existing passing behavior.

## Issues Encountered

- The first hook launch was blocked by macOS process permissions; rerunning the installed Chromium test with approved escalated access succeeded.
- The repository's PII pre-commit hook rejected the raw machine-local path in Task 1's unchanged JUnit RED record. The actual report and classifier JSON remain in the ignored local evidence directory; committed current-GREEN evidence is path-free.
- The first full `CI=1 npm run e2e:phase199` run exposed three acceptance fixture/selector failures; the follow-up below corrected them. The final full suite passes 21 tests with 15 existing skips and no failures.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Theme state and keyboard review contracts are available for later Phase 240 plans to reuse.
- The earlier Node harness failures are cleared and the full Phase 199 acceptance gate passes. No deferred Phase 199 acceptance failures remain.

## Self-Check: PASSED

- Summary file exists and the three task commits are ancestors of the final plan metadata commit.
- Task and metadata commit count is measured from the persisted `gsd-plan-head-before-240-04` ledger.
- No new placeholder or stub patterns were introduced in plan-owned implementation/test files.
- Threat-surface review found no new endpoint, auth path, file access pattern, or schema trust boundary.

---
*Phase: 240-shared-system-and-real-billing-exemplar*
*Completed: 2026-10-09*

## Acceptance Gate Follow-up (2026-10-09)

The plan was reopened to complete its required full Phase 199 acceptance gate. The original focused theme and keyboard cases were already passing; this follow-up fixed the three broader suite failures without removing assertions or adding retries.

- **Recovery fixture clock:** `seed_phase199_interactions!/0` used wall-clock timestamps while Recovery queries use `Accrue.Clock.utc_now/0`. Its five-day-old campaign therefore appeared outside the deterministic 30-day window and the route had no row. The fixture now uses the same application clock. The route test identifies the specific seeded subscription by its real `href` prefix (which also carries `return_to`) and continues to assert the long email accessible name and destination route.
- **Current Home DOM:** `DashboardLive` renders the Recent audit activity home section and the keyboard customer-search control; it does not render the historical `data-ax-zone="attention-rail"` selector. The two existing ratchet rows now target `.ax-home [data-command-palette-trigger]`, a real keyboard control on `/billing`. Both rows retain the same visible focus-outline assertion, with desktop and mobile coverage.
- **Evidence:** Both exact pre-fix target tests have native JUnit reports and records in this phase directory. `gsd_run check tdd-red-evidence` returned `RED_EVIDENCE_OK` for each. Current GREEN records and reports are preserved alongside them as `240-04-acceptance-route-{red,green}.*` and `240-04-acceptance-ratchet-{red,green}.*`.
- **Verification:** `CI=1 npm run e2e:phase199` passes 21 and skips 15 existing tests, with zero failures. `node --test --test-reporter=tap test/js/*.mjs` passes 41/41. The full suite and focused route/ratchet GREEN JUnit records are durable in the committed run evidence.
- **Fix commit:** `aec79f52` (`test(240-04): repair Phase 199 acceptance fixtures`).

This follow-up supersedes the initial closeout note that listed the three Phase 199 failures as open. `deferred-items.md` now records them as resolved.
