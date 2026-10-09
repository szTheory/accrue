---
phase: 240-shared-system-and-real-billing-exemplar
plan: "03"
subsystem: billing-ui
tags: [invoice, phoenix-liveview, playwright, responsive-css, accessibility]
requires:
  - phase: 240-01
    provides: invoice review identity, server-owned action eligibility, shared dense geometry
  - phase: 240-02
    provides: blocking Linux snapshot-set guard and CI owner
provides:
  - Explicit safe recovery copy for unsupported invoice actions
  - Mounted invoice list and detail review acceptance across narrow and intermediate widths
  - Coarse-pointer 44px targets for invoice table links and staged drawer form controls
affects: [240-04, 240-05, 240-06, 241, 242]
actuals:
  tokens: 70066
  tasks: 3
  commits: 6
tech-stack:
  added: []
  patterns:
    - Mounted Playwright assertions use the Phase 191 real seeded invoice and assert exact formatted money and identity.
    - Coarse-pointer 44px target fixes live in the owning shared selector and ship with rebuilt package CSS.
key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/copy/invoice.ex
    - accrue_admin/lib/accrue_admin/live/invoice_live.ex
    - accrue_admin/test/accrue_admin/live/invoice_live_test.exs
    - accrue_admin/assets/css/app.css
    - accrue_admin/priv/static/accrue_admin.css
    - accrue_admin/e2e/admin-spec-list-phase196.spec.js
    - accrue_admin/e2e/admin-spec-detail-phase198.spec.js
key-decisions:
  - "Use the existing detail-page missing-due wording and the real JPY formatting from the seeded fixture in mounted assertions."
  - "Keep 44px target sizing under pointer: coarse so the incumbent fine-pointer density remains intact."
  - "Record CDP page scale as pinch/visual scaling; the installed headless browser cannot faithfully exercise browser page zoom."
requirements-completed: [DSN-01, DSN-02, UXC-02, EVR-02]
coverage:
  - id: D1
    description: Unsupported invoice actions explain the unavailable state and offer only a safe return to the invoice.
    requirement: UXC-02
    verification:
      - kind: unit
        ref: "accrue_admin/test/accrue_admin/live/invoice_live_test.exs#unsupported invoice action recovery"
        status: pass
    human_judgment: false
  - id: D2
    description: Seeded invoice list identity, exact money, state, and target remain reachable at required widths and in coarse-pointer mode.
    requirement: DSN-01
    verification:
      - kind: e2e
        ref: "npm run e2e:phase196 (14 passed)"
        status: pass
    human_judgment: false
  - id: D3
    description: Invoice detail and staged void review retain identity, exact money, state, target, focus, and controls across required widths, CSS enlargement, spacing, and coarse-pointer modes.
    requirement: DSN-02
    verification:
      - kind: automated_ui
        ref: "npm run e2e:phase198 (28 passed, 4 existing mobile action skips)"
        status: pass
      - kind: automated_ui
        ref: "npm run e2e:a11y (2 passed)"
        status: pass
    human_judgment: false
  - id: D4
    description: CSS enlargement, text-spacing simulation, and available page-scale evidence are distinguished from actual browser zoom, whose control is unavailable in the headless host.
    requirement: EVR-02
    verification:
      - kind: e2e
        ref: "Phase 196/198 zoom evidence: visualViewport scale 3 desktop / 4 mobile while CSS viewport remains 320px; test logs state the headless host limitation"
        status: pass
    human_judgment: false
metrics:
  duration: 9min
  completed: 2026-10-09
  status: complete
  commits: 6
  plan_head_before: a588121f67464e380465f686dbd2e730689aea4d
  plan_head_after: 6ae839c792cf95cf9d94e05a8d157bb097860135
---

# Phase 240 Plan 03: Truthful Invoice States and Responsive/Content Acceptance Summary

**Invoice unsupported-action recovery and responsive list/detail review acceptance, with truthful zoom limits and shared coarse-pointer targets.**

## Performance

- **Duration:** 9 minutes
- **Started:** 2026-10-09T20:50:12Z
- **Completed:** 2026-10-09T20:59:15Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments

- Added a focused unsupported invoice-action negative case and explicit safe recovery copy, without dispatching a provider action.
- Added mounted list and detail/review checks using the actual seeded Unicode customer and JPY invoice, preserving exact identity, formatted money, state, missing-due disclosure, review target, visible focus, and served CSS bytes.
- Verified width boundaries, separate 200% CSS text enlargement, text-spacing overrides, and coarse-pointer use. Raised coarse-pointer table links and action-drawer form controls to the shared 44px target; rebuilt and served the package CSS.
- Recorded CDP page scale separately from browser zoom: it changed `visualViewport.scale` while CSS width stayed 320px, so it is pinch/visual scaling and not proof of actual 400% browser zoom. This headless host exposed no faithful browser zoom control.

## Task Commits

1. **Task 1: Make invoice state and next-step distinctions exact** - `30f90d4b` (RED), `67b1ebca` (GREEN)
2. **Task 2: Preserve invoice list facts and controls across width and content extremes** - `a8d4a5d6` (RED), `7f1d89a4` (GREEN)
3. **Task 3: Keep detail and review access under enlargement and zoom** - `3f6e161b` (RED), `6ae839c7` (GREEN)

Plan commit ledger measured six commits from `a588121f67464e380465f686dbd2e730689aea4d` through `6ae839c792cf95cf9d94e05a8d157bb097860135`.

## Files Modified

- `accrue_admin/lib/accrue_admin/copy/invoice.ex` - explicit unavailable action copy with a supported return path.
- `accrue_admin/lib/accrue_admin/live/invoice_live.ex` - renders the explicit copy for forged unsupported actions.
- `accrue_admin/test/accrue_admin/live/invoice_live_test.exs` - verifies exact unsupported-action recovery and no dispatch.
- `accrue_admin/e2e/admin-spec-list-phase196.spec.js` - seeded invoice list width, CSS enlargement, spacing, page-scale evidence, and coarse-pointer checks.
- `accrue_admin/e2e/admin-spec-detail-phase198.spec.js` - seeded invoice detail/review responsive, enlargement, spacing, focus, and coarse-pointer checks.
- `accrue_admin/assets/css/app.css` - coarse-pointer target sizing for data-table links and action-drawer form buttons.
- `accrue_admin/priv/static/accrue_admin.css` - rebuilt package CSS served by the mounted app.

## Decisions Made

- Kept the detail assertion aligned with the actual explicit “No due or finalized boundary” message and rendered `¥100,000` amount.
- Scoped the 44px adjustment to coarse pointers, preserving fine-pointer data density.
- Treated browser zoom availability as an evidence limitation, not as a CSS or viewport-emulation pass.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical interaction sizing] Raised coarse-pointer drawer review control to 44px**
- **Found during:** Task 3
- **Issue:** At 768px with a coarse pointer, the invoice drawer review submit button measured 36px high despite the existing 44px touch-target direction.
- **Fix:** Added a coarse-pointer rule for action-drawer form buttons and rebuilt package CSS.
- **Files modified:** `accrue_admin/assets/css/app.css`, `accrue_admin/priv/static/accrue_admin.css`
- **Verification:** Coarse-pointer detail tests passed in desktop and mobile Playwright projects; full Phase 198 and axe suites passed.
- **Committed in:** `6ae839c7`

**Total deviations:** 1 auto-fixed (Rule 2)
**Impact on plan:** The shared selector fix closed a mounted interaction defect within the planned responsive acceptance scope.

## Issues Encountered

- Initial detail assertions assumed list-style missing-due copy and literal “JPY”; mounted output instead displayed the accurate detail copy and `¥100,000`. Assertions were corrected to the observed existing output; no product copy or money behavior was changed for this.
- The detector reported incumbent font-role warnings and side-tab borders in untouched selectors; these were outside this plan's changed surface and left unchanged.

## Verification

- `MIX_ENV=test mix test test/accrue_admin/live/invoices_live_test.exs test/accrue_admin/live/invoice_live_test.exs` — 36 tests passed.
- `npm run e2e:phase196` — 14 passed, both desktop and mobile projects.
- `npm run e2e:phase198` — 28 passed; 4 existing mobile action cases remain skipped by their owner configuration.
- `npm run e2e:a11y` — 2 passed, desktop and mobile.
- The mounted detail assertion compared served package CSS bytes with `priv/static/accrue_admin.css`; the rebuilt stylesheet was served successfully.
- `git diff --check` — passed.

## User Setup Required

None.

## Next Phase Readiness

The invoice list and detail review exemplar now has recurring mounted acceptance for the implemented responsive cases. Actual 400% browser zoom still needs a browser/host mechanism that can set it faithfully. Plan 240-04 remains the owner for full keyboard containment and the previously logged focus-trap/command-palette harness failures.

---
*Phase: 240-shared-system-and-real-billing-exemplar*
*Completed: 2026-10-09*

## Self-Check: PASSED

- SUMMARY file exists at the required phase path.
- All six measured task commits are ancestors of the current plan head.
- Summary commit ledger matches `git rev-list --count`: 6 commits from the recorded base.
