---
phase: 199-cross-cutting-interaction-overlay-correctness-fixture-stress
plan: 09
subsystem: ui
tags: [theme, anti-fouc, affordance, css-source-audit, playwright]

requires:
  - phase: 199-cross-cutting-interaction-overlay-correctness-fixture-stress
    provides: [Phase 199 dropdown/floating-panel viewport bounds from plan 199-08]
provides:
  - malformed accrue_theme cookie hardening before stylesheet load
  - browser coverage for production theme picker persistence through reload
  - explicit fixed-shell CSS source audit markers for transform and containment traps
  - continued Phase 199 affordance coverage for non-interactive empty states and absent controls
affects: [admin-ui, theme-persistence, anti-fouc, phase199-e2e, css-source-guards]

tech-stack:
  added: []
  patterns:
    - Anti-FOUC theme boot code treats decoded cookie values as untrusted input and falls back to trusted localStorage/default state.
    - Fixed viewport shells carry phase-scoped source-audit markers naming transform/filter/backdrop-filter/contain/perspective risks.

key-files:
  created:
    - .planning/phases/199-cross-cutting-interaction-overlay-correctness-fixture-stress/199-09-SUMMARY.md
  modified:
    - accrue_admin/test/accrue_admin/theme_test.exs
    - accrue_admin/lib/accrue_admin/layouts.ex
    - accrue_admin/assets/css/app.css
    - accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js

key-decisions:
  - "Treat malformed `accrue_theme` cookies as untrusted input in the anti-FOUC script and fall back to localStorage/default theme resolution before CSS loads."
  - "Keep the Phase 199 fixed-shell audit source-level and marker-backed in `app.css` instead of adding new runtime overlay architecture."

patterns-established:
  - "Theme persistence browser checks must exercise the production `accrue_theme` cookie/localStorage path and at least one real picker-to-reload flow."
  - "CSS fixed-shell audit markers identify the audited shell and explicitly name transform/filter/backdrop-filter/contain/perspective risks."

requirements-completed: [IXN-03, IXN-04]

duration: 9 min
completed: 2026-06-30
status: complete
---

# Phase 199 Plan 09: Affordance Semantics and Theme Persistence Summary

**Production theme boot now survives malformed `accrue_theme` cookies and Phase 199 browser/source checks prove reload persistence, system emulation, and fixed-shell audit coverage.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-06-30T03:17:00Z
- **Completed:** 2026-06-30T03:25:37Z
- **Tasks:** 1
- **Files modified:** 4

## Accomplishments

- Added RED coverage for malformed `accrue_theme` cookies and fixed-shell CSS source audit markers.
- Hardened the root anti-FOUC script so invalid percent-encoded cookie values cannot throw before `data-theme` is set.
- Extended Phase 199 `@theme` browser coverage with real theme-picker persistence through cookie/localStorage and reload.
- Added source-audit markers around fixed shell paths for overlay, command palette, command-palette backdrop, and mobile sidebar risks.

## Task Commits

This TDD task was committed atomically:

1. **Task 1 RED: Prove affordance semantics and production theme persistence** - `97c79102` (test)
2. **Task 1 GREEN: Harden theme persistence and source audit** - `23e53209` (feat)

**Plan metadata:** committed with this summary.

## Files Created/Modified

- `accrue_admin/test/accrue_admin/theme_test.exs` - Adds malformed-cookie anti-FOUC execution coverage and fixed-shell source-audit assertions.
- `accrue_admin/lib/accrue_admin/layouts.ex` - Adds safe cookie decoding before theme precedence resolution.
- `accrue_admin/assets/css/app.css` - Adds Phase 199 fixed-shell audit markers for the relevant viewport-fixed shells.
- `accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js` - Adds system dark-emulation assertion and real theme-picker reload persistence coverage.
- `.planning/phases/199-cross-cutting-interaction-overlay-correctness-fixture-stress/199-09-SUMMARY.md` - Plan execution summary.

## Decisions Made

- Treat malformed `accrue_theme` cookie values as untrusted input and ignore them rather than letting `decodeURIComponent` abort the anti-FOUC script.
- Keep fixed-shell audit coverage source-level and marker-backed because the existing overlay architecture already satisfies the browser contract.
- Do not commit regenerated static assets for this plan because `mix accrue_admin.assets.build` produced no tracked asset diff after comment-only CSS source changes.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Hardened malformed theme-cookie handling**
- **Found during:** Task 1 (Prove affordance semantics and production theme persistence)
- **Issue:** The plan required sanitized `accrue_theme` cookie/localStorage behavior for T-199-19, but the anti-FOUC script decoded the cookie directly. A malformed percent-encoded cookie could throw before the root theme was set.
- **Fix:** Added `safeDecodeTheme` in `AccrueAdmin.Layouts.anti_fouc_script/0` and RED coverage that executes the script in Node with a malformed cookie.
- **Files modified:** `accrue_admin/lib/accrue_admin/layouts.ex`, `accrue_admin/test/accrue_admin/theme_test.exs`
- **Verification:** `cd accrue_admin && mix test test/accrue_admin/theme_test.exs --max-failures 5`
- **Committed in:** `23e53209`

---

**Total deviations:** 1 auto-fixed (1 missing critical)
**Impact on plan:** The auto-fix directly mitigates the plan threat register without changing public API, routes, dependencies, or overlay architecture.

## Issues Encountered

- The RED gate failed as intended on malformed cookie decoding and missing fixed-shell source-audit markers.
- The asset build completed with no tracked `priv/static` diff because the CSS source changes were comments consumed by source tests and stripped from the compiled bundle.

## Verification

- `cd accrue_admin && mix test test/accrue_admin/theme_test.exs --max-failures 5` - passed, 7 tests.
- `cd accrue_admin && npm run e2e:phase199 -- --grep @theme` - passed, 2 desktop tests; 2 mobile project variants intentionally skipped by the spec.
- `cd accrue_admin && npm run e2e:phase199 -- --grep @affordance` - passed, 2 desktop tests; 2 mobile project variants intentionally skipped by the spec.
- `bash scripts/ci/verify_package_docs.sh` - passed, including foundation contrast checks.
- `cd accrue_admin && mix accrue_admin.assets.build && git diff --check priv/static/accrue_admin.css` - passed; no tracked static asset diff.

## Known Stubs

None. Stub scan found only legitimate test helper JavaScript `null` checks and the existing CSS class name `.ax-input-placeholder`; no incomplete UI or mock data source was introduced.

## Threat Flags

None. The plan changed theme boot hardening, CSS comments, and tests only; it introduced no new network endpoint, auth path, file access pattern, schema change, or unplanned trust boundary.

## User Setup Required

None - no external service configuration required.

## TDD Gate Compliance

- RED commit present: `97c79102`
- GREEN commit present after RED: `23e53209`
- Refactor commit: not needed

## Self-Check: PASSED

- Confirmed SUMMARY exists at `.planning/phases/199-cross-cutting-interaction-overlay-correctness-fixture-stress/199-09-SUMMARY.md`.
- Confirmed key modified files exist.
- Confirmed RED commit `97c79102` and GREEN commit `23e53209` exist in git history.

## Next Phase Readiness

Plan 199-09 is complete. Phase 199 can continue with the remaining route-flow, fixture, and sign-off plans using the hardened production theme contract.

---
*Phase: 199-cross-cutting-interaction-overlay-correctness-fixture-stress*
*Completed: 2026-06-30*
