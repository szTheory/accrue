---
phase: 188-foundations-hardening
plan: "07"
subsystem: testing
tags: [ci, verifier, css, playwright, kitchen, human-review]
human_review: approved
requires:
  - phase: 188-foundations-hardening
    provides: "Plans 01-06 foundation tokens, semantic role contrast verifier, kitchen specimens, and static verifier guards"
provides:
  - "Full automated foundation verification gate (static guards + unit suite + targeted Playwright)"
  - "Maintainer-approved foundation component kitchen across four review rounds"
  - "bin/kitchen one-command kitchen launcher and dropdown click-away dismissal"
affects: [phase-188, phase-189, phase-190, phase-191, release-gate]
tech-stack:
  added: []
  patterns:
    - "DB-safe gate order: static guards -> unit suite on a clean DB -> Playwright (e2e self-seeds outside the sandbox)."
    - "Dev kitchen renders each specimen once; light/dark reviewed via the page theme toggle."
    - "Token swatches render a color chip only for color-valued tokens; structural tokens show a kind tag."
key-files:
  created:
    - ".planning/phases/188-foundations-hardening/188-07-SUMMARY.md"
    - "accrue_admin/bin/kitchen"
    - "accrue_admin/assets/js/hooks/dropdown.js"
    - "accrue_admin/e2e/dropdown-dismiss.spec.js"
  modified:
    - "accrue_admin/assets/css/app.css"
    - "accrue_admin/assets/css/theme.css"
    - "accrue_admin/assets/js/app.js"
    - "accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex"
    - "accrue_admin/lib/accrue_admin/dev/component_registry.ex"
    - "accrue_admin/e2e/foundation-tokens.spec.js"
    - "accrue_admin/priv/static/accrue_admin.css"
    - "accrue_admin/priv/static/accrue_admin.js"
key-decisions:
  - "Treated the maintainer's 'looks good enough' as sign-off after four iterative kitchen review rounds."
  - "Kitchen remains an accrue_admin-only (:test env) tool; Docker host exposure is infeasible because deps compile as :prod and strip the Dev.* modules."
  - "Breadcrumb current crumb opts out of the global [aria-current=page] selected-pill background via higher-specificity override."
requirements-completed: [FND-01, FND-02, FND-03, FND-04, FND-05, FND-06]
duration: multi-session
completed: 2026-06-17
---

# Phase 188 Plan 07: Full Verification + Maintainer Kitchen Review Summary

**The full Phase 188 foundation verification gate passed and the foundation component kitchen was approved by the maintainer after four review rounds.**

## Accomplishments

- Ran the full foundation gate green in the DB-safe order: `scripts/ci/verify_package_docs.sh` (exit 0), `mix test` (266/0 on a clean DB), targeted Playwright foundation specs (26/26 including the new dropdown-dismiss coverage).
- Completed the blocking maintainer foundation-kitchen review across four feedback rounds, with each round rebuilt, gated, and committed atomically.
- Added `bin/kitchen`, a one-command launcher for the accrue_admin component kitchen (the kitchen is dev/test-only and cannot be served from a host app because dependencies compile as `:prod` and strip the `Dev.*` modules).

## Maintainer Review Rounds

1. **Round 1 — badge label semantics** (`c8178d9f`): made kitchen badge labels tone-coherent so each color reads true to its lifecycle status.
2. **Round 2 — z-index specimen + Docker DX** (`28b52554`, `5767f0c8`): reworked the elevation specimen into a visible cascading overlap that proves stacking order; added `bin/kitchen` after the Docker-demo exposure of dev routes proved infeasible.
3. **Round 3 — kitchen UX pass** (`1223298d`): removed the inert dual-theme wrappers (render once + page toggle), merged the redundant Badges/Status sections, fixed the cramped KPI pill, made the toast/scrollbar specimens actually demonstrate, added an editable input and self-explaining captions, and introduced the token-reference appendix.
4. **Round 4 — breadcrumb, dropdown, swatches** (`f099ff1a`): breadcrumb current crumb opts out of the selected-pill background; native `ax-dropdown` menus dismiss on outside-click/Escape via `initDropdowns()`; token swatches render a color chip only for color tokens and a muted kind tag for structural tokens; added `dropdown-dismiss.spec.js`.

## Task Commits

- **Task 1: full automated foundation gate** - `20a31a7e` (test)
- **Round 0 maintainer fixes (buttons, danger-solid, readonly, flash, specimens)** - `1571adb9` (fix), `35da4f44` (test)
- **Round 1** - `c8178d9f` (fix)
- **Round 2** - `28b52554` (fix), `5767f0c8` (chore)
- **Round 3** - `1223298d` (fix)
- **Round 4** - `f099ff1a` (fix)

## Decisions Made

- The component kitchen stays an accrue_admin-only tool served by its own `:test` e2e endpoint on :4017; exposing it in the Docker host demo is infeasible because deps compile as `:prod` and `allow_live_reload` requires a literal boolean.
- Specimens render once and are reviewed in light/dark via the page theme toggle, since `data-ax-theme` wrappers were inert (no scoped token CSS).
- Token swatches only paint for color-valued tokens; structural tokens (font/length/z-index/shadow/motion) show a kind tag rather than a misleading empty chip.

## Issues Encountered

- **External DB pollution:** lingering `MIX_ENV=test` e2e servers from prior sessions re-seeded edge-state rows outside the Ecto sandbox, failing `QueryModulesTest`/`DashboardLiveTest`. Resolved by SIGTERM-ing the stray servers and rebuilding the test DB; the suite then passed 266/0. This is the canonical reason the unit suite must run before Playwright on a clean DB.
- **FND-01 scope:** the verifier's raw-type guard also flags `letter-spacing`; the new `.ax-token-kind` tag was kept FND-01-clean by removing it and relying on uppercase + muted color for differentiation.

## Verification

- `bash scripts/ci/verify_package_docs.sh` - passed (exit 0), including FND-01..FND-06 and semantic role contrast.
- `cd accrue_admin && mix test` - 266 tests, 0 failures on a clean DB.
- `cd accrue_admin && npx playwright test e2e/reduced-motion.spec.js e2e/admin-a11y.spec.js e2e/kitchen-banner.spec.js e2e/foundation-tokens.spec.js e2e/dropdown-dismiss.spec.js` - 26 passed.
- Asset bundles rebuilt with no drift beyond `priv/static/accrue_admin.{css,js}`; no Tailwind config files present.

## Human Review

**Status: approved.** The maintainer reviewed the foundation kitchen across four rounds and confirmed it is good to ship. No follow-up changes requested.

- Visual-snapshot follow-up: not required — the `admin-visuals`/`admin-baseline` specs capture-and-score on the fly with no committed PNG baselines (all output is gitignored), so there is nothing to regenerate after the markup changes.
- Stray `examples/accrue_host/mix.lock` (an unrelated prior-session partial dep resolution) was reverted to the committed state.

## Next Phase Readiness

Phase 188 (foundations-hardening) is complete. The design system foundation — tokens, semantic role contrast, layer/motion routing, static verifier guards, and an approved component kitchen — is in place for Phases 189-192 of the v1.53 Admin UI Design-System Hardening milestone.

---
*Phase: 188-foundations-hardening*
*Completed: 2026-06-17*
