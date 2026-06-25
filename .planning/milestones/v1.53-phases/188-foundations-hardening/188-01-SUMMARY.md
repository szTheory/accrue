---
phase: 188-foundations-hardening
plan: "01"
subsystem: ui
tags: [accrue_admin, assets, tailwind, docs]
requires:
  - phase: 187-audit-baseline
    provides: "Severity-ranked foundation defect baseline and FND-04 inert Tailwind ambiguity"
provides:
  - "Deleted the package Tailwind config and preset files"
  - "Removed the Tailwind CLI --config input while preserving tailwindcss@3.4.17 as compiler/minifier"
  - "Documented theme.css and app.css as the AccrueAdmin styling authoring contract"
affects: [phase-188, phase-189, foundation-verifiers, admin-ui-docs]
tech-stack:
  added: []
  patterns:
    - "Tailwind remains a package-local compiler/minifier, not an authoring source of truth"
    - "AccrueAdmin styling authorship is limited to --ax-* tokens and ax-* classes in theme.css/app.css"
key-files:
  created:
    - ".planning/phases/188-foundations-hardening/188-01-SUMMARY.md"
  modified:
    - "accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex"
    - "accrue_admin/test/mix/tasks/accrue_admin_assets_build_test.exs"
    - "accrue_admin/guides/admin_ui.md"
  deleted:
    - "accrue_admin/assets/tailwind.config.js"
    - "accrue_admin/assets/tailwind_preset.js"
key-decisions:
  - "Preserved Tailwind CSS v3 as the package-local compiler/minifier and removed only the stale config/preset input."
  - "Documented --ax-* tokens and ax-* classes in theme.css/app.css as the only AccrueAdmin styling authoring path."
patterns-established:
  - "Asset build contract tests assert absence of --config and tailwind.config.js."
  - "Host apps never configure Tailwind for accrue_admin."
requirements-completed: [FND-04]
duration: 16 min
completed: 2026-06-16
---

# Phase 188 Plan 01: Tailwind Source-of-Truth Cleanup Summary

**Package-local Tailwind compilation without a config/preset authoring surface, backed by tests and guide wording**

## Performance

- **Duration:** 16 min
- **Started:** 2026-06-16T02:13:00Z
- **Completed:** 2026-06-16T02:29:05Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Deleted `accrue_admin/assets/tailwind.config.js` and `accrue_admin/assets/tailwind_preset.js`.
- Updated `mix accrue_admin.assets.build` so Tailwind still uses `tailwindcss@3.4.17`, `assets/css/app.css`, `priv/static/accrue_admin.css`, and `--minify`, but no longer passes `--config`.
- Strengthened the fake-runner test to assert the required Tailwind arguments and reject `--config` / `tailwind.config.js`.
- Rewrote the admin UI guide to name `assets/css/theme.css` and `assets/css/app.css` with `--ax-*` tokens and `ax-*` classes as the styling authoring contract.

## Task Commits

Each task was committed atomically:

1. **Task 1: Remove Tailwind config from the build contract** - `e3ecea0d` (fix)
2. **Task 2: Rewrite the admin UI styling source-of-truth docs** - `0b70f094` (docs)

**Plan metadata:** committed separately with this summary.

## Files Created/Modified

- `accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex` - Removed Tailwind `--config` and stale config path from build args.
- `accrue_admin/test/mix/tasks/accrue_admin_assets_build_test.exs` - Added assertions for Tailwind input/output/minify args and absence of config args.
- `accrue_admin/guides/admin_ui.md` - Clarified the build role and styling authoring source of truth.
- `accrue_admin/assets/tailwind.config.js` - Deleted.
- `accrue_admin/assets/tailwind_preset.js` - Deleted.

## Decisions Made

- Preserved Tailwind CSS v3 as the CSS compiler/minifier instead of replacing the asset pipeline.
- Treated `theme.css` and `app.css` as the complete package styling authoring surface; host Tailwind configuration remains outside the contract.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Verification

- `test ! -e accrue_admin/assets/tailwind.config.js` - passed.
- `test ! -e accrue_admin/assets/tailwind_preset.js` - passed.
- `cd accrue_admin && mix test --warnings-as-errors test/mix/tasks/accrue_admin_assets_build_test.exs` - passed, 1 test, 0 failures.
- `bash -lc 'grep -q "Tailwind utilities are not an authoring path" accrue_admin/guides/admin_ui.md'` - passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 02 can build on one styling source of truth without resolving package Tailwind config ambiguity. Plan 06 can add permanent guards for deleted config/preset files and docs drift.

---
*Phase: 188-foundations-hardening*
*Completed: 2026-06-16*
