---
phase: 197-propagate-list
plan: "01"
subsystem: testing
tags: [phoenix-liveview, playwright, exunit, spec-list, pageheader, list-propagation]

requires:
  - phase: 196-subscriptions-list-pageheader
    provides: Subscriptions LIST exemplar, PageHeader contract, DataTable state semantics, FilterChipBar contract
provides:
  - Test-only LIST propagation manifest covering all eight Phase 197 target pages
  - RED query contracts for Webhooks multi-status replay, Connect attention, and Payments owner scope
  - Phase 197 Playwright browser contract and npm script for all-page LIST propagation smoke
affects: [phase-197-propagate-list, phase-200-verification-signoff, accrue_admin-list-pages]

tech-stack:
  added: []
  patterns:
    - Test-only contract manifest in test/support for cross-page LIST expectations
    - RED-first query contracts for high-risk URL/filter semantics
    - Project-scoped Playwright coverage to avoid an exhaustive desktop/mobile matrix

key-files:
  created:
    - accrue_admin/test/support/list_contracts.ex
    - accrue_admin/e2e/admin-spec-list-phase197.spec.js
  modified:
    - accrue_admin/test/accrue_admin/queries/query_modules_test.exs
    - accrue_admin/package.json

key-decisions:
  - "Wave 0 remains validation-only: RED contracts define required Phase 197 behavior before runtime page migrations."
  - "The browser contract is project-scoped: desktop all-page/deep checks run on chromium-desktop and mobile card smoke runs on chromium-mobile."

patterns-established:
  - "ListContracts manifest: route, list id, default lens, all target, copy, clear-all, and loading fixture expectations live in test/support only."
  - "Phase 197 RED checks may fail for missing runtime behavior, but syntax, fixture setup, route reachability, and command wiring must pass."

requirements-completed: [PRP-01]

duration: 16min
completed: 2026-06-28
status: complete
---

# Phase 197 Plan 01: Wave 0 Validation Scaffold Summary

**Executable LIST propagation contracts for eight remaining admin list pages, covering manifest rows, RED query semantics, and focused Playwright browser smoke.**

## Performance

- **Duration:** 16 min
- **Started:** 2026-06-28T16:06:56Z
- **Completed:** 2026-06-28T16:22:49Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Added `AccrueAdmin.ListContracts`, a test-only manifest for customers, invoices, payments, coupons, promotion codes, webhooks, events, and connect accounts.
- Added RED ExUnit contracts for Webhooks replay status allowlisting, Connect `needs_attention`, and Payments/Charges owner-scope filtering.
- Added `admin-spec-list-phase197.spec.js` plus `npm run e2e:phase197` to exercise all target routes through PageHeader, LIST chrome, chips, counts, clear-all, mobile cards, loading fixtures, and representative deep coverage.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create the Phase 197 LIST contract manifest** - `216cec3a` (test)
2. **Task 2: Add RED query contracts for high-risk LIST semantics** - `5644d835` (test)
3. **Task 3: Create the Phase 197 browser smoke contract and script** - `e2ac0ba6` (test)

## Files Created/Modified

- `accrue_admin/test/support/list_contracts.ex` - Test-only manifest for all eight target list pages and their default lenses, clear-all targets, empty/loading copy, and list ids.
- `accrue_admin/test/accrue_admin/queries/query_modules_test.exs` - RED query coverage for Webhooks status replay, Connect attention, and Charges owner-scope behavior.
- `accrue_admin/e2e/admin-spec-list-phase197.spec.js` - Playwright contract for all-page LIST smoke plus representative deeper cases.
- `accrue_admin/package.json` - Adds the focused `e2e:phase197` command.

## Decisions Made

- Wave 0 stays validation-only. The plan intentionally does not implement the runtime behavior that makes the new contracts green.
- Browser coverage is scoped by Playwright project: desktop all-page/deep checks run only on `chromium-desktop`; mobile all-page card smoke runs only on `chromium-mobile`.

## Deviations from Plan

None - plan executed as written.

## Verification

- `cd accrue_admin && mix test test/accrue_admin/queries/query_modules_test.exs --max-failures 3` - RED as expected: 10 tests reached, 3 planned failures for missing Webhooks replay-status, Connect attention, and Charges owner-scope semantics.
- `cd accrue_admin && node --check e2e/admin-spec-list-phase197.spec.js` - passed.
- `cd accrue_admin && node -e "const p=require('./package.json'); if(!p.scripts['e2e:phase197'] || !p.scripts['e2e:phase197'].includes('e2e/admin-spec-list-phase197.spec.js')) process.exit(1)"` - passed.
- `cd accrue_admin && npm run e2e:phase197` - RED as expected after reaching the admin app: 15 failed, 15 skipped, with failures limited to missing Phase 197 runtime behavior (PageHeader markers, default URL lenses, chips, loading fixture, and mobile LIST card contract).

## Issues Encountered

The first Playwright run proved the command reached the app but duplicated all checks across both configured projects. The spec was tightened before commit so desktop and mobile checks run in their intended projects without turning the scaffold into an exhaustive matrix.

## Known Stubs

None.

## Threat Flags

None. This plan added test-only contracts and an npm script; it introduced no new runtime endpoint, auth path, file access, or schema trust boundary.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Wave 1 can now migrate shared LIST/PageHeader seams against executable RED contracts. The remaining RED results are the intended handoff for later Phase 197 implementation plans.

## Self-Check: PASSED

- Found expected files: `accrue_admin/test/support/list_contracts.ex`, `accrue_admin/test/accrue_admin/queries/query_modules_test.exs`, `accrue_admin/e2e/admin-spec-list-phase197.spec.js`, `accrue_admin/package.json`.
- Found task commits: `216cec3a`, `5644d835`, `e2ac0ba6`.
- Unrelated `.planning/research/.cache/` files remain untracked and were not modified or staged.

---
*Phase: 197-propagate-list*
*Completed: 2026-06-28*
